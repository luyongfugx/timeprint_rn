#import <Foundation/Foundation.h>
#import "BMWBaseDrawer.h"
#import "BMWImageContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWPipInputDrawer : BMWBaseDrawer

@property (nonatomic, readonly) GLint inputImageTextureId;

- (instancetype)initWithContext:(BMWImageContext *)imageContext useYUV:(BOOL)useYUV;

- (void)setBorder:(CGSize)resolution radius:(int)radius borderWidth:(float)borderWidth borderColor:(UIColor*)borderColor;
- (void)setInputPixelBuffer:(CVPixelBufferRef)pixelBuffer;
- (void)setMaskPixelBuffer:(CVPixelBufferRef _Nullable)pixelBuffer;
- (void)draw;

@end

NS_ASSUME_NONNULL_END


