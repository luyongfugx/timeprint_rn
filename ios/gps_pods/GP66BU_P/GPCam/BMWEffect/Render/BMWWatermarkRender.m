#import "BMWWatermarkRender.h"
#import "BMWGLUtils.h"
#import "BMWRenderDefine.h"
#import "BMWWatermarkItem.h"
#import "BMWImageContext.h"
#import "BMWWatermarkBufferCache.h"
#import "BMWWatermarkDrawer.h"
#import "BMWInputDrawer.h"

@interface BMWWatermarkRender ()
@property (nonatomic) BOOL isValid;
@property (nonatomic) GLint watermarkTexId;
@property (nonatomic) GLint defaultMarkTexId;
@property (nonatomic) BMWImageContext *imageContext;
@property (nonatomic) BMWWatermarkBufferCache *watermarkBufferCache;
@property (nonatomic) BMWDeviceOrientation deviceOrientation;
@property (nonatomic) CGSize renderOutputSize;
@property (nonatomic) BMWWatermarkItem *watermark;
@property (nonatomic) BMWWatermarkItem *productWatermark;

@property (nonatomic) double startTime;
@property (nonatomic) BMWFramebuffer *outputFramebuffer;
@property (nonatomic) BMWWatermarkDrawer* watermarkDrawer;
@property (nonatomic) BMWBaseDrawer* inputDrawer;
@property (nonatomic) GLint inputTexId;
@property (nonatomic, strong) BMWInputDrawer *subCameraDrawer;
@property (nonatomic, copy) NSArray<BMWWatermarkInfoV2* > *watermarkInfoV2s;

@end

@implementation BMWWatermarkRender

- (void)dealloc
{
    BMWMLogM(@"BMWWatermarkRender dealloc...");
}

- (instancetype)initWithContext:(BMWImageContext *)imageContext
{
    self = [super init];
    if (self) {
        self.imageContext = imageContext;
    }
    return self;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.imageContext = [BMWImageContext sharedImageProcessingContext];
    }
    return self;
}

- (void)reset
{
    BMWMLogM(@"BMWWatermarkRender reset...");
    self.isValid = NO;
    [self.watermarkBufferCache clear];
    [self.inputDrawer destory];
    self.inputDrawer = nil;
    [self.watermarkDrawer destory];
    self.watermarkDrawer = nil;
    [self.outputFramebuffer destroy];
    self.outputFramebuffer = nil;
    if (_watermarkTexId > 0) {
        glDeleteTextures(1, &_watermarkTexId);
        _watermarkTexId = 0;
    }
    if (_defaultMarkTexId > 0) {
        glDeleteTextures(1, &_defaultMarkTexId);
        _defaultMarkTexId = 0;
    }
    [self.imageContext flush];
}

- (void)setInputTexture:(GLuint)textureId
{
    if (!self.watermarkDrawer) {
        self.watermarkDrawer = [[BMWWatermarkDrawer alloc] initWithContext:self.imageContext];
    }
    if (!self.inputDrawer) {
        self.inputDrawer = [BMWBaseDrawer new];
    }
    if (!self.outputFramebuffer) {
        self.outputFramebuffer = [[BMWFramebuffer alloc] initWithSize:self.renderOutputSize imageContext:self.imageContext];
    }
    [self.inputDrawer setInputTexId:textureId];
    [self.inputDrawer resetMatrix];
    if (self.deviceOrientation == BMWDeviceOrientationPortait) {
        [self.inputDrawer rotateZ:0];
    } else if (self.deviceOrientation == BMWDeviceOrientationRight) {
        [self.inputDrawer rotateZ:M_PI_2];
    } else if (self.deviceOrientation == BMWDeviceOrientationDown) {
        [self.inputDrawer rotateZ:M_PI];
    } else if (self.deviceOrientation == BMWDeviceOrientationLeft) {
        [self.inputDrawer rotateZ:-M_PI_2];
    }
    [self.inputDrawer scaleX:self.isMirror ? -1.0f : 1.0f scaleY:1.0f];
    self.isValid = YES;
}

