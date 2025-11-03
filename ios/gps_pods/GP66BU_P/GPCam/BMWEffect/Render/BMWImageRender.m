#import "BMWImageRender.h"
#import "BMWDeviceUtils.h"
#import "BMWGLUtils.h"
#import "BMWBufferUtils.h"
#import "BMWRenderDefine.h"
#import "BMWWatermarkItem.h"
#import "GPCamDefine.h"
#import "BMWToneCurveData.h"
#import "BMWFramebuffer.h"
#import "BMWWatermarkBufferCache.h"
#import "NightMode.h"
#if CVAlgorithmgEnable
#import "BMWZeroDCE.h"
#endif
#import "BMWInputDrawer.h"
#import "BMWPipInputDrawer.h"
#import "BMWFliterDrawer.h"
#import "BMWUnsharpMaskDrawer.h"
#import "BMWSharpenDrawer.h"
#import "BMWNightModeDrawer.h"
#import "BMWWatermarkDrawer.h"
#import "BMWWatermarkExtractor.h"
#import "BMWWatermarkEmbeder.h"
#import "BMWSliceImageProcessor.h"
#import "BMWALifeCycleHelper.h"
#import "GPCamConfigurator.h"
#import "BMWSimilarityDetector.h"
#import "BMWClarityDetector.h"
#import "BMWAlgorithmUtils.h"
#import "UIView+GPCam.h"
#import "BMWImageQualityAlgorithm.h"

@interface BMWImageRender ()

@property (nonatomic) BMWImageContext *imageContext;
@property (nonatomic) BMWFramebuffer *outputImageBuffer;
@property (nonatomic) BMWEffectType effectType;
@property (nonatomic) BMWDeviceOrientation deviceOrientation;

@property (nonatomic) CGFloat extraScaleRatio;
@property (nonatomic) BOOL needBeautyRender;
@property (nonatomic) CMTime imageTimestamp;

@property (nonatomic) float outputWidth;
@property (nonatomic) float outputHeight;

@property (nonatomic) NSString *lutPath;
@property (nonatomic) CGFloat lutIntensity;
@property (nonatomic) CGFloat brightnessIntensity;

@property (nonatomic) NightMode* nightMode;
#if CVAlgorithmgEnable
@property (nonatomic) BMWZeroDCE* nightMode2;
#endif
@property (nonatomic) NightModeOutput *nightModeOutput;

@property (nonatomic) NSMutableDictionary<NSString*, BMWEffectTypeItem* >* beautyTypeDic;
@property (nonatomic) NSMutableDictionary<NSString*, NSNumber*>* beautyIntensityDic;

@property (nonatomic) BMWBlindWatermarkModel *blindWmModel;
@property (nonatomic) BMWWatermarkEmbeder *watermarkEmbeder;

@property (nonatomic) BMWClarityOptStatus shouldClarityOpt;

@property (nonatomic) UIImage *previewImage;
@property (nonatomic) BMWOrginalMetaData *orginalMetaData;
@property (nonatomic) BMWWatermarkBufferCache *watermarkBufferCache;

@property (nonatomic, copy) NSArray<BMWWatermarkInfoV2 *> *watermarkInfoV2s;

@property (nonatomic) BMWImageQualityAlgorithm* imageQualityAlgorithm;

@end

@implementation BMWImageRender

- (void)dealloc
{
    BMWMLogM(@"BMWImageRender dealloc...");
}

- (instancetype)initWithContext:(BMWImageContext *)imageContext
{
    self = [super init];
    if (self) {
        self.imageContext = imageContext;
        self.brightnessIntensity = 0.0;
        self.effectType = BMWEffectTypeOriginalWithoutSharpen;
        self.watermarkBufferCache = [BMWWatermarkBufferCache new];
        self.beautyTypeDic = NSMutableDictionary.new;
        self.beautyIntensityDic = NSMutableDictionary.new;
        self.extraScaleRatio = 1.0;
        self.imageQualityAlgorithm = [[BMWImageQualityAlgorithm alloc] init];
    }
    return self;
}

- (void)buildBeautyRender
{

}

- (void)processOrginalWithPixelbuffer:(void (^)(BMWOrginalRenderModel *model))builder block:(void (^)(UIImage *_Nullable image, BMWOrginalMetaData *orginalMetaData, NSError *_Nullable error))block
{
    BMWOrginalRenderModel *model = [[BMWOrginalRenderModel alloc] init];
    SafeBlock(builder, model);
    !model.pixelBuffer ? : CVPixelBufferRetain(model.pixelBuffer);
    runAsynchronouslyOnContextQueue(self.imageContext, ^{
        [self.imageContext useAsCurrentContext];
        [self _processOrginalWithPixelbuffer:model block:block];
        !model.pixelBuffer ? : CVPixelBufferRelease(model.pixelBuffer);
    });
}

