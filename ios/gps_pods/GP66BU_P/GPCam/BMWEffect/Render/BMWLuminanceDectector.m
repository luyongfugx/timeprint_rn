#import "BMWLuminanceDectector.h"
#import "BMWBaseDrawer.h"
#import "BMWFramebuffer.h"
#import "BMWLaplacianDrawer.h"
#import "BMWRGB2YUVDrawer2.h"
#import "BMWGLUtils.h"

@interface BMWLuminanceDectector ()
@property (nonatomic) BMWImageContext *imageContext;
@property (nonatomic) BMWBaseDrawer *scaledDrawer;
@property (nonatomic) BMWFramebuffer *scaledFBO;
@end

@implementation BMWLuminanceDectector

+ (BMWLuminanceDectector*)sharedInstance
{
    static BMWLuminanceDectector* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[BMWLuminanceDectector alloc] initWithContext:BMWImageContext.sharedImageProcessingContext];
        }
    });
    return instance;
}

- (instancetype)initWithContext:(BMWImageContext *)imageContext
{
    if (self = [super init]) {
        self.imageContext = imageContext;
    }
    return self;
}

- (CGFloat)detectWithTexId:(int)texId texSize:(CGSize)texSize
{
    if(self.scaledDrawer == nil) {
        self.scaledDrawer = [[BMWBaseDrawer alloc] init];
    }
    if(self.scaledFBO == nil) {
        self.scaledFBO = [[BMWFramebuffer alloc] initWithSize:CGSizeMake(16, 16) imageContext:self.imageContext];
    }
    [self.scaledFBO bind];
    [self.scaledDrawer drawWithTexId:texId];
    glFinish();
    CVPixelBufferRef buffer = self.scaledFBO.renderTarget;
    CVPixelBufferLockBaseAddress(buffer, 0);
    unsigned char* pixelData = (unsigned char *)CVPixelBufferGetBaseAddress(buffer);
    int width = (int)CVPixelBufferGetWidth(buffer);
    int height = (int)CVPixelBufferGetHeight(buffer);
    int stride = (int)CVPixelBufferGetBytesPerRow(buffer);
    uint64_t luminance = 0;
    for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
            int i = row * stride + 4 * col;
            // BGRA
            int r = pixelData[i+2];
            luminance+=r;
        }
    }
    CGFloat ret = (CGFloat)luminance / (width * height);
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    return ret;
}
@end
