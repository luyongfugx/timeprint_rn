#import "BMWClarityDetector.h"
#import "BMWBaseDrawer.h"
#import "BMWFramebuffer.h"
#import "BMWLaplacianDrawer.h"
#import "BMWRGB2YUVDrawer2.h"
#import "BMWGLUtils.h"
#import "BMWSliceData.h"
#import "BMWImageQualityAlgorithm.h"
#import "BMWBufferUtils.h"
#import "UIImage+GPCam.h"
#import "BMWGLUtils.h"

@interface BMWClarityDetector ()

@property (nonatomic) BMWImageContext *imageContext;

@end

@implementation BMWClarityDetector

- (instancetype)initWithContext:(BMWImageContext *)imageContext
{
    if (self = [super init]) {
        self.imageContext = imageContext;
    }
    return self;
}

- (CGFloat)detectWithImage:(UIImage*)image texSize:(CGSize)texSize
{
    double begin = CACurrentMediaTime();
    GLuint texId = [BMWGLUtils setupTexture:image];

    __block CGFloat laplacianVar =  0;
    [self yuvDraw:texId texSize:texSize rectOfInInterest:BMWRectFull() completeBlock:^(int texId2, CGSize texSize2) {
        laplacianVar = [self detectWithTexIdInternal:texId2 texSize:texSize2];
    }];

    if (texId > 0) {
        glDeleteTextures(1, &texId);
    }
    double end = CACurrentMediaTime();
        return laplacianVar;
}

- (CGFloat)detectWithTexId:(int)texId texSize:(CGSize)texSize
{
    return [self detectWithTexId:texId texSize:texSize rectOfInInterest:BMWRectFull()];
}

- (CGFloat)detectWithTexId:(int)texId texSize:(CGSize)texSize rectOfInInterest:(BMWRect*)rect
{
    double begin = CACurrentMediaTime();
    __block CGFloat laplacianVar =  0;
    [self yuvDraw:texId texSize:texSize rectOfInInterest:rect completeBlock:^(int texId3, CGSize texSize3) {
        laplacianVar = [self detectWithTexIdInternal:texId3 texSize:texSize3];
    }];
    double end = CACurrentMediaTime();
        return laplacianVar;
}

- (CGFloat)detectWithTexIdInternal:(int)texId texSize:(CGSize)texSize
{
    // laplacian
    BMWLaplacianDrawer *laplacianDrawer = [[BMWLaplacianDrawer alloc] init];
    laplacianDrawer.inputSize = texSize;
    BMWFramebuffer *laplacianFBO = [[BMWFramebuffer alloc] initWithSize:texSize imageContext:self.imageContext];
    [laplacianFBO bind];
    [laplacianDrawer drawWithTexId:texId];
    // scale for mean
    BMWBaseDrawer *scaledDrawer = [[BMWBaseDrawer alloc] init];
    CGFloat min = MIN(texSize.width, texSize.height);
    CGFloat ratio = 64 / min;
    CGSize scaledSize = CGSizeMake(texSize.width * ratio, texSize.height * ratio);
    BMWFramebuffer *scaledFBO = [[BMWFramebuffer alloc] initWithSize:scaledSize imageContext:self.imageContext];
    [scaledFBO bind];
    [scaledDrawer drawWithTexId:laplacianFBO.texture];
    glFinish();
    CGFloat charity = calcVar(scaledFBO.renderTarget);
    // release
    [laplacianDrawer destory];
    [laplacianFBO destroy];
    [scaledDrawer destory];
    [scaledFBO destroy];
    return charity;
}

