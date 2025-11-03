#import <GPCam/GPCam.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^CaptureFlashCompletion)(BOOL flashed);

@interface BMWCameraKit (Flash)

- (void)onCameraOpened:(AVCaptureDevice *)device;

- (void)onCameraClosed:(AVCaptureDevice *)device;

- (void)simulateCaptureFlashWithCompletion:(CaptureFlashCompletion)completion;

@end

NS_ASSUME_NONNULL_END
