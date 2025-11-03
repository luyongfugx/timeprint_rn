#import "BMWAudioKit.h"
#import "GPCamDefine.h"
#import "BMWDeviceUtils.h"
#include <mach/mach_time.h>
#import "BMWAudioSessionCenter.h"
#import "BMWAudioKitV2.h"

static double HOST_TICK_TO_SECONDS = 0.0;

@interface BMWAudioKit ()
{
    void *_operationQueueKey;
}
@property (nonatomic) BOOL isCaptureStarted;
@property (nonatomic) NSTimer *watchDogTimer;
@property (nonatomic) NSTimeInterval currentTimestamp;

@property (nonatomic, assign) AudioComponent component;

@property (nonatomic, assign) AudioComponentInstance componetInstance;

@property (nonatomic, assign) OSStatus status;

@property (nonatomic, strong) dispatch_queue_t operationQueue;

@property (nonatomic, strong) NSMutableDictionary<NSNumber*, id<BMWAudioKitDelegate>>* delegatesDic;

@property (nonatomic, strong) NSRecursiveLock* delegatesLock;

@end

@implementation BMWAudioKit

+ (BMWAudioKit*)sharedInstance
{
    static BMWAudioKit* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            if (GPCamConfigurator.sharedInstance.enableAudioKitV2) {
                instance = [[BMWAudioKitV2 alloc] init];
            } else {
                instance = [[BMWAudioKit alloc] init];
            }
        }
    });
    return instance;
}

- (void)dealloc
{
    [self runSyncOnOperationQueue:^{
        [self reset];
        [self removeAllDelegates];
    }];
}

- (void)reset
{
    if (self.componetInstance) {
        self.status = AudioOutputUnitStop(self.componetInstance);
        AudioComponentInstanceDispose(self.componetInstance);
        self.componetInstance = NULL;
    }
}

- (instancetype)init
{
    self = [super init];
        if (self) {
        self.delegatesLock = [[NSRecursiveLock alloc] init];
        self.isCaptureStarted = NO;
        self.currentTimestamp = 0;
        self.componetInstance = NULL;
        self.delegatesDic = [NSMutableDictionary new];
        _operationQueueKey = &_operationQueueKey;
        self.operationQueue = dispatch_queue_create("com.CAD.capture.audio.operation", 0);
        dispatch_queue_set_specific(self.operationQueue, _operationQueueKey, (__bridge void *_Nullable)(self), NULL);
        mach_timebase_info_data_t tinfo;
        kern_return_t kerror = mach_timebase_info(&tinfo);
        if(kerror == KERN_SUCCESS) {
            HOST_TICK_TO_SECONDS = ((double)tinfo.numer / tinfo.denom) * 1.0e-9;
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)willResignActiveNotification:(NSNotification *)notification {
    [self runAsyncOnOperationQueue:^{
        [self stopAudioCapture];
    }];
}

- (void)didBecomeActiveNotification:(NSNotification *)notification {
    [self runAsyncOnOperationQueue:^{
        BOOL shouldStart = NO;
        {
            [self.delegatesLock lock];
            shouldStart = self.delegatesDic.allKeys.count > 0;
            [self.delegatesLock unlock];
        }
        if (shouldStart) {
            [self stopAudioCapture];
            [self startAudioCapture];
        }
    }];
}

- (void)initMicrophoneSource
{
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
            }
}

- (void)watchDogRefresh
{
    [self runAsyncOnOperationQueue: ^{
        if (!self.isCaptureStarted) {
            return;
        }
        if ([NSProcessInfo processInfo].systemUptime - self.currentTimestamp > 2.0) {
            [self stopAudioCapture];
            [self startAudioCapture];
        }
    }];
}

- (AudioStreamBasicDescription)audioStreamDescription
{
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

- (void)startAudioCaptureWithDelegate:(id<BMWAudioKitDelegate>)delegate
{
    [self runAsyncOnOperationQueue:^{
                if(![self addDelegate:delegate]) return;
        if(self.isCaptureStarted == YES) return;
        [BMWAudioSessionCenter activeAudioSession];
        [self startAudioCapture];
        if (self.status == noErr) {
            self.isCaptureStarted = YES;
        }
            }];
}

- (void)stopAudioCaptureWithDelegate:(id<BMWAudioKitDelegate>)delegate
{
    [self runAsyncOnOperationQueue:^{
                if(self.isCaptureStarted == NO) return;
        if ([self removeDelegate:delegate]) return;
        [self stopAudioCapture];
        self.isCaptureStarted = NO;
            }];
}

- (void)startAudioCapture
{
        if(self.componetInstance != NULL) return;
    [self initMicrophoneSource];
    OSStatus status = AudioOutputUnitStart(self.componetInstance);
    self.status = status;
    if (status == noErr) {
        self.isCaptureStarted = YES;
        self.currentTimestamp = [NSProcessInfo processInfo].systemUptime;
        if (self.watchDogTimer == nil) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.watchDogTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(watchDogRefresh) userInfo:nil repeats:YES];
            });
        }
    } else {
        [self stopAudioCapture];
    }
    }

- (void)stopAudioCapture
{
        self.isCaptureStarted = NO;
    [self reset];
    if (self.watchDogTimer) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.watchDogTimer invalidate];
            self.watchDogTimer = nil;
        });
    }
    }

