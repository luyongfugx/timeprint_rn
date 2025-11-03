#import "BMWGLUtils.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import "BMWImageContext.h"
#import "UIView+GPCam.h"
#import "BMWALifeCycleHelper.h"
#import "BMWWatermarkItem.h"

@implementation BMWGLUtils

+ (GLuint)setupTexture:(UIImage*)image
{
    if (image == nil) return 0;
    __block GLuint textureHandle = 0;
    [[self class] getRawData:image block:^(GLubyte * _Nonnull imageData, int width, int height, GLenum format) {
        if (imageData) {
            glGenTextures(1, &textureHandle);
            glBindTexture(GL_TEXTURE_2D, textureHandle);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, imageData);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    }];
    return textureHandle;
}

+ (GLuint)setupTexture:(UIImage*)image redraw:(BOOL)redraw
{
    if (image == nil) return 0;
    __block GLuint textureHandle = 0;
    [[self class] getRawData:image forceRedraw:redraw block:^(GLubyte * _Nonnull imageData, int width, int height, GLenum format) {
        if (imageData) {
            glGenTextures(1, &textureHandle);
            glBindTexture(GL_TEXTURE_2D, textureHandle);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
            glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
            glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, format, GL_UNSIGNED_BYTE, imageData);
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    }];
    return textureHandle;
}

+ (void)getRawData:(UIImage*)image block:(void (^)(GLubyte *imageData, int width, int height, GLenum format))result
{
    [[self class] getRawData:image forceRedraw:NO block:result];
}

+ (void)getRawData:(UIImage*)image forceRedraw:(BOOL)redraw block:(void (^)(GLubyte *imageData, int width, int height, GLenum format))result
{
    if (!image) {
         // fixme replace ERROR LOG
        !result ? : result(NULL, 0, 0, GL_BGRA);
    }
    CGImageRef newImageSource = image.CGImage;

    CGFloat widthOfImage = CGImageGetWidth(newImageSource);
    CGFloat heightOfImage = CGImageGetHeight(newImageSource);

    // If passed an empty image reference, CGContextDrawImage will fail in future versions of the SDK.
    NSAssert( widthOfImage > 0 && heightOfImage > 0, @"Passed image must not be empty - it should be at least 1px tall and wide");

    CGSize pixelSizeOfImage = CGSizeMake(widthOfImage, heightOfImage);
    CGSize pixelSizeToUseForTexture = pixelSizeOfImage;

    BOOL shouldRedrawUsingCoreGraphics = redraw;

    GLubyte *imageData = NULL;
    CFDataRef dataFromImageDataProvider = NULL;
    GLenum format = GL_BGRA;
    BOOL isLitteEndian = YES;
    BOOL alphaFirst = NO;
    BOOL premultiplied = NO;

    if (!shouldRedrawUsingCoreGraphics) {
        /* Check that the memory layout is compatible with GL, as we cannot use glPixelStore to
         * tell GL about the memory layout with GLES.
         */
        if (CGImageGetBytesPerRow(newImageSource) != CGImageGetWidth(newImageSource) * 4 ||
            CGImageGetBitsPerPixel(newImageSource) != 32 ||
            CGImageGetBitsPerComponent(newImageSource) != 8)
        {
            shouldRedrawUsingCoreGraphics = YES;
        } else {
            /* Check that the bitmap pixel format is compatible with GL */
            CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(newImageSource);
            if ((bitmapInfo & kCGBitmapFloatComponents) != 0) {
                /* We don't support float components for use directly in GL */
                shouldRedrawUsingCoreGraphics = YES;
            } else {
                CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
                if (byteOrderInfo == kCGBitmapByteOrder32Little) {
                    /* Little endian, for alpha-first we can use this bitmap directly in GL */
                    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
                    if (alphaInfo != kCGImageAlphaPremultipliedFirst && alphaInfo != kCGImageAlphaFirst &&
                        alphaInfo != kCGImageAlphaNoneSkipFirst) {
                        shouldRedrawUsingCoreGraphics = YES;
                    }
                } else if (byteOrderInfo == kCGBitmapByteOrderDefault || byteOrderInfo == kCGBitmapByteOrder32Big) {
                    isLitteEndian = NO;
                    /* Big endian, for alpha-last we can use this bitmap directly in GL */
                    CGImageAlphaInfo alphaInfo = bitmapInfo & kCGBitmapAlphaInfoMask;
                    if (alphaInfo != kCGImageAlphaPremultipliedLast && alphaInfo != kCGImageAlphaLast &&
                        alphaInfo != kCGImageAlphaNoneSkipLast) {
                        shouldRedrawUsingCoreGraphics = YES;
                    } else {
                        /* Can access directly using GL_RGBA pixel format */
                        premultiplied = alphaInfo == kCGImageAlphaPremultipliedLast || alphaInfo == kCGImageAlphaPremultipliedLast;
                        alphaFirst = alphaInfo == kCGImageAlphaFirst || alphaInfo == kCGImageAlphaPremultipliedFirst;
                        format = GL_RGBA;
                    }
                }
            }
        }
    }

    __unused CFAbsoluteTime elapsedTime, startTime = CFAbsoluteTimeGetCurrent();
    if (shouldRedrawUsingCoreGraphics) {
        // For resized or incompatible image: redraw
        imageData = (GLubyte *) calloc(1, (int)pixelSizeToUseForTexture.width * (int)pixelSizeToUseForTexture.height * 4);

        CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();

        CGContextRef imageContext = CGBitmapContextCreate(imageData, (size_t)pixelSizeToUseForTexture.width, (size_t)pixelSizeToUseForTexture.height, 8, (size_t)pixelSizeToUseForTexture.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        // CGContextSetBlendMode(imageContext, kCGBlendModeCopy); // From Technical Q&A QA1708: http://developer.apple.com/library/ios/#qa/qa1708/_index.html
        CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, pixelSizeToUseForTexture.width, pixelSizeToUseForTexture.height), newImageSource);
        CGContextRelease(imageContext);
        CGColorSpaceRelease(genericRGBColorspace);
        isLitteEndian = YES;
        alphaFirst = YES;
        premultiplied = YES;
    } else {
        // Access the raw image bytes directly
        dataFromImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(newImageSource));
        if(dataFromImageDataProvider != NULL) {
            imageData = (GLubyte *)CFDataGetBytePtr(dataFromImageDataProvider);
        }
    }

    !result ? : result(imageData, pixelSizeToUseForTexture.width, pixelSizeToUseForTexture.height, format);

    if (shouldRedrawUsingCoreGraphics) {
        free(imageData);
    } else {
        if (dataFromImageDataProvider) {
            CFRelease(dataFromImageDataProvider);
        }
    }
}

