#import <Foundation/Foundation.h>
#import "BMWBaseDrawer.h"

NS_ASSUME_NONNULL_BEGIN

__attribute__((visibility("hidden"))) @interface BMWWmMergeDrawer : BMWBaseDrawer

- (instancetype)init:(CGSize)size wmSize:(int)wmSize;

- (void)renderTextureId:(GLuint)texId wmBitsCount:(int)wmBitsCount vertices:(const GLfloat *)vertices;

@end

NS_ASSUME_NONNULL_END

