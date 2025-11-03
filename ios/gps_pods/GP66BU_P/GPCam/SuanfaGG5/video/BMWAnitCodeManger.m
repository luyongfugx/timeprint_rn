#import "BMWAnitCodeManger.h"
#import "BMWVideoAlgorithmOCRSource.h"
#import "BMWVideoExtractor.h"
#import "BMWWatermarkExtractor.h"
#import "BMWErrorHelper.h"
#import "BMWGLUtils.h"
#import "BMWOCRProcessDrawer.h"

@interface BMWAnitCodeRequestModel()
@property (nonatomic) UIImage* adjustedImage;
// 标记检测流程是否走完，无论是否遇到错误，默认为true
@property (nonatomic) BOOL passThrough;
// 标记盲水印提取失败时候，是否重试，以支持拼图和边拍边拼，默认为false
@property (nonatomic) BOOL shouldAdjustedImage;
@property (nonatomic) NSUInteger adjustedCount;
@property (nonatomic) NSUInteger MaxAdjustedCount;
@end

@implementation BMWAnitCodeRequestModel
- (instancetype)init
{
    if (self = [super init]) {
        _passThrough = YES;
        _shouldAdjustedImage = YES;
        _MaxAdjustedCount = 2;
        _similarityThreshold = 0.2f;
    }
    return self;
}

- (BOOL)shouldAdjustedImage
{
    return (_shouldAdjustedImage && self.adjustedImage == nil) ||
    self.adjustedCount < self.MaxAdjustedCount;
}
@end

@implementation BMWAnitCodeReslutModel

- (NSString *)description
{
    return [NSString stringWithFormat:@"{%@, %@, %@}", self.wmResultModel, self.ocrMetaData, self.codeDataModel];
}

@end

@implementation BMWAnitCodeErrorModel
- (NSString *)description
{
    return [NSString stringWithFormat:@"{shouldAbort:%@, bwmError:%@, codeError:%@}", @(self.shouldAbort), self.bwmError, self.codeError];
}

@end

@interface BMWAnitCodeManger()
@property (nonatomic) BOOL busy;
@property (nonatomic) BMWVideoExtractor *ocrExtractor;
@property (nonatomic) BMWWatermarkExtractor *wmExtractor;
@property (nonatomic, copy) void (^completeBlock)(BMWAnitCodeReslutModel* _Nullable codeReslutModel, BMWAnitCodeErrorModel *_Nullable errorModel);
@property (nonatomic) BMWAnitCodeRequestModel *requestModel;
@property (nonatomic) BMWAnitCodeReslutModel *reslutModel;
@property (nonatomic) NSInteger retryCount;
@property (nonatomic) BMWImageContext *context;
@property (nonatomic) BMWFramebuffer *adjustedFBO;
@property (nonatomic) NSError *bwmError;
@property (nonatomic) NSError *codeError;
@end

@implementation BMWAnitCodeManger

- (void)triggerCallBack
{
    dispatch_async(dispatch_get_main_queue(), ^{
        BMWAnitCodeErrorModel *errorModel = nil;
        if(self.bwmError != nil || self.codeError != nil) {
            errorModel = [[BMWAnitCodeErrorModel alloc] init];
            if (self.bwmError != nil ||
                (self.bwmError == nil && self.requestModel.abortWhenError)) {
                errorModel.shouldAbort = YES;
            }
            errorModel.bwmError = self.bwmError;
            errorModel.codeError = self.codeError;
        }
        NSString *baseInfo = [NSString stringWithFormat:@"callBack errorModel:%@, codeReslutModel:%@", errorModel, self.reslutModel];

        SafeBlock(self.completeBlock, self.reslutModel, errorModel);
        [self reset];
    });
}

- (void)dealloc
{
    [self reset];
}

- (void)reset
{
    self.busy = NO;
    self.bwmError = nil;
    self.codeError = nil;
    self.requestModel.adjustedImage = nil;
    self.requestModel = nil;
    [self.ocrExtractor stopDetect];
    [self removeObservers];
    runSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        if(self.adjustedFBO != nil) {
            [self.adjustedFBO destroy];
            self.adjustedFBO = nil;
        }
        [self.context flush];
    });
}

