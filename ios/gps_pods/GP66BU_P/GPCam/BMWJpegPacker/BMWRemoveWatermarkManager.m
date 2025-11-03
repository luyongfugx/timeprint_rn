#import "BMWRemoveWatermarkManager.h"
#import "BMWFramebuffer.h"
#import "BMWGLUtils.h"
#import "BMWJpegPacker.h"
#import "BMWBaseDrawer.h"
#import "BMWWatermarkDrawer.h"
#import "BMWMUserCommentModel.h"
#import "BMWClarityDetector.h"
#import "GPCamConfigurator.h"
#import "BMWWatermarkItem.h"

@implementation BMWRemoveWatermarkRequest
- (instancetype)init
{
    if (self = [super init]) {
        self.removeWatermarkType = BMWRemoveWatermarkTypeAll;
    }
    return self;
}
@end

@implementation BMWRemoveWatermarkReslut
@end

@interface BMWRemoveWatermarkManager ()
@property (nonatomic, strong) BMWImageContext *context;
@property (nonatomic, strong) BMWFramebuffer *outputFBO;
@end

static GLfloat vertices[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};
@implementation BMWRemoveWatermarkManager

- (void)dealloc
{
    [self destroy];
}

- (void)destroy
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

- (instancetype)init
{
    if (self = [super init]) {
        _context = BMWImageContext.sharedImageProcessingContext;
    }
    return self;
}

/**
 * steps as following
 * 1 get parameters
 * * 1.1 parse us
 * * 1.2 get slice image from BMWJpegPacker
 * 2 Use WatermarkRender to blend slice image to input image
 * * 2.1 draw input with rect
 * * 2.2 prepare WaterMark
 * * 2.3 rendering slice via  WatermarkRender
 * * 2.4 read bitmap
 * * 2.5 release resources
 */
