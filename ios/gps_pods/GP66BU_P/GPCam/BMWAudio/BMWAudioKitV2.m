#import "BMWAudioKitV2.h"
#import "GPCamDefine.h"
#import "BMWDeviceUtils.h"
#include <mach/mach_time.h>
#import "BMWAudioSessionCenter.h"

static double kHostTickToSeconds = 0.0;

@interface BMWAudioKitV2 ()
{
    void *_operationQueueKey;
}

@property (nonatomic) NSTimer *watchDogTimer;

@property (nonatomic) NSTimeInterval currentTimestamp;

@property (nonatomic, assign) AudioComponent component;

@property (nonatomic, assign) AudioComponentInstance componetInstance;

@property (nonatomic, assign) OSStatus status;

@property (nonatomic, strong) dispatch_queue_t operationQueue;

@property (nonatomic, strong) NSMutableDictionary<NSNumber*, id<BMWAudioKitDelegate>>* delegatesDic;

@end

@implementation BMWAudioKitV2

- (instancetype)init {
        if (self = [super init]) {
        self.currentTimestamp = 0;
        self.componetInstance = NULL;
        self.delegatesDic = [NSMutableDictionary new];
        _operationQueueKey = &_operationQueueKey;
        self.operationQueue = dispatch_queue_create("com.cad.capture.audiov2.operation", 0);
        dispatch_queue_set_specific(self.operationQueue, _operationQueueKey, (__bridge void *_Nullable)(self), NULL);
        mach_timebase_info_data_t tinfo;
        kern_return_t kerror = mach_timebase_info(&tinfo);
        if(kerror == KERN_SUCCESS) {
            kHostTickToSeconds = ((double)tinfo.numer / tinfo.denom) * 1.0e-9;
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            self.watchDogTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                  target:self
                                                                selector:@selector(watchDogRefresh)
                                                                userInfo:nil
                                                                 repeats:YES];
        });

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willResignActiveNotification:)
                                                     name:UIApplicationWillResignActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];

    }
    return self;
}

- (void)dealloc {
    [self runAsyncOnOperationQueue:^{
        [self reset];
        [self.delegatesDic removeAllObjects];
    }];
}

- (void)watchDogRefresh {
//    BMWMLog(@"%s %d", __FUNCTION__, __LINE__);
    [self runAsyncOnOperationQueue: ^{
        if (BMWALifeCycleHelper.sharedInstance.appInBackground) {
            return;
        }

        if ([NSProcessInfo processInfo].systemUptime - self.currentTimestamp > 2.0 &&
            self.delegatesDic.allKeys.count > 0) {
            [self reset];
            [self startAudioCapture];
        }
    }];
}

- (void)willResignActiveNotification:(NSNotification *)notification {
        [self runAsyncOnOperationQueue:^{
        [self stopAudioCapture];
    }];
}

- (void)didBecomeActiveNotification:(NSNotification *)notification {
        [self runAsyncOnOperationQueue:^{
        if (self.delegatesDic.allKeys.count > 0) {
            [self startAudioCapture];
        }
    }];
}

- (void)startAudioCaptureWithDelegate:(id<BMWAudioKitDelegate>)delegate {
    [self runAsyncOnOperationQueue:^{
                if (self.delegatesDic.allKeys.count == 0) {
            [self startAudioCapture];
        }
        NSNumber *key = @((int64_t)delegate);
        self.delegatesDic[key] = delegate;
            }];
}

- (void)stopAudioCaptureWithDelegate:(id<BMWAudioKitDelegate>)delegate {
    [self runAsyncOnOperationQueue:^{
                NSNumber *key = @((int64_t)delegate);
        [self.delegatesDic removeObjectForKey:key];
        if (self.delegatesDic.allKeys.count == 0) {
            [self stopAudioCapture];
        }
            }];
}

- (void)initIfNeeded {
    if (self.componetInstance != NULL) {
        return;
    }

        AudioComponentDescription acDesc;
    acDesc.componentType = kAudioUnitType_Output;
    acDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    acDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    acDesc.componentFlags = 0;
    acDesc.componentFlagsMask = 0;

    self.component = AudioComponentFindNext(NULL, &acDesc);

    OSStatus status = noErr;
    status = AudioComponentInstanceNew(self.component, &_componetInstance);

    if (noErr != status) {
                [self reset];
        return;
    }

    UInt32 flagOne = 1;
    AudioUnitSetProperty(self.componetInstance, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &flagOne, sizeof(flagOne));

    AudioStreamBasicDescription asbd = [self audioStreamDescription];

    AudioUnitSetProperty(self.componetInstance, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &asbd, sizeof(asbd));

    AURenderCallbackStruct cb;
    cb.inputProcRefCon = (__bridge void *) (self);
    cb.inputProc = handleInputBuffer;

    AudioUnitSetProperty(self.componetInstance, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &cb, sizeof(cb));

    status = AudioUnitInitialize(self.componetInstance);

    if (noErr != status) {
                [self reset];
    }
}

