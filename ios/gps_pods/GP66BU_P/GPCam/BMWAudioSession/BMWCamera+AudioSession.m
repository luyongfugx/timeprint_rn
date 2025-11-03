#import "BMWCamera+AudioSession.h"
#import <objc/runtime.h>
#import "BMWAudioSessionCenter.h"

#define UseAVPlayer 0
// 按需切换AudioSession
#define UseZFAVPlayerNormal 0
// 只要有播放器启动了播放，就把AudioSession切换到PlayRecord,不再切换回来，保证关键播放的流畅
#define UseZFAVPlayerForce 1

@implementation BMWCamera (AudioSession)

+ (void)load
{
    Method originalMethod = class_getInstanceMethod(self, @selector(changeFilter:));
    Method newMethod = class_getInstanceMethod(self, @selector(as_changeFilter:));
    method_exchangeImplementations(originalMethod, newMethod);
    
    originalMethod = class_getInstanceMethod(self, @selector(startCapture));
    newMethod = class_getInstanceMethod(self, @selector(as_startCapture));
    method_exchangeImplementations(originalMethod, newMethod);
    
    originalMethod = class_getInstanceMethod(self, @selector(stopCapture));
    newMethod = class_getInstanceMethod(self, @selector(as_stopCapture));
    method_exchangeImplementations(originalMethod, newMethod);
}

- (void)as_changeFilter:(BMWCameraMode)mode
{
    // 摄像头预览时，在视频模式下启用PlayRecord
    if (mode == BMWCameraModeVideoFront || mode == BMWCameraModeVideoBack || mode == BMWCameraModeVideoFrontMirror) {
        [[BMWAudioSessionCenter sharedInstance] setAudioSessionMode:BAAudioSessionModePlayRecord identifier:self];
    }
    [self as_changeFilter:mode];
}

- (void)as_startCapture
{
    // 摄像头预览时，在视频模式下启用PlayRecord
    if (self.filterMode == BMWCameraModeVideoFront || self.filterMode == BMWCameraModeVideoBack) {
        [[BMWAudioSessionCenter sharedInstance] setAudioSessionMode:BAAudioSessionModePlayRecord identifier:self];
    }
    [self as_startCapture];
}

- (void)as_stopCapture
{
    // 停止预览时启用Idle
    [[BMWAudioSessionCenter sharedInstance] setAudioSessionModeSync:BAAudioSessionModeIdle identifier:self];
    [self as_stopCapture];
}

@end

#if UseAVPlayer

@interface AVPlayer(AudioSession)

@end

@implementation AVPlayer (AudioSession)

+ (void)load
{

    Method originalMethod = class_getInstanceMethod(self, @selector(play));
    Method newMethod = class_getInstanceMethod(self, @selector(as_play));
    method_exchangeImplementations(originalMethod, newMethod);
    
    originalMethod = class_getInstanceMethod(self, @selector(pause));
    newMethod = class_getInstanceMethod(self, @selector(as_pause));
    method_exchangeImplementations(originalMethod, newMethod);
    
    originalMethod = class_getInstanceMethod(self, @selector(stop));
    newMethod = class_getInstanceMethod(self, @selector(as_stop));
    method_exchangeImplementations(originalMethod, newMethod);
    
    originalMethod = class_getInstanceMethod(self, NSSelectorFromString(@"playerItemDidReachEnd:"));
    newMethod = class_getInstanceMethod(self, NSSelectorFromString(@"as_playerItemDidReachEnd:"));
    method_exchangeImplementations(originalMethod, newMethod);
}

- (void)as_play
{
    [[BMWAudioSessionCenter sharedInstance] setAudioSessionMode:BAAudioSessionModePlayRecord identifier:self];
    [self as_play];
}

- (void)as_stop
{
    [self as_stop];
    [[BMWAudioSessionCenter sharedInstance] setAudioSessionMode:BAAudioSessionModeIdle identifier:self];
}