- (instancetype)init
{
    if (self = [super init]) {
        self.ocrExtractor = BMWVideoExtractor.ocrExtractor;
        self.context = BMWImageContext.sharedImageProcessingContext;
        self.wmExtractor = [[BMWWatermarkExtractor alloc] init:self.context];
        self.retryCount = 0;
    }
    return self;
}

- (void)probeAntiCodeWithRequestBulder:(void (^)(BMWAnitCodeRequestModel *model))builder completeBlock:(void (^)(BMWAnitCodeReslutModel* _Nullable codeReslutModel, BMWAnitCodeErrorModel *_Nullable errorModel))completeBlock
{
    BMWAnitCodeRequestModel *requestModel = [[BMWAnitCodeRequestModel alloc] init];
    SafeBlock(builder, requestModel);
    NSError *error = nil;
    if (self.busy) {
        error = [BMWErrorHelper antiCodeErrorDomain:nil code:BMWAntiCodeErrorDomainBusy msg:@"busy .."];
        self.bwmError = error;
        [self triggerCallBack];
        return;
    }
    if (requestModel.image == nil) {
        NSString *msg = [NSString stringWithFormat:@"input image null"];
        error = [BMWErrorHelper antiCodeErrorDomain:nil code:BMWAntiCodeErrorDomainAntiCodeInvalidParameter msg:msg];
        self.bwmError = error;
        [self triggerCallBack];
        return;
    }
    self.busy = YES;
    self.requestModel = requestModel;
    self.reslutModel = [[BMWAnitCodeReslutModel alloc] init];
    self.completeBlock = completeBlock;
    [self extractBWM];
}

- (void)extractBWM
{
    // reset
    self.bwmError = nil;
    self.reslutModel.wmResultModel = nil;
    self.reslutModel.ocrMetaData = nil;
    // start
    __weak typeof(self) wself = self;
    UIImage *image = self.requestModel.adjustedImage != nil ? self.requestModel.adjustedImage : self.requestModel.image;
    [self.wmExtractor extract:image completeBlock:^(BMWWatermarkResultModel * _Nullable wmResultModel, NSError * _Nullable error) {
        __strong typeof(wself) sself = wself;
        sself.reslutModel.wmResultModel = wmResultModel;
        if (wmResultModel.allSimilarity < sself.requestModel.similarityThreshold) {
            NSString *msg = [NSString stringWithFormat:@"bwm similarity less than threshold, want:%@, get:%@", @(sself.requestModel.similarityThreshold), @(wmResultModel.allSimilarity)];
            error = [BMWErrorHelper antiCodeErrorDomain:nil code:BMWAntiCodeErrorDomainBWMFail msg:msg];
            sself.bwmError = error;
                        // adjustedImage为空，进行image裁剪后再做检测
            if(sself.requestModel.shouldAdjustedImage) {
                sself.requestModel.adjustedCount++;
                                UIImage *adjustedInputImage = sself.requestModel.adjustedImage == nil ?
                sself.requestModel.image : sself.requestModel.adjustedImage;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [sself adjustInputImage:adjustedInputImage completeBlock:^(UIImage* adjustedImage) {
                        sself.requestModel.adjustedImage = adjustedImage;
                        [sself extractBWM];
                    }];
                });
                return;
            }
            if (!sself.requestModel.shouldAdjustedImage && !sself.requestModel.passThrough) {
                [sself triggerCallBack];
                return;
            }
        }
        [sself extractCode:sself.retryCount];
    }];
}

- (void)extractCode:(NSUInteger)level
{
    // reset
    [self removeObservers];
    [self.ocrExtractor stopDetect];
    self.codeError = nil;
    self.reslutModel.codeDataModel = nil;
    self.reslutModel.ocrMetaData = nil;
    // start
    UIImage *image = self.requestModel.adjustedImage != nil ? self.requestModel.adjustedImage : self.requestModel.image;
    CGSize size = image.size;
    BMWVideoAlgorithmOCRSource *source = [[BMWVideoAlgorithmOCRSource alloc] initWithImage:image size:size level:level];
    [self.ocrExtractor setSource:source];
    self.ocrExtractor.refreshInterval = 0.1;
    [self addObservers];
    [self.ocrExtractor startDetect];
}

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ocrNotification:) name:BMWOCRResultNotification object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:BMWOCRResultNotification object:nil];
}

