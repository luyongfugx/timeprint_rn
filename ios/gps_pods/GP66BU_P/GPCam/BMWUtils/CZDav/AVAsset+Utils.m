#import "AVAsset+Utils.h"
#import <CoreLocation/CLLocation.h>

static const int DESC = 0x64657363;
static const int XYZ = 0xA978797A;
static const int MOOV = 0x766F6F6D; // voom
static NSString* COMMON_META_KEY = @"commonMetadata";
static NSString* AVAILABLE_META_KEY = @"availableMetadataFormats";

@implementation AVAsset (Utils)

- (float)videoDuration
{
    __block float duration = 0.0;
    __block NSError* error = nil;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [self loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
        AVKeyValueStatus status;
        status = [self statusOfValueForKey:@"duration" error:&error];
        if (status == AVKeyValueStatusLoaded) {
            duration = CMTimeGetSeconds(self.duration);
        }
        dispatch_group_leave(group);
    }];
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    return duration;
}

- (void)videoDuration:(void (^)(float duration, NSError* error))result
{
    __block float duration = 0.0;
    __block NSError* error = nil;
    [self loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
        AVKeyValueStatus status;
        status = [self statusOfValueForKey:@"duration" error:&error];
        if (status == AVKeyValueStatusLoaded) {
            duration = CMTimeGetSeconds(self.duration);
        }
        !result ? : result(duration, error);
    }];
}

- (void)videoDurationSync:(void (^)(float duration, NSError* error))result
{
    __block float duration = 0.0;
    __block NSError* error = nil;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [self loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
        AVKeyValueStatus status;
        status = [self statusOfValueForKey:@"duration" error:&error];
        if (status == AVKeyValueStatusLoaded) {
            duration = CMTimeGetSeconds(self.duration);
        }
        dispatch_group_leave(group);
    }];
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    !result ? : result(duration, error);
}

- (NSDictionary *)getVideoInfo
{
    __block float duration = 0.0;
    __block CGSize videoSize = CGSizeZero;
    __block float frameRate = 0;
    __block float bitrate = 0;
    __block float rotation = 0;
    __block NSError* error = nil;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    [self loadValuesAsynchronouslyForKeys:@[@"duration", @"tracks"] completionHandler:^{
        AVKeyValueStatus status;
        status = [self statusOfValueForKey:@"duration" error:&error];
        if (status == AVKeyValueStatusLoaded) {
            duration = CMTimeGetSeconds(self.duration);
        }
        status = [self statusOfValueForKey:@"tracks" error:&error];
        if (status == AVKeyValueStatusLoaded) {
            NSArray *videoTracks = [self tracksWithMediaType:AVMediaTypeVideo];
            AVAssetTrack *videoTrack = nil;
            if ([videoTracks count] > 0) {
                videoTrack = [videoTracks objectAtIndex:0];
            }
            videoSize = [videoTrack naturalSize];
            frameRate = [videoTrack nominalFrameRate];
            bitrate = [videoTrack estimatedDataRate];
        
            CGAffineTransform transform = videoTrack.preferredTransform;
            rotation = atan2(transform.b, transform.a) * 180 / M_PI;
            if (rotation == 90 || rotation == 270 || rotation == -90) {
                CGFloat w = videoSize.width;
                CGFloat h = videoSize.height;
                videoSize = CGSizeMake(h, w);
            }
        }
        dispatch_group_leave(group);
    }];
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    
    return error ? nil : @{
        @"duraiton" : @(duration),
        @"videoSize" : @(videoSize),
        @"rotation" : @(rotation),
        @"frameRate" : @(frameRate),
        @"bitrate" : @(bitrate)
    };
}

- (NSString*)getUserComment
{
    NSDictionary *dic = [self getVideoMetadata];
    NSString* comment = dic[@"description"];
    return comment;
}

- (NSDictionary*)getVideoMetadata
{
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    NSMutableDictionary <NSString*, id> *dic = [NSMutableDictionary new];
    dic[@"date"] = self.creationDate.dateValue;
    [self loadValuesAsynchronouslyForKeys:@[COMMON_META_KEY, AVAILABLE_META_KEY] completionHandler:^{
        AVKeyValueStatus formatsStatus =
        [self statusOfValueForKey:AVAILABLE_META_KEY error:nil];
        
        if (formatsStatus == AVKeyValueStatusLoaded) {
            NSArray *acceptedFormats = @[
                AVMetadataFormatQuickTimeMetadata,
                AVMetadataFormatiTunesMetadata,
            ];
            for (NSString *format in self.availableMetadataFormats) {
                if ([acceptedFormats containsObject:format]) {
                    NSArray *items = [self metadataForFormat:format];
                    for (AVMetadataItem *item in items) {
                        AVMetadataKey key = (AVMetadataKey)item.key;
                        if([key isKindOfClass:[NSString class]]) {
                            if ([key containsString:@"com.android.version"]) {
                                dic[@"andriod"] = @(1);
                            }
                            if ([key containsString:@"description"] ||
                                [key containsString:@"desc"]) {
                                dic[@"description"] = [item stringValue];
                            }
                            else if([key containsString:@"location.ISO6709"]) {
                                double accuracy = 0.0;
                                if ([key containsString:@"location.accuracy"]) {
                                    accuracy = item.stringValue.doubleValue;
                                }
                                NSString *locDesc = [item stringValue];
                                CLLocation* location = [self buildLocation:locDesc accuracy:accuracy];
                                if (location) {
                                    dic[@"location"] = location;
                                }
                            }
                        }
                        else if([key isKindOfClass:[NSNumber class]]) {
                            int fourcc = [key intValue];
                            if (fourcc == DESC) {
                                dic[@"description"] = [item stringValue];
                            } else if(fourcc == XYZ) {
                                id locDesc = [item stringValue];
                                if (locDesc == nil) {
                                    NSData *data = [item dataValue];
                                    data = [data subdataWithRange: NSMakeRange(4, data.length-4)];
                                    locDesc = [[NSString alloc] initWithData:data encoding:(NSASCIIStringEncoding)];
                                }
                                CLLocation *location = [self buildLocation:locDesc accuracy:0];
                                if (location) {
                                    dic[@"location"] = location;
                                }
                            }
                        }
                    }
                }
            }
        }
        dispatch_group_leave(group);
    }];
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
    return [dic copy];
}

