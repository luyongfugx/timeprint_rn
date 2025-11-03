#import "BMWAudioUtils.h"

@implementation BMWAudioUtils

+ (int16_t *_Nullable *_Nullable)rawFloatDataFromAudioBuffer:(AudioBuffer)audioBuffer numberOfChannels:(int *)channels samplesPerChannel:(int *)samplesPerChannel
{
    BMWAudioFormat_Integer *audioRawData = audioBuffer.mData;
    int samples = audioBuffer.mDataByteSize / sizeof(BMWAudioFormat_Integer);
    *channels = audioBuffer.mNumberChannels;
    *samplesPerChannel = samples / *channels;

    int16_t **rawFloatData = (int16_t **)malloc(*channels * sizeof(int16_t *));
    for (int i = 0; i < *channels; ++i) {
        rawFloatData[i] = (int16_t *)malloc(*samplesPerChannel * sizeof(int16_t));
        for (int j = 0; j < *samplesPerChannel; ++j) {
            // audioRawData ==> L R L R
            rawFloatData[i][j] = (int16_t)audioRawData[j * *channels + i];
        }
    }
    return rawFloatData;
}
@end