- (void)as_pause
{
    [self as_pause];
    [[BMWAudioSessionCenter sharedInstance] setAudioSessionMode:BAAudioSessionModeIdle identifier:self];
}

- (void)as_playerItemDidReachEnd:(NSNotification *)notification
{
    [self as_playerItemDidReachEnd:notification];
}

@end
#endif

#if UseZFAVPlayerNormal

@interface BMWAudioSessionCenter (ZFAVPlayer)

@end

@implementation BMWAudioSessionCenter (ZFAVPlayer)

+ (void)load
{
    Method originalMethod;
    Method newMethod;
    
    Class c1 = objc_getClass("ZFAVPlayerManager");
    originalMethod = class_getInstanceMethod(c1, NSSelectorFromString(@"play"));
    class_addMethod(c1, NSSelectorFromString(@"as_play"), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    newMethod = class_getInstanceMethod(self, @selector(as_play));
    method_exchangeImplementations(originalMethod, newMethod);
    
    originalMethod = class_getInstanceMethod(c1, NSSelectorFromString(@"pause"));
    class_addMethod(c1, NSSelectorFromString(@"as_pause"), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    newMethod = class_getInstanceMethod(self, @selector(as_pause));
    method_exchangeImplementations(originalMethod, newMethod);
    
    originalMethod = class_getInstanceMethod(c1, NSSelectorFromString(@"stop"));
    class_addMethod(c1, NSSelectorFromString(@"as_stop"), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    newMethod = class_getInstanceMethod(self, @selector(as_stop));
    method_exchangeImplementations(originalMethod, newMethod);
    
    originalMethod = class_getInstanceMethod(c1, NSSelectorFromString(@"setPlayerDidToEnd:"));
    class_addMethod(c1, NSSelectorFromString(@"as_setPlayerDidToEnd:"), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    newMethod = class_getInstanceMethod([self class], NSSelectorFromString(@"as_setPlayerDidToEnd:"));
    method_exchangeImplementations(originalMethod, newMethod);
}

- (void)as_play
{
    [[BMWAudioSessionCenter sharedInstance] setAudioSessionModeSync:BAAudioSessionModePlayRecord identifier:self];
    [self as_play];
}

- (void)as_stop
{
    [self as_stop];
    [[BMWAudioSessionCenter sharedInstance] setAudioSessionMode:BAAudioSessionModeIdle identifier:self];
}

- (void)as_pause
{
    [self as_pause];
    [[BMWAudioSessionCenter sharedInstance] setAudioSessionMode:BAAudioSessionModeIdle identifier:self];
}

- (void)as_playerItemDidReachEnd:(NSNotification *)notification
{
    [self as_playerItemDidReachEnd:notification];
}

- (void)as_setPlayerDidToEnd:(void (^)(id))playerDidToEnd
{
    NSNumber *this = @((int64_t)self);
    void(^_handler)(id) = ^(id x) {
        playerDidToEnd(x);
        [[BMWAudioSessionCenter sharedInstance] setAudioSessionMode:BAAudioSessionModeIdle identifier:this];
    };
    [self as_setPlayerDidToEnd:_handler];
}

@end
#endif

#if UseZFAVPlayerForce

@interface BMWAudioSessionCenter (ZFAVPlayer)

@end

@implementation BMWAudioSessionCenter (ZFAVPlayer)

+ (void)load
{
    Method originalMethod;
    Method newMethod;
    Class c1 = objc_getClass("ZFAVPlayerManager");
    originalMethod = class_getInstanceMethod(c1, NSSelectorFromString(@"play"));
    class_addMethod(c1, NSSelectorFromString(@"as_play"), method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    newMethod = class_getInstanceMethod(self, @selector(as_play));
    method_exchangeImplementations(originalMethod, newMethod);
}

- (void)as_play
{
    [BMWAudioSessionCenter activeAudioSession];
    [self as_play];
}
@end

#endif