- (void)deactiveAudioSession
{
    [self runAsyncOnOperationQueue:^{
        [BMWAudioSessionCenter deactiveAudioSession];
    }];
}

- (void)activeAudioSession
{
    [self runAsyncOnOperationQueue:^{
        [BMWAudioSessionCenter activeAudioSession];
    }];
}

#pragma mark - Private

static OSStatus handleInputBuffer(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags, const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber, UInt32 inNumberFrames, AudioBufferList *ioData)
{
    @autoreleasepool {

        BMWAudioKit *this = (__bridge BMWAudioKit *)inRefCon;
        AudioStreamBasicDescription audioDescription = [this audioStreamDescription];
        CMSampleBufferRef sampleBuffer = NULL;
        CMFormatDescriptionRef format = NULL;

        OSStatus status = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &audioDescription, 0, NULL, 0, NULL, NULL, &format);
        if (status) {
            return status;
        }

        uint64_t hostTime = inTimeStamp->mHostTime;
        if (HOST_TICK_TO_SECONDS == 0.0) {
            mach_timebase_info_data_t tinfo;
            kern_return_t kerror = mach_timebase_info(&tinfo);
            if(kerror == KERN_SUCCESS) {
                HOST_TICK_TO_SECONDS = ((double)tinfo.numer / tinfo.denom) * 1.0e-9;
            }
        }
        CMTime presentationTime;
        if(HOST_TICK_TO_SECONDS > 0.0) {
            presentationTime = CMTimeMakeWithSeconds(hostTime * HOST_TICK_TO_SECONDS, VIDEO_TIMESCALE);
        } else {
            presentationTime = CMTimeMakeWithSeconds(CACurrentMediaTime(), VIDEO_TIMESCALE);
        }
        CMSampleTimingInfo timing = {CMTimeMake(1, audioDescription.mSampleRate), presentationTime, kCMTimeInvalid};
        size_t sampleSize = audioDescription.mBytesPerFrame;
        status = CMSampleBufferCreate(kCFAllocatorDefault, NULL, false, NULL, NULL, format, (CMItemCount)inNumberFrames, 1, &timing, 1, &sampleSize, &sampleBuffer);
        CFRelease(format);

        if (status) {
            return status;
        }

        AudioBuffer buffer;
        buffer.mData = NULL;
        buffer.mDataByteSize = 0;
        buffer.mNumberChannels = 2;

        AudioBufferList buffers;
        buffers.mNumberBuffers = 1;
        buffers.mBuffers[0] = buffer;

        status = AudioUnitRender(this.componetInstance, ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, &buffers);
        if (status) {
            return status;
        }

        status = CMSampleBufferSetDataBufferFromAudioBufferList(sampleBuffer, kCFAllocatorDefault, kCFAllocatorDefault, 0, &buffers);

        if (!status) {
            this.currentTimestamp = [NSProcessInfo processInfo].systemUptime;
            [this processAudioBuffer:sampleBuffer];
        }
        CFRelease(sampleBuffer);
        return status;
    }
}

- (BOOL)useBluetoothA2DP
{
    AVAudioSessionRouteDescription* route = [[AVAudioSession sharedInstance] currentRoute];
    for (AVAudioSessionPortDescription* desc in [route outputs]) {
        if ([[desc portType] isEqualToString:AVAudioSessionPortBluetoothA2DP]
            || [[desc portType] isEqualToString:AVAudioSessionPortBluetoothHFP]
            || [[desc portType] isEqualToString:AVAudioSessionPortBluetoothLE])
            return YES;
    }
    return NO;
}

- (void)runSyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block
{
    if (dispatch_get_specific(_operationQueueKey)) {
        block();
    } else {
        dispatch_sync(_operationQueue, block);
    }
}

- (void)runAsyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block
{
    if (dispatch_get_specific(_operationQueueKey)) {
        block();
    } else {
        dispatch_async(_operationQueue, block);
    }
}

- (BOOL)addDelegate:(id<BMWAudioKitDelegate>)delegate
{
    [self.delegatesLock lock];
    NSNumber *key = @((int64_t)delegate);
    if (!self.delegatesDic[key]) {
        self.delegatesDic[key] = delegate;
    }
    NSUInteger count = self.delegatesDic.allKeys.count;
    [self.delegatesLock unlock];
    return count > 0;
}

- (BOOL)removeDelegate:(id<BMWAudioKitDelegate>)delegate
{
    [self.delegatesLock lock];
    NSNumber *key = @((int64_t)delegate);
    [self.delegatesDic removeObjectForKey:key];
    NSUInteger count = self.delegatesDic.allKeys.count;
    [self.delegatesLock unlock];
    return count > 0;
}

- (void)removeAllDelegates
{
    [self.delegatesLock lock];
    [self.delegatesDic removeAllObjects];
    [self.delegatesLock unlock];
}

- (void)processAudioBuffer:(CMSampleBufferRef)sampleBuffer
{
    [self.delegatesLock lock];
    for (id<BMWAudioKitDelegate> l in self.delegatesDic.allValues) {
        if([l respondsToSelector:@selector(processAudioBuffer:)]) {
            [l processAudioBuffer:sampleBuffer];
        }
    }
    [self.delegatesLock unlock];
}

@end