- (void)_processOrginalWithPixelbuffer:(BMWOrginalRenderModel *)model block:(void (^)(UIImage *_Nullable image, BMWOrginalMetaData *orginalMetaData, NSError *_Nullable error))block;
{
    CFTimeInterval startTime = CACurrentMediaTime();
    CVPixelBufferRef pixelBuffer = model.pixelBuffer;
    CVPixelBufferRef maskPixelBuffer = model.maskPixelBuffer;
    self.previewImage = model.previewImage;

    NSError* error = NULL;
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    OSType format = CVPixelBufferGetPixelFormatType(pixelBuffer);

    int inputWidth = width;
    int inputHeight = height;
    if (_deviceOrientation == BMWDeviceOrientationDown ||
        _deviceOrientation == BMWDeviceOrientationPortait) {
        inputWidth = height;
        inputHeight = width;
    }
    // draw input
    BOOL useYUV = format != 'BGRA';
    BMWBaseDrawer *inputDrawer = nil;
    GLint nightmodeTextureId = 0;
    CVPixelBufferRef nightModePixelBuffer = nil;
    if (!self.enableNightMode) {
        inputDrawer = [[BMWInputDrawer alloc] initWithContext:self.imageContext useYUV:useYUV];
        [(BMWInputDrawer*)inputDrawer setInputPixelBuffer:pixelBuffer];
        [(BMWInputDrawer*)inputDrawer setMaskPixelBuffer:maskPixelBuffer];
    } else {
        CFTimeInterval startTime = CACurrentMediaTime();
        nightModePixelBuffer = [BMWBufferUtils createResizedSampleBuffer:pixelBuffer size:CGSizeMake(128, 128)];

        NSUInteger nightModeVer = GPCamConfigurator.sharedInstance.nightModeVer;
#if !CVAlgorithmgEnable
        nightModeVer = 1;
#endif
        if ((nightModeVer == 1) ||
            @available(iOS 12.0, *)) {
            self.nightMode = [NightMode new];
            self.nightModeOutput = [self.nightMode predictionFromInputImage:nightModePixelBuffer error:&error];
            nightmodeTextureId = [BMWGLUtils createTextureWithBuffer:self.nightModeOutput.output context:self.imageContext];
        } else {
#if CVAlgorithmgEnable
            self.nightMode2 = [BMWZeroDCE new];
            nightmodeTextureId = [self.nightMode2 detect:nightModePixelBuffer error:nil];
#endif
        }
        CFTimeInterval endTime = CACurrentMediaTime();
                inputDrawer = [[BMWNightModeDrawer alloc] initWithContext:self.imageContext useYUV:useYUV];
        [(BMWNightModeDrawer*)inputDrawer setInputPixelBuffer:pixelBuffer];
        [(BMWNightModeDrawer*)inputDrawer setMaskTexId:nightmodeTextureId];
    }

    if (self.outputImageBuffer == nil) {
        self.outputImageBuffer = [[BMWFramebuffer alloc] initWithSize:CGSizeMake(self.outputWidth, self.outputHeight) imageContext:self.imageContext];
    }
    [self.outputImageBuffer bind];

    // ugly rotate && crop && mirror
    float inputRatio = inputWidth / (float)inputHeight;
    float outputRatio = _outputWidth / _outputHeight;
    float scaleX = 1.0f;
    float scaleY = 1.0f;
    if (inputRatio > outputRatio) {
        scaleX = inputRatio / outputRatio;
    } else if (outputRatio > inputRatio) {
        scaleY = outputRatio / inputRatio;
    }
    float radians = 0;
    if (self.deviceOrientation == BMWDeviceOrientationRight) {
        radians = M_PI_2;
    } else if (self.deviceOrientation == BMWDeviceOrientationDown) {
        radians = M_PI;
    } else if (self.deviceOrientation == BMWDeviceOrientationLeft) {
        radians = -M_PI_2;
    }
    [inputDrawer resetMatrix];
    [inputDrawer rotateZ:M_PI_2];
    [inputDrawer scaleX:_isFront ? -self.extraScaleRatio : self.extraScaleRatio scaleY:self.extraScaleRatio];
    [inputDrawer rotateZ:radians];
    [inputDrawer scaleX:!_isMirror ? scaleX : -scaleX scaleY:scaleY];
    [inputDrawer draw];

    // 处理画中画
    if(model.pipSampleBuffer) {
        CGSize size = self.outputImageBuffer.bufferSize;
        float ratio = size.width / size.height;
        float pipOffsetX = PIP_OFFSET_X * size.width;
        float pipOffsetY = PIP_OFFSET_Y * PIP_RATIO * size.height;
        float w = PIP_SCALE * size.width;
        float h = w / PIP_RATIO;
        if (self.deviceOrientation == BMWDeviceOrientationRight || self.deviceOrientation == BMWDeviceOrientationLeft) {
            h = PIP_SCALE * size.height;
            w = h / PIP_RATIO;
        }
        float pipOutputRatio = w / h;
        float pipInputRatio = outputRatio;
        float scaleX2 = 1.0f;
        float scaleY2 = 1.0f;
        if (pipInputRatio > pipOutputRatio) {
            scaleX2 = pipInputRatio / pipOutputRatio;
        } else if (pipOutputRatio > pipInputRatio) {
            scaleY2 = pipOutputRatio / pipInputRatio;
        }
        BMWPipInputDrawer *pipInputDrawer = [[BMWPipInputDrawer alloc] initWithContext:self.imageContext useYUV:useYUV];
        CVPixelBufferRef pipPixelBuffer = CMSampleBufferGetImageBuffer(model.pipSampleBuffer);
        [pipInputDrawer setInputPixelBuffer:pipPixelBuffer];
        [pipInputDrawer resetMatrix];
        [pipInputDrawer rotateZ:M_PI_2];
        [pipInputDrawer scaleX:!_isFront ? -self.extraScaleRatio : self.extraScaleRatio scaleY:self.extraScaleRatio];
        [pipInputDrawer rotateZ:radians];
        [pipInputDrawer scaleX:!_isMirror ? scaleX*scaleX2 : -scaleX * scaleX2 scaleY:scaleY * scaleY2];
        [pipInputDrawer setBorder:CGSizeMake(h, w) radius:w*PIP_RADIUS borderWidth:w*PIP_BORDER borderColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.5]];

        [self.outputImageBuffer bind];
        glViewport(pipOffsetX, pipOffsetY, w, h);

        [pipInputDrawer draw];
        [inputDrawer destory];
        CFRelease(model.pipSampleBuffer);
    }

    // 模糊度检测
    BMWOrginalMetaData *orginalMetaData = [[BMWOrginalMetaData alloc] init];
    if(model.clarityDetectMode == BMWClarityDetectModeOnline) {
        CGSize size = self.previewImage.size;
        CGFloat min = MIN(size.width, size.height);
        CGFloat ratio = 640 / min;
        size = CGSizeMake(size.width * ratio, size.height * ratio);
        BMWClarityDetector *detector = [[BMWClarityDetector alloc] initWithContext:self.imageContext];
        orginalMetaData.capturedClarity = [detector detectWithTexId:self.outputImageBuffer.texture texSize:size];
        orginalMetaData.previewClarity = [detector detectWithImage:self.previewImage texSize:size];
        if((orginalMetaData.previewClarity - orginalMetaData.capturedClarity > model.previewClarityOffsetForIOS) && model.clarityThreshold < orginalMetaData.previewClarity) {
            self.shouldClarityOpt = BMWClarityOptStatusCanOpt;
        } else {
            self.shouldClarityOpt = BMWClarityOptStatusCanNotOpt;
        }
    } else if(model.clarityDetectMode == BMWClarityDetectModeOffline) {
        self.shouldClarityOpt = BMWClarityOptStatusCanUnkown;
    } else {
        self.shouldClarityOpt = BMWClarityOptStatusCanNotOpt;
    }

