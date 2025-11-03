#import "BMWBlindWatermarkUtils.h"
#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/ES3/glext.h>

@implementation BMWBlindWatermarkUtils

+ (void)printBuffer:(BMWFramebuffer*)framebuffer tag:(NSString*)tag
{
#if 0
        glFinish();
    CVPixelBufferRef buffer = framebuffer.renderTarget;
    CVPixelBufferLockBaseAddress(buffer, 0);
    unsigned char* pixelData = (unsigned char *)CVPixelBufferGetBaseAddress(buffer);
    int width = (int)CVPixelBufferGetWidth(buffer);
    int height = (int)CVPixelBufferGetHeight(buffer);
    int stride = (int)CVPixelBufferGetBytesPerRow(buffer);
    for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
            int i = row * stride + 4 * col;
            // BGRA
            int a = pixelData[i+3];
            int r = pixelData[i+2];
            int g = pixelData[i+1];
            int b = pixelData[i+0];
                    }
            }
    CVPixelBufferUnlockBaseAddress(buffer, 0);
#endif
}
@end
