#import <GPCam/GPCam.h>
#import "BMWAudioKit.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWAudioKitV2 : NSObject

@property (nonatomic, readonly) OSStatus status;

- (void)startAudioCaptureWithDelegate:(id<BMWAudioKitDelegate>)delegate;

- (void)stopAudioCaptureWithDelegate:(id<BMWAudioKitDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