//    // 图片质量检测
//    if(model.enableImageQualityDetect) {
//        BMWClarityDetector *detector = [[BMWClarityDetector alloc] initWithContext:self.imageContext];
//        orginalMetaData.imageQualityAlgorithmResult = [detector imageQualityDetectWithTexId:self.outputImageBuffer.texture];
//    }

    // 相似度检查
    if(model.enableSimilarityCheck) {
        BMWSimilarityDetector *detector = [[BMWSimilarityDetector alloc] initWithContext:self.imageContext];
        orginalMetaData.previewCapturedSimilarity = [detector detect:self.previewImage capturedTexId:self.outputImageBuffer.texture CGSize:self.outputImageBuffer.bufferSize];
    }

    self.orginalMetaData = orginalMetaData;

    glFinish();
    UIImage *image = [self.outputImageBuffer imageFromFramebufferContent];

    // release
    [inputDrawer destory];
    self.nightMode = nil;
    self.nightModeOutput = nil;
#if CVAlgorithmgEnable
    self.nightMode2 = nil;
#endif
    !nightModePixelBuffer ? : CVPixelBufferRelease(nightModePixelBuffer);
    if (nightmodeTextureId > 0) {
        glDeleteTextures(1, &nightmodeTextureId);
    }

    // check and callback
    if (image == nil) {
        NSDictionary *userinfo = [NSDictionary dictionaryWithObjectsAndKeys:@"图片为空，返回", NSLocalizedDescriptionKey, [NSMutableString stringWithFormat:@"失败原因:图片创建失败 %d", __LINE__], NSLocalizedFailureReasonErrorKey, nil];
        error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:GPCamTakePhotoImageCreateError userInfo:userinfo];
    }

    CFTimeInterval endTime = CACurrentMediaTime();
        SafeBlock(block, image, orginalMetaData, error);
}

