#import <Foundation/Foundation.h>
#import "BMWVideoAlgorithmInterface.h"
@class BMWRect;
NS_ASSUME_NONNULL_BEGIN

@interface BMWOCRAlgorithmV3 : NSObject<BMWVideoAlgorithmInterface>
@property(nonatomic) NSUInteger boxLimit;
@property(nonatomic) BOOL justMaxBox;
@end

NS_ASSUME_NONNULL_END

