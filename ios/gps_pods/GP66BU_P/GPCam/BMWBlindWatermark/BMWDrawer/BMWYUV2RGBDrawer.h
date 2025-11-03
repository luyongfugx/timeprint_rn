#import <Foundation/Foundation.h>
#import "BMWBaseDrawer.h"

NS_ASSUME_NONNULL_BEGIN

__attribute__((visibility("hidden"))) @interface BMWYUV2RGBDrawer : BMWBaseDrawer

- (void)renderTextureId:(GLuint)texId uTexId:(int)uTexId vertices:(const GLfloat *)vertices;

@end

NS_ASSUME_NONNULL_END


