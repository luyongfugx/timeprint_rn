#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "BMWImageContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWSimilarityDetector : NSObject

- (instancetype)initWithContext:(BMWImageContext *)imageContext;

//similarity = [[[BMWSimilarityDetector alloc] initWithContext:self.imageContext] detect:self.previewImage capturedTexId:self.outputImageBuffer.texture CGSize:self.outputImageBuffer.bufferSize];

- (CGFloat)detect:(UIImage*)previewImage capturedTexId:(int)capturedTexId CGSize:(CGSize)capturedSize;

@end

NS_ASSUME_NONNULL_END
