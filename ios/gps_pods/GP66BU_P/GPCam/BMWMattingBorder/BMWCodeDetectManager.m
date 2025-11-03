#import "BMWCodeDetectManager.h"
#import "BMWFramebuffer.h"
#import "BMWBaseDrawer.h"
#import "BMWGLUtils.h"
#import "UIView+GPCam.h"
#import "BMWDeviceUtils.h"
#import "GPCamDefine.h"
#import "BMWSliceData.h"
#import "BMWVlprAlgorithm.h"
#import "BMWOCRAlgorithmV3.h"
#import "GPCamRegistrator.h"
#import <Vision/Vision.h>

static int MIN_LOGO_IMAGE_SIZE = 320;

static GLfloat vertices[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};

@implementation BMWCodeRequestModel
- (instancetype)init
{
    if (self = [super init]) {
        _cropRect = CGRectMake(0, 0, 1, 1);
        _type = BMWCodeDetectTypeNone;
    }
    return self;
}
@end

@implementation BMWCodeReslutModel

- (NSString *)description
{
    return [NSString stringWithFormat:@"{data.count:%d, code:%@}", self.data.count, self.data.firstObject.label];
}

@end

@interface BMWCodeDetectManager ()
@property (nonatomic) BMWImageContext *context;
@property (nonatomic) BMWFramebuffer *outputFBO;
@end

@implementation BMWCodeDetectManager

+ (BMWCodeDetectManager*)sharedInstance
{
    static BMWCodeDetectManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[BMWCodeDetectManager alloc] init];
        }
    });
    return instance;
}

- (void)dealloc
{
    [self clearBuffer];
}

- (instancetype)init
{
    if (self = [super init]) {
        _context = BMWImageContext.sharedImageProcessingContext;
        requestModelDownload(@"generalOCR");
    }
    return self;
}

- (void)clearBuffer
{
    runSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        if (self.outputFBO) {
            [self.outputFBO destroy];
            self.outputFBO = nil;
        }
        [self.context flush];
    });
}

- (void)detectWithRequestBulder:(void (^)(BMWCodeRequestModel *model))builder completeBlock:(void (^)(BMWCodeReslutModel* _Nullable reslutModel, NSError *_Nullable error))completeBlock
{
    BMWCodeRequestModel *model = [[BMWCodeRequestModel alloc] init];
    SafeBlock(builder, model);
    BMWCodeReslutModel *reslutModel = [[BMWCodeReslutModel alloc] init];

    __block NSError *error = nil;
    if (model.image == nil) {
        error = [BMWErrorHelper codeDetectErrorDomain:nil code:-1 toast:@"检测失败，请重试"];
        SafeBlock(completeBlock, reslutModel, error);
        return;
    }
    double begin = CACurrentMediaTime();
    runOnContextQueue(model.sync, self.context, ^{
        [self.context useAsCurrentContext];
        // draw input
        __block GLuint scrId = 0;
        __block CGSize inputSize;
        BMWImageRotationMode rotationMode = [self imageRotationMode:model.image];
        [BMWGLUtils getRawData:model.image forceRedraw:YES block:^(GLubyte * _Nonnull imageData, int width, int height, GLenum format) {
            scrId = [BMWGLUtils createTextureWithData:imageData width:width height:height];
            inputSize = CGSizeMake(width, height);
        }];

        CGFloat ratio = 640.0f / MAX(inputSize.width, inputSize.height);
        CGSize algorithmSize = CGSizeMake(inputSize.width * ratio, inputSize.height * ratio);
        BMWBaseDrawer *inputDrawer = [[BMWBaseDrawer alloc] init];
        BMWFramebuffer *inputFBO = [[BMWFramebuffer alloc] initWithSize:algorithmSize imageContext:self.context];
        [inputFBO bind];
        [inputDrawer drawWithTexId:scrId vertices:vertices rotation:rotationMode];

        BMWRect *normCropRect = BMWMakeRectFromCGRect(model.cropRect);

        GLfloat l = MAX(normCropRect.left, 0.0);
        GLfloat t = MAX(normCropRect.top, 0.0);
        GLfloat r = MIN(normCropRect.right, 1.0);
        GLfloat b = MIN(normCropRect.bottom, 1.0);
        const GLfloat coordinates[8] = {
            l, t,
            r, t,
            l, b,
            r, b,
        };

        // crop draw
        CGFloat cropW = normCropRect.width * inputSize.width;
        CGFloat cropH = normCropRect.height * inputSize.height;
        BMWBaseDrawer *cropDrawer = [[BMWBaseDrawer alloc] init];
        BMWFramebuffer *cropFBO = [[BMWFramebuffer alloc] initWithSize:CGSizeMake(cropW, cropH) imageContext:self.context];
        [cropFBO bind];
        [cropDrawer drawWithTexId:scrId vertices:vertices coordinates:coordinates];
        glFinish();
        self.outputFBO = cropFBO;
        __block NSError *error = nil;
        if(model.type == BMWCodeDetectTypeLPCode) {
            [self detectLP:cropFBO.renderTarget completeBlock:^(NSArray<BMWOCRMetaData *> *data, NSError * _Nullable error) {
                reslutModel.data = data;
                error = error;
            }];
        } else if(model.type == BMWCodeDetectTypeBarCode) {
            [self detectBarCode:model.captureMetaData.metadataObjects completeBlock:^(NSArray<BMWOCRMetaData *> *data, NSError * _Nullable error) {
                reslutModel.data = data;
                error = error;
            }];
        }  else if(model.type == BMWCodeDetectTypeOCRCode) {
            [self detectOCR:cropFBO.renderTarget completeBlock:^(NSArray<BMWOCRMetaData *> *data, NSError * _Nullable error) {
                reslutModel.data = data;
                error = error;
            }];
        } else {
            NSAssert(NO, @"不支持的XHCodeDetectType");
        }
        // rect坐标转换
        for (BMWOCRMetaData *data in reslutModel.data) {
            BMWRect *rect = BMWMakeRectFromCGRect(data.rect);
            if(rect.width > 0 && rect.height > 0) {
                data.rect = [rect convert2ParentRect:normCropRect].CGrect;
            }
        }
        // release2
        glDeleteTextures(1, &scrId);
        [inputDrawer destory];
        [inputFBO destroy];
        [cropDrawer destory];
        if(cropFBO != self.outputFBO) {
            [cropFBO destroy];
        }
        double timeCost = CACurrentMediaTime() - begin;
        reslutModel.cropImage = self.outputFBO.imageFromFramebufferContent;
        reslutModel.type = model.type;
        SafeBlock(completeBlock, reslutModel, error);
        [self.outputFBO destroy];
            });
}