- (void)reset {
        if (self.componetInstance) {
        self.status = AudioOutputUnitStop(self.componetInstance);
        if (self.status != noErr) {
                    }
        OSStatus status = AudioUnitUninitialize(self.componetInstance);
        if (self.status != noErr) {
                    }
        status = AudioComponentInstanceDispose(self.componetInstance);
        if (status != noErr) {
                    }
        self.componetInstance = NULL;
    }
}

- (void)startAudioCapture {
        if (BMWALifeCycleHelper.sharedInstance.appInBackground) {
        return;
    }
    [BMWAudioSessionCenter activeAudioSession];
    [self initIfNeeded];
    if (self.componetInstance) {
        OSStatus status = AudioOutputUnitStart(self.componetInstance);
        if (status != noErr) {
                        [self reset];
        } else {
            self.currentTimestamp = [NSProcessInfo processInfo].systemUptime;
                    }
    }
}

- (void)stopAudioCapture {
        if (self.componetInstance) {
        AudioOutputUnitStop(self.componetInstance);
    }
}

- (void)deactiveAudioSession {
    [self runAsyncOnOperationQueue:^{
        [BMWAudioSessionCenter deactiveAudioSession];
    }];
}

static OSStatus handleInputBuffer(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData) {
    @autoreleasepool {
        BMWAudioKitV2 *this = (__bridge BMWAudioKitV2 *)inRefCon;
        AudioStreamBasicDescription audioDescription = [this audioStreamDescription];

        uint64_t hostTime = inTimeStamp->mHostTime;
        if (kHostTickToSeconds == 0.0) {
            mach_timebase_info_data_t tinfo;
            kern_return_t kerror = mach_timebase_info(&tinfo);
            if(kerror == KERN_SUCCESS) {
                kHostTickToSeconds = ((double)tinfo.numer / tinfo.denom) * 1.0e-9;
            }
        }

        CMTime presentationTime;
        if(kHostTickToSeconds > 0.0) {
            presentationTime = CMTimeMakeWithSeconds(hostTime * kHostTickToSeconds, VIDEO_TIMESCALE);
        } else {
            presentationTime = CMTimeMakeWithSeconds(CACurrentMediaTime(), VIDEO_TIMESCALE);
        }

        CMSampleTimingInfo timing = {CMTimeMake(1, audioDescription.mSampleRate), presentationTime, kCMTimeInvalid};

        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0].mData = NULL;
        buffers.mBuffers[0].mDataByteSize = 0;
        buffers.mBuffers[0].mNumberChannels = 1;

        OSStatus status = AudioUnitRender(this.componetInstance, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &buffers);
        if (status != noErr) {
                        return status;
        }

        this.currentTimestamp = [NSProcessInfo processInfo].systemUptime;

        BMWAudioFrame *audioFrame = [BMWAudioFrame new];
        audioFrame.pcmData = [NSData dataWithBytes:buffers.mBuffers[0].mData
                                            length:buffers.mBuffers[0].mDataByteSize];
        audioFrame.sampleRate = audioDescription.mSampleRate;
        audioFrame.channels = audioDescription.mChannelsPerFrame;
        audioFrame.presentationTimestamp = presentationTime;

        [this processAudioFrame:audioFrame];

        return status;
    }
}

- (void)processAudioFrame:(BMWAudioFrame *)audioFrame {
    [self runAsyncOnOperationQueue:^{
        for (id<BMWAudioKitDelegate> delegate in self.delegatesDic.allValues) {
            if ([delegate respondsToSelector:@selector(processAudioFrame:)]) {
                [delegate processAudioFrame:audioFrame];
            }
       }
    }];
}

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer {
    BMWAudioFrame *frame = [BMWAudioFrame audioFrameFromSampleBuffer:audioBuffer];
    [self processAudioFrame:frame];
}

- (BOOL)useBluetoothA2DP {
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortBluetoothA2DP]
            || [[desc portType] isEqualToString:AVAudioSessionPortBluetoothHFP]
            || [[desc portType] isEqualToString:AVAudioSessionPortBluetoothLE])
            return YES;
    }
    return NO;
}

- (void)runSyncOnOperationQueue:(dispatch_block_t)block {
    if (dispatch_get_specific(_operationQueueKey)) {
        block();
    } else {
        dispatch_sync(_operationQueue, block);
    }
}

- (void)runAsyncOnOperationQueue:(dispatch_block_t)block {
    if (dispatch_get_specific(_operationQueueKey)) {
        block();
    } else {
        dispatch_async(_operationQueue, block);
    }
}

- (AudioStreamBasicDescription)audioStreamDescription {
    AudioStreamBasicDescription desc = {0};
    desc.mSampleRate = kXHAudioStreamDescription_SampleRate;
    desc.mFormatID = kXHAudioStreamDescription_FormatID;
    desc.mFormatFlags = kXHAudioStreamDescription_FormatFlags;
    desc.mChannelsPerFrame = kXHAudioStreamDescription_ChannelsPerFrame;
    desc.mFramesPerPacket = kXHAudioStreamDescription_FramesPerPacket;
    desc.mBitsPerChannel = kXHAudioStreamDescription_BitsPerChannel;
    desc.mBytesPerFrame = kXHAudioStreamDescription_BytesPerFrame;
    desc.mBytesPerPacket = kXHAudioStreamDescription_BytesPerPacket;
    return desc;
}

@end
