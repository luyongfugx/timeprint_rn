#import "BMWFrameRender.h"
#import "BMWGLUtils.h"
#import "BMWRenderDefine.h"
#import "BMWToneCurveData.h"
#import "BMWInputDrawer.h"
#import "BMWPipInputDrawer.h"
#import "BMWFliterDrawer.h"
#import "BMWSharpenDrawer.h"
#import "BMWUnsharpMaskDrawer.h"

#define FRONT_FILTER_INTENSITY 0.65
#define BACK_FILTER_INTENSITY 0.8

@interface BMWFrameRender ()
{
    GLuint  textureId, lutTexId, lummasktoneTexId, toneTexId;
}
@property (nonatomic) BOOL inited;
@property (nonatomic) BMWImageContext *imageContext;
@property (nonatomic) BMWInputDrawer *inputDrawer;
@property (nonatomic) BMWPipInputDrawer *pipInputDrawer;
@property (nonatomic) BMWFliterDrawer *fliterDrawer;
@property (nonatomic) BMWUnsharpMaskDrawer *unsharpMaskDrawer;
@property (nonatomic) BMWFramebuffer *inputFBO;
@property (nonatomic) BMWFramebuffer *fliterFBO;
@property (nonatomic) BMWFramebuffer *unsharpMaskFBO;
@property (nonatomic) BMWFramebuffer *outputFBO;
@property (nonatomic) BMWFramebuffer *scaleExtraRatioFBO;
@property (nonatomic) BMWBaseDrawer *scaleExtraRatioDrawer;
@property (nonatomic, readwrite, assign) CGSize outputSize;
@property (nonatomic) CGSize lastOuputSize;
@property (nonatomic) BMWEffectType effectType;
@property (nonatomic, readwrite, copy) NSString *lutPath;
@property (nonatomic, assign) BOOL lutDirty;
@property (nonatomic, readwrite, assign) CGFloat lutIntensity;
@property (nonatomic) CGFloat brightnessIntensity;
@property (nonatomic) BMWDeviceOrientation deviceOrientation;
@property (nonatomic) BOOL useYUV;
@property (nonatomic, readwrite, strong) NSMutableDictionary<NSString*, BMWEffectTypeItem* >* beautyTypeDic;
@property (nonatomic, readwrite, strong) NSMutableDictionary<NSString*, NSNumber*>* beautyIntensityDic;
@property (nonatomic) BOOL needBeautyRender;
@property (nonatomic) CGFloat extraScaleRatio;

@property (nonatomic) BOOL enableLuminanceDetect;
@property (nonatomic) CGFloat luminance;

@end

@implementation BMWFrameRender

- (void)dealloc
{
    BMWMLogM(@"BMWFrameRender dealloc...");
}

- (instancetype)init
{
    if (self = [super init]) {
        self.extraScaleRatio = 1.0;
        self.useYUV = NO;
        self.rotation = kXHImageRotateLeft;
        self.outputSize = CGSizeZero;
        self.lastOuputSize = CGSizeZero;
        self.imageContext = [BMWImageContext sharedImageProcessingContext];
        self.beautyTypeDic = NSMutableDictionary.new;
        self.beautyIntensityDic = NSMutableDictionary.new;
        self.frameTime = kCMTimeInvalid;
        [self initRender];
    }
    return self;
}

- (instancetype)initWithContext:(BMWImageContext *)imageContext rotation:(BMWImageRotationMode)rotation useYUV:(BOOL)useYUV
{
    if (self = [super init]) {
        self.extraScaleRatio = 1.0;
        self.useYUV = useYUV;
        self.rotation = rotation;
        self.outputSize = CGSizeZero;
        self.lastOuputSize = CGSizeZero;
        self.imageContext = imageContext;
        self.beautyTypeDic = NSMutableDictionary.new;
        self.beautyIntensityDic = NSMutableDictionary.new;
        self.frameTime = kCMTimeInvalid;
        [self initRender];
    }
    return self;
}

