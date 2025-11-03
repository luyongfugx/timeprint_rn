#import "BMWCameraWriter.h"
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import "BMWImageContext.h"
#import <VideoToolbox/VideoToolbox.h>

@interface BMWCameraWriter()
{
    AVAssetWriter *_assetWriter;
    AVAssetWriterInputPixelBufferAdaptor *_assetWriterPixelBufferInput;
    AVAssetWriterInput* _assetWriterVideoInput;
    AVAssetWriterInput* _assetWriterAudioInput;
    NSString *_pathToMovie;
    
    CMTime _startTime, offsetTime;
    CFTimeInterval _pauseTime, _totalPausedTimeV, _previousEncodeTimeV;
    CFTimeInterval _totalPausedTimeA, _previousEncodeTimeA;
    BOOL _audioEncodingIsFinished, _videoEncodingIsFinished;
    
    BMWImageContext* _cameraWriterContext;
    
    BOOL _encodingLiveVideo;
    BOOL alreadyFinishedRecording;
    
    CVPixelBufferRef renderTarget;
}

@property (nonatomic, strong) NSRecursiveLock* lock;
@property (nonatomic, strong) BMWEncodeProfile* encodeProfile;

@end

@implementation BMWCameraWriter

- (void)dealloc
{
    BMWMLogM(@"BMWCameraWriter dealoc ..");
}

- (instancetype)initWithEncodeProfile:(BMWEncodeProfile*)encodeProfile movieURL:(NSURL*)movieURL
{
    if (!(self = [super init])) {
        return nil;
    }
    BMWMLog(@"%s %d movieURL:%@, %@", __FUNCTION__, __LINE__, movieURL, self);
    _encodeProfile = encodeProfile;
    _moviePath = movieURL.path;
    _startTime = kCMTimeInvalid;
    _pauseTime = 0;
    _totalPausedTimeV = _previousEncodeTimeV = 0;
    _totalPausedTimeA = _previousEncodeTimeA = 0;
    _videoEncodingIsFinished = NO;
    _audioEncodingIsFinished = NO;
    _cameraWriterContext = [BMWImageContext sharedImageProcessingContext];
    _encodingLiveVideo = YES;
    self.lock = [[NSRecursiveLock alloc] init];
    
    NSError *error = nil;
    _assetWriter = [[AVAssetWriter alloc] initWithURL:movieURL fileType:AVFileTypeQuickTimeMovie error:&error];
    
    if (error != nil) {
        self.errorStr = [NSString stringWithFormat:@"create writer fail:%@", error.description];
    }
    
    _assetWriter.movieFragmentInterval = kCMTimeInvalid;
    _assetWriter.movieTimeScale = VIDEO_TIMESCALE;
    _assetWriter.shouldOptimizeForNetworkUse = encodeProfile.shouldOptimizeForNetworkUse;
    
    CGSize frameSize = encodeProfile.videoSize;
    CGFloat frameRate = encodeProfile.frameRate;
    NSUInteger maxKeyFrameInterval = frameRate * 2;
    if(encodeProfile.frameRate < 30) {
        maxKeyFrameInterval = frameRate * 10;
    }
    NSDictionary * prop = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithBool:YES], kVTCompressionPropertyKey_AllowFrameReordering,
                           [NSNumber numberWithInt:encodeProfile.bitrate], kVTCompressionPropertyKey_AverageBitRate,
                           kVTProfileLevel_H264_High_AutoLevel, kVTCompressionPropertyKey_ProfileLevel,
                           kVTH264EntropyMode_CABAC, kVTCompressionPropertyKey_H264EntropyMode,
                           [NSNumber numberWithInt:maxKeyFrameInterval], kVTCompressionPropertyKey_MaxKeyFrameInterval,
                           [NSNumber numberWithInt:frameRate],kVTCompressionPropertyKey_ExpectedFrameRate,
                           nil];
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   prop,AVVideoCompressionPropertiesKey,
                                   [NSNumber numberWithInt:frameSize.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:frameSize.height], AVVideoHeightKey,
                                   nil];
    
    _assetWriterVideoInput = [AVAssetWriterInput
                              assetWriterInputWithMediaType:AVMediaTypeVideo
                              outputSettings:videoSettings];
    // fixes all errors
    _assetWriterVideoInput.expectsMediaDataInRealTime = _encodingLiveVideo;
    _assetWriterVideoInput.mediaTimeScale = VIDEO_TIMESCALE;
    
    NSMutableDictionary *attributes = [[NSMutableDictionary alloc] init];
    [attributes setObject:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA] forKey:(NSString*)kCVPixelBufferPixelFormatTypeKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.height] forKey:(NSString*)kCVPixelBufferWidthKey];
    [attributes setObject:[NSNumber numberWithUnsignedInt:frameSize.width] forKey:(NSString*)kCVPixelBufferHeightKey];
    
    _assetWriterPixelBufferInput = [AVAssetWriterInputPixelBufferAdaptor
                                    assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_assetWriterVideoInput
                                    sourcePixelBufferAttributes:attributes];
    
    [_assetWriter addInput:_assetWriterVideoInput];
    
    // 配置meta data
    [self configMetaData:encodeProfile.metaData];
    
    return self;
}

