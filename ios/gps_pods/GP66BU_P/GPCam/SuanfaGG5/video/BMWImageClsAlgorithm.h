#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "BMWVideoAlgorithmInterface.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWImageClsAlgorithm  : NSObject<BMWVideoAlgorithmInterface>
+ (BOOL)isShelf:(NSString*)label;
@end

NS_ASSUME_NONNULL_END
