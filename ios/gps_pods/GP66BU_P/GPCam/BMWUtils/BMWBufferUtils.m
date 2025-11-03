#import "BMWBufferUtils.h"
#import "BMWDeviceUtils.h"
#import <AVFoundation/AVFoundation.h>

@implementation BMWBufferUtils

// 此API不会重绘，返回的Image生命周期和pixelBuffer绑定
+ (UIImage*)genImageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVPixelBufferRetain(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    NSUInteger paddedWidthOfImage = CVPixelBufferGetBytesPerRow(pixelBuffer) / 4.0;
    NSUInteger paddedBytesForImage = paddedWidthOfImage * height * 4;

    GLubyte *rawImagePixels = (GLubyte *)CVPixelBufferGetBaseAddress(pixelBuffer);

    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rawImagePixels, paddedBytesForImage, NULL);

    CGColorSpaceRef defaultRGBColorSpace = CGColorSpaceCreateDeviceRGB();

    CGImageRef cgImage = CGImageCreate(width, height, 8, 32, CVPixelBufferGetBytesPerRow(pixelBuffer), defaultRGBColorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, dataProvider, NULL, NO, kCGRenderingIntentDefault);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CGDataProviderRelease(dataProvider);
    CGColorSpaceRelease(defaultRGBColorSpace);
    CVPixelBufferRelease(pixelBuffer);

    UIImage *image = [UIImage imageWithCGImage:cgImage];
    return image;
}

+ (UIImage *)UIImageFromImageBuffer:(CVImageBufferRef)imageBuffer
                        orientation:(UIImageOrientation)orientation
{
  CIImage *CIImg = [CIImage imageWithCVPixelBuffer:imageBuffer];
  CIContext *context = [[CIContext alloc] initWithOptions:nil];
  CGImageRef CGImg = [context createCGImage:CIImg fromRect:CIImg.extent];
  UIImage *image = [UIImage imageWithCGImage:CGImg scale:1.0f orientation:orientation];
  CGImageRelease(CGImg);
  return image;
}

+ (UIImage *)createImageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    CVPixelBufferRetain(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    float width = CVPixelBufferGetWidth(pixelBuffer);
    float height = CVPixelBufferGetHeight(pixelBuffer);
    CIImage *ciImage = nil;
    CIContext *temporaryContext = nil;
    CGImageRef videoImage = NULL;
    UIImage *image = nil;
    @try {
        ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
        temporaryContext = [CIContext contextWithOptions:nil];
        videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(0, 0, width, height)];
        image = [UIImage imageWithCGImage:videoImage scale:1.0 orientation:UIImageOrientationUp];
    } @catch (NSException *exception) {
            } @finally {
        !videoImage ? : CGImageRelease(videoImage);
        temporaryContext = nil;
        ciImage = nil;
    };
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    CVPixelBufferRelease(pixelBuffer);
    return image;
}

+ (UIImage *)createImageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef isFront:(BOOL) isFront isMirror:(BOOL) isMirror orient:(int)orient scale:(float)scale cut:(int)cut
{
    CVPixelBufferLockBaseAddress(pixelBufferRef, 0);
    float width = CVPixelBufferGetWidth(pixelBufferRef);
    float height = CVPixelBufferGetHeight(pixelBufferRef);
    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBufferRef];
    UIImage *image = [[self class] redrawImage:ciImage width:width height:height isFront:isFront isMirror:isMirror orient:orient scale:scale cut:cut];
    CVPixelBufferUnlockBaseAddress(pixelBufferRef, 0);
    return image;
}

