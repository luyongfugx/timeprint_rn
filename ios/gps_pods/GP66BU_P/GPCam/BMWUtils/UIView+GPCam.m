#import "UIView+GPCam.h"
#import <objc/runtime.h>

static void *const kGPCamViewInvisibleKey = (void *)&kGPCamViewInvisibleKey;
static void *const kGPCamViewIsHiddenBeforeRenderingKey = (void *)&kGPCamViewIsHiddenBeforeRenderingKey;

@interface UIView (GPCam_internal)

@property(nonatomic, assign) BOOL xhm_isHiddenBeforeRendering;

@end

@implementation UIView (GPCam_internal)

- (BOOL)xhm_isHiddenBeforeRendering
{
    return [objc_getAssociatedObject(self, kGPCamViewIsHiddenBeforeRenderingKey) boolValue];
}

- (void)setXhm_isHiddenBeforeRendering:(BOOL)isHiddenBeforeRendering
{
    objc_setAssociatedObject(self, kGPCamViewIsHiddenBeforeRenderingKey, [NSNumber numberWithBool:isHiddenBeforeRendering], OBJC_ASSOCIATION_ASSIGN);
}

@end

@implementation UIView (GPCam)

- (BOOL)xhm_invisible
{
    return [objc_getAssociatedObject(self, kGPCamViewInvisibleKey) boolValue];
}

- (void)setXhm_invisible:(BOOL)xhm_invisible
{
    objc_setAssociatedObject(self, kGPCamViewInvisibleKey, [NSNumber numberWithBool:xhm_invisible], OBJC_ASSOCIATION_ASSIGN);
}

- (NSNumber*)originalContentScaleFactor
{
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setOriginalContentScaleFactor:(NSNumber*)factor
{
    objc_setAssociatedObject(self, @selector(originalContentScaleFactor), factor, OBJC_ASSOCIATION_COPY);
}

- (void)xhm_setScale:(CGFloat)scale
{
    self.originalContentScaleFactor = @(self.contentScaleFactor);
    self.contentScaleFactor = scale;
    for (UIView *subView in self.subviews) {
        // TODO 图片设置了contentScaleFactor会有问题
        if (![subView isKindOfClass:[UIImageView class]]) {
            [subView xhm_setScale:scale];
        }
    }
}

- (void)xhm_resotorScale
{
    CGFloat scale = self.originalContentScaleFactor.doubleValue;
    self.contentScaleFactor = scale;
    for (UIView *subView in self.subviews) {
        // TODO 图片设置了contentScaleFactor会有问题
        if (![subView isKindOfClass:[UIImageView class]]) {
            [subView xhm_resotorScale];
        }
    }
}

- (void)xhm_setInvisible
{
    self.xhm_isHiddenBeforeRendering = self.isHidden;
    if (self.xhm_invisible && self.alpha > 0.0f) {
        self.hidden = YES;
    }
    for (UIView *subView in self.subviews) {
        [subView xhm_setInvisible];
    }
}

- (void)xhm_retoreVisible
{
    if (self.xhm_invisible && self.alpha > 0.0f) {
        self.hidden = self.xhm_isHiddenBeforeRendering;
    }
    for (UIView *subView in self.subviews) {
        [subView xhm_retoreVisible];
    }
}

- (UIImage*)xhm_captureWithNewApi:(CGFloat)scale
{
    double begin = CACurrentMediaTime();
    [self xhm_setScale:scale];
    [self xhm_setInvisible];
    UIGraphicsImageRendererFormat *format = [UIGraphicsImageRendererFormat defaultFormat];
    format.scale = scale;
    UIGraphicsImageRenderer *renderer = [[UIGraphicsImageRenderer alloc] initWithSize:self.bounds.size format:format];
    UIImage *renderImage = [renderer imageWithActions:^(UIGraphicsImageRendererContext * _Nonnull rendererContext) {
        CGContextRef context = rendererContext.CGContext;
        return [self.layer renderInContext:context];
    }];
    [self xhm_retoreVisible];
    [self xhm_resotorScale];
    BMWMLog(@"xhm_captureWithNewApi capture[%@] timecost:%lfms", NSStringFromClass([self class]), 1000 * (CACurrentMediaTime() - begin));
    return renderImage;
}

- (UIImage*)xhm_capture:(CGFloat)scale
{
    [self xhm_setScale:scale];
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, scale);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    UIImage *renderImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return renderImage;
}

