#import <Foundation/Foundation.h>
#import "BMWImageContext.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWLuminanceDectector : NSObject

+ (BMWLuminanceDectector*)sharedInstance;

- (instancetype)initWithContext:(BMWImageContext *)imageContext;

- (CGFloat)detectWithTexId:(int)texId texSize:(CGSize)texSize;

@end

NS_ASSUME_NONNULL_END