- (void)process:(double)frameTime
{
    if (self.watermark && self.watermark.refreshTime > 0) {
        if (self.startTime == 0) {
            self.startTime = frameTime;
        }
        float deltaTime = self.startTime - frameTime;
        float ns = self.watermark.refreshTime * 30.0;
        float de = ceil(deltaTime * 30.0);
        float dn = de / ns;
        if (dn - floor(dn) < 0.01) {
            __weak typeof(self) wself = self;
            [self.watermarkBufferCache popWatermarkSync:self.watermark buffer:^(BMWWatermarkBuffer * _Nonnull buffer) {
                __strong typeof(wself) sself = wself;
                [buffer updateTexture:sself.watermarkTexId];
            }];
        }
        if (dn - floor(dn) < 0.22 && dn - floor(dn) > 0.17) {
            [self.watermarkBufferCache pushWatermark:self.watermark];
        }
    }
    [self.watermarkDrawer updateWatermarkV2s:self.watermarkInfoV2s];
    [self.outputFramebuffer bind];
    [self.inputDrawer draw];
    [self.outputFramebuffer bind];
    [self.watermarkDrawer draw];
}

- (void)processForTrancode:(double)frameTime
{
    if (self.watermark && self.watermark.refreshTime > 0) {
        if (self.startTime == 0) {
            self.startTime = frameTime;
        }
        float deltaTime = self.startTime - frameTime;
        float ns = self.watermark.refreshTime * 30.0;
        float de = ceil(deltaTime * 30.0);
        float dn = de / ns;
        if (dn - floor(dn) < 0.01) {
            [BMWGLUtils updateTextureWithLayer:self.watermark.waterLayer scale:self.watermark.scale textureId:_watermarkTexId];
        }
    }
    [self.outputFramebuffer bind];
    [self.inputDrawer draw];
    [self.outputFramebuffer bind];
    [self.watermarkDrawer draw];
}

- (void)prepareWatermark:(BMWWatermarkItem *)watermark
{
    _watermark = watermark;
    [self.watermarkBufferCache pushWatermark:self.watermark];
}

- (void)setWatermark:(BMWWatermarkItem *)watermark
{
    _watermark = watermark;
    _startTime = 0;
    if (_watermark) {
        __weak typeof(self) wself = self;
        [self.watermarkBufferCache popWatermarkSync:self.watermark buffer:^(BMWWatermarkBuffer * _Nonnull buffer) {
            __strong typeof(wself) sself = wself;
            sself.watermarkTexId = buffer.genTexture;
        }];
        if (_watermarkTexId == 0) {
            _watermarkTexId = [BMWGLUtils createTextureWithLayer:self.watermark.waterLayer scale:self.watermark.scale];
        }
        CGRect rect = CGRectMake(self.watermark.x,
                                 self.watermark.y,
                                 self.watermark.w,
                                 self.watermark.h);
        BMWWatermarkInfo *info = [BMWWatermarkInfo buildInfo:@"watermark" texId:_watermarkTexId rect:rect deviceOrientation:watermark.deviceOrientation];
        if (!self.watermarkDrawer) {
            self.watermarkDrawer = [[BMWWatermarkDrawer alloc] initWithContext:self.imageContext];
        }
        [self.watermarkDrawer updateWatermark:info];
    }
}

- (void)setProductWatermark:(BMWWatermarkItem *)productWatermark
{
    _productWatermark = productWatermark;
    if (_productWatermark && !_hiddenProductWatermark) {
        _defaultMarkTexId = [BMWGLUtils createTextureWithLayer:self.productWatermark.waterLayer scale:self.productWatermark.scale];
        CGRect rect = CGRectMake(self.productWatermark.x,
                                 self.productWatermark.y,
                                 self.productWatermark.w,
                                 self.productWatermark.h);
        BMWWatermarkInfo *info = [BMWWatermarkInfo buildInfo:@"productWatermark" texId:_defaultMarkTexId rect:rect deviceOrientation:productWatermark.deviceOrientation];
        if (!self.watermarkDrawer) {
            self.watermarkDrawer = [[BMWWatermarkDrawer alloc] initWithContext:self.imageContext];
        }
        [self.watermarkDrawer updateWatermark:info];
    }
}

- (void)updateWatermarkV2s:(NSArray<BMWWatermarkInfoV2* >*)infos
{
    self.watermarkInfoV2s = infos;
}

- (void)setDeviceOritaion:(BMWDeviceOrientation)orientation
{
    _deviceOrientation = orientation;
}

- (void)setRenderOutputSize:(CGSize)size
{
    _renderOutputSize = size;
}

- (CVPixelBufferRef)renderTarget
{
    return self.isValid ? self.outputFramebuffer.renderTarget : nil;
}

- (BMWWatermarkBufferCache *)watermarkBufferCache
{
    if(!_watermarkBufferCache) {
        _watermarkBufferCache = [BMWWatermarkBufferCache new];
    }
    return _watermarkBufferCache;
}

@end