- (void)setCameraWriterTransform:(CGAffineTransform)transform
{
    _assetWriterVideoInput.transform = transform;
}

- (void)start
{
    BMWMLog(@"%s %d %@", __FUNCTION__, __LINE__, self);
    [_lock lock];
    _startTime = kCMTimeInvalid;
    _pauseTime = 0;
    _totalPausedTimeV = _previousEncodeTimeV = 0;
    _totalPausedTimeA = _previousEncodeTimeA = 0;
    runSynchronouslyOnContextQueue(_cameraWriterContext, ^{
        BOOL ret = [_assetWriter startWriting];
        if (!ret) {
            self.errorStr = [NSString stringWithFormat:@"%@ - startWriting fail, error:%@", self.errorStr, _assetWriter.error.description];
        }
    });
    _writerStatus = BMWCameraWriterStatusRecording;
    
    [_lock unlock];
}

- (void)stop
{
    BMWMLog(@"%s %d %@", __FUNCTION__, __LINE__, self);
    [_lock lock];
    [self stop:nil];
    [_lock unlock];
}

- (void)pause
{
    [_lock lock];
    BMWMLog(@"record pause ... status:%d, %@", self.writerStatus, self);
    if (self.writerStatus == BMWCameraWriterStatusRecording ||
        self.writerStatus == BMWCameraWriterStatusSwitchingPaused) {
        self.writerStatus = BMWCameraWriterStatusPaused;
        _pauseTime = CACurrentMediaTime();
    }
    [_lock unlock];
}

- (void)resume
{
    [_lock lock];
    if (self.writerStatus == BMWCameraWriterStatusPaused) {
        self.writerStatus = BMWCameraWriterStatusRecording;
        CFTimeInterval curTime = CACurrentMediaTime();
        CFTimeInterval delta = curTime - _pauseTime;
        _totalPausedTimeV += delta;
        _totalPausedTimeA += delta;
        BMWMLog(@"record resume, and total paused time:[%lf,%lf]", _totalPausedTimeV,_totalPausedTimeA);
    }
    [_lock unlock];
}

- (void)pauseForSwitching
{
    [_lock lock];
    BMWMLog(@"pause resume for switching...status:%d", self.writerStatus);
    if (self.writerStatus == BMWCameraWriterStatusRecording) {
        self.writerStatus = BMWCameraWriterStatusSwitchingPaused;
        _pauseTime = CACurrentMediaTime();
    }
    [_lock unlock];
}

- (void)resumeForSwitching;
{
    [_lock lock];
    if (self.writerStatus == BMWCameraWriterStatusSwitchingPaused) {
        self.writerStatus = BMWCameraWriterStatusRecording;
        CFTimeInterval curTime = CACurrentMediaTime();
        CFTimeInterval delta = curTime - _pauseTime;
        _totalPausedTimeV += delta;
        _totalPausedTimeA += delta;
        BMWMLog(@"record resume for switching, and total paused time:[%lf,%lf]", _totalPausedTimeV,_totalPausedTimeA);
    }
    [_lock unlock];
}

