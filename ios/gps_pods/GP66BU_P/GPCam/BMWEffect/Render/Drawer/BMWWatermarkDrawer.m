#import "BMWWatermarkDrawer.h"
#import "BMWGLUtils.h"
#import "BMWFramebuffer.h"
#import "BMWImageContext.h"

@implementation BMWWatermarkInfo

+ (BMWWatermarkInfo*)buildInfo:(NSString*)tag texId:(GLint)texId rect:(CGRect)rect deviceOrientation:(BMWDeviceOrientation)deviceOrientation
{
    BMWWatermarkInfo *info = BMWWatermarkInfo.new;
    info.tag = tag;
    info.texId = texId;
    info.rect = rect;
    info.rotationMode = kXHImageNoRotation;
    if (deviceOrientation == BMWDeviceOrientationLeft) {
        info.rotationMode = kXHImageRotateLeft;
    } else if (deviceOrientation == BMWDeviceOrientationRight) {
        info.rotationMode = kXHImageRotateRight;
    } else if (deviceOrientation == BMWDeviceOrientationDown) {
        info.rotationMode = kXHImageRotate180;
    }
    return info;
}

@end

@implementation BMWWatermarkInfoV2

@end

@interface BMWWatermarkDrawer()

@property(nonatomic) NSMutableArray<BMWWatermarkInfo*> *watermarkArray;

@property(nonatomic) NSMutableArray<BMWWatermarkInfoV2 *> *watermarkArrayV2;

@property (nonatomic, strong) BMWImageContext *imageContext;

@end

@implementation BMWWatermarkDrawer

- (void)destory
{
    [super destory];
    for (BMWWatermarkInfo* info in self.watermarkArray) {
        GLint texid = info.texId;
        glDeleteTextures(1, &texid);
    }
    [self.watermarkArray removeAllObjects];
}

- (instancetype)initWithContext:(BMWImageContext *)context
{
    if (self = [super init]) {
        self.watermarkArray = [NSMutableArray new];
        self.watermarkArrayV2 = [NSMutableArray new];
        self.imageContext = context;
    }
    return self;
}

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:nil fragmentShader:nil];
}

- (void)prepare
{
    [super prepare];
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
}

- (void)updateWatermark:(BMWWatermarkInfo*)info
{
    [self.watermarkArray addObject:info];
}

- (void)updateWatermarkV2s:(NSArray<BMWWatermarkInfoV2* >*)infos
{
    self.watermarkArrayV2 = [NSMutableArray arrayWithArray:infos];
}

- (NSArray<BMWWatermarkInfo*>*)findWatermrkWithTag:(NSString*)tag
{
    NSMutableArray<BMWWatermarkInfo*> *temp = [[NSMutableArray alloc] initWithCapacity:1];
    for (BMWWatermarkInfo* info in self.watermarkArray) {
        if([info.tag isEqualToString:tag]) {
            [temp addObject:info];
        }
    }
    return temp;
}

- (void)clearup
{
    // do nothing
}

- (void)draw
{
    for (BMWWatermarkInfoV2 *info in self.watermarkArrayV2) {
        [BMWGLUtils rect2GLCoordinate:info.rect reslut:^(GLfloat * _Nonnull v) {
            if (info.framebuffer.imageContext == self.imageContext) {
                [super drawWithTexId:info.framebuffer.texture vertices:v rotation:info.rotationMode];
            } else {
                GLuint textureId = [BMWGLUtils createTextureWithBuffer:info.framebuffer.renderTarget context:self.imageContext];
                [super drawWithTexId:textureId vertices:v rotation:info.rotationMode];
                glDeleteTextures(1, &textureId);
            }
        }];
    }
    for (BMWWatermarkInfo* info in self.watermarkArray) {
        [BMWGLUtils rect2GLCoordinate:info.rect reslut:^(GLfloat * _Nonnull v) {
            [super drawWithTexId:info.texId vertices:v rotation:info.rotationMode];
        }];
    }
    [super clearup];
    glDisable(GL_BLEND);
}

@end