- (BMWImageRotationMode)imageRotationMode:(UIImage*)image
{
    UIImageOrientation orientation = image.imageOrientation;
    BMWImageRotationMode rotationMode = kXHImageNoRotation;
    if (orientation == UIImageOrientationLeft) {
        rotationMode = kXHImageRotateLeft;
    } else if (orientation == UIImageOrientationRight) {
        rotationMode = kXHImageRotateRight;
    } else if (orientation == UIImageOrientationDown) {
        rotationMode = kXHImageRotate180;
    } else if (orientation == UIImageOrientationDownMirrored) {
        rotationMode = kXHImageFlipHorizonal;
    } else if (orientation == UIImageOrientationLeftMirrored) {
        rotationMode = kXHImageFlipVertical;
    } else if (orientation == UIImageOrientationRightMirrored) {
        rotationMode = kXHImageFlipVertical;
    }
    return rotationMode;
}

- (void)detectBarCode:(NSArray<BMWOCRMetaData*>*)objects completeBlock:(void (^)(NSArray<BMWOCRMetaData*> *data, NSError *_Nullable error))completeBlock;
{
    NSMutableArray<BMWOCRMetaData*>* array = [[NSMutableArray alloc] init];
    for (BMWOCRMetaData* obj in objects) {
        [array addObject:obj];
    }
    SafeBlock(completeBlock, array , nil);
}

- (void)detectQrcode:(UIImage*)image completeBlock:(void (^)(NSArray<BMWOCRMetaData*> *data, NSError *_Nullable error))completeBlock;
{
    CIImage *ciImage = [CIImage imageWithCGImage:image.CGImage];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{ CIDetectorAccuracy : CIDetectorAccuracyHigh }];
    NSArray *features = [detector featuresInImage:ciImage];

    NSMutableArray<BMWOCRMetaData*>* array = [[NSMutableArray alloc] init];
    for (CIQRCodeFeature *feature in features) {
        BMWOCRMetaData* data = [[BMWOCRMetaData alloc] init];
        data.label = feature.messageString;
        data.rect = feature.bounds;
        [array addObject:data];
    }
    SafeBlock(completeBlock, array , nil);
}

-(void)detectLP:(CVPixelBufferRef*)buffer completeBlock:(void (^)(NSArray<BMWOCRMetaData*> *data, NSError *_Nullable error))completeBlock
{
    BMWVlprAlgorithm* vlprAlgorithm = [[BMWVlprAlgorithm alloc] init];
    [vlprAlgorithm start];
    BMWVlprAlgorithmResult *result = [vlprAlgorithm process:^(BMWAlgorithmProcessProfile * _Nonnull profile) {
        profile.pixelBuffer = buffer;
    }];

    NSMutableArray<BMWOCRMetaData*>* array = [[NSMutableArray alloc] init];
    BMWOCRMetaData* data = [[BMWOCRMetaData alloc] init];
    data.label = result.data.firstObject.formatCharacter;
    [array addObject:data];
    SafeBlock(completeBlock, array , nil);
    [vlprAlgorithm stop];
}

