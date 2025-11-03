#import <GPCam/GPCam.h>
#import "BMWBaseDrawer.h"
#import "BMWImageContext.h"
NS_ASSUME_NONNULL_BEGIN

@interface BMWRoundRectangleDrawer : BMWBaseDrawer

- (instancetype)initWithContext:(BMWImageContext *)imageContext;

- (void)setResolution:(CGSize)resolution
               radius:(int)radius
          borderWidth:(float)borderWidth
          borderColor:(UIColor*)borderColor;

@end

NS_ASSUME_NONNULL_END
