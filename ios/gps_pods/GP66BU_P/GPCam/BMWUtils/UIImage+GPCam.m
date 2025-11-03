#import "UIImage+GPCam.h"
#import <objc/runtime.h>
#import "GPCamConfigurator.h"
#import "BMWAlgorithmUtils.h"


@implementation UIImage (GPCam)

- (NSData*)xhm_jpegData:(CGFloat)quality
{
    NSData *jpegData = nil;
    if (GPCamConfigurator.sharedInstance.jpegCodecSDK == 2) {

        jpegData = UIImageJPEGRepresentation(self, quality);
        return jpegData;
    }
    
    double begin = CACurrentMediaTime();
    jpegData = UIImageJPEGRepresentation(self, quality);
    double end = CACurrentMediaTime();
    BMWMLog(@"xhm_jpegData apple codec quality:%0.2f, size:%dKb, timecost:%lfms", quality, jpegData.length/1000, (end - begin) * 1000);
    return jpegData;
}


- (UIImage*)xhm_resizeImage:(CGSize)size
{
    UIGraphicsBeginImageContextWithOptions(size, false, 1.0);
    [self drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resizedImage;
}

- (CGFloat)xhm_similarityCheck:(UIImage*)otherImage
{
    CGImageRef selfImageSource = self.CGImage;
    CFDataRef selfImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(selfImageSource));
    unsigned char *selfBuffer = (unsigned char *)CFDataGetBytePtr(selfImageDataProvider);
    
    CGImageRef otherImageSource = otherImage.CGImage;
    CFDataRef otherImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(otherImageSource));
    unsigned char *otherImageBuffer = (unsigned char *)CFDataGetBytePtr(otherImageDataProvider);

    int width = self.size.width;
    int height = self.size.height;
    
    int selfImageStride = (int)CGImageGetBytesPerRow(selfImageSource);
    int otherImageStride = (int)CGImageGetBytesPerRow(otherImageSource);
    float similarity = [BMWImageProcessUtils similarityCheck:selfBuffer oriOffsetY:0 oriStride:selfImageStride ext:otherImageBuffer extOffsetY:0 extStride:otherImageStride width:width height:height];
    if (selfImageDataProvider) {
        CFRelease(selfImageDataProvider);
    }
    if (otherImageDataProvider) {
        CFRelease(otherImageDataProvider);
    }
    return similarity;
}

- (UIImage *)cropImageWithRect:(CGRect)normRect
{
    CGImageRef cgImage = self.CGImage;
    if (!cgImage) {
        return self;
    }
    
    CGRect rect = CGRectMake(normRect.origin.x * self.size.width,
                             normRect.origin.y * self.size.height,
                             normRect.size.width * self.size.width,
                             normRect.size.height * self.size.height);
    CGImageRef croppedCgImage = CGImageCreateWithImageInRect(cgImage, rect);
    if (!croppedCgImage) {
        return nil;
    }

    UIImage *croppedImage = [UIImage imageWithCGImage:croppedCgImage];
    CGImageRelease(croppedCgImage);
    return croppedImage;
}


@end