+ (UIImage*)imageFromImageData:(void*)imageData size:(CGSize)size
{
    int width = size.width;
    int height = size.height;

    const void *rawImagePixels = imageData;
    NSUInteger paddedBytesForImage = width * height * 4;

    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rawImagePixels, paddedBytesForImage, NULL);

    CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();

    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, width * 4, defaultRGBColorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, dataProvider, NULL, NO, kCGRenderingIntentDefault);

    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(defaultRGBColorSpace);

    return image;
}

+ (GLuint)createTextureWithData:(uint8_t*)data width:(int)width height:(int)height
{
    GLubyte *imageData = data;
    GLuint imageTexture = 0;
    glGenTextures(1, &imageTexture);
    glBindTexture(GL_TEXTURE_2D, imageTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_BGRA, GL_UNSIGNED_BYTE, imageData);
    return imageTexture;
}

+ (GLuint)createTextureWithLayer:(CALayer *)layer scale:(CGFloat)scale
{
    layer.contentsScale = scale;
    CGSize pointSize = layer.bounds.size;
    CGSize layerPixelSize = CGSizeMake(layer.contentsScale * pointSize.width, layer.contentsScale * pointSize.height);
    layerPixelSize = [BMWGLUtils clampToMaxSize:layerPixelSize];
    GLubyte *imageData = (GLubyte*)calloc(1, (int)layerPixelSize.width * (int)layerPixelSize.height * 4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)layerPixelSize.width, (int)layerPixelSize.height, 8, (int)layerPixelSize.width * 4, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextTranslateCTM(imageContext, 0.0f, layerPixelSize.height);
    CGContextScaleCTM(imageContext, layer.contentsScale, - layer.contentsScale);
    @try {
        // TODO 放在主线程避免layer render不出来的情况，注意死锁问题
        if(BMWALifeCycleHelper.sharedInstance.appInBackground) {
            [layer xhm_renderInContext:imageContext];
        } else {
            runSynchronouslyOnMainQueue(^{
                [layer xhm_renderInContext:imageContext];
            });
        }
    } @catch (NSException *exception) {
            } @finally {
        CGContextRelease(imageContext);
        CGColorSpaceRelease(genericRGBColorspace);
    };
    GLuint textureHandle = 0;
    glGenTextures(1, &textureHandle);
    glBindTexture(GL_TEXTURE_2D, textureHandle);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);

    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)layerPixelSize.width, (int)layerPixelSize.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, imageData);
    free(imageData);
    return textureHandle;
}

