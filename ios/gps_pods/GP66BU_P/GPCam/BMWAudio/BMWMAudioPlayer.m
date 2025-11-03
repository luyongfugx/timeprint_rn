#import "BMWMAudioPlayer.h"

@interface BMWMAudioPlayer () <AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, assign) BOOL isPlaying;

@end

@implementation BMWMAudioPlayer

#pragma mark - Initialization

- (instancetype)initWithFilePath:(NSString *)filePath {
    self = [super init];
    if (self) {
        NSError *error = nil;
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:filePath] error:&error];
        
        if (error) {
            if ([self.delegate respondsToSelector:@selector(audioPlayerEncounteredError:)]) {
                [self.delegate audioPlayerEncounteredError:error];
            }
            return nil;
        }
        
        [self setupAudioPlayer];
    }
    return self;
}

- (void)setupAudioPlayer {
    _audioPlayer.delegate = self;
    _audioPlayer.volume = 1.0;
    [self prepareToPlay];
}

#pragma mark - Public Methods

- (void)play {
    if (!_isPlaying) {
        BOOL success = [_audioPlayer play];
        if (success) {
            _isPlaying = YES;
            if ([self.delegate respondsToSelector:@selector(audioPlayerDidChangePlayingStatus:)]) {
                [self.delegate audioPlayerDidChangePlayingStatus:YES];
            }
        }
    }
}

- (void)pause {
    if (_isPlaying) {
        [_audioPlayer pause];
        _isPlaying = NO;
        if ([self.delegate respondsToSelector:@selector(audioPlayerDidChangePlayingStatus:)]) {
            [self.delegate audioPlayerDidChangePlayingStatus:NO];
        }
    }
}

- (void)stop {
    if (_audioPlayer) {
        [_audioPlayer stop];
        _audioPlayer.currentTime = 0;
        _isPlaying = NO;
        if ([self.delegate respondsToSelector:@selector(audioPlayerDidChangePlayingStatus:)]) {
            [self.delegate audioPlayerDidChangePlayingStatus:NO];
        }
    }
}

- (void)seekToTime:(NSTimeInterval)time {
    if (_audioPlayer) {
        _audioPlayer.currentTime = time;
    }
}

- (BOOL)prepareToPlay {
    return [_audioPlayer prepareToPlay];
}

- (float)getCurrentPlayProgress {
    if (_audioPlayer.duration > 0) {
        return _audioPlayer.currentTime / _audioPlayer.duration;
    }
    return 0.0f;
}

#pragma mark - Properties

- (NSTimeInterval)duration {
    return _audioPlayer.duration;
}

- (NSTimeInterval)currentTime {
    return _audioPlayer.currentTime;
}

- (void)setVolume:(float)volume {
    _audioPlayer.volume = volume;
}

- (float)volume {
    return _audioPlayer.volume;
}

#pragma mark - AVAudioPlayerDelegate

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    _isPlaying = NO;
    if ([self.delegate respondsToSelector:@selector(audioPlayerDidFinishPlaying)]) {
        [self.delegate audioPlayerDidFinishPlaying];
    }
    if ([self.delegate respondsToSelector:@selector(audioPlayerDidChangePlayingStatus:)]) {
        [self.delegate audioPlayerDidChangePlayingStatus:NO];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    _isPlaying = NO;
    if ([self.delegate respondsToSelector:@selector(audioPlayerEncounteredError:)]) {
        [self.delegate audioPlayerEncounteredError:error];
    }
}

@end
