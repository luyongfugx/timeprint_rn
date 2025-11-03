#import <Foundation/Foundation.h>
#import "BMWBaseDrawer.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWFliterDrawer : BMWBaseDrawer

@property (readonly) float brightnessIntensity;
@property (readonly) float lutIntensity;
@property (readonly) float toneCurveIntensity;
@property (readonly) float lumMaskCurveIntensity;

- (void)setInputTexId:(GLint)inputTexId;
- (void)setLutTexId:(GLint)texId;
- (void)setLumMaskCurveTexId:(GLint)texId;
- (void)setToneCurveTextId:(GLint)texId;

- (void)setBrightnessIntensity:(float)intensity;
- (void)setLutIntensity:(float)intensity;
- (void)setToneCurveIntensity:(float)intensity;
- (void)setLumMaskCurveIntensity:(float)intensity;

- (void)draw;

@end

NS_ASSUME_NONNULL_END


