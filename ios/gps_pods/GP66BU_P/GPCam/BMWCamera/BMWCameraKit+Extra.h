#import "BMWCameraKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWCameraKit (Extra)

- (void)playShutterSound;

- (AVCaptureVideoStabilizationMode)getVideoStabilizationMode;

- (void)configDefaultDimensions;

- (NSInteger)getMuteTakePhoto;

- (NSInteger)getFastImageCaptureMode;

- (CGSize)calcResolution:(BMWDeviceOrientation)orientation quality:(BMWImageResolutionQuality)quality ratioMode:(BMWCameraKitMode)ratioMode clampByDevice:(BOOL)clamp;

- (BOOL)captureImageImmediateIfNeeded:(BMWTakePhotoImmediate)immediate;

@end

NS_ASSUME_NONNULL_END
