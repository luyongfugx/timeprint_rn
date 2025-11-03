#import "BMWCameraRecorder.h"
#import "BMWCameraWriter.h"
#import "BMWJpegPacker.h"

@interface BMWCameraRecorder ()

@property (nonatomic, strong) BMWCameraWriter *mainWriter;

@property (nonatomic, strong) BMWCameraWriter *noWatermarkWriter;

@end

@implementation BMWCameraRecorder

- (instancetype)initWithEncodeProfile:(BMWEncodeProfile*)encodeProfile
{
    BMWMLog(@"%s %d", __FUNCTION__, __LINE__);
    self = [super init];
    if (self) {
        _enableRecordNoWatermarkVideo = encodeProfile.enableRecordNoWatermarkVideo;
        _mainWriter = [[BMWCameraWriter alloc] initWithEncodeProfile:encodeProfile movieURL:encodeProfile.videoUrl];
        if (_enableRecordNoWatermarkVideo) {
            _noWatermarkWriter = [[BMWCameraWriter alloc] initWithEncodeProfile:encodeProfile movieURL:encodeProfile.noWatermarkVideoUrl];
            [_noWatermarkWriter configMetaData:encodeProfile.noWatermarkMetaData];
            @xhm_weakify(self);
            _noWatermarkWriter.recordDurationBlock = ^(CGFloat duration) {
                if (encodeProfile.noWatermarkVideoMaxDuration > 0 && duration >= encodeProfile.noWatermarkVideoMaxDuration) {
                    @xhm_strongify(self);
                    [self.noWatermarkWriter cancelRecording];
                    self.noWatermarkWriter = nil;
                }
            };
        }
    }
    return self;
}

- (BOOL)isReady {
    return self.mainWriter.isReady;
}

- (void)setIsReady:(BOOL)isReady {
    self.mainWriter.isReady = isReady;
}

- (BMWCameraWriterStatus)writerStatus {
    return self.mainWriter.writerStatus;
}

- (void)setWriterStatus:(BMWCameraWriterStatus)writerStatus {
    self.mainWriter.writerStatus = writerStatus;
}

- (void (^)(CGFloat))recordDurationBlock {
    return self.mainWriter.recordDurationBlock;
}

- (void)setRecordDurationBlock:(void (^)(CGFloat))recordDurationBlock {
    self.mainWriter.recordDurationBlock = recordDurationBlock;
}

- (NSString *)errorStr {
    return self.mainWriter.errorStr;
}

- (void)setErrorStr:(NSString *)errorStr {
    self.mainWriter.errorStr = errorStr;
}

- (NSString *)moviePath {
    return self.mainWriter.moviePath;
}

- (void)setMoviePath:(NSString *)moviePath {
    self.mainWriter.moviePath = moviePath;
}

- (BMWEncodeProfile *)encodeProfile {
    return self.mainWriter.encodeProfile;
}

- (void)start {
    BMWMLog(@"%s %d", __FUNCTION__, __LINE__);
    [self.mainWriter start];
    [self.noWatermarkWriter start];
}

- (void)stop {
    BMWMLog(@"%s %d", __FUNCTION__, __LINE__);
    [self.mainWriter stop];
    [self.noWatermarkWriter stop];
}

- (void)stop:(void (^ _Nullable)(BMWVideoMetaData *metaData))handler;
{
    BMWMLog(@"%s %d noWatermarkWriter.duration: %fs, mainWriter.duration: %fs", __FUNCTION__, __LINE__, self.noWatermarkWriter.duration, self.mainWriter.duration);
    [self.noWatermarkWriter pause];
    [self.mainWriter pause];
    @xhm_weakify(self);
    [self.mainWriter stop:^{
        @xhm_strongify(self);
        if (self.noWatermarkWriter && self.noWatermarkWriter.duration > 0 && self.noWatermarkWriter.duration < self.encodeProfile.noWatermarkVideoMaxDuration) {
            [self.noWatermarkWriter stop: ^{
                BMWSliceDataModel *sliceDataModel = self.encodeProfile.sliceDataModel;
                BMWVideoMetaData *videoMetaData = [[BMWVideoMetaData alloc] init:sliceDataModel];

                [BMWJpegPacker.sharedInstance packVideo:sliceDataModel completeBlock:^(BMWSliceDataModel * _Nullable reslut) {
                    SafeBlock(handler, videoMetaData);
                }];
            }];
        } else {
            SafeBlock(handler, nil);
        }
    }];
}

- (void)pause {
    BMWMLog(@"%s %d", __FUNCTION__, __LINE__);
    [self.mainWriter pause];
    [self.noWatermarkWriter pause];
}

- (void)resume {
    BMWMLog(@"%s %d", __FUNCTION__, __LINE__);
    [self.mainWriter resume];
    [self.noWatermarkWriter resume];
}

- (void)pauseForSwitching {
    BMWMLog(@"%s %d", __FUNCTION__, __LINE__);
    [self.mainWriter pauseForSwitching];
    [self.noWatermarkWriter pauseForSwitching];
}

- (void)resumeForSwitching {
    BMWMLog(@"%s %d", __FUNCTION__, __LINE__);
    [self.mainWriter resumeForSwitching];
    [self.noWatermarkWriter resumeForSwitching];
}

- (void)appendVideoBuffer:(CVPixelBufferRef)renderTarget frameTime:(CMTime)frameTime {
    [self.mainWriter appendVideoBuffer:renderTarget frameTime:frameTime];
}

- (void)appendNoWatermarkVideoBuffer:(CVPixelBufferRef)renderTarget frameTime:(CMTime)frameTime {
    if (!renderTarget) {
        return;
    }
    [self.noWatermarkWriter appendVideoBuffer:renderTarget frameTime:frameTime];
}

- (void)processAudioBuffer:(CMSampleBufferRef)sampleBuffer {
    [self.mainWriter processAudioBuffer:sampleBuffer];
    [self.noWatermarkWriter processAudioBuffer:sampleBuffer];
}

- (void)processAudioFrame:(BMWAudioFrame *)audioFrame {
    [self.mainWriter processAudioFrame:audioFrame];
    [self.noWatermarkWriter processAudioFrame:audioFrame];
}

- (void)activateAudioTrack {
    [self.mainWriter activateAudioTrack];
    [self.noWatermarkWriter activateAudioTrack];
}

- (void)setCameraWriterTransform:(CGAffineTransform) transform {
    [self.mainWriter setCameraWriterTransform:transform];
    [self.noWatermarkWriter setCameraWriterTransform:transform];
}

- (void)cancelRecording {
    BMWMLog(@"%s %d", __FUNCTION__, __LINE__);
    [self.mainWriter cancelRecording];
    [self.noWatermarkWriter cancelRecording];
}

- (void)configMetaData:(NSString*)metaInfo {
    [self.mainWriter configMetaData:metaInfo];
    [self.noWatermarkWriter configMetaData:metaInfo];
}

@end
