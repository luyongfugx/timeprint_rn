#import "BMWFramebuffer.h"
#include <OpenGLES/ES3/gl.h>
#include <OpenGLES/ES3/glext.h>
#import "BMWImageContext.h"
#import "GPCamConfigurator.h"

@interface BMWFramebuffer ()
{
    GLuint _frameBuffer;
    CVPixelBufferRef _renderTarget;
    CVOpenGLESTextureRef _renderTexture;
    GLuint texture;
}
@property (nonatomic, strong, readwrite) BMWImageContext *imageContext;
@property (nonatomic) CGSize bufferSize;
@property (nonatomic) BOOL isValid;
@property (nonatomic) NSUInteger useCount;
@end

@implementation BMWFramebuffer

- (void)dealloc
{
//    BMWMLog(@"BMWFramebuffer dealloc");
}

- (instancetype)initWithSize:(CGSize)framebufferSize imageContext:(BMWImageContext*)imageContext
{
    if (!(self = [super init])) {
        return nil;
    }
    _imageContext = imageContext;
    _bufferSize = framebufferSize;
    [self generateFramebuffer];
    return self;
}

- (instancetype)initWithSize2:(CGSize)framebufferSize imageContext:(BMWImageContext*)imageContext
{
    if (!(self = [super init])) {
        return nil;
    }
    _imageContext = imageContext;
    _bufferSize = framebufferSize;
    [self generateFramebuffer];
    return self;
}

- (void)generateFramebuffer
{
    CFDictionaryRef empty;
    CFMutableDictionaryRef attrs;
    empty = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    attrs = CFDictionaryCreateMutable(kCFAllocatorDefault, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFDictionarySetValue(attrs, kCVPixelBufferIOSurfacePropertiesKey, empty);

    CVReturn error = CVPixelBufferCreate(kCFAllocatorDefault, _bufferSize.width, self.bufferSize.height, kCVPixelFormatType_32BGRA, attrs, &_renderTarget);

    CFRelease(attrs);
    CFRelease(empty);

    if (error) {
                NSAssert(NO, @"Error at CVPixelBufferCreate:%d", error);
        return;
    }

    CVReturn err = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.imageContext.coreVideoTextureCache, _renderTarget, NULL, GL_TEXTURE_2D, GL_RGBA, _bufferSize.width, _bufferSize.height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &_renderTexture);
    if (err) {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreateTextureFromImage %d", err);
        return;
    }

    _texture = CVOpenGLESTextureGetName(_renderTexture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _texture, 0);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);

    glBindTexture(GL_TEXTURE_2D, 0);
    self.useCount = 1;
    self.isValid = YES;
    self.imageContext.bufferCount++;
}

- (void)generateFramebuffer2
{
    [self generateTexture];

    glBindTexture(GL_TEXTURE_2D, _texture);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA16F, (int)_bufferSize.width, (int)_bufferSize.height, 0, GL_RGBA, GL_FLOAT, 0);

    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _texture, 0);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSAssert(status == GL_FRAMEBUFFER_COMPLETE, @"Incomplete filter FBO: %d", status);

    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)generateTexture;
{
    glActiveTexture(GL_TEXTURE0);
    glGenTextures(1, &_texture);
    glBindTexture(GL_TEXTURE_2D, _texture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
}

- (void)bind
{
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(0, 0, (int)_bufferSize.width, (int)_bufferSize.height);
}

- (void)destroy
{
    [self destroyInternal:NO sync:YES];
}

- (BMWImageContext *)imageContext
{
    return _imageContext;
}

- (void)destroyInternal:(BOOL)releaseContext sync:(BOOL)sync
{
    runOnContextQueue(sync, self.imageContext, ^{
        self.useCount--;
        if (self.useCount > 0) return;
        [self.imageContext useAsCurrentContext];

        if (_frameBuffer) {
            glDeleteFramebuffers(1, &_frameBuffer);
            _frameBuffer = 0;
        }
        if (_renderTarget) {
            CVPixelBufferRelease(_renderTarget);
            _renderTarget = NULL;
        }

        if (_renderTexture) {
            CFRelease(_renderTexture);
            _renderTexture = NULL;
        }
        self.imageContext.bufferCount--;
        if(releaseContext) {
            // TODO 做了这个事情会导致切换摄像头花屏
            if(_texture > 0) {
                glDeleteTextures(1, &_texture);
                _texture = 0;
            }
            // TODO 释放glcontext风险比较大
            if(self.imageContext.bufferCount == 0) {
                self.imageContext.context = nil;
            }
        }
        _texture = 0;
    });
}

- (CVPixelBufferRef)renderTarget
{
    return _renderTarget;
}

- (UIImage*)imageFromFramebufferContent
{
    CVPixelBufferLockBaseAddress(_renderTarget, 0);

    int width = (int)CVPixelBufferGetWidth(_renderTarget);
    int height = (int)CVPixelBufferGetHeight(_renderTarget);
    NSUInteger paddedWidthOfImage = CVPixelBufferGetBytesPerRow(_renderTarget) / 4.0;
    NSUInteger paddedBytesForImage = paddedWidthOfImage * height * 4;

    GLubyte *rawImagePixels = (GLubyte *)CVPixelBufferGetBaseAddress(_renderTarget);

    CGDataProviderRef dataProvider = CGDataProviderCreateWithData((__bridge_retained void*)self, rawImagePixels, paddedBytesForImage, dataProviderReleaseCallback);

    CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();

    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, CVPixelBufferGetBytesPerRow(_renderTarget), defaultRGBColorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, dataProvider, NULL, NO, kCGRenderingIntentDefault);

    CVPixelBufferUnlockBaseAddress(_renderTarget, 0);
    if(dataProvider != NULL) CGDataProviderRelease(dataProvider);
    if(defaultRGBColorSpace != NULL) CGColorSpaceRelease(defaultRGBColorSpace);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    if(cgImage != NULL) CGImageRelease(cgImage);
    self.useCount++;
    return image;
}

static void dataProviderReleaseCallback(void *info, const void *data, size_t size)
{
    BMWFramebuffer *framebuffer = (__bridge_transfer BMWFramebuffer*)info;
    BOOL releaseContext = GPCamConfigurator.sharedInstance.smoothPreviewTakingImage == 1 &&
    framebuffer.imageContext != BMWImageContext.sharedImageProcessingContext;
    [framebuffer destroyInternal:releaseContext sync:NO];
}

@end