- (void)ocrNotification:(NSNotification*)notification
{
    NSError *error = nil;
    NSDictionary *userInfo = notification.userInfo;
    if (!userInfo[@"pp_ocr"]) {
        NSString *msg = [NSString stringWithFormat:@"algorithm detect internal error!!"];
        self.codeError = [BMWErrorHelper antiCodeErrorDomain:nil code:BMWAntiCodeErrorDomainOCRDetectInitError msg:msg];
        [self triggerCallBack];
        return;
    }

    BMWOCRAlgorithmResult *result = userInfo[@"pp_ocr"];

    BMWOCRMetaData *ocrMetaData = result.data.firstObject;
    self.reslutModel.ocrMetaData = ocrMetaData;

    // result
    NSString* label = ocrMetaData.label;
    __unused CGRect rect = ocrMetaData.rect;

    // tips
    BMWCodeDataModel *data = [BMWCodeDataModel buildWithCode:label];
    self.reslutModel.codeDataModel = data;
    NSString *baseInfo = [NSString stringWithFormat:@"valid:%@, retryCount:%@, containIllegalWord:%d, label[%@], rawLabel[%@]", @(data.valid), @(self.retryCount), ocrMetaData.containIllegalWord, ocrMetaData.label, ocrMetaData.rawLabel];
        if (self.bwmError == nil && !data.valid && self.retryCount < BMWVideoAlgorithmOCRSource.maxRetryCount) {
        self.retryCount++;
        [self extractCode:self.retryCount];
        return;
    }
    self.retryCount = 0;
    if (result.status == 0) {
        NSString *msg = [NSString stringWithFormat:@"ocr code detect return nothing, maybe init fail, suggest user restart!! or no code on picture!! baseInfo: %@", baseInfo];
        error = [BMWErrorHelper antiCodeErrorDomain:nil code:BMWAntiCodeErrorDomainOCRDetectNull msg:msg];
    } else if (ocrMetaData.label.length != data.digitCount) {
        NSString *msg = [NSString stringWithFormat:@"ocr code len error!! baseInfo: %@", baseInfo];
        error = [BMWErrorHelper antiCodeErrorDomain:nil code:BMWAntiCodeErrorDomainOCRDetectLenError msg:msg];
   } else if (!data.valid) {
       NSString *msg = [NSString stringWithFormat:@"code internal check invalid!! baseInfo: %@", baseInfo];
       error = [BMWErrorHelper antiCodeErrorDomain:nil code:BMWAntiCodeErrorDomainInvalidCode msg:msg];
    } else {
        if (self.requestModel.timestampExtraCheck) {
            BOOL pass = self.requestModel.timestampExtraCheck(data.timestampFormat, data.timeStamp);
            if(!pass) {
                NSString *msg = [NSString stringWithFormat:@"code extra timestamp check invalid!! baseInfo: %@", baseInfo];
                error = [BMWErrorHelper antiCodeErrorDomain:nil code:BMWAntiCodeErrorDomainInvalidStimetamp msg:msg];
            }
        }
        if (self.requestModel.locationExtraCheck && !error) {
            BOOL pass = self.requestModel.locationExtraCheck(data.longitude, data.latitude);
            if(!pass) {
                NSString *msg = [NSString stringWithFormat:@"code extra location check invalid!! baseInfo: %@", baseInfo];
                error = [BMWErrorHelper antiCodeErrorDomain:nil code:BMWAntiCodeErrorDomainInvalidLocation msg:msg];
            }
        }
    }
    // 对错误做一下映射，尝试对作弊的case做一个判断, 如果命中强制去掉bwmError错误
    // 前置条件：检测到了非法字符
    // 其他条件分两种可能：a）字符长度不对(目前作弊的case，字符长度一般都不对)；b）盲水印提取失败
    // 可能性b 基于今拍照片的OCR提取异常和盲水印提取异常同时出现的概率很低
    if (ocrMetaData.containIllegalWord &&
        (error.code == BMWAntiCodeErrorDomainOCRDetectLenError /*|| self.bwmError*/)) {
         NSString *msg = [NSString stringWithFormat:@"ocr code contain illegal character!! maybe cheat!! baseInfo: %@", baseInfo];
         self.bwmError = nil;
         error = [BMWErrorHelper antiCodeErrorDomain:nil code:BMWAntiCodeErrorDomainCodeCheat msg:msg];
    }
    self.codeError = error;
    [self triggerCallBack];
}