- (UIView *)xhm_findSubview:(BOOL(^)(UIView *subview))filter
{
    if (filter(self)) {
        return self;
    }
    
    for (UIView *subview in self.subviews) {
        UIView *result = [subview xhm_findSubview:filter];
        if (result) {
            return result;
        }
    }
    
    return nil;
}

@end


static void *const kGPCamCALayerInvisibleKey = (void *)&kGPCamCALayerInvisibleKey;
static void *const kGPCamCALayerIsHiddenBeforeRenderingKey = (void *)&kGPCamCALayerIsHiddenBeforeRenderingKey;

@interface CALayer (GPCam_internal)

@property(nonatomic, assign) BOOL xhm_isHiddenBeforeRendering;

@end

@implementation CALayer (GPCam_internal)

- (BOOL)xhm_isHiddenBeforeRendering
{
    return [objc_getAssociatedObject(self, kGPCamCALayerIsHiddenBeforeRenderingKey) boolValue];
}

- (void)setXhm_isHiddenBeforeRendering:(BOOL)isHiddenBeforeRendering
{
    objc_setAssociatedObject(self, kGPCamCALayerIsHiddenBeforeRenderingKey, [NSNumber numberWithBool:isHiddenBeforeRendering], OBJC_ASSOCIATION_ASSIGN);
}

- (BOOL)xhm_invisible
{
    return [objc_getAssociatedObject(self, kGPCamCALayerInvisibleKey) boolValue];
}

- (void)setXhm_invisible:(BOOL)xhm_invisible
{
    objc_setAssociatedObject(self, kGPCamCALayerInvisibleKey, [NSNumber numberWithBool:xhm_invisible], OBJC_ASSOCIATION_ASSIGN);
}

@end
@implementation CALayer (GPCam)

+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class c1 = objc_getClass("CALayer");
        Method origMethod = class_getInstanceMethod(c1, NSSelectorFromString(@"layoutSublayers"));
        class_addMethod(c1, NSSelectorFromString(@"xh_layoutSublayers"), method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
        Method swizzledMethod = class_getInstanceMethod(self, NSSelectorFromString(@"xh_layoutSublayers"));
        IMP origIMP = method_getImplementation(origMethod);
        method_exchangeImplementations(origMethod, swizzledMethod);
    });
}

// Ulgy 防止在后台线程调用[layer renderInContext:contxt]后
// 走到释放逻辑的时候系统触发后台线程渲染UI Exception
- (void)xh_layoutSublayers
{
    @try {
        [self xh_layoutSublayers];
    } @catch (NSException *exception) {
    }
}

- (void)xhm_renderInContext:(CGContextRef)ctx
{
    [self xhm_setInvisible];
    [self renderInContext:ctx];
    [self xhm_retoreVisible];
}

- (void)xhm_setInvisible
{
    self.xhm_isHiddenBeforeRendering = self.isHidden;
    if (self.xhm_invisible) {
        self.hidden = YES;
    }
    for (CALayer *subLayer in self.sublayers) {
        [subLayer xhm_setInvisible];
    }
}

- (void)xhm_retoreVisible
{
    if (self.xhm_invisible) {
        self.hidden = self.xhm_isHiddenBeforeRendering;
    }
    for (CALayer *subLayer in self.sublayers) {
        [subLayer xhm_retoreVisible];
    }
}

@end