+ (UIImage *)redrawImage:(CIImage*)ciImage width:(int)width height:(int)height isFront:(BOOL)isFront isMirror:(BOOL)isMirror orient:(int)orient scale:(float)scale cut:(int)cut
{
    // 先缩放
    if(scale > 1) {
        ciImage = [ciImage imageByApplyingTransform:CGAffineTransformMakeScale(scale, scale)];
    }

    // 再旋转和裁剪
    int x = 0, y = 0, w = 0, h = 0;
    if (orient == 1 || orient == 5 || orient == 2) {
        if (cut == 0) {
            x = 0; y = 0; w = height; h = width;
        }
        else if (cut == 1) { // 1:1
            x = 0;
            y = (width - height) / 2.0;
            w = height;
            h = height;
        }
        else if (cut == 2) { // 16:9
            w = width * RATIO9x16; h = width;
            x = (height - w) / 2.0; y = 0;
        }
        else if (cut == 3) { // FULL
            w = width * BMWDeviceUtils.sharedInstance.deviceRatio; h = width;
            x = (height - w) / 2.0; y = 0;
        }
    }

    if (orient == 3 || orient == 4) {
        if (cut == 0) {
            x = 0; y = 0;
            w = width; h = height;
        }
        else if (cut == 1) {
            x = (width - height) / 2.0;
            y = 0;
            w = height;
            h = height;
        }
        else if (cut == 2) {
            h = width * RATIO9x16; w = width;
            x = 0; y = (height - h) / 2.0;
        }
        else if (cut == 3) {
            h = width * BMWDeviceUtils.sharedInstance.deviceRatio; w = width;
            x = 0; y = (height - h) / 2.0;
        }
    }

    if (isFront == NO) {
        if (orient == 1 || orient == 5) {
            ciImage = [ciImage imageByApplyingOrientation:6];
        }
        if (orient == 2) {
            ciImage = [ciImage imageByApplyingOrientation:8];
        }
        if (orient == 3) {
            ciImage = [ciImage imageByApplyingOrientation:1];
        }

        if (orient == 4) {
            ciImage = [ciImage imageByApplyingOrientation:3];
        }
    } else {
        if (orient == 1 || orient == 5) {
            if (isMirror) {
                ciImage = [ciImage imageByApplyingOrientation:6];
            } else {
                ciImage = [ciImage imageByApplyingOrientation:5];
            }
        }
        if (orient == 2) {
            if (isMirror) {
                ciImage = [ciImage imageByApplyingOrientation:8];
            } else {
                ciImage = [ciImage imageByApplyingOrientation:7];
            }
        }
        if (orient == 3) {
            if (isMirror) {
                ciImage = [ciImage imageByApplyingOrientation:3];
            } else {
                ciImage = [ciImage imageByApplyingOrientation:4];
            }
        }

        if (orient == 4) {
            if (isMirror) {
                ciImage = [ciImage imageByApplyingOrientation:1];
            } else {
                ciImage = [ciImage imageByApplyingOrientation:2];
            }
        }
    }

    UIImage *image = nil;
    CIContext *temporaryContext = nil;
    CGImageRef videoImage = NULL;
    @try {
        temporaryContext = [CIContext contextWithOptions:nil];
        videoImage = [temporaryContext createCGImage:ciImage fromRect:CGRectMake(x, y, w, h)];
        image = [UIImage imageWithCGImage:videoImage scale:1.0 orientation:(UIImageOrientationUp)];
    } @catch (NSException *exception) {
            } @finally {
        !videoImage ? : CGImageRelease(videoImage);
        temporaryContext = nil;
        ciImage = nil;
    };
    return image;
}

+ (UIImage*)redrawImage:(UIImage*)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

static void StillImageDataReleaseCallback(void *releaseRefCon, const void *baseAddress)
{
    if (baseAddress != NULL) {
        free((void *)baseAddress);
    }
}

+ (CVPixelBufferRef)createResizedSampleBuffer:(CVPixelBufferRef)cameraFrame size:(CGSize)finalSize
{
    CGSize originalSize = CGSizeMake(CVPixelBufferGetWidth(cameraFrame), CVPixelBufferGetHeight(cameraFrame));
    if (CGSizeEqualToSize(finalSize, CGSizeZero)) {
        finalSize = originalSize;
    }

    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    GLubyte *sourceImageBytes =  (GLubyte*)CVPixelBufferGetBaseAddress(cameraFrame);
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, sourceImageBytes, CVPixelBufferGetBytesPerRow(cameraFrame) * originalSize.height, NULL);
    CGColorSpaceRef genericRGBColorspace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImageFromBytes = CGImageCreate((int)originalSize.width, (int)originalSize.height, 8, 32, CVPixelBufferGetBytesPerRow(cameraFrame), genericRGBColorspace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst, dataProvider, NULL, NO, kCGRenderingIntentDefault);

    GLubyte *imageData = (GLubyte *) calloc(1, (int)finalSize.width * (int)finalSize.height * 4);

    CGContextRef imageContext = CGBitmapContextCreate(imageData, (int)finalSize.width, (int)finalSize.height, 8, (int)finalSize.width * 4, genericRGBColorspace,  kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGContextDrawImage(imageContext, CGRectMake(0.0, 0.0, finalSize.width, finalSize.height), cgImageFromBytes);
    CGImageRelease(cgImageFromBytes);
    CGContextRelease(imageContext);
    CGColorSpaceRelease(genericRGBColorspace);
    CGDataProviderRelease(dataProvider);

    CVPixelBufferRef pixelbuffer;
    CVPixelBufferCreateWithBytes(kCFAllocatorDefault, finalSize.width, finalSize.height, kCVPixelFormatType_32BGRA, imageData, finalSize.width * 4, StillImageDataReleaseCallback, NULL, NULL, &pixelbuffer);

    return pixelbuffer;
}

+ (CVImageBufferRef)imageBufferFromUIImage:(UIImage *)image
{
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);

    CVPixelBufferRef imageBuffer;
    CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA,
                      (__bridge CFDictionaryRef) @{}, &imageBuffer);

    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    CGContextRef context = CGBitmapContextCreate(
      baseAddress, width, height, /*bitsPerComponent=*/8, bytesPerRow, colorSpace,
      kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);

    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextClearRect(context, rect);
    CGContextDrawImage(context, rect, image.CGImage);

    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);

    return imageBuffer;
}

@end