- (void)initRender
{
    if (self.inited == YES) {
        return;
    }
    self.inputDrawer = [[BMWInputDrawer alloc] initWithContext:self.imageContext useYUV:self.useYUV];
    self.pipInputDrawer = [[BMWPipInputDrawer alloc] initWithContext:self.imageContext useYUV:self.useYUV];
    self.fliterDrawer = [[BMWFliterDrawer alloc] init];
    self.unsharpMaskDrawer = [[BMWUnsharpMaskDrawer alloc] init];

    lummasktoneTexId = [[BMWToneCurveData alloc] initWithName:@"light11"].getTexId;
    toneTexId = [[BMWToneCurveData alloc] initWithName:@"color22"].getTexId;

    [self.fliterDrawer setLumMaskCurveTexId:lummasktoneTexId];
    [self.fliterDrawer setToneCurveTextId:toneTexId];
    self.inited = YES;
    }

- (void)buildBeautyRender
{

}

- (GLuint)processPixelBuffer:(CVPixelBufferRef)cameraFrame pipPixelBuffer:(CVPixelBufferRef)pipCameraFrame pipOrientation:(BMWDeviceOrientation)pipOrientation frameTime:(CMTime)frameTime isFront:(BOOL)isFront
{
    [self initRender];

    self.frameTime = frameTime;
    int width = (int)CVPixelBufferGetWidth(cameraFrame);
    int height = (int)CVPixelBufferGetHeight(cameraFrame);
    CGSize curFrameSize = CGSizeMake(width, height);
    if (CGSizeEqualToSize(CGSizeZero, self.outputSize)) {
        self.outputSize = curFrameSize;
    }
    CGSize outputSize = self.outputSize;
    if (self.rotation == kXHImageRotateLeft ||
        self.rotation == kXHImageRotateRight) {
        curFrameSize = CGSizeMake(height, width);
        outputSize = CGSizeMake(outputSize.height, outputSize.width);
    }
    // clear buffer if needed
    if (!CGSizeEqualToSize(self.lastOuputSize, outputSize)) {
        self.lastOuputSize = outputSize;
        [self clearBuffer];
    }

    // downsampling to 1080p when front
    if ((self.effectType == BMWEffectTypeFront)) {
        float max = MAX(outputSize.width, outputSize.height);
        float min = MIN(outputSize.width, outputSize.height);
        float dst = min / max > 0.75 ? 1080 : 1280;
        float scale = dst / max;
        float sw = outputSize.width * scale;
        float sh = outputSize.height * scale;
        outputSize = CGSizeMake(sw, sh);
    }

    // config intensity
    if (self.effectType == BMWEffectTypeFront) {
        [self.fliterDrawer setBrightnessIntensity:self.brightnessIntensity];
        [self.fliterDrawer setLutIntensity:self.lutIntensity];
        [self.fliterDrawer setToneCurveIntensity:0.0];
        [self.fliterDrawer setLumMaskCurveIntensity:0.0];
        [self.unsharpMaskDrawer setIntensity:0.0 saturation:1.0];
    }
    else if (self.effectType == BMWEffectTypeOriginalWithoutSharpen) {
        [self.fliterDrawer setBrightnessIntensity:self.brightnessIntensity];
        [self.fliterDrawer setLutIntensity:0.0];
        [self.fliterDrawer setToneCurveIntensity:0.0];
        [self.fliterDrawer setLumMaskCurveIntensity:0.0];
        [self.unsharpMaskDrawer setIntensity:0.0 saturation:1.0];
    }
    else if (self.effectType == BMWEffectTypeOriginal) {
        [self.fliterDrawer setBrightnessIntensity:self.brightnessIntensity];
        [self.fliterDrawer setLutIntensity:0.0];
        [self.fliterDrawer setToneCurveIntensity:0.0];
        [self.fliterDrawer setLumMaskCurveIntensity:0.0];
        [self.unsharpMaskDrawer setIntensity:SHARPEN_INTENSITY saturation:1.0];
    }
    else if (self.effectType == BMWEffectTypeBackWithTone) {
        [self.fliterDrawer setBrightnessIntensity:self.brightnessIntensity];
        [self.fliterDrawer setLutIntensity:self.lutIntensity];
        [self.fliterDrawer setToneCurveIntensity:1.0];
        [self.fliterDrawer setLumMaskCurveIntensity:1.0];
        [self.unsharpMaskDrawer setIntensity:SHARPEN_INTENSITY saturation:SATURATION_INTENSITY];
    }
    else if (self.effectType == BMWEffectTypeBackWithoutTone) {
        [self.fliterDrawer setBrightnessIntensity:self.brightnessIntensity];
        [self.fliterDrawer setLutIntensity:self.lutIntensity];
        [self.fliterDrawer setToneCurveIntensity:0.0];
        [self.fliterDrawer setLumMaskCurveIntensity:0.0];
        [self.unsharpMaskDrawer setIntensity:SHARPEN_INTENSITY saturation:SATURATION_INTENSITY];
    }

    // draw input

    // ugly rotate && crop && mirror
    float inputRatio = curFrameSize.width / curFrameSize.height;
    float outputRatio = outputSize.width / outputSize.height;
    float scaleX = 1.0f;
    float scaleY = 1.0f;
    if (inputRatio > outputRatio) {
        scaleX = inputRatio / outputRatio;
    } else if (outputRatio > inputRatio) {
        scaleY = outputRatio / inputRatio;
    }

    float radians = 0.0;
    if(self.rotation == kXHImageRotateLeft) {
        radians = M_PI_2;
    } else if(self.rotation == kXHImageRotateRight) {
        radians = -M_PI_2;
    } else if(self.rotation == kXHImageFlipVertical) {
        radians = M_PI;
    }
    [self.inputDrawer setInputPixelBuffer:cameraFrame];
    [self.inputDrawer resetMatrix];
    [self.inputDrawer rotateZ:radians];
    [self.inputDrawer scaleX:isFront ? -self.extraScaleRatio * scaleX : self.extraScaleRatio * scaleX scaleY : self.extraScaleRatio * scaleY];
    if (!self.inputFBO) {
        self.inputFBO = [[BMWFramebuffer alloc] initWithSize:outputSize imageContext:self.imageContext];
    }
    [self.inputFBO bind];
    [self.inputDrawer draw];
    self.outputFBO = self.inputFBO;
    textureId = self.inputFBO.texture;
    GLint inputTextureId = textureId;

    // light detect
    [self luminanceDectect];

    // draw beauty if needed(front && at least one intensity > 0)
//    if (self.effectType == BMWEffectTypeFront && self.needBeautyRender) {
//        [self buildBeautyRender];
//        textureId = [self.beautyRender processTexture:textureId inputSize:outputSize frameTime:frameTime];
//    }

    // draw filter if needed
    if (fabsf(self.fliterDrawer.brightnessIntensity) > 1e-4 ||
        self.fliterDrawer.lutIntensity > 0.0 ||
        self.fliterDrawer.toneCurveIntensity > 0.0 ||
        self.fliterDrawer.lumMaskCurveIntensity > 0.0) {
        if (!self.fliterFBO) {
            self.fliterFBO = [[BMWFramebuffer alloc] initWithSize:outputSize imageContext:self.imageContext];
        }
        if (self.lutPath.length > 0 && self.lutDirty) {
            UIImage *lutImage = [UIImage imageWithContentsOfFile:self.lutPath];
            if(lutTexId > 0) glDeleteTextures(1, &lutTexId);
            lutTexId = [BMWGLUtils setupTexture:lutImage];
            [self.fliterDrawer setLutTexId:lutTexId];
            [self.fliterDrawer setLutIntensity:lutTexId > 0 ? self.lutIntensity : 0];
//            self.lutPath = nil;
            self.lutDirty = NO;
        }
        [self.fliterDrawer setInputTexId:textureId];
        [self.fliterFBO bind];
        [self.fliterDrawer draw];
        self.outputFBO = self.fliterFBO;
        textureId = self.fliterFBO.texture;
    }

    // draw unsharpMask if needed
    if (self.effectType != BMWEffectTypeOriginalWithoutSharpen &&
        self.effectType != BMWEffectTypeFront) {
        if (!self.unsharpMaskFBO) {
            self.unsharpMaskFBO = [[BMWFramebuffer alloc] initWithSize:outputSize imageContext:self.imageContext];
        }
        [self.unsharpMaskDrawer setInputTexId:textureId tex2Id:inputTextureId];
        [self.unsharpMaskDrawer setInputSize:outputSize];
        [self.unsharpMaskFBO bind];
        [self.unsharpMaskDrawer draw];
        self.outputFBO = self.unsharpMaskFBO;
        textureId = self.unsharpMaskFBO.texture;
    }
    // 处理画中画
    if(pipCameraFrame) {
        CGSize size = self.outputFBO.bufferSize;
        float pipOffsetX = PIP_OFFSET_X * size.width;
        float pipOffsetY = PIP_OFFSET_Y * PIP_RATIO * size.height;
        float w = PIP_SCALE * size.width;
        float h = w / PIP_RATIO;
        float x = size.width - pipOffsetX - w;
        float y = size.height - pipOffsetY - h;
        float pipOutputRatio = w / h;
        float pipInputRatio = outputRatio;
        float scaleX2 = 1.0f;
        float scaleY2 = 1.0f;
        if (pipInputRatio > pipOutputRatio) {
            scaleX2 = pipInputRatio / pipOutputRatio;
        } else if (pipOutputRatio > pipInputRatio) {
            scaleY2 = pipOutputRatio / pipInputRatio;
        }
        [self.pipInputDrawer setInputPixelBuffer:pipCameraFrame];
        [self.pipInputDrawer resetMatrix];
        [self.pipInputDrawer rotateZ:radians];
        [self.pipInputDrawer scaleX:!isFront ? -self.extraScaleRatio * scaleX * scaleX2 : self.extraScaleRatio * scaleX * scaleX2 scaleY : self.extraScaleRatio * scaleY *scaleY2];
        [self.outputFBO bind];

        if (pipOrientation == BMWDeviceOrientationPortait) {
            glViewport(pipOffsetX, pipOffsetY, w, h);
        } else if (pipOrientation == BMWDeviceOrientationRight) {
            glViewport(pipOffsetX, y, w, h);
        } else if (pipOrientation == BMWDeviceOrientationDown) {
            glViewport(x, y, w, h);
        } else if (pipOrientation == BMWDeviceOrientationLeft) {
            glViewport(x, pipOffsetY, w, h);
        }
        [self.pipInputDrawer setBorder:CGSizeMake(h, w) radius:w*PIP_RADIUS borderWidth:w*PIP_BORDER borderColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];
        [self.pipInputDrawer draw];
    }
    self.faceCount = 0;
    return textureId;
}

