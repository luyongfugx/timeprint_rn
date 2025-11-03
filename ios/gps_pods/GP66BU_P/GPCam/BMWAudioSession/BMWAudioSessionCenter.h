#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BAAudioSessionMode) {
    BAAudioSessionModeIdle = 0,
    BAAudioSessionModePlayRecord = 1
};

NS_ASSUME_NONNULL_BEGIN

@interface BMWAudioSessionCenter : NSObject

+ (BMWAudioSessionCenter*)sharedInstance;

- (void)setAudioSessionMode:(BAAudioSessionMode)mode identifier:(id)identifier;

- (void)setAudioSessionModeSync:(BAAudioSessionMode)mode identifier:(id)identifier;

- (void)setAudioSessionModeRealSync:(BAAudioSessionMode)mode identifier:(id)identifier;

- (void)setLockSleep:(BOOL)lockSleep identifier:(id)identifier;

+ (void)activeAudioSession;

+ (void)deactiveAudioSession;

@end

NS_ASSUME_NONNULL_END