- (void)process:(void (^)(BMWRemoveWatermarkRequest *request))builder completeBlock:(void (^)(BMWRemoveWatermarkReslut* reslut))completeBlock
{
    BMWRemoveWatermarkRequest *request = [[BMWRemoveWatermarkRequest alloc] init];
    SafeBlock(builder, request);

    BMWRemoveWatermarkReslut *reslut = [[BMWRemoveWatermarkReslut alloc] init];
    BMWMUserCommentModel *userCommentModel = nil;
    // 1.1 parse us
    do {
        if (request.userCommentStr.length == 0) {
            break;
        }
        NSError *error = nil;
        NSData *jsonData = [request.userCommentStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        if(error) {
                        break;
        }
        userCommentModel = [MTLJSONAdapter modelOfClass:[BMWMUserCommentModel class] fromJSONDictionary:jsonDic error:&error];

        if(error || userCommentModel == nil) {
                        break;
        }
    } while (0);

    if (request.inputImageData.length == 0) {
        reslut.error = [[NSError alloc] initWithDomain:@"imageData.length==0" code:BMWRemoveWatermarkErrorInvalidParameter userInfo:nil];
        SafeBlock(completeBlock, reslut);
        return;
    }

    if (request.removeWatermarkType != BMWRemoveWatermarkTypeAll &&
        request.removeWatermarkType != BMWRemoveWatermarkTypeOfficalWatermark &&
        request.removeWatermarkType != BMWRemoveWatermarkTypeGetClarityOptImage) {
        reslut.error = [[NSError alloc] initWithDomain:[NSString stringWithFormat:@"removeWatermarkType:%d", request.removeWatermarkType] code:BMWRemoveWatermarkErrorInvalidParameter userInfo:nil];
        SafeBlock(completeBlock, reslut);
        return;
    }

    // 1.2 get slice image from BMWJpegPacker
    [BMWJpegPacker.sharedInstance unpack:^(BMWSliceDataModel * _Nonnull request2) {
        request2.jpegData = request.inputImageData;
        request2.clarityOpt = request.removeWatermarkType == BMWRemoveWatermarkTypeGetClarityOptImage;
    } completeBlock:^(BMWSliceDataModel * _Nullable reslut2) {
        reslut.error = reslut2.error;
        reslut.sliceDataModel = reslut2;
    }];

    if (reslut.error) {
        SafeBlock(completeBlock, reslut);
        return;
    }

    // 构造list2/list3 from us
    reslut.sliceDataModel.position = userCommentModel.sliceImage.postion;
    reslut.sliceDataModel.sliceType = userCommentModel.sliceImage.type;
    reslut.sliceDataModel.previewClarity = userCommentModel.sliceImage.previewClarity;
    reslut.sliceDataModel.capturedClarity = userCommentModel.sliceImage.capturedClarity;
    reslut.sliceDataModel.clarityOpt = userCommentModel.sliceImage.clarityOpt;
    reslut.sliceDataModel.sliceDataList2 = userCommentModel.sliceDataList2;
    reslut.sliceDataModel.sliceDataList3 = userCommentModel.sliceDataList3;

    if(request.removeWatermarkType == BMWRemoveWatermarkTypeGetClarityOptImage) {
        for (BMWSliceData *sliceData in reslut.sliceDataModel.sliceDataList) {
            if(sliceData.type == JpegDataClarityOptOrg) {
                reslut.sliceDataModel.jpegData = sliceData.data;
                break;
            }
        }
        if(reslut.sliceDataModel.jpegData == nil) {
            reslut.error = [[NSError alloc] initWithDomain:[NSString stringWithFormat:@"removeWatermarkType:%d", request.removeWatermarkType] code:BMWRemoveWatermarkErrorGetClarityOptError userInfo:nil];
        }
        SafeBlock(completeBlock, reslut);
        return;
    }

    UIImage *inputImage = [UIImage imageWithData:request.inputImageData];
    if (CGSizeEqualToSize(CGSizeZero, request.outputSize)) {
        request.outputSize = inputImage.size;
    }
    runSynchronouslyRenderingQueue(^{
        [self.context useAsCurrentContext];
        // * 2.1 draw input
        BMWRect *rect = BMWRectMakeForList(userCommentModel.sliceImage.list3.firstObject.sliceRect);
        if(rect == nil){
            rect = BMWRectFull();
        }
        request.outputSize = CGSizeMake(request.outputSize.width * rect.width, request.outputSize.height * rect.height);
        GLfloat coordinates[8] = {
            rect.left, rect.top, // l, t,
            rect.right, rect.top, // r, t,
            rect.left, rect.bottom, // l, b,
            rect.right, rect.bottom, // r, b,
        };
        int scrId = [BMWGLUtils setupTexture:inputImage];
        BMWBaseDrawer *inputDrawer = [[BMWBaseDrawer alloc] init];
        BMWFramebuffer *inputFBO = [[BMWFramebuffer alloc] initWithSize:request.outputSize imageContext:self.context];
        [inputFBO bind];
        [inputDrawer drawWithTexId:scrId vertices:vertices coordinates:coordinates];
        glDeleteTextures(1, (const GLuint *)&scrId);

        // * 2.2 prepare WaterMark
        GLint officalwmtexId = 0;
        GLint shadowtexId = 0;
        BMWWatermarkDrawer *watermarkDrawer = [[BMWWatermarkDrawer alloc] initWithContext:self.context];
        for (BMWSliceData *sliceData in reslut.sliceDataModel.sliceDataList) {
            // ignore fo clarity opt
            if (sliceData.type != JpegDataOrgSlice)
                continue;
            // ignore 如果只去右下角官方水印+id不为官方水印
            if(request.removeWatermarkType == BMWRemoveWatermarkTypeOfficalWatermark &&
               sliceData.id != BMWWatermarkTagOfficialWatermark) {
                continue;
            }
            // 外部显水印因为是编辑添加，独立处理这块逻辑
            if(sliceData.id == BMWWatermarkTagVisitInfoDisplayOutside) {
                sliceData.rect = BMWRectMake((sliceData.rect.left - rect.left) / rect.width,
                                            (sliceData.rect.top - rect.top) /  rect.height,
                                            (sliceData.rect.right) / rect.width,
                                            (sliceData.rect.bottom) / rect.height);
            }
            NSString *tagInfo = [NSString stringWithFormat:@"SliceImage-%d", sliceData.id];
            UIImage *sliceImage = [UIImage imageWithData:sliceData.data];
            GLint sliceScrId = [BMWGLUtils setupTexture:sliceImage];
            BMWWatermarkInfo *info = [BMWWatermarkInfo buildInfo:tagInfo texId:sliceScrId rect:sliceData.rect.CGrect deviceOrientation:BMWDeviceOrientationPortait];
            [watermarkDrawer updateWatermark:info];
        }

        // * 2.3 rendering slice via WatermarkRender
        [inputFBO bind];
        [watermarkDrawer draw];
        glFinish();

        // * 2.4 read bitmap
        UIImage *image = inputFBO.imageFromFramebufferContent;
        reslut.sliceDataModel.jpegData = UIImageJPEGRepresentation(image, 1.0);

        // * 2.5 release resources
        if(officalwmtexId > 0) {
            glDeleteTextures(1, (const GLuint *)&officalwmtexId);
        }
        if(shadowtexId > 0) {
            glDeleteTextures(1, (const GLuint *)&shadowtexId);
        }
        [inputDrawer destory];
        [inputFBO destroy];
        [watermarkDrawer destory];
        if(request.sync) {
            SafeBlock(completeBlock, reslut);
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                SafeBlock(completeBlock, reslut);
            });
        }
    });
}