+ (GLint)updateTextureWithImage:(UIImage *)image textureId:(GLuint)textureId
{
    if (image == nil) {
        return textureId;
    }
    if (textureId == 0) {
        return [self setupTexture:image];
    }
    [self getRawData:image block:^(GLubyte * _Nonnull imageData, int width, int height, GLenum format) {
        [self updateTextureWithBuffer:imageData bufferSize:CGSizeMake(width, height) textureId:textureId];
    }];
    return textureId;
}

+ (void)updateTextureWithBuffer:(GLbyte *)buffer bufferSize:(CGSize)bufferSize textureId:(GLuint)textureId
{
    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)bufferSize.width, (int)bufferSize.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, buffer);
    glBindTexture(GL_TEXTURE_2D, 0);
}

+ (void)updateTextureWithLayer:(CALayer *)layer scale:(CGFloat)scale textureId:(GLuint)textureId
{
    layer.contentsScale = scale;
    CGSize pointSize = layer.bounds.size;
    CGSize layerPixelSize = CGSizeMake(layer.contentsScale * pointSize.width, layer.contentsScale * pointSize.height);
    layerPixelSize = [BMWGLUtils clampToMaxSize:layerPixelSize];
    GLubyte *imageData = (GLubyte*)calloc(1, (int)layerPixelSize.width * (int)layerPixelSize.height * 4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)layerPixelSize.width, (int)layerPixelSize.height, 8, (int)layerPixelSize.width * 4, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextTranslateCTM(imageContext, 0.0f, layerPixelSize.height);
    CGContextScaleCTM(imageContext, layer.contentsScale, - layer.contentsScale);
    @try {
        [layer xhm_renderInContext:imageContext];
    } @catch (NSException *exception) {
            } @finally {
        CGContextRelease(imageContext);
        CGColorSpaceRelease(genericRGBColorspace);
    };

    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, (int)layerPixelSize.width, (int)layerPixelSize.height, 0, GL_BGRA, GL_UNSIGNED_BYTE, imageData);
    glBindTexture(GL_TEXTURE_2D, 0);
    free(imageData);
}

+ (void)createBufferWithLayer:(CALayer *)layer scale:(CGFloat)scale block:(void (^)(GLubyte *buffer, CGSize size))block
{
    double begin = CACurrentMediaTime();
    layer.contentsScale = scale;
    CGSize pointSize = layer.bounds.size;
    CGSize layerPixelSize = CGSizeMake(layer.contentsScale * pointSize.width, layer.contentsScale * pointSize.height);
    layerPixelSize = [BMWGLUtils clampToMaxSize:layerPixelSize];
    GLubyte *imageData = (GLubyte*)calloc(1, (int)layerPixelSize.width * (int)layerPixelSize.height * 4);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)layerPixelSize.width, (int)layerPixelSize.height, 8, (int)layerPixelSize.width * 4, genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextTranslateCTM(imageContext, 0.0f, layerPixelSize.height);
    CGContextScaleCTM(imageContext, layer.contentsScale, - layer.contentsScale);
    @try {
        [layer xhm_renderInContext:imageContext];
    } @catch (NSException *exception) {
            } @finally {
        CGContextRelease(imageContext);
        CGColorSpaceRelease(genericRGBColorspace);
    };
        !block ? : block(imageData, layerPixelSize);
}

