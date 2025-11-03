#import <Foundation/Foundation.h>
#import "BMWVideoAlgorithmSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWVideoAlgorithmOCRSource : BMWVideoAlgorithmSource

- (instancetype)initWithImage:(UIImage*)image size:(CGSize)size level:(NSUInteger)level;

+ (int)maxRetryCount;

@end

NS_ASSUME_NONNULL_END
