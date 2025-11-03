#import "BMWWatermarkBuffer.h"
#import <QuartzCore/QuartzCore.h>
#import "BMWGLUtils.h"

@implementation BMWWatermarkBuffer

- (instancetype)init {
    self = [super init];
    if (self) {
        _buf = NULL;
        _size = CGSizeZero;
        _autoReset = YES;
    }
    return self;
}

- (void)dealloc
{
    [self reset];
}

+ (BMWWatermarkBuffer*)watermarkBuffer:(GLbyte*)buffer size:(CGSize)size
{
    if(buffer == NULL || size.width == 0 || size.height == 0) return nil;
    BMWWatermarkBuffer *b = [BMWWatermarkBuffer new];
    b.buf = buffer;
    b.size = size;
    return b;
}

+ (BMWWatermarkBuffer*)watermarkImage:(UIImage*)image
{
    if(image == nil) return nil;
    BMWWatermarkBuffer *b = [BMWWatermarkBuffer new];
    b.image = image;
    return b;
}

- (GLuint)genTexture
{
    __block GLuint texId = 0;
    if (self.image == nil) {
        texId = [BMWGLUtils createTextureWithData:self.buf width:self.size.width height:self.size.height];
    } else {
        [BMWGLUtils getRawData:self.image forceRedraw:YES block:^(GLubyte * _Nonnull imageData, int width, int height, GLenum format) {
            texId = [BMWGLUtils createTextureWithData:imageData width:width height:height];
        }];
    }
    if (self.autoReset) {
        [self reset];
    }
    return texId;
}

- (void)updateTexture:(GLuint)texId
{
    if (self.image == nil) {
        [BMWGLUtils updateTextureWithBuffer:(GLuint *)self.buf bufferSize:self.size textureId:texId];
    } else {
        GLubyte *imageData = NULL;
        CGImageRef imageSource = self.image.CGImage;
        CGFloat width = CGImageGetBytesPerRow(imageSource)/4;
        CGFloat height = CGImageGetHeight(imageSource);
        CFDataRef dataProvider = CGDataProviderCopyData(CGImageGetDataProvider(imageSource));
        imageData = (GLubyte *)CFDataGetBytePtr(dataProvider);
        [BMWGLUtils updateTextureWithBuffer:(GLuint *)imageData bufferSize:CGSizeMake(width, height) textureId:texId];
        if (dataProvider) {
            CFRelease(dataProvider);
        }
    }
    if (self.autoReset) {
        [self reset];
    }
}

- (void)reset
{
    self.image = nil;
    if (self.buf) {
        free(self.buf);
        self.buf = NULL;
    }
    BMWMLogD(@"GPCam", @"BMWWatermarkBuffer free");
}

@end