+ (GLuint)createTextureWithWatermark:(BMWWatermarkItem *)watermark
{
    __block GLuint textureId = 0;
    __block UIImage *renderImage = nil;
    UIView *view = watermark.water;
    CGFloat scale = watermark.scale;
    runSynchronouslyOnMainQueue(^{
        if (watermark.refreshWatermark) {
            @xhm_weakify(watermark);
            watermark.refreshWatermark(BMWRefreshWatermarkStatusCaptureView, nil, ^{
                @xhm_strongify(watermark);
                renderImage = [view xhm_captureWithNewApi:scale];
            });
        } else {
            renderImage = [view xhm_captureWithNewApi:scale];
        }
    });
    textureId = [self setupTexture:renderImage];
    return textureId;
}

+ (void)createBufferWithWatermark:(BMWWatermarkItem *)watermark block:(void (^)(UIImage*image))block
{
    UIView *view = watermark.water;
    CGFloat scale = watermark.scale;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (watermark.refreshWatermark) {
            @xhm_weakify(watermark);
            watermark.refreshWatermark(BMWRefreshWatermarkStatusCaptureView, nil, ^{
                @xhm_strongify(watermark);
                UIImage *renderImage = [view xhm_captureWithNewApi:scale];
                !block ? : block(renderImage);
            });
        } else {
            UIImage *renderImage = [view xhm_captureWithNewApi:scale];
            !block ? : block(renderImage);
        }
    });
}

+ (GLuint)createTextureWithBuffer:(CVPixelBufferRef)pixelBuffer context:(BMWImageContext*)context
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    CVOpenGLESTextureRef rgbaTextureRef = NULL;
    CVReturn ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, context.coreVideoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, width, height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &rgbaTextureRef);
    if (ret != noErr) {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return 0;
    }
    GLuint texid = CVOpenGLESTextureGetName(rgbaTextureRef);
    glBindTexture(GL_TEXTURE_2D, texid);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    CFRelease(rgbaTextureRef);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return texid;
}

+ (GLuint)genTexture
{
    GLuint textId = 0;
    glGenTextures(1, &textId);
    glBindTexture(GL_TEXTURE_2D, textId);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);
    return textId;
}

+ (CGSize)clampToMaxSize:(CGSize)inSize
{
    CGFloat max = MAX(inSize.width, inSize.height);
    CGFloat limit = BMWGLUtils.maxSupportImageSize;
    if (limit > 0 && max > limit) {
        CGFloat r = limit / max;
        CGFloat w = inSize.width * r;
        CGFloat h = inSize.height * r;
        inSize = CGSizeMake(floor(w), floor(h));
    }
    return inSize;
}

+ (CGFloat)maxSupportImageSize
{
    static GLint maxSize = 11384;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        runSynchronouslyRenderingQueue(^{
//            [BMWImageContext useImageProcessingContext];
//            GLint texSize = 0;
//            glGetIntegerv(GL_MAX_TEXTURE_SIZE, &texSize);
//            maxSize = texSize;
//        });
//    });
    return maxSize > 0 ? maxSize : 11384;
}

+ (void)rect2GLCoordinate:(CGRect)rect reslut:(void(^)(GLfloat * v))reslut;
{
    CGPoint bl = {
        rect.origin.x,
        rect.origin.y
    };
    CGPoint br = {
        (rect.origin.x + rect.size.width),
        rect.origin.y
    };
    CGPoint tl = {
        rect.origin.x,
       (rect.origin.y + rect.size.height)
    };
    CGPoint tr = {
        (rect.origin.x + rect.size.width),
        (rect.origin.y + rect.size.height)
    };
    GLfloat vertices[] = {
        2 * bl.x - 1, 2 * bl.y - 1,
        2 * br.x - 1, 2 * br.y - 1,
        2 * tl.x - 1, 2 * tl.y - 1,
        2 * tr.x - 1, 2 * tr.y - 1

    };
    reslut(vertices);
}

+ (UIImage *)imageFromView:(UIView *)view
{
    if (!view) {
        return nil;
    }
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, view.opaque, 0.0f);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