- (void)processImageWithOriginal:(void (^)(BMWProcessRenderModel *model))builder textureBlock:(void (^ _Nullable )(GLuint textId, NSError *_Nullable error))textureBlock imageBlock:(void (^ _Nullable )(UIImage *_Nullable processedImage, BMWPocessedMetaData *pocessedMetaData, NSError *_Nullable error))imageBlock
{
    BMWProcessRenderModel *model = [[BMWProcessRenderModel alloc] init];
    SafeBlock(builder, model);
    runOnContextQueue(model.sync, self.imageContext, ^{
        [self.imageContext useAsCurrentContext];
        [self _processImageWithOriginal:model textureBlock:textureBlock imageBlock:imageBlock];
    });
}

/**
 case 1: 正常拍照，model.image  ==  nil, self.outputImageBuffer != nil, model.inEditMode == NO
 case 2: 截图拍照，model.image  !=  nil, self.outputImageBuffer == nil, model.inEditMode == NO
 case 3: 编辑，       model.image  !=  nil, self.outputImageBuffer == nil, model.inEditMode == YES
 */
- (void)_processImageWithOriginal:(BMWProcessRenderModel *)model textureBlock:(void (^ _Nullable )(GLuint textId, NSError *_Nullable error))textureBlock imageBlock:(void (^ _Nullable )(UIImage *_Nullable processedImage, BMWPocessedMetaData *pocessedMetaData, NSError *_Nullable error))imageBlock
{
    CFTimeInterval startTime = CACurrentMediaTime();
    BMWPocessedMetaData *pocessedMetaData = [[BMWPocessedMetaData alloc] init];
    NSArray<BMWWatermarkItem*>* watermarks = model.watermarks;

    if(self.outputImageBuffer == nil && model.image  ==  nil) {
        NSError *error = [[NSError alloc] initWithDomain:@"self.outputImageBuffer == nil && model.image  == nil" code:-1 userInfo:nil];
        SafeBlock(textureBlock, INVALID_TEXTURE, error);
        SafeBlock(imageBlock, nil, nil, error);
        return;
    }

    // model.image的优先级高
    CGSize curFrameSize = self.outputImageBuffer.bufferSize;
    int width = curFrameSize.width;
    int height = curFrameSize.height;
    GLuint inputPicTexureId = self.outputImageBuffer.texture;
    if(model.image) {
        width = (int)CGImageGetWidth(model.image.CGImage);
        height = (int)CGImageGetHeight(model.image.CGImage);
        curFrameSize = CGSizeMake(width, height);
        inputPicTexureId = [BMWGLUtils setupTexture:model.image redraw:model.redrawImage];
    }
    // model.effectType优先级高于self.effectType
    BMWEffectType currentEffectType = model.effectType != BMWEffectTypeUnknown ? model.effectType: self.effectType;
    if (currentEffectType == BMWEffectTypeNightMode) {
        currentEffectType = BMWEffectTypeOriginalWithoutSharpen;
    }

    // init drawer
    BMWFliterDrawer *fliterDrawer = [BMWFliterDrawer new];
    BMWUnsharpMaskDrawer *unsharpMaskDrawer = [BMWUnsharpMaskDrawer new];
    BMWWatermarkDrawer *watermarkDrawer = [[BMWWatermarkDrawer alloc] initWithContext:self.imageContext];

    // config fliter
    GLuint lummasktoneTextureId = [[BMWToneCurveData alloc] initWithName:@"light11"].getTexId;
    GLuint toneTextureId = [[BMWToneCurveData alloc] initWithName:@"color22"].getTexId;
    UIImage *lutImage = [UIImage imageWithContentsOfFile:self.lutPath];
    GLuint lookupTextureId = [BMWGLUtils setupTexture:lutImage];
    [fliterDrawer setLumMaskCurveTexId:lummasktoneTextureId];
    [fliterDrawer setToneCurveTextId:toneTextureId];
    [fliterDrawer setLutTexId:lookupTextureId];

    // config watermark
    for (BMWWatermarkItem* watermark in watermarks) {
        // config watermark
        __block GLuint watermarkTexId = 0;
        if (watermark && watermark.water && !watermark.hidden) {
            if(watermark.locationRect) {
                pocessedMetaData.locationRect = watermark.locationRect;
            }
            if(watermark.timeRects) {
                pocessedMetaData.timeRects = watermark.timeRects;
            }
            if (watermark.buffer) {
                watermarkTexId = watermark.buffer.genTexture;
            } else {
                [self.watermarkBufferCache popWatermarkSync:watermark buffer:^(BMWWatermarkBuffer * _Nonnull buffer) {
                    watermarkTexId = buffer.genTexture;
                    if (watermark.cacheBuffer) {
                        watermark.buffer = buffer;
                    }
                }];
            }
            // 如果失败了，尝试同步读取
            if(watermarkTexId == 0) {
                SafeBlock(watermark.beginCapture);
                watermark.beginCapture = nil;
                if(watermark.highResolution && !BMWALifeCycleHelper.sharedInstance.appInBackground) {
                    watermarkTexId = [BMWGLUtils createTextureWithWatermark:watermark];
                } else {
                    watermarkTexId = [BMWGLUtils createTextureWithLayer:watermark.waterLayer scale:watermark.scale];
                }
            }
            if(watermarkTexId == 0) {
                                continue;
            }
            CGRect rect = CGRectMake(watermark.x,
                                     watermark.y,
                                     watermark.w,
                                     watermark.h);
            NSString *tag = [NSString stringWithFormat:@"%lu", watermark.tag];
            BMWWatermarkInfo *info = [BMWWatermarkInfo buildInfo:tag texId:watermarkTexId rect:rect deviceOrientation:watermark.deviceOrientation];
            [watermarkDrawer updateWatermark:info];
        }
    }

    // config intensity
    CGSize filterFBOSize = CGSizeMake(self.outputWidth, self.outputHeight);
    CGSize unsharpMaskFBOSize = curFrameSize;
    CGFloat sharpnessIntensity = SHARPEN_INTENSITY;
    if (GPCamConfigurator.sharedInstance.cameraSharpnessConfig.enable &&
        GPCamConfigurator.sharedInstance.cameraSharpnessConfig.minAppVersion <= GPCamConfigurator.sharedInstance.versionCode) {
        sharpnessIntensity = GPCamConfigurator.sharedInstance.cameraSharpnessConfig.captureSharpnessIntensity;
    }
    GLint textureId = inputPicTexureId;
    if (self.ignoreFilter) {
        [fliterDrawer setBrightnessIntensity:0.0];
        [fliterDrawer setLutIntensity:0.0];
        [fliterDrawer setToneCurveIntensity:0.0];
        [fliterDrawer setLumMaskCurveIntensity:0.0];
        [unsharpMaskDrawer setIntensity:0.0 saturation:1.0];
        unsharpMaskFBOSize = CGSizeMake(self.outputWidth, self.outputHeight);
    } else if (currentEffectType == BMWEffectTypeFront) {
        [fliterDrawer setBrightnessIntensity:self.brightnessIntensity];
        [fliterDrawer setLutIntensity:self.lutIntensity];
        [fliterDrawer setToneCurveIntensity:0.0];
        [fliterDrawer setLumMaskCurveIntensity:0.0];
        [unsharpMaskDrawer setIntensity:0.0 saturation:1.0];
    }
    else if (currentEffectType == BMWEffectTypeOriginalWithoutSharpen) {
        [fliterDrawer setBrightnessIntensity:self.brightnessIntensity];
        [fliterDrawer setLutIntensity:0.0];
        [fliterDrawer setToneCurveIntensity:0.0];
        [fliterDrawer setLumMaskCurveIntensity:0.0];
        [unsharpMaskDrawer setIntensity:0.0 saturation:1.0];
    }
    else if (currentEffectType == BMWEffectTypeOriginal) {
        [fliterDrawer setBrightnessIntensity:self.brightnessIntensity];
        [fliterDrawer setLutIntensity:0.0];
        [fliterDrawer setToneCurveIntensity:0.0];
        [fliterDrawer setLumMaskCurveIntensity:0.0];
        [unsharpMaskDrawer setIntensity:sharpnessIntensity saturation:1.0];
        unsharpMaskFBOSize = CGSizeMake(self.outputWidth, self.outputHeight);
    }
    else if (currentEffectType == BMWEffectTypeBackWithTone) {
        [fliterDrawer setBrightnessIntensity:self.brightnessIntensity];
        if(model.enableTextFilter) {
            [fliterDrawer setLutIntensity:0.4];
            [fliterDrawer setToneCurveIntensity:1.0];
            [fliterDrawer setLumMaskCurveIntensity:0.0];
            [unsharpMaskDrawer setIntensity:1.4 saturation:1.05];
        } else {
            [fliterDrawer setLutIntensity:self.lutIntensity];
            [fliterDrawer setToneCurveIntensity:1.0];
            [fliterDrawer setLumMaskCurveIntensity:1.0];
            [unsharpMaskDrawer setIntensity:sharpnessIntensity saturation:SATURATION_INTENSITY];
        }
        filterFBOSize = curFrameSize;
        unsharpMaskFBOSize = CGSizeMake(self.outputWidth, self.outputHeight);
    }
    else { //原图和不加曲线的case
        [fliterDrawer setBrightnessIntensity:self.brightnessIntensity];
        [fliterDrawer setLutIntensity:self.lutIntensity];
        [fliterDrawer setToneCurveIntensity:0.0];
        [fliterDrawer setLumMaskCurveIntensity:0.0];
        [unsharpMaskDrawer setIntensity:sharpnessIntensity saturation:SATURATION_INTENSITY];
        filterFBOSize = curFrameSize;
        unsharpMaskFBOSize = CGSizeMake(self.outputWidth, self.outputHeight);
    }

    // draw beauty
    BMWFramebuffer *outputFramebuffer = nil;
    if (currentEffectType == BMWEffectTypeFront && self.needBeautyRender && !self.ignoreBeauty) {

    }
    // draw filter 强制走
    BMWFramebuffer *fliterFBO = [[BMWFramebuffer alloc] initWithSize:filterFBOSize imageContext:self.imageContext];
    [fliterDrawer setInputTexId:textureId];
    [fliterFBO bind];
    [fliterDrawer draw];
    outputFramebuffer = fliterFBO;
    textureId = fliterFBO.texture;

    // draw unsharpMask
    BMWFramebuffer *unsharpMaskFBO = nil;
    if (currentEffectType != BMWEffectTypeOriginalWithoutSharpen &&
        currentEffectType != BMWEffectTypeFront) {
        unsharpMaskFBO = [[BMWFramebuffer alloc] initWithSize:unsharpMaskFBOSize imageContext:self.imageContext];
        [unsharpMaskDrawer setInputTexId:textureId tex2Id:inputPicTexureId];
        [unsharpMaskDrawer setInputSize:curFrameSize];
        [unsharpMaskFBO bind];
        [unsharpMaskDrawer draw];
        textureId = unsharpMaskFBO.texture;
        outputFramebuffer = unsharpMaskFBO;
    }

    // 获取加水印前的小图
    if(self.enableSliceImage) {
        NSArray<BMWRect *> *extraSliceRects = @[];
        if (model.extraSliceRectsBlock != nil) {
            extraSliceRects = model.extraSliceRectsBlock();
        }
        [self processSliceImage:textureId texSize:outputFramebuffer.bufferSize watermarks:watermarks extraSliceRects:extraSliceRects pocessedMetaData:pocessedMetaData];
    }

    // 画中画当作水印来处理
    BMWFramebuffer *passthroughBuffer = nil;
    NSArray<BMWWatermarkInfo*>* pipWatermarks = [watermarkDrawer findWatermrkWithTag: @(BMWWatermarkTagPiP).stringValue];
    for (BMWWatermarkInfo* info in pipWatermarks) {
        // TODO 只构造一个pip纹理,先假定第一个watermark能满足所有诉求
        if(passthroughBuffer == nil) {
            BMWBaseDrawer *passthroughDrawer = [[BMWBaseDrawer alloc] init];
            passthroughBuffer = [[BMWFramebuffer alloc] initWithSize:CGSizeMake(outputFramebuffer.bufferSize.width * info.rect.size.width, outputFramebuffer.bufferSize.height * info.rect.size.height) imageContext:self.imageContext];
            [passthroughBuffer bind];
            [passthroughDrawer drawWithTexId:outputFramebuffer.texture];
            [passthroughDrawer destory];
        }
        info.texId = passthroughBuffer.texture;
    }

    [watermarkDrawer updateWatermarkV2s:self.watermarkInfoV2s];

    // draw watermark
    if (watermarks.count > 0 || self.watermarkInfoV2s.count > 0) {
        [outputFramebuffer bind];
        [watermarkDrawer draw];
    }
    SafeBlock(textureBlock, outputFramebuffer.texture, nil);

    UIImage *processedImage = nil;
    // draw blind watermark if need
    if (self.blindWmModel) {
        double blindWatermarkStart = CACurrentMediaTime();
        if(GPCamConfigurator.sharedInstance.smoothPreviewTakingImage == 1) {
            self.watermarkEmbeder = [[BMWWatermarkEmbeder alloc] init:self.imageContext];
            [self.watermarkEmbeder updateWmModel:self.blindWmModel];
        }
        [self.watermarkEmbeder embeded:outputFramebuffer.texture texSize:CGSizeMake(_outputWidth, _outputHeight) sliceEmbedCallback:^(CGRect sliceRect) {
            [outputFramebuffer bind];
            int x = sliceRect.origin.x * _outputWidth + 0.5;
            int y = sliceRect.origin.y * _outputHeight + 0.5;
            int width = sliceRect.size.width * _outputWidth + 0.5;
            int height = sliceRect.size.height * _outputHeight + 0.5;
            glViewport(x, y, width, height);
        }];
        if(GPCamConfigurator.sharedInstance.smoothPreviewTakingImage == 1) {
            [self.watermarkEmbeder destory];
            self.watermarkEmbeder = nil;
        }
        double blindWatermarkEnd = CACurrentMediaTime();
            }
    if(model.enableImageFeature) {
        double begin = CACurrentMediaTime();
        BMWBaseDrawer *scaledDrawer = [[BMWBaseDrawer alloc] init];
        BMWFramebuffer *scaledBuffer = [[BMWFramebuffer alloc] initWithSize:CGSizeMake(20,20) imageContext:self.imageContext];
        [scaledBuffer bind];
        [scaledDrawer drawWithTexId:outputFramebuffer.texture];
        glFinish();
        pocessedMetaData.imageFeature = [BMWImageProcessUtils imageEncode:scaledBuffer.renderTarget];
        [scaledDrawer destory];
        [scaledBuffer destroy];
        double end = CACurrentMediaTime();
            }

    glFinish();
    processedImage = [outputFramebuffer imageFromFramebufferContent];

    // release
    if (inputPicTexureId > 0) {
        glDeleteTextures(1, &inputPicTexureId);
    }
    if (lookupTextureId > 0) {
        glDeleteTextures(1, &lookupTextureId);
    }
    if (lummasktoneTextureId > 0) {
        glDeleteTextures(1, &lummasktoneTextureId);
    }
    if (toneTextureId > 0) {
        glDeleteTextures(1, &toneTextureId);
    }
    [passthroughBuffer destroy];
    [watermarkDrawer destory];
    [fliterDrawer destory];
    [unsharpMaskDrawer destory];
    [unsharpMaskFBO destroy];
    [fliterFBO destroy];
    [self.watermarkBufferCache clear:watermarks];
    CFTimeInterval endTime = CACurrentMediaTime();

    NSError *error = nil;
    if (processedImage == nil) {
        NSDictionary *userinfo = [NSDictionary dictionaryWithObjectsAndKeys:@"图片为空，返回", NSLocalizedDescriptionKey, [NSMutableString stringWithFormat:@"失败原因:图片创建失败 %d", __LINE__], NSLocalizedFailureReasonErrorKey, nil];

        error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:GPCamTakePhotoImageCreateError userInfo:userinfo];
    }
    SafeBlock(imageBlock, processedImage, pocessedMetaData, error);
}

