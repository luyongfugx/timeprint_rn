#import "BMWLittleImageDrawer.h"

@interface BMWLittleImageDrawer ()

@property (nonatomic, assign) CGSize size;
@property (nonatomic, strong) BMWImageContext *context;

@end

@implementation BMWLittleImageDrawer

- (void)destory
{
    [self.baseDrawer destory];
    [self.framebuffer destroy];
}

- (instancetype)initWithContext:(BMWImageContext*)context size:(CGSize)size
{
    self = [super init];
    if (!self) {
        return nil;
    }
    self.size = size;
    self.context = context;
    self.baseDrawer = [[BMWBaseDrawer alloc] init];
    self.deviceOrientation = BMWDeviceOrientationPortait;
    return self;
}

- (void)setDeviceOrientation:(BMWDeviceOrientation)deviceOrientation
{
    if (_deviceOrientation == deviceOrientation) {
        return;
    }
    _deviceOrientation = deviceOrientation;
    CGSize bufferSize = self.size;
    if(deviceOrientation == BMWDeviceOrientationLeft || deviceOrientation == BMWDeviceOrientationRight) {
        bufferSize = CGSizeMake(self.size.height, self.size.width);
    }
    [self.framebuffer destroy];
    self.framebuffer = [[BMWFramebuffer alloc] initWithSize:bufferSize imageContext:self.context];
}

- (void)draw:(GLint)texId
{
    [self.baseDrawer resetMatrix];
    if (self.deviceOrientation == BMWDeviceOrientationRight) {
        [self.baseDrawer rotateZ:M_PI_2];
    } else if (self.deviceOrientation == BMWDeviceOrientationDown) {
        [self.baseDrawer rotateZ:M_PI];
    } else if (self.deviceOrientation == BMWDeviceOrientationLeft) {
        [self.baseDrawer rotateZ:-M_PI_2];
    }
    [self.baseDrawer scaleX:self.isMirror ? -1 : 1 scaleY:1];
    [self.framebuffer bind];
    GLfloat vertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    [self.baseDrawer drawWithTexId:texId];
    glFinish();
}

- (void)draw:(GLint)texId coordinates:(const GLfloat *)coordinates
{
    [self.framebuffer bind];
    static GLfloat vertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    [self.baseDrawer drawWithTexId:texId vertices:vertices coordinates:coordinates];
    glFinish();
}

@end