- (GLuint)processWithExtraScaleRatio:(CGFloat)factor {
    if (CGSizeEqualToSize(self.outputFBO.bufferSize, CGSizeZero) || factor <= 1.0) {
        return self.outputFBO.texture;
    }
    if (!self.scaleExtraRatioFBO || !CGSizeEqualToSize(self.scaleExtraRatioFBO.bufferSize, self.outputFBO.bufferSize)) {
        [self.scaleExtraRatioFBO destroy];
        self.scaleExtraRatioFBO = [[BMWFramebuffer alloc] initWithSize:self.outputFBO.bufferSize imageContext:self.imageContext];
    }
    if (!self.scaleExtraRatioDrawer) {
        self.scaleExtraRatioDrawer = [[BMWBaseDrawer alloc] init];
    }
    [self.scaleExtraRatioFBO bind];
    [self.scaleExtraRatioDrawer resetMatrix];
    [self.scaleExtraRatioDrawer setInputTexId:self.outputFBO.texture];
    [self.scaleExtraRatioDrawer scaleX:factor scaleY:factor];
    [self.scaleExtraRatioDrawer draw];
    self.outputFBO = self.scaleExtraRatioFBO;
    return self.outputFBO.texture;
}

- (CVPixelBufferRef)getOutputPixelBuffer {
    return self.outputFBO.renderTarget;
}

