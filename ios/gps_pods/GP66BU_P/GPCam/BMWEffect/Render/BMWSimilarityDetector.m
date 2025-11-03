#import "BMWSimilarityDetector.h"
#import "GPCamConfigurator.h"
#import "UIImage+GPCam.h"
#import "BMWGLUtils.h"
#import "BMWBaseDrawer.h"
#import "BMWFramebuffer.h"

@interface BMWSimilarityDetector ()
@property (nonatomic) BMWImageContext *imageContext;
@end

@implementation BMWSimilarityDetector

- (instancetype)initWithContext:(BMWImageContext *)imageContext
{
    if (self = [super init]) {
        self.imageContext = imageContext;
    }
    return self;
}

- (CGFloat)detect:(UIImage*)previewImage capturedTexId:(int)capturedTexId CGSize:(CGSize)capturedSize
{
    double begin = CACurrentMediaTime();

    CGFloat min = MIN(capturedSize.width, capturedSize.height);
    CGFloat ratio = 64 / min;
    CGSize size = CGSizeMake(capturedSize.width * ratio, capturedSize.height * ratio);

    // resize
    BMWBaseDrawer *scaledDrawer = [[BMWBaseDrawer alloc] init];
    BMWFramebuffer *scaledBuffer = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.imageContext];
    [scaledBuffer bind];
    [scaledDrawer drawWithTexId:capturedTexId];

    BMWFramebuffer *scaledBuffer2 = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.imageContext];
    [scaledBuffer2 bind];
    GLuint previewTexId = [BMWGLUtils setupTexture:previewImage];
    [scaledDrawer drawWithTexId:previewTexId];
    glFinish();

    // resize2
    CGSize targetSize = CGSizeMake(32, 32);
    previewImage = scaledBuffer.imageFromFramebufferContent;
    if(!CGSizeEqualToSize(size, targetSize)) {
        previewImage = [previewImage xhm_resizeImage:targetSize];
    }
    UIImage * capturedImage = scaledBuffer2.imageFromFramebufferContent;
    if(!CGSizeEqualToSize(size, targetSize)) {
        capturedImage = [capturedImage xhm_resizeImage:targetSize];
    }
    CGFloat similarity = [previewImage xhm_similarityCheck:capturedImage];

    // release
    [scaledDrawer destory];
    [scaledBuffer destroy];
    [scaledBuffer2 destroy];
    if (previewTexId > 0) {
        glDeleteTextures(1, &previewTexId);
    }

        return similarity;
}

@end
