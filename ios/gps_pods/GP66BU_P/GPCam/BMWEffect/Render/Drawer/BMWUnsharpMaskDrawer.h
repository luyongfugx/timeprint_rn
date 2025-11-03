#import <Foundation/Foundation.h>
#import "BMWBaseDrawer.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWUnsharpMaskDrawer : BMWBaseDrawer

- (void)setIntensity:(float)intensity saturation:(float)saturation;

- (void)setInputSize:(CGSize)size;

- (void)setInputTexId:(GLint)inputTexId tex2Id:(GLint)tex2Id;

- (void)draw;

@end

NS_ASSUME_NONNULL_END