- (BOOL)validCode:(BMWCodeDataModel*)data
{
    if (!data.valid) {
        return NO;
    }
    if (self.requestModel.timestampExtraCheck) {
        BOOL valid = self.requestModel.timestampExtraCheck(data.timestampFormat, data.timeStamp);
        if (!valid) {
            return NO;
        }
    }
    if (self.requestModel.locationExtraCheck) {
        BOOL valid = self.requestModel.locationExtraCheck(data.longitude, data.latitude);
        if (!valid) {
            return NO;
        }
    }
    return YES;
}

- (void)adjustInputImage:(UIImage*)image completeBlock:(void (^)(UIImage* _Nullable adjustedImage))completeBlock
{
    runAsynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        CGSize imageSize = image.size;
        GLuint srcTexId = [BMWGLUtils setupTexture:image];
        float scale = 480.0f / MAX(imageSize.width, imageSize.height);
        CGSize scaledSize = CGSizeMake(imageSize.width * scale, imageSize.height * scale);
        BMWBaseDrawer *resizeDrawer = [[BMWBaseDrawer alloc] init];
        BMWFramebuffer *resizeFBO = [[BMWFramebuffer alloc] initWithSize2:scaledSize imageContext:self.context];
        [resizeFBO bind];
        [resizeDrawer drawWithTexId:srcTexId];
        glFinish();

        CVPixelBufferRef pixelBuffer = resizeFBO.renderTarget;
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);
        int width = (int)CVPixelBufferGetWidth(pixelBuffer);
        int height = (int)CVPixelBufferGetHeight(pixelBuffer);
        int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
        unsigned char *ori = CVPixelBufferGetBaseAddress(pixelBuffer);
        int top = 0; int bottom = height; int left = 0; int right = width;

        // scan row for top/botom
        bool findTop = true;
        for (int v = 0; v < height; v++) {
            long r = LONG_MAX; long g = LONG_MAX;  long b = LONG_MAX;
            long avg_r = 0; long avg_g = 0; long avg_b = 0;
            long bDelta = 0; long gDelta = 0; long rDelta = 0;
            findTop = v < height / 5;
            for (int u = 0; u < width; u++) {
                int index = v*stride + 4*u;
                avg_r += ori[index+2];
                avg_g += ori[index+1];
                avg_b += ori[index+0];
                if (u == width - 1) {
                    // 计算均值
                    avg_r = (int)(avg_r / width);
                    avg_g = (int)(avg_g / width);
                    avg_b = (int)(avg_b / width);
                    // 计算方差
                    for (int u = 0; u < width; u++) {
                        int index = v*stride + 4*u;
                        rDelta +=powl(avg_r-ori[index+2], 2);
                        gDelta +=powl(avg_g-ori[index+1], 2);
                        bDelta +=powl(avg_b-ori[index+0], 2);
                    }
                    rDelta /= width; gDelta /= width; bDelta /= width;
                    rDelta = pow(rDelta, 0.5);
                    gDelta = pow(gDelta, 0.5);
                    bDelta = pow(bDelta, 0.5);
                    if (rDelta < 5 && gDelta < 5 && bDelta < 5) {
                        if (findTop) {
                            top = v+1;
                        } else {
                            bottom = v;
                            v += height;
                            break;
                        }
                    }
                }
            }
        }
        // scan row for left/right
        bool findLeft = true;
        for (int u = 0; u < width; u++) {
            long r = LONG_MAX; long g = LONG_MAX; long b = LONG_MAX;
            long avg_r = 0; long avg_g = 0; long avg_b = 0;
            findLeft = u < width / 4;
            for (int v = 0; v < height; v++) {
                int index = v*stride + 4*u;
                avg_r += ori[index+2];
                avg_g += ori[index+1];
                avg_b += ori[index+0];
                if (r == LONG_MAX && g == LONG_MAX && b == LONG_MAX) {
                    r = ori[index+2];
                    g = ori[index+1];
                    b = ori[index+0];
                }
                int tmp_r = (int)(avg_r / (v+1));
                int tmp_g = (int)(avg_g / (v+1));
                int tmp_b = (int)(avg_b / (v+1));
                if (labs(tmp_r-r) > 1 && labs(tmp_g-g) > 1 && labs(tmp_b-b) > 1) {
                    break;
                }
                if (v == height - 1) {
                    avg_r = (int)(avg_r / height);
                    avg_g = (int)(avg_g / height);
                    avg_b = (int)(avg_b / height);
                    if (labs(avg_r-r) < 2 && labs(avg_g-g) < 2 && labs(avg_b-b) < 2) {
                        if (findLeft) {
                            left = u+1;
                        } else {
                            right = u;
                            u += width;
                            break;
                        }
                    }
                }
            }
        }
        CVPixelBufferLockBaseAddress(pixelBuffer, 0);

        // 裁剪失败做一些兼容处理
                if ((left == 0.0 && top == 0.0 && right == width && bottom == height)/*无裁剪*/ ||
            (right - left <= width*0.1 || bottom - top <= height*0.1)/*裁剪异常*/ ||
            (top > 0) /*拼图或是边拍边拼*/) {
            glDeleteTextures(1, (const GLuint *)&srcTexId);
            [resizeDrawer destory];
            [resizeFBO destroy];
            dispatch_async(dispatch_get_main_queue(), ^{
                SafeBlock(completeBlock , image);
            });
            return;
        }

        // 方格图再一些微调
        if(right - left < width && bottom - top < height) {
            CGRect margin = [self probeMargin:pixelBuffer rect:CGRectMake(left, top, right, bottom) ratio:0.08];
            left += margin.origin.x;
            top += margin.origin.y;
            right -= margin.size.width;
            bottom -= margin.size.height;
        }

        float l = (float )left / width;
        float t = (float )top / height;
        float r = (float )right / width;
        float b = (float )bottom / height;

        const GLfloat coordinates[8] = {
            l, t,
            r, t,
            l, b,
            r, b,
        };
        GLfloat vertices[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f,  1.0f,
            1.0f,  1.0f,
        };

        if (!(r > l && b > t)) {
            dispatch_async(dispatch_get_main_queue(), ^{
                SafeBlock(completeBlock , image);
            });
            return;
        }

        CGSize cropedSize = CGSizeMake(imageSize.width * (r - l), imageSize.height * (b - t));
        BMWBaseDrawer *adjustedDrawer = [[BMWBaseDrawer alloc] init];
        self.adjustedFBO = [[BMWFramebuffer alloc] initWithSize:cropedSize imageContext:self.context];
        [self.adjustedFBO bind];
        [adjustedDrawer drawWithTexId:srcTexId vertices:vertices coordinates:coordinates];
        glFinish();
        dispatch_async(dispatch_get_main_queue(), ^{
            SafeBlock(completeBlock , self.adjustedFBO.imageFromFramebufferContent);
        });
        [adjustedDrawer destory];
        [resizeDrawer destory];
        [resizeFBO destroy];
        glDeleteTextures(1, (const GLuint *)&srcTexId);
    });
}

