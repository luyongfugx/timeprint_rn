#import <AVFoundation/AVFoundation.h>
#import "BMWRenderInterface.h"
#import "BMWImageContext.h"
#import "BMWFramebuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWFrameRender : NSObject <BMWRenderInterface>

@property (nonatomic, readonly) CGFloat luminance;

@property (nonatomic) NSUInteger faceCount;
@property (nonatomic, assign) CMTime frameTime;

@property (nonatomic, readonly, copy) NSString *lutPath;

@property (nonatomic, readonly, assign) CGFloat lutIntensity;

@property (nonatomic, readonly, assign) CGFloat brightnessIntensity;

@property (nonatomic, readonly, strong) NSMutableDictionary<NSString*, BMWEffectTypeItem* >* beautyTypeDic;

@property (nonatomic, readonly, strong) NSMutableDictionary<NSString*, NSNumber*>* beautyIntensityDic;

@property (nonatomic, assign) BMWImageRotationMode rotation;

@property (nonatomic, readonly, assign) CGSize outputSize;

- (instancetype)init;

- (instancetype)initWithContext:(BMWImageContext *)imageContext rotation:(BMWImageRotationMode)rotation useYUV:(BOOL)useYUV;

- (GLuint)processPixelBuffer:(CVPixelBufferRef)cameraFrame pipPixelBuffer:(CVPixelBufferRef)pipCameraFrame pipOrientation:(BMWDeviceOrientation)pipOrientation frameTime:(CMTime)frameTime isFront:(BOOL)isFront;

- (GLuint)processWithExtraScaleRatio:(CGFloat)factor;

- (void)setExtraScaleRatio:(CGFloat)factor;

- (void)triggerLuminanceDetect:(BOOL)enable;

- (UIImage*)renderPreview:(BOOL)isMirror orientation:(BMWDeviceOrientation)orientation;

- (UIImage*)renderPreview:(BOOL)isMirror outputSize:(CGSize)outputSize orientation:(BMWDeviceOrientation)orientation;

- (UIImage*)outputImage;

- (CVPixelBufferRef)getOutputPixelBuffer;

@end

NS_ASSUME_NONNULL_END