- (void)processAudioFrame:(BMWAudioFrame *)audioFrame {
    if (self.writerStatus != BMWCameraWriterStatusRecording) {
        return;
    }
    
    // 先录制视频帧
    if (CMTIME_IS_INVALID(_startTime)) {
        return;
    }
    
    if (audioFrame.channels > 1) {
        BMWMLog(@"retrun to avoid audio buffer inavlid when audio channels > 1");
        return;
    }
    
    CMTime currentSampleTime = audioFrame.presentationTimestamp;
    
    if (CMTIME_IS_INVALID(_startTime)) {
        
        runSynchronouslyOnContextQueue(_cameraWriterContext, ^{
            if (_assetWriter.status != AVAssetWriterStatusWriting && _assetWriter.status != AVAssetWriterStatusFailed) {
                [_assetWriter startWriting];
            }
            if (_assetWriter.status == AVAssetWriterStatusFailed) {
                self.errorStr = [NSString stringWithFormat:@"%@ - append audio buffer fail status:%@, error:%@", self.errorStr, @(_assetWriter.status), _assetWriter.error.description];
            }
            [_assetWriter startSessionAtSourceTime:currentSampleTime];
            _startTime = currentSampleTime;
        });
    }
    CMTime currentSampleTime2 = [self adjustPresentationTimeA:currentSampleTime];
    CMSampleBufferRef sampleBuffer = audioFrame.sampleBuffer;
    if (!sampleBuffer) {
        return;
    }
    CFRetain(sampleBuffer);
    CMSampleBufferSetOutputPresentationTimeStamp(sampleBuffer, currentSampleTime2);
    if (!_assetWriterAudioInput.readyForMoreMediaData && _encodingLiveVideo) {
        CFRelease(sampleBuffer);
        return;
    }
    
    void(^write)(void) = ^() {
        while (!_assetWriterAudioInput.readyForMoreMediaData && !_encodingLiveVideo && !_audioEncodingIsFinished) {
            NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
            [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
        }
                
        if (!_assetWriterAudioInput.readyForMoreMediaData) {
            BMWMLog(@"Had to drop an audio frame %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
            
        } else if (_assetWriter.status == AVAssetWriterStatusWriting &&
                   self.writerStatus == BMWCameraWriterStatusRecording){
            if (![_assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                BMWMLog(@"appending audio buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime2)));
                 if (self.errorStr == nil) {
                     self.errorStr = [NSString stringWithFormat:@"%@ - append audio buffer fail, error:%@", self.errorStr, _assetWriter.error.description];
                 }
            }
            _previousEncodeTimeA = CMTimeGetSeconds(currentSampleTime2);
        } else {

        }
        
        CFRelease(sampleBuffer);
    };
    
    if (_encodingLiveVideo) {
        runAsynchronouslyOnContextQueue(_cameraWriterContext, write);
    } else {
        write();
    }
}

- (void)processAudioBuffer:(CMSampleBufferRef)sampleBuffer
{
    if (self.writerStatus != BMWCameraWriterStatusRecording) {
        return;
    }
    
    // 先录制视频帧
    if (CMTIME_IS_INVALID(_startTime)) {
        return;
    }
    
    AudioBufferList audioBufferList;
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);
    AudioBuffer audioBuffer = audioBufferList.mBuffers[0];
    UInt32 channels = audioBuffer.mNumberChannels;
    CFRelease(blockBuffer);
    if (channels > 1) {
        BMWMLog(@"retrun to avoid audio buffer inavlid when audio channels > 1");
        return;
    }
    
    NSData *data = [NSData dataWithBytes:audioBuffer.mData length:audioBuffer.mDataByteSize];
    
    CFRetain(sampleBuffer);
    CMTime currentSampleTime = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
    
    if (CMTIME_IS_INVALID(_startTime)) {
        
        runSynchronouslyOnContextQueue(_cameraWriterContext, ^{
            if (_assetWriter.status != AVAssetWriterStatusWriting && _assetWriter.status != AVAssetWriterStatusFailed) {
                [_assetWriter startWriting];
            }
            if (_assetWriter.status == AVAssetWriterStatusFailed) {
                self.errorStr = [NSString stringWithFormat:@"%@ - append audio buffer fail status:%@, error:%@", self.errorStr, @(_assetWriter.status), _assetWriter.error.description];
            }
            [_assetWriter startSessionAtSourceTime:currentSampleTime];
            _startTime = currentSampleTime;
        });
    }
    CMTime currentSampleTime2 = [self adjustPresentationTimeA:currentSampleTime];
    CMSampleBufferSetOutputPresentationTimeStamp(sampleBuffer, currentSampleTime2);
    if (!_assetWriterAudioInput.readyForMoreMediaData && _encodingLiveVideo) {
        CFRelease(sampleBuffer);
        return;
    }
    
    void(^write)(void) = ^() {
        while (!_assetWriterAudioInput.readyForMoreMediaData && !_encodingLiveVideo && !_audioEncodingIsFinished) {
            NSDate *maxDate = [NSDate dateWithTimeIntervalSinceNow:0.5];
            [[NSRunLoop currentRunLoop] runUntilDate:maxDate];
        }
        
        {
            AudioBuffer buffer;
            buffer.mData = data.bytes;
            buffer.mDataByteSize = data.length;
            buffer.mNumberChannels = channels;
            
            AudioBufferList buffers;
            buffers.mNumberBuffers = 1;
            buffers.mBuffers[0] = buffer;

            OSStatus status = CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer, kCFAllocatorDefault, kCFAllocatorDefault, 0, &buffers);
        }
        
        if (!_assetWriterAudioInput.readyForMoreMediaData) {
            BMWMLog(@"Had to drop an audio frame %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime)));
            
        } else if (_assetWriter.status == AVAssetWriterStatusWriting &&
                   self.writerStatus == BMWCameraWriterStatusRecording){
            if (![_assetWriterAudioInput appendSampleBuffer:sampleBuffer]) {
                BMWMLog(@"appending audio buffer at time: %@", CFBridgingRelease(CMTimeCopyDescription(kCFAllocatorDefault, currentSampleTime2)));
                 if (self.errorStr == nil) {
                     self.errorStr = [NSString stringWithFormat:@"%@ - append audio buffer fail, error:%@", self.errorStr, _assetWriter.error.description];
                 }
            }
            _previousEncodeTimeA = CMTimeGetSeconds(currentSampleTime2);
        } else {

        }
        
        CFRelease(sampleBuffer);
    };
    
    if (_encodingLiveVideo) {
        runAsynchronouslyOnContextQueue(_cameraWriterContext, write);
    } else {
        write();
    }
}

- (void)cancelRecording
{
    BMWMLog(@"%s %d %@", __FUNCTION__, __LINE__, self);
    [_lock lock];
    if (_assetWriter.status == AVAssetWriterStatusCompleted) {
        [_lock unlock];
        return;
    }
    _writerStatus = BMWCameraWriterStatusInited;
    _isReady = NO;
    
    runSynchronouslyOnContextQueue(_cameraWriterContext, ^{
        alreadyFinishedRecording = YES;
        
        if (_assetWriter.status == AVAssetWriterStatusWriting && ! _videoEncodingIsFinished )
        {
            _videoEncodingIsFinished = YES;
            [_assetWriterVideoInput markAsFinished];
        }
        if (_assetWriter.status == AVAssetWriterStatusWriting && ! _audioEncodingIsFinished )
        {
            _audioEncodingIsFinished = YES;
            [_assetWriterAudioInput markAsFinished];
        }
        [_assetWriter cancelWriting];
    });
    [_lock unlock];
}

- (void)stop:(void (^)(void))handler
{
    BMWMLog(@"%s %d %@", __FUNCTION__, __LINE__, self);
    [_lock lock];
    runSynchronouslyOnContextQueue(_cameraWriterContext, ^{
        _isReady = NO;
        _writerStatus = BMWCameraWriterStatusInited;
        if (_assetWriter.status == AVAssetWriterStatusCompleted || _assetWriter.status == AVAssetWriterStatusCancelled || _assetWriter.status == AVAssetWriterStatusUnknown) {
            self.errorStr = [NSString stringWithFormat:@"%@ - asset writer stop fail status:%@, error:%@", self.errorStr, @(_assetWriter.status), _assetWriter.error.description];
            if (handler) {
                runAsynchronouslyOnContextQueue(_cameraWriterContext, handler);
            }
            return;
        }
        
        if (_assetWriter.status == AVAssetWriterStatusWriting && !_videoEncodingIsFinished) {
            _videoEncodingIsFinished = YES;
            [_assetWriterVideoInput markAsFinished];
            if (renderTarget) {
                CVPixelBufferRelease(renderTarget);
                renderTarget = NULL;
            }
        }
        
        if (_assetWriter.status == AVAssetWriterStatusWriting && !_audioEncodingIsFinished) {
            _audioEncodingIsFinished = YES;
            [_assetWriterAudioInput markAsFinished];
        }
        
        if (handler) {
            void(^_handler)(void) = ^() {
                if (_assetWriter.status != AVAssetWriterStatusCompleted) {
                    self.errorStr = [NSString stringWithFormat:@"%@ - asset writer finish fail status:%@, error:%@", self.errorStr, @(_assetWriter.status), _assetWriter.error.description];
                }
                handler();
            };
            [_assetWriter finishWritingWithCompletionHandler:_handler];
        } else {
            [_assetWriter finishWriting];
        }
    });
    [_lock unlock];
}

- (void)activateAudioTrack
{
    AudioChannelLayout acl;
    bzero(&acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
    NSDictionary* audioOutputSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                         [NSNumber numberWithInt:kAudioFormatMPEG4AAC], AVFormatIDKey,
                                         [NSNumber numberWithInt:2], AVNumberOfChannelsKey,
                                         [NSNumber numberWithFloat:44100], AVSampleRateKey,
                                         [NSData dataWithBytes:&acl length:sizeof(acl)],
                                         AVChannelLayoutKey,
                                         [NSNumber numberWithInt:128000], AVEncoderBitRateKey, nil];
    
    _assetWriterAudioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings];
    [_assetWriter addInput:_assetWriterAudioInput];
    [_assetWriterAudioInput setExpectsMediaDataInRealTime:_encodingLiveVideo];
}

- (void)appendVideoBuffer:(CVPixelBufferRef)renderTarget frameTime:(CMTime)frameTime;
{
    if (_writerStatus != BMWCameraWriterStatusRecording || renderTarget == NULL) {
        return;
    }
    if(CMTIME_IS_INVALID(frameTime)) {
        return;
    }
    
    if (CMTIME_IS_INVALID(_startTime)) {
        
        runSynchronouslyOnContextQueue(_cameraWriterContext, ^{
            if (_assetWriter.status != AVAssetWriterStatusWriting && _assetWriter.status != AVAssetWriterStatusFailed) {
                [_assetWriter startWriting];
            }
            if (_assetWriter.status == AVAssetWriterStatusFailed) {
                self.errorStr = [NSString stringWithFormat:@"%@ - append video buffer fail status:%@, error:%@", self.errorStr, @(_assetWriter.status), _assetWriter.error.description];
            }
            [_assetWriter startSessionAtSourceTime:frameTime];
            
            _startTime = frameTime;
        });
    }
    
    frameTime = [self adjustPresentationTimeV:frameTime];
    CMTime currentTime = CMTimeSubtract(frameTime, _startTime);
    CGFloat recordDuration = CMTimeGetSeconds(currentTime);
    
    runAsynchronouslyOnContextQueue(_cameraWriterContext, ^{
        
        if (_writerStatus == BMWCameraWriterStatusRecording &&
            [[_assetWriterPixelBufferInput assetWriterInput] isReadyForMoreMediaData]) {
            
            BOOL result = [_assetWriterPixelBufferInput appendPixelBuffer:renderTarget withPresentationTime:frameTime];
            _previousEncodeTimeV = CMTimeGetSeconds(frameTime);
            
            if (result == NO) {
                BMWMLog(@"append video buffer error:%@", [_assetWriter error]);
                if (self.errorStr == nil) {
                    self.errorStr = [NSString stringWithFormat:@"%@ - append video buffer  fail, error:%@", self.errorStr, _assetWriter.error.description];
                }
            }
            if (result) {
                SafeBlock(self.recordDurationBlock, recordDuration);
            }
            self.duration = recordDuration;
        }
    });
}

- (void)configMetaData:(NSString*)metaInfo
{
    if (metaInfo.length == 0) {
        return;
    }
    NSMutableArray *metadata = [NSMutableArray array];
    
    if (metaInfo.length > 0) {
        AVMutableMetadataItem *metaItem = [AVMutableMetadataItem metadataItem];
        metaItem.key = AVMetadataCommonKeyDescription;
        metaItem.keySpace = AVMetadataKeySpaceCommon;
        metaItem.value = metaInfo;
        [metadata addObject:metaItem];
    }
    
    AVMutableMetadataItem *metaItem2 = [AVMutableMetadataItem metadataItem];
    metaItem2.keySpace = AVMetadataKeySpaceCommon;
    metaItem2.key = AVMetadataCommonKeyCopyrights;
    metaItem2.value = [NSString stringWithFormat:@"XCAMERA-IPHONE"];
    [metadata addObject:metaItem2];
    _assetWriter.metadata = metadata;
}

- (CMTime)adjustPresentationTimeV:(CMTime)time
{
    CFTimeInterval cur = CMTimeGetSeconds(time);
    CFTimeInterval real = cur - _totalPausedTimeV;
    if (real <= _previousEncodeTimeV) {
        _totalPausedTimeV -= _previousEncodeTimeV - real;
        real = _previousEncodeTimeV + 1.0f / self.encodeProfile.frameRate;
    }
    CMTime newTime = CMTimeMakeWithSeconds(real, time.timescale);
    return newTime;
}

- (CMTime)adjustPresentationTimeA:(CMTime)time
{
    CFTimeInterval cur = CMTimeGetSeconds(time);
    CFTimeInterval real = cur - _totalPausedTimeA;
    if (real <= _previousEncodeTimeA) {
        _totalPausedTimeA -= _previousEncodeTimeA - real;
        real = _previousEncodeTimeA + 0.02;
    }
    CMTime newTime = CMTimeMakeWithSeconds(real, time.timescale);
    return newTime;
}

@end

