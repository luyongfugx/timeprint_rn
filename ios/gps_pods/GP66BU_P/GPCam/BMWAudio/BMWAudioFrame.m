#import "BMWAudioFrame.h"
#import <CoreMedia/CoreMedia.h>
#import <CoreMedia/CMBase.h>

@interface BMWAudioFrame ()

@property (nonatomic, assign, readwrite) CMSampleBufferRef sampleBuffer;

@end

@implementation BMWAudioFrame

- (instancetype)init {
    if (self = [super init]) {
        _sampleBuffer = NULL;
        _pcmData = nil;
    }

    return self;
}

- (void)dealloc {
    if (_sampleBuffer) {
        CFRelease(_sampleBuffer);
        _sampleBuffer = NULL;
    }
}

- (CMSampleBufferRef)sampleBuffer {
    if (_sampleBuffer) {
        return _sampleBuffer;
    }

    AudioStreamBasicDescription audioDescription = [self audioStreamDescription];
    CMFormatDescriptionRef format = NULL;
    OSStatus status = CMAudioFormatDescriptionCreate(kCFAllocatorDefault, &audioDescription, 0, NULL, 0, NULL, NULL, &format);
    @onExit {
        if (format) {
            CFRelease(format);
        }
    };

    if (status != noErr) {
                return NULL;
    }

    CMSampleTimingInfo timing = {CMTimeMake(1, audioDescription.mSampleRate), self.presentationTimestamp, kCMTimeInvalid};
    size_t sampleSize = audioDescription.mBytesPerFrame;
    UInt32 inNumberFrames = self.pcmData.length / (self.channels * sizeof(BMWAudioFormat_Integer));
    status = CMSampleBufferCreate(kCFAllocatorDefault, NULL, false,
                                  NULL, NULL, format, (CMItemCount)inNumberFrames,
                                  1, &timing, 1, &sampleSize, &_sampleBuffer);

    if (status != noErr) {
                return NULL;
    }

    AudioBuffer buffer;
    buffer.mData = (void *)self.pcmData.bytes;
    buffer.mDataByteSize = (UInt32)self.pcmData.length;
    buffer.mNumberChannels = self.channels;

    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0] = buffer;

    status = CMSampleBufferSetDataBufferFromAudioBufferList(_sampleBuffer, kCFAllocatorDefault, kCFAllocatorDefault, 0, &bufferList);
    if (status != noErr) {
                if (_sampleBuffer) {
            CFRelease(_sampleBuffer);
            _sampleBuffer = NULL;
        }
        return NULL;
    }

    return _sampleBuffer;
}

- (AudioStreamBasicDescription)audioStreamDescription {
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

+ (BMWAudioFrame *)audioFrameFromSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    if (!sampleBuffer) {
        return nil;
    }

    BMWAudioFrame *audioFrame = [[BMWAudioFrame alloc] init];

    AudioBufferList audioBufferList;
    CMBlockBufferRef blockBuffer;
    CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, NULL, &audioBufferList, sizeof(audioBufferList), NULL, NULL, 0, &blockBuffer);

    AudioBuffer audioBuffer = audioBufferList.mBuffers[0];
    audioFrame.pcmData = [NSData dataWithBytes:audioBuffer.mData length:audioBuffer.mDataByteSize];

    audioFrame.channels = audioBuffer.mNumberChannels;
    CMFormatDescriptionRef formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer);

    const AudioStreamBasicDescription* const asbd = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription);

    audioFrame.sampleRate = asbd->mSampleRate;

    @onExit {
        if (blockBuffer) {
            CFRelease(blockBuffer);
        }
    };

    CMTime presentationTimeStamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    audioFrame.presentationTimestamp = presentationTimeStamp;

    return audioFrame;
}

@end
