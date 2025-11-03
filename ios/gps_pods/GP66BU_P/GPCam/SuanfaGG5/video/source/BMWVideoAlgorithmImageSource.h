#import <Foundation/Foundation.h>
#import "BMWVideoAlgorithmSource.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWVideoAlgorithmImageSource : BMWVideoAlgorithmSource

- (instancetype)initWithImage:(UIImage*)image;

- (instancetype)initWithImage:(UIImage*)image size:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
