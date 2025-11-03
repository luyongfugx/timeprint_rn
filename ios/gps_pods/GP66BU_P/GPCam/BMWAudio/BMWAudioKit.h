#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import "BMWAudioFrame.h"

NS_ASSUME_NONNULL_BEGIN

@protocol BMWAudioKitDelegate <NSObject>

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer;

@optional
- (void)processAudioFrame:(BMWAudioFrame *)audioFrame;

@end

@protocol BMWAudioSource <NSObject>

- (void)startAudioCaptureWithDelegate:(id<BMWAudioKitDelegate>)delegate;

- (void)stopAudioCaptureWithDelegate:(id<BMWAudioKitDelegate>)delegate;

@end

@interface BMWAudioKit : NSObject

@property (nonatomic, readonly) OSStatus status;

+ (BMWAudioKit*)sharedInstance;

- (void)startAudioCaptureWithDelegate:(id<BMWAudioKitDelegate>)delegate;

- (void)stopAudioCaptureWithDelegate:(id<BMWAudioKitDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
