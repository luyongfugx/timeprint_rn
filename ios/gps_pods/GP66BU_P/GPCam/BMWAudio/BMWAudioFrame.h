#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMWAudioFrame : NSObject

@property (nonatomic, strong) NSData *pcmData;

@property (nonatomic, assign) NSInteger sampleRate;

@property (nonatomic, assign) NSInteger channels;

@property (nonatomic, assign) CMTime presentationTimestamp;

@property (nonatomic, assign, readonly) CMSampleBufferRef sampleBuffer;

+ (BMWAudioFrame *)audioFrameFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;

@end

NS_ASSUME_NONNULL_END
