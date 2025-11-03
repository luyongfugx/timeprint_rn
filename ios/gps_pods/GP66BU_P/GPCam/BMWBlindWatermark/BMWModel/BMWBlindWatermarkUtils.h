#import <Foundation/Foundation.h>
#import "BMWFramebuffer.h"

NS_ASSUME_NONNULL_BEGIN

__attribute__((visibility("hidden"))) @interface BMWBlindWatermarkUtils : NSObject

+ (void)printBuffer:(BMWFramebuffer*)framebuffer tag:(NSString*)tag;

@end

NS_ASSUME_NONNULL_END