- (void)prepareWatermark:(BMWWatermarkItem *)watermark
{
    if (!watermark) return;
    if(!watermark.renderingSync) {
        SafeBlock(watermark.beginCapture);
        watermark.beginCapture = nil;
        [self.watermarkBufferCache pushWatermark:watermark];
    }
}

- (void)setTimestamp:(CMTime)timestamp
{
    self.imageTimestamp = timestamp;
}

- (void)setExtraScaleRatio:(CGFloat)factor
{
    _extraScaleRatio = factor;
}

#pragma mark - BMWRenderInterface

- (void)reset
{
    BOOL sync = GPCamConfigurator.sharedInstance.smoothPreviewTakingImage == 0;
    runOnContextQueue(sync, self.imageContext, ^{
        BMWMLogM(@"BMWImageRender reset...");
        [self.imageContext useAsCurrentContext];
        [self _reset];
    });
}

- (void)_reset
{
    if (self.outputImageBuffer) {
        [self.outputImageBuffer destroy];
        self.outputImageBuffer = nil;
    }

    [self.imageContext flush];
    self.ignoreBeauty = NO;
    self.ignoreFilter = NO;
    self.watermarkInfoV2s = nil;
}

- (void)setEffectType:(BMWEffectType)type
{
    _effectType = type;
}

