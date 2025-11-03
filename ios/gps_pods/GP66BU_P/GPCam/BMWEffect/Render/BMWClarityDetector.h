#import <Foundation/Foundation.h>
#import "BMWImageContext.h"
#import "BMWVideoAlgorithmResult.h"
NS_ASSUME_NONNULL_BEGIN
@class BMWRect;
@interface BMWClarityDetector : NSObject

- (instancetype)initWithContext:(BMWImageContext *)imageContext;

- (CGFloat)detectWithImage:(UIImage*)image texSize:(CGSize)texSize;

- (CGFloat)detectWithTexId:(int)texId texSize:(CGSize)texSize;

- (CGFloat)detectWithTexId:(int)texId texSize:(CGSize)texSize rectOfInInterest:(BMWRect*)rect;

- (BMWImageQualityAlgorithmResult*)imageQualityDetectWithTexId:(int)texId;
- (BMWImageQualityAlgorithmResult*)imageQualityDetectWithImage:(UIImage*)image;

@end

NS_ASSUME_NONNULL_END