- (CGRect)probeMargin:(CVPixelBufferRef)buffer rect:(CGRect)rect ratio:(float)ratio
{
    CVPixelBufferLockBaseAddress(buffer, 0);
    int x = rect.origin.x;
    int y = rect.origin.y;
    int width = (int)rect.size.width;
    int height = (int)rect.size.height;
    int stride = (int)CVPixelBufferGetBytesPerRow(buffer);
    unsigned char* ori = (unsigned char *)CVPixelBufferGetBaseAddress(buffer);
    long avg_r = 0; long avg_g = 0; long avg_b = 0;
    // top
    int topPixelCount = 0;
    for (int row = y; row < height; row++) {
        for (int col = x; col < width; col++) {
            int index = row * stride + 4 * col;
            avg_r += ori[index+2];
            avg_g += ori[index+1];
            avg_b += ori[index+0];
            if (col == width - 1) {
                int count = width-x;
                avg_r = (int)(avg_r / count);
                avg_g = (int)(avg_g / count);
                avg_b = (int)(avg_b / count);
                if (labs(avg_r - 255) < 255*ratio && labs(avg_g - 255) < 255*ratio && labs(avg_b - 255) < 255*ratio) {
                    topPixelCount++;
                } else {
                    row = height;
                    break;
                }
            }
        }
    }
    int bottomPixelCount = 0;
    for (int row = height-1; row >= y; row--) {
        for (int col = x; col < width; col++) {
            int index = row * stride + 4 * col;
            avg_r += ori[index+2];
            avg_g += ori[index+1];
            avg_b += ori[index+0];
            if (col == width - 1) {
                int count = width-x;
                avg_r = (int)(avg_r / count);
                avg_g = (int)(avg_g / count);
                avg_b = (int)(avg_b / count);
                if (labs(avg_r - 255) < 255*ratio && labs(avg_g - 255) < 255*ratio && labs(avg_b - 255) < 255*ratio) {
                    bottomPixelCount++;
                } else {
                    row = -1;
                    break;
                }
            }
        }
    }

    int leftPixelCount = 0;
    for (int col = x; col < width; col++) {
        for (int row = y; row < height; row++) {
            int index = row * stride + 4 * col;
            avg_r += ori[index+2];
            avg_g += ori[index+1];
            avg_b += ori[index+0];
            if (row == height - 1) {
                int count = height-y;
                avg_r = (int)(avg_r / count);
                avg_g = (int)(avg_g / count);
                avg_b = (int)(avg_b / count);
                if (labs(avg_r - 255) < 255*ratio && labs(avg_g - 255) < 255*ratio && labs(avg_b - 255) < 255*ratio) {
                    leftPixelCount++;
                } else {
                    col = width;
                    break;
                }
            }
        }
    }

    int rightPixelCount = 0;
    for (int col = width-1; col >= x; col--) {
        for (int row = y; row < height; row++) {
            int index = row * stride + 4 * col;
            avg_r += ori[index+2];
            avg_g += ori[index+1];
            avg_b += ori[index+0];
            if (row == height - 1) {
                int count = height-y;
                avg_r = (int)(avg_r / count);
                avg_g = (int)(avg_g / count);
                avg_b = (int)(avg_b / count);
                if (labs(avg_r - 255) < 255*ratio && labs(avg_g - 255) < 255*ratio && labs(avg_b - 255) < 255*ratio) {
                    rightPixelCount++;
                } else {
                    col = -1;
                    break;
                }
            }
        }
    }
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    CGRect marginRect = CGRectMake(leftPixelCount, topPixelCount, rightPixelCount, bottomPixelCount);
    return marginRect;
}

