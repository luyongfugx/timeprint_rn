#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMWDecibelFilter : NSObject

+ (int)decibelFromPcm:(const int16_t *)pcmdata size:(size_t)size;
+ (int)decibelFromPcm2:(const int16_t *)pcmdata size:(size_t)size;

@end

@interface BMWKalmanFilter : NSObject

- (double)kalmanFilter:(double)value;

- (void)reset;

@end

@interface BMWLinearSmoothFilter : NSObject

// gravity[x,y] 0.97/0.0
// 2s
// 0.2 - 7/20 v
// 0.3 - 4/20 v
// 0.4 - 3/20 v
// 0.5 - 2/20 v
// 1s
// 0.2 - 5/10 x
// 0.3 - 4/10 v
// 0.4 - 3/10 v
// 0.5 - 2/10 v
@property (assign) double factor;

- (double)smoothFilter:(double)value;

- (void)reset;

@end

@interface BMWImageProcessUtils : NSObject
+ (CGFloat)similarityCheck:(unsigned char*)ori
                oriOffsetY:(int)oriOffsetY
                 oriStride:(int) oriStride
                       ext:(unsigned char*)ext
                extOffsetY:(int) extOffsetY
                 extStride:(int)extStride
                     width:(int)width
                    height:(int)height;

+ (NSString*)imageEncode:(CVPixelBufferRef)pixelBuffer;
+ (NSString*)imageEncodeWithImage:(UIImage*)image size:(CGSize)size;

+ (float)laplacian:(CVPixelBufferRef)pixelBuffer;
           
@end

NS_ASSUME_NONNULL_END
