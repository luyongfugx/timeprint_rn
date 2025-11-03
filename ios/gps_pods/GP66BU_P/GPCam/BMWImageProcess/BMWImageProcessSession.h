#import <Foundation/Foundation.h>
#import "BMWImageProcessRequest.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWImageProcessSession : NSObject

- (void)process:(BMWImageProcessRequest*)request;

@end

NS_ASSUME_NONNULL_END