- (BMWImageQualityAlgorithmResult*)imageQualityDetectWithTexId:(int)texId
{
    double begin = CACurrentMediaTime();
    __block BMWImageQualityAlgorithmResult *imageQualityResult= nil;
    [self scaleDraw:texId texSize:CGSizeMake(480, 480) completeBlock:^(BMWFramebuffer *frameBuffer, CGSize texSize) {
        glFinish();
        BMWImageQualityAlgorithm *imageQualityAlgorithm = [[BMWImageQualityAlgorithm alloc] init];
        [imageQualityAlgorithm start];
        imageQualityResult = [imageQualityAlgorithm process:^(BMWAlgorithmProcessProfile * _Nonnull profile) {
            profile.pixelBuffer = frameBuffer.renderTarget;
        }];
        [imageQualityAlgorithm stop];
    }];
    double end = CACurrentMediaTime();
        return imageQualityResult;
}

- (BMWImageQualityAlgorithmResult*)imageQualityDetectWithImage:(UIImage*)image
{
    double begin = CACurrentMediaTime();
    UIImage *resizedImage = [image xhm_resizeImage:CGSizeMake(480, 480)];
    CVPixelBufferRef pixelBuffer = [BMWBufferUtils imageBufferFromUIImage:resizedImage];
    BMWImageQualityAlgorithm *imageQualityAlgorithm = [[BMWImageQualityAlgorithm alloc] init];
    [imageQualityAlgorithm start];
    BMWImageQualityAlgorithmResult *imageQualityResult = [imageQualityAlgorithm process:^(BMWAlgorithmProcessProfile * _Nonnull profile) {
        profile.pixelBuffer = pixelBuffer;
    }];
    [imageQualityAlgorithm stop];
    CFRelease(pixelBuffer);
    double end = CACurrentMediaTime();
        return imageQualityResult;
}

- (void)yuvDraw:(int)texId texSize:(CGSize)texSize rectOfInInterest:(BMWRect*)rect completeBlock:(void (^)(int texId, CGSize texSize))completeBlock
{
    const GLfloat coordinates[8] = {
        rect.left, rect.top,
        rect.right, rect.top,
        rect.left, rect.bottom,
        rect.right, rect.bottom,
    };
    BMWRGB2YUVDrawer2 *yuvDrawer = [[BMWRGB2YUVDrawer2 alloc] init];
    BMWFramebuffer *yuvFBO = [[BMWFramebuffer alloc] initWithSize:texSize imageContext:self.imageContext];
    [yuvFBO bind];
    [yuvDrawer drawWithTexId:texId coordinates:coordinates];
    SafeBlock(completeBlock, yuvFBO.texture, texSize);

    [yuvDrawer destory];
    [yuvFBO destroy];
}

- (void)scaleDraw:(int)texId texSize:(CGSize)texSize completeBlock:(void (^)(BMWFramebuffer *buffer, CGSize texSize))completeBlock;
{
    BMWBaseDrawer *scaledDrawer = [[BMWBaseDrawer alloc] init];
    BMWFramebuffer *scaledFBO = [[BMWFramebuffer alloc] initWithSize:texSize imageContext:self.imageContext];
    [scaledFBO bind];
    [scaledDrawer drawWithTexId:texId];

    SafeBlock(completeBlock, scaledFBO, texSize);

    [scaledDrawer destory];
    [scaledFBO destroy];
}

static CGFloat calcVar(CVPixelBufferRef buffer)
{
    CVPixelBufferLockBaseAddress(buffer, 0);
    unsigned char* pixelData = (unsigned char *)CVPixelBufferGetBaseAddress(buffer);
    int width = (int)CVPixelBufferGetWidth(buffer);
    int height = (int)CVPixelBufferGetHeight(buffer);
    int stride = (int)CVPixelBufferGetBytesPerRow(buffer);

    // calc mean
    uint64_t iMean = 0;
    for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
            int i = row * stride + 4 * col;
            // BGRA
            int r = pixelData[i+2];
            iMean += r;
        }
    }
    CGFloat fMean = (CGFloat)iMean / (width * height);

    // calc var
    uint64_t iVar = 0;
    for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
            int i = row * stride + 4 * col;
            // BGRA
            int r = pixelData[i+2];
            iVar +=powl((r - fMean), 2);
        }
    }
    CGFloat fVar = (CGFloat)iVar / (width * height);
    fVar = pow(fVar, 0.5);
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    return fVar;
}
@end
