#import "BMWAudioSessionCenter.h"
#import <AVFoundation/AVFoundation.h>
#import <objc/runtime.h>
#import "BMWALifeCycleHelper.h"

@interface BMWAudioSessionCenter ()
{
    dispatch_queue_t _operationQueue;
    void *_operationQueueKey;
}

@property(nonatomic, strong) CADisplayLink *timer;

@property (nonatomic, assign) BAAudioSessionMode mode;

@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSNumber*> *lockSleepDic;

@property (nonatomic, strong) NSMutableDictionary<NSNumber*, NSNumber*> *sessionModeDic;

@end

@implementation BMWAudioSessionCenter

+ (void)load
{
    [[BMWAudioSessionCenter sharedInstance] setAudioSessionMode:BAAudioSessionModeIdle];
}

+ (BMWAudioSessionCenter*)sharedInstance
{
    static BMWAudioSessionCenter* manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!manager && !BMWALifeCycleHelper.sharedInstance.launchedPassively) {
            manager = [[BMWAudioSessionCenter alloc] init];
        }
    });
    return manager;
}

- (void)dealloc
{
    [self removeObservers];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _operationQueueKey = &_operationQueueKey;
        _operationQueue = dispatch_queue_create("BMWAudioSessionCenter-Operation", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(_operationQueue, _operationQueueKey, (__bridge void *) (self), NULL);
        self.sessionModeDic = [NSMutableDictionary new];
        self.lockSleepDic = [NSMutableDictionary new];
        [self startTimer];
        [self addObservers];
    }
    return self;
}

- (void)setAudioSessionModeRealSync:(BAAudioSessionMode)mode identifier:(id)identifier;
{
    NSNumber *this = @((int64_t)identifier);
    [self runSyncInOperationQueue:^{
        self.sessionModeDic[this] = @(mode);
        if (self.mode == mode) {
            return;
        }
        [self _setAudioSessionMode:mode];
        self.mode = mode;
    }];
}

- (void)setAudioSessionModeSync:(BAAudioSessionMode)mode identifier:(id)identifier;
{
    NSNumber *this = @((int64_t)identifier);
    [self runAsyncInOperationQueue:^{
        self.sessionModeDic[this] = @(mode);
        if (self.mode == mode) {
            return;
        }
        [self _setAudioSessionMode:mode];
        self.mode = mode;
    }];
}

- (void)setAudioSessionMode:(BAAudioSessionMode)mode identifier:(id)identifier;
{
    NSNumber *this = @((int64_t)identifier);
    [self runAsyncInOperationQueue:^{
        self.sessionModeDic[this] = @(mode);
    }];
}

- (void)setLockSleep:(BOOL)lockSleep identifier:(id)identifier;
{
    NSNumber *this = @((int64_t)identifier);
    [self runAsyncInOperationQueue:^{
        self.lockSleepDic[this] = @(lockSleep);
    }];
}

- (void)setAudioSessionMode:(BAAudioSessionMode)mode
{
    [self runAsyncInOperationQueue:^{

        if (self.mode == mode) {
            return;
        }
        [self _setAudioSessionMode:mode];
        self.mode = mode;
    }];
}

- (void)_setAudioSessionMode:(BAAudioSessionMode)mode
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    if (mode == BAAudioSessionModeIdle) {
        [self.class deactiveAudioSession];
    }
    // 先不实现BAAudioSessionModePlay
    else if(mode == BAAudioSessionModePlayRecord) {
        [self.class activeAudioSession];
    }
}

- (void)stopTimer
{
    if (self.timer != nil) {
        [self.timer setPaused:YES];
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)startTimer
{
    if (self.timer == nil || [self.timer isPaused]) {
        self.timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkCallback:)];
        [self.timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        if (@available(iOS 10.0, *)) {
            self.timer.preferredFramesPerSecond = 1;
        } else {
            self.timer.frameInterval = 60;
        }
#pragma clang diagnostic pop
    }
}

- (void)displayLinkCallback:(CADisplayLink *)sender
{
    [self runAsyncInOperationQueue:^{
        __block BOOL idle = YES;
        [self.sessionModeDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
            if (obj.integerValue != BAAudioSessionModeIdle) {
                idle = NO;
                *stop = YES;
            }
        }];
        if (idle) {
            [self setAudioSessionMode:BAAudioSessionModeIdle];
        } else {
            [self setAudioSessionMode:BAAudioSessionModePlayRecord];
        }
    }];
}

- (void)addObservers
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)removeObservers
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];
}

- (void)didEnterBackgroundNotification:(NSNotification*)notification
{
    [self stopTimer];
    __block BOOL lockSleep = NO;
    [self.lockSleepDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.integerValue == YES) {
            lockSleep = YES;
            *stop = YES;
        }
    }];
    if (!lockSleep) {
        self.mode = BAAudioSessionModeIdle;
        [self _setAudioSessionMode:BAAudioSessionModeIdle];
    }
    // clear
    NSMutableDictionary *tmp = [NSMutableDictionary new];
    [self.lockSleepDic enumerateKeysAndObjectsUsingBlock:^(NSNumber * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        if (obj.integerValue == YES) {
            tmp[key] = obj;
        }
    }];
    self.lockSleepDic = tmp;
}

- (void)willEnterForegroundNotification:(NSNotification*)notification
{
    [self startTimer];
}

- (void)runSyncInOperationQueue:(dispatch_block_t)block
{
    if (dispatch_get_specific(_operationQueueKey)) {
        block();
    } else {
        dispatch_sync(_operationQueue, block);
    }
}

- (void)runAsyncInOperationQueue:(dispatch_block_t)block
{
    dispatch_async(_operationQueue, block);
}

+ (void)activeAudioSession
{
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    if(!([audioSession.category isEqualToString:AVAudioSessionCategoryPlayAndRecord] && (audioSession.categoryOptions & AVAudioSessionCategoryOptionDefaultToSpeaker) && (audioSession.categoryOptions & AVAudioSessionCategoryOptionAllowBluetooth))) {
        [audioSession setPreferredSampleRate:44100 error:&error];
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                      withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth
                            error:&error];
        [audioSession setActive:YES error:&error];
            }
}

+ (void)deactiveAudioSession
{
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error = nil;
    if (![audioSession.category isEqualToString:AVAudioSessionCategorySoloAmbient]) {
        [audioSession setCategory:AVAudioSessionCategorySoloAmbient error:&error];
        [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
            }
}

@end
