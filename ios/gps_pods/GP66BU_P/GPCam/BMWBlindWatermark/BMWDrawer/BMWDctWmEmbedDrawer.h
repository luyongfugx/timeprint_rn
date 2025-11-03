#import <Foundation/Foundation.h>
#import "BMWBaseDrawer.h"

NS_ASSUME_NONNULL_BEGIN

__attribute__((visibility("hidden"))) @interface BMWDctWmEmbedDrawer : BMWBaseDrawer

- (instancetype)init:(CGSize)size;

- (void)renderTextureId:(GLuint)texId wmBits:(int32_t*)wmBits wmBitsCount:(int)wmBitsCount vertices:(const GLfloat *)vertices;

- (void)renderTextureId:(GLuint)texId wmTexId:(GLuint)wmTexId wmBitsCount:(int)wmBitsCount vertices:(const GLfloat *)vertices;

@end

NS_ASSUME_NONNULL_END