- (void)setDeviceOritaion:(BMWDeviceOrientation)orientation
{
    _deviceOrientation = orientation;
}

- (void)setRenderOutputSize:(CGSize)size
{
    self.outputWidth = size.width;
    self.outputHeight = size.height;
    if(self.isLockLandscape) {
        float tmp = self.outputWidth;
        self.outputWidth = self.outputHeight;
        self.outputHeight = tmp;
    }
}

- (void)setBrightnessIntensity:(CGFloat)intensity
{
    _brightnessIntensity = intensity;
}

- (void)setEffectIntensity:(BMWEffectTypeItem *)item intensity:(float)intensity
{
    if ([item.catigory isEqualToString:@"beauty"]) {
        self.beautyTypeDic[item.identifer] = item;
        self.beautyIntensityDic[item.identifer] = @(intensity);
        __block BOOL needed = NO;
        [self.beautyIntensityDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull intensity, BOOL * _Nonnull stop) {
            if (intensity.floatValue > 0) {
                needed = YES;
                *stop = YES;
            }
        }];
        self.needBeautyRender = needed;
    } else if ([item.catigory isEqualToString:@"lut"]) {
        self.lutPath = item.path;
        self.lutIntensity = intensity;
    } else if ([item.catigory isEqualToString:@"brightness"]) {
        _brightnessIntensity = intensity;
    }
}

