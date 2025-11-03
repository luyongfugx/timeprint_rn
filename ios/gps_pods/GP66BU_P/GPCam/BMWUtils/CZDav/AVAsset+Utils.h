#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AVAsset (Utils)

+ (BOOL)xhm_isOptimizeForNetworkUse:(NSString*)path;

- (float)videoDuration;

- (void)videoDurationSync:(void (^)(float duration, NSError* error))result;

- (void)videoDuration:(void (^)(float duration, NSError* error))result;

/*
 @{@"duraiton" : @(duration),
    @"videoSize" : @(videoSize), // 根据rotation校准后的w/h
    @"rotation" : @(rotation),
    @"frameRate" : @(frameRate),
    @"bitrate" : @(bitrate)}
 */
- (NSDictionary *)getVideoInfo;

- (NSString*)getUserComment;

/*
 @{@"andriod" : @(1),
    @"description" : "userCommnet",
    @"date" : NSDate,
    @"location" : CLLocation}
 */
- (NSDictionary*)getVideoMetadata;

- (void)getPreviewImageAtTime:(NSTimeInterval)atTime preferredSize:(CGSize)size compeletion:(void (^)(UIImage *image, NSTimeInterval atTime))compeletion;

@end

NS_ASSUME_NONNULL_END
