#import <Foundation/Foundation.h>
#import "BMWBaseDrawer.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWNightModeDrawer : BMWBaseDrawer

- (instancetype)initWithContext:(BMWImageContext *)imageContext useYUV:(BOOL)useYUV;

- (void)setMaskTexId:(GLint)maskTexId;

- (void)setInputPixelBuffer:(CVPixelBufferRef)pixelBuffer;

- (void)draw;

@end

NS_ASSUME_NONNULL_END