- (void)debugReslut:(NSString*)baseInfo
{
    UIAlertController *alterController = [UIAlertController alertControllerWithTitle:@"检测信息" message:baseInfo preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil];
    [alterController addAction:action];
    UIViewController *vc = [[[[UIApplication sharedApplication] delegate] window] rootViewController];
    [vc presentViewController:alterController animated:YES completion:nil];
    CGFloat W = [[UIScreen mainScreen] bounds].size.width;
    CGFloat H = [[UIScreen mainScreen] bounds].size.height;
    {
        UIImage *image = self.reslutModel.wmResultModel.watermarkImage;
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        imageView.layer.borderColor = UIColor.yellowColor.CGColor;
        imageView.layer.borderWidth = 0.5;
        [alterController.view addSubview:imageView];
        imageView.frame = CGRectMake(0, 0, W*0.18, W*0.18);
    }
    {
        UIImage *image = self.reslutModel.ocrMetaData.image;
        if(image) {
            UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
            imageView.layer.borderColor = UIColor.blueColor.CGColor;
            imageView.layer.borderWidth = 0.5;
            imageView.contentMode = UIViewContentModeScaleAspectFit;
            [alterController.view addSubview:imageView];
            imageView.frame = CGRectMake(W*0.18, 0, W*0.6, W*0.6*image.size.height/image.size.width);
        }
    }
}

+ (NSString*)internalErrorMessage:(BMWAnitCodeErrorModel *_Nullable)errorModel reslutModel:(BMWAnitCodeReslutModel* _Nullable)reslutModel
{
    NSString* errorMsg = [NSString stringWithFormat:@"errorModel:%@, reslutModel:%@", errorModel, reslutModel];
    return errorMsg;
}

+ (CGRect)expandRectFromCodeRect:(CGRect)codeRect
{
    CGFloat size = codeRect.size.width / 2;
    CGFloat x = codeRect.origin.x;
    CGFloat y = codeRect.origin.y - size;
    return CGRectMake(x, y, size, size + codeRect.size.height);
}

@end
