#import <Foundation/Foundation.h>
#import "BMWBaseDrawer.h"
#import "BMWFramebuffer.h"
#import "BMWGLView.h"
#import "GPCamDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWLittleImageDrawer : NSObject

@property (nonatomic, strong) BMWBaseDrawer *baseDrawer;
@property (nonatomic, strong) BMWFramebuffer *framebuffer;
@property (nonatomic, assign) BOOL isMirror;
@property (nonatomic, assign) BMWDeviceOrientation deviceOrientation;

- (instancetype)initWithContext:(BMWImageContext*)context size:(CGSize)size;

- (void)draw:(GLint)texId;

- (void)draw:(GLint)texId coordinates:(const GLfloat *)coordinates;

- (void)destory;

@end

NS_ASSUME_NONNULL_END