#pragma mark - BMWRenderInterface

- (void)setDeviceOritaion:(BMWDeviceOrientation)orientation
{
    _deviceOrientation = orientation;
//    [_beautyRender setDeviceOritaion:orientation];
}

- (void)setRenderOutputSize:(CGSize)size
{
    _outputSize = size;
}

- (void)setBrightnessIntensity:(CGFloat)intensity
{
    _brightnessIntensity = intensity;
}

- (void)setEffectType:(BMWEffectType)type;
{
    _effectType = type;
}

+ (NSArray<BMWEffectTypeItem *>*)supportedEffects
{
    return NSMutableArray.new;
}

- (void)setEffectIntensity:(BMWEffectTypeItem *)item intensity:(float)intensity
{
    if ([item.catigory isEqualToString:@"beauty"]) {
//        [self.beautyRender setEffectIntensity:item intensity:intensity];
        self.beautyTypeDic[item.identifer] = item;
        self.beautyIntensityDic[item.identifer] = @(intensity);
        __block BOOL needed = NO;
//        [self.beautyIntensityDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull intensity, BOOL * _Nonnull stop) {
//            if (intensity.floatValue > 0) {
//                needed = YES;
//                *stop = YES;
//            }
//        }];
        self.needBeautyRender = needed;
    } else if ([item.catigory isEqualToString:@"lut"]) {
        self.lutPath = item.path;
        self.lutIntensity = intensity;
        self.lutDirty = YES;
    } else if ([item.catigory isEqualToString:@"brightness"]) {
        _brightnessIntensity = intensity;
    }
}

