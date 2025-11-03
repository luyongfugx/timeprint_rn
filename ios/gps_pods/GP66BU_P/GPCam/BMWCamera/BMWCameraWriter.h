#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPCamDefine.h"
#import "BMWCameraProfile.h"
#import "BMWAudioFrame.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWCameraWriter : NSObject

@property (nonatomic, assign) BOOL isReady;
@property (nonatomic, assign) BMWCameraWriterStatus writerStatus;
@property (nonatomic, copy) void(^recordDurationBlock)(CGFloat duration);
@property (nonatomic, assign) CGFloat duration;

@property (nonatomic, strong) NSString *errorStr;
@property (nonatomic, strong) NSString *moviePath;
@property (nonatomic, readonly) BMWEncodeProfile* encodeProfile;
- (instancetype)initWithEncodeProfile:(BMWEncodeProfile*)encodeProfile movieURL:(NSURL*)movieURL;
- (void)start;
- (void)stop;
- (void)stop:(void (^ _Nullable)(void))handler;
- (void)pause;
- (void)resume;
// 录制过程中切换摄像头
- (void)pauseForSwitching;
- (void)resumeForSwitching;
- (void)appendVideoBuffer:(CVPixelBufferRef)renderTarget frameTime:(CMTime)frameTime;
- (void)processAudioBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)processAudioFrame:(BMWAudioFrame *)audioFrame;
- (void)activateAudioTrack;
- (void)setCameraWriterTransform:(CGAffineTransform) transform;
- (void)cancelRecording;

- (void)configMetaData:(NSString*)metaInfo;

@end

NS_ASSUME_NONNULL_END
