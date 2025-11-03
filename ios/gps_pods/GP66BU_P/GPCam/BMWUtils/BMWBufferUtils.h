#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMWBufferUtils : NSObject

+ (CVPixelBufferRef)createResizedSampleBuffer:(CVPixelBufferRef)cameraFrame size: (CGSize)finalSize;

+ (UIImage*)genImageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer;

+ (UIImage*)createImageFromPixelBuffer:(CVPixelBufferRef)pixelBuffer;

+ (UIImage*)createImageFromPixelBuffer:(CVPixelBufferRef)pixelBufferRef isFront:(BOOL) isFront isMirror:(BOOL) isMirror orient:(int)orient scale:(float)scale cut:(int)cut;

+ (UIImage*)redrawImage:(UIImage*)image scaledToSize:(CGSize)newSize;

+ (UIImage *)UIImageFromImageBuffer:(CVImageBufferRef)imageBuffer
                        orientation:(UIImageOrientation)orientation;

+ (CVImageBufferRef)imageBufferFromUIImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