// +40.0347+116.3089+050.427/
// +40.0347+116.3086/
- (CLLocation*)buildLocation:(NSString *)locDesc accuracy:(double)accuracy
{
    NSString *latitude = [locDesc substringToIndex:8];
    NSString *longitude = [locDesc substringWithRange:NSMakeRange(8, 9)];
    NSString *altitude = nil;
    NSInteger len = latitude.length + longitude.length;
    if (len + 1 < locDesc.length) {
        altitude = [locDesc substringWithRange:NSMakeRange(len, locDesc.length - len - 1)];
    }
    if (latitude.length == 0 ||  longitude.length == 0) {
        return nil;
    }
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue) altitude:altitude.doubleValue horizontalAccuracy:accuracy verticalAccuracy:accuracy timestamp:[NSDate date]];
    return location;
}

- (void)getPreviewImageAtTime:(NSTimeInterval)atTime preferredSize:(CGSize)size compeletion:(void (^)(UIImage *image, NSTimeInterval atTime))compeletion
{
    void (^processedImage)(UIImage *image, NSTimeInterval atTime) = ^(UIImage *image, NSTimeInterval atTime) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SafeBlock(compeletion, image, atTime);
        });
    };
    
    [[self class] getImageWithAsset:self videoComposition:nil atTime:atTime preferredSize:size compeletion:processedImage];
}

+ (void)getImageWithAsset:(AVAsset *)asset videoComposition:(nullable AVVideoComposition *)videoComposition atTime:(NSTimeInterval)atTime preferredSize:(CGSize)size compeletion:(void (^)(UIImage *image, NSTimeInterval atTime))compeletion
{
    if (!asset) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SafeBlock(compeletion, nil, atTime);
        });
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:[asset copy]];
        generator.appliesPreferredTrackTransform = YES;
        if (videoComposition) {
            generator.videoComposition = [videoComposition copy];
        }
        generator.maximumSize = size;
        generator.requestedTimeToleranceBefore = CMTimeMakeWithSeconds(0.1f, NSEC_PER_SEC);
        generator.requestedTimeToleranceAfter = CMTimeMakeWithSeconds(0.1f, NSEC_PER_SEC);
        Float64 seconds = atTime;
        if (seconds < 0) {
            seconds = 0;
        }
        if (seconds > CMTimeGetSeconds(asset.duration)) {
            seconds = CMTimeGetSeconds(asset.duration);
        }
        CMTime atCMTime = CMTimeMakeWithSeconds(seconds, asset.duration.timescale);
        CGImageRef imageRef = [generator copyCGImageAtTime:atCMTime actualTime:NULL error:NULL];
        if (!imageRef) {
            atCMTime = CMTimeMakeWithSeconds(MAX(0, seconds - 0.05), asset.duration.timescale);
            imageRef = [generator copyCGImageAtTime:atCMTime actualTime:NULL error:NULL];
            if (!imageRef) {
                atCMTime = CMTimeMakeWithSeconds(MAX(0, seconds - 0.05), asset.duration.timescale);
                imageRef = [generator copyCGImageAtTime:atCMTime actualTime:NULL error:NULL];
            }
        }
        UIImage *frameImage = [[UIImage alloc] initWithCGImage:imageRef];
        CGImageRelease(imageRef);
        SafeBlock(compeletion, frameImage, atTime);
    });
}

+ (BOOL)xhm_isOptimizeForNetworkUse:(NSString*)path
{
    if(path == nil) return NO;
    FILE* pFile = fopen(path.UTF8String, "rb");
    if (pFile == 0) return NO;
    char buf[64] = {0};
    fread(buf, 1, 64, pFile);
    fclose(pFile);
    BOOL hasMoov = NO;
    for(int i = 0; i < 60; i = i + 4) {
        if (*(int*)(buf+i) == MOOV) {
            hasMoov = YES; break;
        }
    }
    return hasMoov;
}

@end
