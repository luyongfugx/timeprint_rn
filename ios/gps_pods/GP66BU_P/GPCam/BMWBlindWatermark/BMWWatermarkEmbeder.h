#import <Foundation/Foundation.h>
#import "BMWBaseDrawer.h"

@class BMWBlindWatermarkModel;

NS_ASSUME_NONNULL_BEGIN

__attribute__((visibility("hidden"))) @interface BMWWatermarkEmbeder : NSObject

- (instancetype)init:(BMWImageContext*)context;

- (void)embeded:(GLuint)texId size:(CGSize)size wm:(NSString*)wm;

- (void)updateWmModel:(BMWBlindWatermarkModel*)wmModel;

- (void)embeded:(GLuint)texId texSize:(CGSize)texSize sliceEmbedCallback:(void (^)(CGRect sliceRect))sliceEmbedCallback;

- (void)embeded:(UIImage*)image embedCallback:(void (^)(UIImage *processedImage))embedCallback;

- (void)destory;

@end

NS_ASSUME_NONNULL_END

