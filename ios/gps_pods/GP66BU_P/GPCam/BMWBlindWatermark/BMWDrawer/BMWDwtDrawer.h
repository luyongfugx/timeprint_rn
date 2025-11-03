#import <Foundation/Foundation.h>
#import "BMWBaseDrawer.h"

NS_ASSUME_NONNULL_BEGIN

__attribute__((visibility("hidden"))) @interface BMWDwtDrawer : BMWBaseDrawer

- (instancetype)init:(CGSize)size direction:(int)direction;

- (void)renderTextureId:(GLuint)texId vertices:(const GLfloat *)vertices;

@end

NS_ASSUME_NONNULL_END
