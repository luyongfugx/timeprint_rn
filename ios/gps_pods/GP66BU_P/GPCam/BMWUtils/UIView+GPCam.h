#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (GPCam)

@property(nonatomic, assign) BOOL xhm_invisible;

- (UIImage*)xhm_capture:(CGFloat)scale;

- (UIImage*)xhm_captureWithNewApi:(CGFloat)scale;

- (UIView *)xhm_findSubview:(BOOL(^)(UIView *subview))filter;

@end

@interface CALayer (GPCam)
@property(nonatomic, assign) BOOL xhm_invisible;
- (void)xhm_renderInContext:(CGContextRef)ctx;
@end

NS_ASSUME_NONNULL_END
