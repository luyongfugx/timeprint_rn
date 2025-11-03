#import <Foundation/Foundation.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#import "GPCamDefine.h"
#import "BMWEffectTypeItem.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BMWEffectType) {
    BMWEffectTypeOriginal = 0, // 原始图像(加锐化)
    BMWEffectTypeBackWithoutTone = 1, // 后置摄像头+其他
    BMWEffectTypeBackWithTone = 2, // 后置摄像头+推荐1
    BMWEffectTypeFront = 3, // 前置摄像头
    BMWEffectTypeNightMode = 4,
    BMWEffectTypeOriginalWithoutSharpen = 5, // 原始图像(不加锐化)
    BMWEffectTypeUnknown = 0xFFFF
};

@protocol BMWRenderInterface <NSObject>

@required

- (void)reset;

- (void)setEffectIntensity:(BMWEffectTypeItem *)item intensity:(float)intensity;

+ (NSArray<BMWEffectTypeItem *>*)supportedEffects;

@optional

- (void)setEffectType:(BMWEffectType)type;

- (void)setDeviceOritaion:(BMWDeviceOrientation)orientation;

- (void)setRenderOutputSize:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
