#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPCamDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWAudioUtils : NSObject
+ (int16_t *_Nullable *_Nullable)rawFloatDataFromAudioBuffer:(AudioBuffer)audioBuffer numberOfChannels:(int *)channels samplesPerChannel:(int *)samplesPerChannel;
@end

NS_ASSUME_NONNULL_END
