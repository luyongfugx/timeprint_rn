#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
NS_ASSUME_NONNULL_BEGIN
@protocol BMWMAudioPlayerDelegate <NSObject>
@optional
- (void)audioPlayerDidFinishPlaying;
- (void)audioPlayerEncounteredError:(NSError *)error;
- (void)audioPlayerDidChangePlayingStatus:(BOOL)isPlaying;
@end

@interface BMWMAudioPlayer : NSObject

@property (nonatomic, weak) id<BMWMAudioPlayerDelegate> delegate;
@property (nonatomic, readonly) BOOL isPlaying;
@property (nonatomic, readonly) NSTimeInterval duration;
@property (nonatomic, readonly) NSTimeInterval currentTime;
@property (nonatomic) float volume;  // 音量范围 0.0 - 1.0

// 初始化方法
- (instancetype)initWithFilePath:(NSString *)filePath;

// 控制方法
- (void)play;
- (void)pause;
- (void)stop;
- (void)seekToTime:(NSTimeInterval)time;

// 播放状态
- (BOOL)prepareToPlay;
- (float)getCurrentPlayProgress;

@end

NS_ASSUME_NONNULL_END