-(void)detectOCR:(CVPixelBufferRef*)buffer completeBlock:(void (^)(NSArray<BMWOCRMetaData*> *data, NSError *_Nullable error))completeBlock
{
    BMWOCRAlgorithmV3* ocrAlgorithm = [[BMWOCRAlgorithmV3 alloc] init];
    [ocrAlgorithm start];
    BMWOCRAlgorithmResult *result = [ocrAlgorithm process:^(BMWAlgorithmProcessProfile * _Nonnull profile) {
        profile.pixelBuffer = buffer;
    }];
    SafeBlock(completeBlock, result.data , nil);
    [ocrAlgorithm stop];
}

- (void)scanBarcodeByVision:(BMWCodeRequestModel *)model completeBlock:(void (^)(BMWCodeReslutModel* _Nullable reslutModel, NSError *_Nullable error))completeBlock
{
    BMWCodeReslutModel *reslutModel = [[BMWCodeReslutModel alloc] init];
    NSMutableArray<BMWOCRMetaData*> *array = [[NSMutableArray alloc] initWithCapacity:5];
    reslutModel.data = array;
    reslutModel.cropImage = model.image;

    CIImage *ciImage = [[CIImage alloc] initWithImage:model.image];

    // 创建Vision的条形码扫描请求
    VNSequenceRequestHandler *requestHandler = [[VNSequenceRequestHandler alloc] init];
    VNDetectBarcodesRequest *request = [[VNDetectBarcodesRequest alloc] initWithCompletionHandler:^(VNRequest * _Nonnull request, NSError * _Nullable error) {
        if (error) {
                        NSError *error2 = [BMWErrorHelper codeDetectErrorDomain:error code:-2 toast:@"检测失败，请重试"];
            runOnMainQueue(NO, ^{
                SafeBlock(completeBlock, nil, error2);
            });
            return;
        }
        NSArray *results = request.results;
        for (VNBarcodeObservation *observation in results) {
                        VNBarcodeSymbology symbology = observation.symbology;
            if (symbology == VNBarcodeSymbologyQR && ((model.type & BMWCodeDetectTypeQRCode) != BMWCodeDetectTypeQRCode )) {
                continue;
            }
            if (symbology != VNBarcodeSymbologyQR && ((model.type & BMWCodeDetectTypeBarCode) != BMWCodeDetectTypeBarCode )) {
                continue;
            }
            if (symbology == VNBarcodeSymbologyQR) {
                reslutModel.type |= BMWCodeDetectTypeQRCode;
            }
            if (symbology != VNBarcodeSymbologyQR) {
                reslutModel.type |= BMWCodeDetectTypeBarCode;
            }
            BMWOCRMetaData* data = [[BMWOCRMetaData alloc] init];
            data.label = observation.payloadStringValue;
            CGFloat x = observation.boundingBox.origin.x;
            CGFloat y = observation.boundingBox.origin.y;
            CGFloat w = observation.boundingBox.size.width;
            CGFloat h = observation.boundingBox.size.height;
            data.rect = CGRectMake(x, 1 - y - h, w, h);
            [array addObject:data];
        }
        SafeBlock(completeBlock, reslutModel, nil);
    }];

    NSError *error = nil;
    // 处理图像中的条形码扫描
    [requestHandler performRequests:@[request] onCIImage:ciImage error:&error];
    if (error) {
                NSError *error2 = [BMWErrorHelper codeDetectErrorDomain:error code:-3 toast:@"检测失败，请重试"];
        SafeBlock(completeBlock, nil, error2);
    }
}

- (void)detectV2WithRequestBulder:(void (^)(BMWCodeRequestModel *model))builder completeBlock:(void (^)(BMWCodeReslutModel* _Nullable reslutModel, NSError *_Nullable error))completeBlock
{
    BMWCodeRequestModel *model = [[BMWCodeRequestModel alloc] init];
    SafeBlock(builder, model);
    BMWCodeReslutModel *reslutModel = [[BMWCodeReslutModel alloc] init];

        __block NSError *error = nil;
    if (model.image == nil) {
        error = [BMWErrorHelper codeDetectErrorDomain:nil code:-1 toast:@"检测失败，请重试"];
        SafeBlock(completeBlock, reslutModel, error);
        return;
    }
    if((model.type & BMWCodeDetectTypeBarCode) == BMWCodeDetectTypeBarCode ||
       (model.type & BMWCodeDetectTypeQRCode) == BMWCodeDetectTypeQRCode) {
        [self scanBarcodeByVision:model completeBlock:completeBlock];
    } else {
        [self detectWithRequestBulder:^(BMWCodeRequestModel * _Nonnull modelV2) {
            modelV2.sync = model.sync;
            modelV2.type = model.type;
            modelV2.cropRect = model.cropRect;
            modelV2.image = model.image;
            modelV2.captureMetaData = model.captureMetaData;
        } completeBlock:completeBlock];
    }
}

@end