- (void)clearBuffer
{
    [self.inputFBO destroy];
    self.inputFBO = nil;
    [self.unsharpMaskFBO destroy];
    self.unsharpMaskFBO = nil;
    [self.scaleExtraRatioFBO destroy];
    self.scaleExtraRatioFBO = nil;
    [self.fliterFBO destroy];
    self.fliterFBO = nil;
    [self.imageContext flush];
}

- (void)reset
{
    BMWMLogM(@"BMWFrameRender reset...");
    [self.inputFBO destroy];
    self.inputFBO = nil;
    [self.unsharpMaskFBO destroy];
    self.unsharpMaskFBO = nil;
    [self.scaleExtraRatioFBO destroy];
    self.scaleExtraRatioFBO = nil;
    [self.fliterFBO destroy];
    self.fliterFBO = nil;

    [self.scaleExtraRatioDrawer destory];
    self.scaleExtraRatioDrawer = nil;
    [self.inputDrawer destory];
    self.inputDrawer = nil;
    [self.pipInputDrawer destory];
    self.pipInputDrawer = nil;
    [self.fliterDrawer destory];
    self.fliterDrawer = nil;
    [self.unsharpMaskDrawer destory];
//    [self.beautyRender reset];
//    self.beautyRender = nil;

    if (lutTexId > 0) {
        glDeleteTextures(1, &lutTexId);
        lutTexId = 0;
    }

    if (lummasktoneTexId > 0) {
        glDeleteTextures(1, &lummasktoneTexId);
        lummasktoneTexId = 0;
    }

    if (toneTexId > 0) {
        glDeleteTextures(1, &toneTexId);
        toneTexId = 0;
    }
    [self.imageContext flush];
    self.inited = NO;
}