- (void)setBlindWatermarkModel:(BMWBlindWatermarkModel*)model
{
    if(GPCamConfigurator.sharedInstance.smoothPreviewTakingImage == 1) {
        self.blindWmModel = model;
        return;
    }
    if (self.blindWmModel != model) {
        self.blindWmModel = model;
        runAsynchronouslyOnContextQueue(self.imageContext, ^{
            [self.imageContext useAsCurrentContext];
            [self.watermarkEmbeder destory];
            self.watermarkEmbeder = nil;
            if (self.blindWmModel) {
                self.watermarkEmbeder = [[BMWWatermarkEmbeder alloc] init:self.imageContext];
                [self.watermarkEmbeder updateWmModel:self.blindWmModel];
            }
        });
    }
}

- (void)processSliceImage:(GLuint)textureId texSize:(CGSize)texSize watermarks:(NSArray<BMWWatermarkItem*>*)watermarks
          extraSliceRects:(NSArray<BMWRect*>*)extraSliceRects
         pocessedMetaData:(BMWPocessedMetaData*)pocessedMetaData
{
    // 获取加水印前的小图
    if (watermarks.count > 0) {
        BMWSliceImageProcessor *processor = [[BMWSliceImageProcessor alloc] initWithContext:self.imageContext];
        [processor processSlice:^(BMWSliceImageRequest * _Nonnull request) {
            request.scrId = textureId;
            request.texSize = texSize;
            NSMutableArray<BMWRect*> *tmp = [NSMutableArray array];
            for (BMWWatermarkItem *item in watermarks) {
                [tmp addObjectsFromArray:item.realWatermarkRectList];
            }
            CGRect cgrect = [BMWBlindWatermarkModel.defaultModel watermarkFullRectByRatio:request.texSize.width/request.texSize.height];
            [tmp addObject:BMWMakeRectFromCGRect(cgrect)];
            for (BMWRect* rect in extraSliceRects) {
                [tmp addObject:rect];
            }

            NSMutableArray<BMWRect*> *rectList = [NSMutableArray array];
            for (BMWRect* newRect in tmp) {
                BOOL ignored = NO;
                for (BMWRect* rect in rectList) {
                    if (rect.left <= newRect.left && rect.top <= newRect.top &&
                        rect.right >= newRect.right && rect.bottom >= newRect.bottom ) {
                        ignored = YES;
                        break;
                    }
                }
                if (!ignored) {
                    [rectList addObject:newRect];
                }
            }
            request.rectList = rectList;
        } completeBlock:^(BMWSliceImageReslut * _Nullable reslut) {
            pocessedMetaData.sliceDataModel = reslut.sliceDataModel;

            // 获取视觉上可以看到的水印rect,存到self.sliceDataModel.sliceDataList2
            NSMutableArray<BMWRect*>* tmp = [NSMutableArray array];
            for (BMWWatermarkItem *item in watermarks) {
                [tmp addObjectsFromArray:item.realWatermarkRectList2];
            }
            NSMutableArray<BMWSliceData*>* sliceDataList2 = [[NSMutableArray alloc] init];
            for (BMWRect* newRect in tmp) {
                BMWSliceData *sliceData = [BMWSliceData buildWithId:newRect.tag type:JpegDataOrgSlice data:nil rect:newRect];
                [sliceDataList2 addObject:sliceData];
            }
            pocessedMetaData.sliceDataModel.sliceDataList2 = sliceDataList2;
        }];

        if(self.shouldClarityOpt != BMWClarityOptStatusCanNotOpt) {
            [processor processClarityOptImage:self.previewImage completeBlock:^(BMWSliceImageReslut * _Nullable reslut) {
                if(!reslut.sliceDataModel.error) {
                    pocessedMetaData.sliceDataModel.clarityOpt = self.shouldClarityOpt;
                };
                [pocessedMetaData.sliceDataModel append:reslut.sliceDataModel];
            }];
            pocessedMetaData.sliceDataModel.previewClarity = self.orginalMetaData.previewClarity;
            pocessedMetaData.sliceDataModel.capturedClarity = self.orginalMetaData.capturedClarity;
        }
    }
}

- (UIImage*)originalLutImage
{
    NSString *bundlePath = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:@"CCameraLib.bundle"];
    NSString *originalFilterPath = [bundlePath stringByAppendingPathComponent:@"cc_filter_alpha2.png"];
    UIImage *lutImage = [UIImage imageWithContentsOfFile:originalFilterPath];
    return lutImage;
}

- (void)updateWatermarkInfoV2s:(NSArray<BMWWatermarkInfoV2 *> *)watermarkInfos
{
    self.watermarkInfoV2s = watermarkInfos;
}

@end