- (void)detectClarityOffline:(NSURL*)srcUrl completeBlock:(void (^)(BMWClarityOptStatus reslut))completeBlock
{
   __block BMWClarityOptStatus shouldClarityOpt = BMWClarityOptStatusCanNotOpt;
    runAsynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        NSData* capturedImageData = [NSData dataWithContentsOfURL:srcUrl];
        __block NSData* capturedImageDataWithoutWatermark = nil;
        [self process:^(BMWRemoveWatermarkRequest * _Nonnull request) {
            request.sync = YES;
            request.inputImageData = capturedImageData;
        } completeBlock:^(BMWRemoveWatermarkReslut * _Nonnull reslut) {
            if(reslut.error || reslut.sliceDataModel.jpegData == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    SafeBlock(completeBlock, shouldClarityOpt);
                });
                return;
            }
            capturedImageDataWithoutWatermark = reslut.sliceDataModel.jpegData;
        }];

        [self process:^(BMWRemoveWatermarkRequest * _Nonnull request) {
            request.sync = YES;
            request.inputImageData = capturedImageData;
            request.removeWatermarkType = BMWRemoveWatermarkTypeGetClarityOptImage;
        } completeBlock:^(BMWRemoveWatermarkReslut * _Nonnull reslut) {
            if(!reslut.error && reslut.sliceDataModel.jpegData != nil) {
                UIImage *capturedImage = [UIImage imageWithData:capturedImageDataWithoutWatermark];
                UIImage *previewImage = [UIImage imageWithData:reslut.sliceDataModel.jpegData];
                CGSize size = previewImage.size;
                CGFloat min = MIN(size.width, size.height);
                CGFloat ratio = 640 / min;
                size = CGSizeMake(size.width * ratio, size.height * ratio);
                BMWClarityDetector *detector = [[BMWClarityDetector alloc] initWithContext:self.context];
                CGFloat capturedClarity = [detector detectWithImage:capturedImage texSize:size];
                CGFloat previewClarity = [detector detectWithImage:previewImage texSize:size];
                CGFloat offset = GPCamConfigurator.sharedInstance.previewClarityOffsetForIOS - 5;
                if((previewClarity - capturedClarity > offset) &&
                   GPCamConfigurator.sharedInstance.clarityThreshold < previewClarity) {
                    shouldClarityOpt = BMWClarityOptStatusCanOpt;
                } else {
                    shouldClarityOpt = BMWClarityOptStatusCanNotOpt;
                }
            }
        }];
        dispatch_async(dispatch_get_main_queue(), ^{
            SafeBlock(completeBlock, shouldClarityOpt);
        });
    });
}

@end