- (void)setExtraScaleRatio:(CGFloat)factor
{
    _extraScaleRatio = factor;
}

- (UIImage *)outputImage
{
    return [self.outputFBO imageFromFramebufferContent];
}

- (BOOL)needBeautyRender
{
    return _needBeautyRender ;
}

#pragma mark - Utils

- (UIImage*)originalLutImage
{
    NSString *bundlePath = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:@"CCameraLib.bundle"];
    NSString *originalFilterPath = [bundlePath stringByAppendingPathComponent:@"cc_filter_alpha2.png"];
    UIImage *lutImage = [UIImage imageWithContentsOfFile:originalFilterPath];
    return lutImage;
}

- (void)triggerLuminanceDetect:(BOOL)enable
{
    _enableLuminanceDetect = enable;
    _luminance = -1;
}

- (void)luminanceDectect
{
    if(!self.enableLuminanceDetect) {
        return;
    }
    _enableLuminanceDetect = NO;
    double currentTimestamp = CACurrentMediaTime();
    BMWBaseDrawer *scaledDrawer = [[BMWBaseDrawer alloc] init];
    BMWFramebuffer *scaledFBO = [[BMWFramebuffer alloc] initWithSize:CGSizeMake(16,16) imageContext:self.imageContext];
    [scaledFBO bind];
    [scaledDrawer drawWithTexId:self.inputDrawer.inputImageTextureId];
    glFinish();

    CVPixelBufferRef buffer = scaledFBO.renderTarget;
    CVPixelBufferLockBaseAddress(buffer, 0);
    unsigned char* pixelData = (unsigned char *)CVPixelBufferGetBaseAddress(buffer);
    int width = (int)CVPixelBufferGetWidth(buffer);
    int height = (int)CVPixelBufferGetHeight(buffer);
    int stride = (int)CVPixelBufferGetBytesPerRow(buffer);
    uint64_t luminance = 0;
    for (int row = 0; row < height; row++) {
        for (int col = 0; col < width; col++) {
            int i = row * stride + 4 * col;
            // BGRA
            int r = pixelData[i+2];
            luminance+=r;
        }
    }
    self.luminance = (CGFloat)luminance / (width * height);
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    [scaledDrawer destory];
    [scaledFBO destroy];
    double end = CACurrentMediaTime();
    // BMWMLog(@"luminanceDectect timecost:%lfms, luminance:%lf", (end - currentTimestamp) * 1000, self.luminance);
}

- (UIImage*)renderPreview:(BOOL)isMirror outputSize:(CGSize)outputSize orientation:(BMWDeviceOrientation)orientation
{
    BMWBaseDrawer *inputDrawer = [BMWBaseDrawer new];
    [inputDrawer setInputTexId:self.outputFBO.texture];
    [inputDrawer resetMatrix];
    CGSize size = self.outputFBO.bufferSize;
    if(!CGSizeEqualToSize(CGSizeZero, outputSize)) {
        size = outputSize;
    }
    if (orientation == BMWDeviceOrientationPortait) {
        [inputDrawer rotateZ:0];
    } else if (orientation == BMWDeviceOrientationRight) {
        [inputDrawer rotateZ:M_PI_2];
        size = CGSizeMake(size.height, size.width);
    } else if (orientation == BMWDeviceOrientationDown) {
        [inputDrawer rotateZ:M_PI];
    } else if (orientation == BMWDeviceOrientationLeft) {
        [inputDrawer rotateZ:-M_PI_2];
        size = CGSizeMake(size.height, size.width);
    }
    BMWFramebuffer* previewFBO = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.imageContext];
    previewFBO.tag = @"previewFBO";
    [inputDrawer scaleX:isMirror ? -1.0f : 1.0f scaleY:1.0f];
    [previewFBO bind];
    [inputDrawer draw];
    glFinish();
    UIImage *image = previewFBO.imageFromFramebufferContent;
    [inputDrawer destory];
    [previewFBO destroy];
    return image;
}
@end
