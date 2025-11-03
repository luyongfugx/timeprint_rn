#import "BMWCamera.h"
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import "BMWAudioKit.h"
#import "BMWGLView.h"
#import "BMWCameraWriter.h"
#import "BMWImageContext.h"
#import "BMWDeviceUtils.h"
#import "BMWImageContext.h"
#import "BMWGLUtils.h"
#import "BMWToneCurveData.h"
#import "BMWBufferUtils.h"
#import "BMWFrameRender.h"
#import "BMWWatermarkRender.h"
#import "BMWImageRender.h"
#import "BMWImageContext.h"
#import "AVAsset+Utils.h"
#import "BMWALifeCycleHelper.h"
#import "BMWLittleImageDrawer.h"
#import "BMWWatermarkEmbeder.h"
#import "BMWCodeHelper.h"
#import "BMWSliceData.h"
#import "BMWSimilarityDetector.h"
#import "UIImage+GPCam.h"

#import "BMWAlgorithmModelManager.h"
#import "BMWLuminanceDectector.h"
#import "BMWCameraKit+Flash.h"
#import "BMWClearestFrameSelector.h"
#import "BMWCameraRecorder.h"
#import "BMWInputDrawer.h"
#import "UIView+GPCam.h"
#import "BMWRoundRectangleDrawer.h"
#import "BMWClarityDetector.h"

NSNotificationName const BMWCameraFaceCountNotification = @"BMWCameraFaceCountNotification";
NSNotificationName const BMWCameraLuminanceNotification = @"BMWCameraLuminanceNotification";

@interface BMWCamera () <BMWCameraKitDelegate, BMWAudioKitDelegate, BMWALifeCycleDelegate>
@property (nonatomic, copy) void (^previewImageCallback)(UIImage *_Nullable, NSError *_Nullable);
@property (nonatomic, copy) void (^cameraInitCompleteBlock)(NSError* _Nullable error, CGFloat totalDuration, CGFloat cameraDuration);
@property (nonatomic, copy) void (^antiFraudCallback)(BMWAntiFraudReslut * _Nullable);
@property (nonatomic, copy) void (^codeDetectCallback)(BMWCodeReslutModel* _Nullable reslutModel, NSError *_Nullable error);

@property (nonatomic, copy) void (^luminanceCallback)(CGFloat luminance);

@property (nonatomic, strong) BMWCameraSettingProfile* cameraSettingProfile;
@property (nonatomic) NSMutableArray<UIView*>* containerViews;
@property (nonatomic, strong) NSMutableArray<BMWGLView *> *subCameraPreviewViews;
@property (nonatomic, assign) BMWCameraKitStatus cameraKitStatus;
@property (nonatomic, assign) CGFloat cameraInitStartTimeStamp;

@property (nonatomic, strong) BMWCameraKit *cameraEntry;
@property (nonatomic, assign) CGFloat currZoomFactor;
@property (nonatomic, strong) BMWAudioKit *audioEntry;
@property (nonatomic, assign) BOOL enableAudioRecord;
// 拍照和录制视频使用的captured orientation
@property (nonatomic, assign) BMWDeviceOrientation deviceOrientation;

//渲染相关
@property (nonatomic, strong) BMWCameraRecorder *cameraWriter;
@property (nonatomic, strong) BMWFrameRender *frameRender;
@property (nonatomic, strong) BMWWatermarkRender *watermarkRender;
@property (nonatomic, strong) BMWImageRender *imageRender;
@property (nonatomic, assign) BMWEffectType effectType;
@property (nonatomic, strong) BMWFramebuffer *noWatermarkFramebuffer;
@property (nonatomic, strong) BMWBaseDrawer *noWatermarkDrawer;

// model
@property (nonatomic, strong) BMWWatermarkItem *watermark;
@property (nonatomic, strong) BMWWatermarkItem *productWatermark;
@property (nonatomic, assign) BMWImageResolutionQuality imageQuality;
@property (nonatomic, assign) BOOL hasSwitchCamera;
@property (nonatomic, assign) int filterId;
@property (nonatomic, assign) BOOL cameraWriterInited;
// 获取预览图Semaphore
@property (nonatomic, strong) dispatch_semaphore_t previewImageFetchSemaphore;
@property (nonatomic, assign) BOOL hasGotPreviewImage;
@property (nonatomic, strong) UIImage *previewImage;
@property (nonatomic, assign) BOOL previewImageHasFilterEffect;
@property (nonatomic, assign) CMTime previewImageTimestamp;
@property (nonatomic, assign) NSInteger clearestFrameIndex;
@property (nonatomic, assign) NSUInteger capturingImageCount;
@property (nonatomic, assign) CFTimeInterval lastTimestamp;
@property (nonatomic, assign) BOOL lastLowLight;

// 拍照时锁住 enter background
@property (nonatomic, strong) dispatch_semaphore_t lockSleepSemaphore;

@property (nonatomic, strong) BMWAntiFraudDetectStatus *antiFraudDetectStatus;

@property (nonatomic, strong) BMWCodeRequestModel *codeDetectRequestModel;


// LivePhoto v1
// 拍照
@property (nonatomic, strong) BMWImageCaptureMetaData *processedImageMetaData;
@property (nonatomic, strong) NSData *processedImageData;
@property (nonatomic, strong) NSError *processedImageError;
@property (nonatomic, copy) void (^processedImageCallBack)(BMWImageCaptureMetaData *metaData, NSData *_Nullable data, NSError * _Nullable error);
@property (nonatomic, strong) NSError *livePhotoError;
@property (nonatomic, copy) void (^captureImageStatusCallBack)(BMWCameraTakeImageStatus status);
@property (nonatomic, assign) BOOL captureLivePhoto;
@property (nonatomic, assign) BMWCameraKitMode capturedCameraKitMode;
@property (nonatomic, copy) NSArray<BMWWatermarkItem *> *watermarksForLivePhoto;

// LivePhoto v2
@property (nonatomic, assign, readwrite) BOOL enableLivePhotoV2;
@property (nonatomic, assign) BOOL livephotoAsyncProcessVideoFrame;

@property (nonatomic, strong) BMWClearestFrameSelector *clearestFrameSelector;

@property (nonatomic, strong) BMWInputDrawer *inputDrawer;
@property (nonatomic, strong) BMWBaseDrawer *baseDrawer;
@property (nonatomic, strong) BMWFramebuffer *subCameraFrameBuffer;
@property (nonatomic, strong) BMWFramebuffer *mainFrameBuffer;
@property (nonatomic, strong) BMWRoundRectangleDrawer *roundRectangleDrawer;

@end

@implementation BMWCamera

// init & reset
- (void)clear
{
    runSynchronouslyRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        [self.imageRender reset];
        [self.frameRender reset];
        [self.watermarkRender reset];
        [self.noWatermarkDrawer destory];
        self.noWatermarkDrawer = nil;
        [self.noWatermarkFramebuffer destroy];
        self.noWatermarkFramebuffer = nil;
        for (BMWGLView *glView in self.containerViews) {
            [glView destoryBuffers];
        }
        for (BMWGLView *glView in self.subCameraPreviewViews) {
            glView.displayedFramebuffer = nil;
            [glView destoryBuffers];
        }
        [self.roundRectangleDrawer destory];
        self.roundRectangleDrawer = nil;
        [self.inputDrawer destory];
        self.inputDrawer = nil;
        [self.baseDrawer destory];
        self.baseDrawer = nil;
        [self.subCameraFrameBuffer destroy];
        self.subCameraFrameBuffer = nil;
        [self.mainFrameBuffer destroy];
        self.mainFrameBuffer = nil;
        [super clear];
    });
    BMWMLogM(@"BMWCamera clear ..");
}

- (void)dealloc
{
    [self clear];
    self.cameraWriter = nil;
    [self.cameraEntry clear];
    self.cameraEntry = nil;
   
    BMWMLogM(@"BMWCamera dealloc ..");
}

- (void)addCameraPreview:(BMWGLView*)view
{
    if(!view) return;
    runSynchronouslyRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        [view commonInit:BMWImageContext.sharedImageProcessingContext];
        [view setInputImageRotation:kXHImageNoRotation];
        [view setFillMode:kXHImageFillModePreserveAspectRatioAndFill];
        [self.containerViews addObject:view];
        BMWMLog(@"addCameraPreview:%@",@(self.containerViews.count));
    });
}

- (void)removeCameraPreview:(BMWGLView*)view
{
    if(!view) return;
    runAsynchronouslyOnRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        [self.containerViews removeObject:view];
        [view destoryBuffers];
        BMWMLog(@"removeCameraPreview:%@",@(self.containerViews.count));
    });
}

- (void)addSubCameraPreviewView:(nullable BMWGLView*)view
{
    if (!view) return;
    runSynchronouslyRenderingQueue(^{
       [BMWImageContext useImageProcessingContext];
        [view commonInit:BMWImageContext.sharedImageProcessingContext];
        [view setInputImageRotation:kXHImageNoRotation];
        [view setFillMode:kXHImageFillModePreserveAspectRatioAndFill];
        [self.subCameraPreviewViews addObject:view];
        BMWMLog(@"addSubCameraPreviewView:%@",@(self.subCameraPreviewViews.count));
    });
}

- (void)removeSubCameraPreviewView:(nullable BMWGLView*)view
{
    if (!view) return;
    runAsynchronouslyOnRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        view.displayedFramebuffer = nil;
        [self.subCameraPreviewViews removeObject:view];
        [view destoryBuffers];
        BMWMLog(@"removeSubCameraPreviewView:%@",@(self.subCameraPreviewViews.count));
    });
}

- (void)removeAllSubCameraPreviewViews
{
    runAsynchronouslyOnRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        for (BMWGLView *glView in self.subCameraPreviewViews) {
            glView.displayedFramebuffer = nil;
            [glView destoryBuffers];
        }
        [self.subCameraPreviewViews removeAllObjects];
    });
}

- (instancetype)initWithBuilder:(void (^)(BMWCameraSettingProfile * profile))builder
{
    self = [super init];
    if (!self) {
        return nil;
    }
    
    BMWCameraSettingProfile* profile = [[BMWCameraSettingProfile alloc] init];
    self.cameraSettingProfile = profile;
    SafeBlock(builder, profile);
    self.containerViews = [NSMutableArray arrayWithCapacity:2];
    if(profile.containView) {
        [self.containerViews addObject:profile.containView];
    }
    self.subCameraPreviewViews = [NSMutableArray arrayWithCapacity:1];
    self.cameraInitStartTimeStamp = CACurrentMediaTime();
    self.cameraInitCompleteBlock = profile.cameraInitCompleteBlock;
    self.enableLivePhotoV2 = YES;
    self.capturingImageCount = 0;
    {
        unsigned long long totalMemory = [[NSProcessInfo processInfo] physicalMemory];
        if ((totalMemory / 1024 / 1024) >= [GPCamConfigurator.sharedInstance livePhotoMemThreshold] &&
            ![GPCamConfigurator.sharedInstance prioritizeLivePhotoV2]) {
            self.enableLivePhotoV2 = NO;
        }
    }
    profile.enableLivePhotoV2 = self.enableLivePhotoV2;
    self.livephotoAsyncProcessVideoFrame = GPCamConfigurator.sharedInstance.livephotoAsyncProcessVideoFrame;

    self.cameraEntry = [[BMWCameraKit alloc] initWithProfile:profile];
    
    self.cameraEntry.delegate = self;
    BMWDeviceUtils.sharedInstance.deviceSize = [UIScreen mainScreen].bounds.size;
    
    // 内存不够的时gl context会创建失败，如果gl创建失败直接return nil
    if(!profile.cameraStartupOpt) {
        if (BMWImageContext.sharedImageProcessingContext.context == nil) {
            return nil;
        }
    }
    
    self.antiFraudDetectStatus = [[BMWAntiFraudDetectStatus alloc] init];
    self.deviceOrientation = BMWDeviceOrientationPortait;
    self.realtimeDeviceOrientation = BMWDeviceOrientationPortait;
    self.enableAudioRecord = YES;
    self.hiddenProductWatermark = NO;
    self.imageQuality = BMWImageResolutionQualityCurrent;
    
    self.previewImageFetchSemaphore = dispatch_semaphore_create(0);
    self.hasGotPreviewImage = YES;
    self.enableClearestFrameSelector = NO;
    self.enableDisplayFrontCameraInSubPreview = profile.enableDisplayFrontCameraInSubPreview;
    
    if (profile.useAudioUnit) {
        self.audioEntry = BMWAudioKit.sharedInstance;
    }
    [self addObservers];
    
    // 设置glView属性
    runInRenderingQueue(YES, ^{
        for (BMWGLView *glView in self.containerViews) {
            [glView commonInit:BMWImageContext.sharedImageProcessingContext];
            [glView setInputImageRotation:kXHImageNoRotation];
            [glView setFillMode:kXHImageFillModePreserveAspectRatioAndFill];
        }
    });
    
    runInRenderingQueue(YES, ^{
        [BMWImageContext useImageProcessingContext];
        self.frameRender = [[BMWFrameRender alloc] initWithContext:BMWImageContext.sharedImageProcessingContext rotation:kXHImageRotateLeft useYUV:profile.useYUV];
        [super setup:BMWImageContext.sharedImageProcessingContext mode:self.cameraEntry.cameraMode];
    });
        
    return self;
}

- (BMWImageRender *)imageRender
{
    if (!_imageRender) {
        BMWImageContext *context = BMWImageContext.sharedImageProcessingContext;
        if(GPCamConfigurator.sharedInstance.smoothPreviewTakingImage == 1) {
            context = [[BMWImageContext alloc] init];
        }
        _imageRender = [[BMWImageRender alloc] initWithContext:context];
    }
    return _imageRender;
}
 
- (void)startCapture
{
    BMWMLog(@"%s %d", __FUNCTION__, __LINE__);
    CGFloat begin = CACurrentMediaTime();
    [self addObservers];
    @xhm_weakify(self);
    [self.cameraEntry startCapture:^(NSError * _Nonnull error) {
        @xhm_strongify(self);
        self.cameraKitStatus = BMWCameraKitStatusStart;
        if (self.cameraInitCompleteBlock) {
            CGFloat startCaptureEnd = [[NSProcessInfo processInfo] systemUptime];
            CGFloat cameraTimeCostFromDidFinishLaunch = startCaptureEnd - self.cameraSettingProfile.didFinishLaunchBegin/1000.0f;
            CGFloat cameraTimeCostFromDidLoad = startCaptureEnd - self.cameraSettingProfile.viewDidLoadBegin/1000.0f;
            CGFloat totalTimeCost = CACurrentMediaTime() - self.cameraInitStartTimeStamp;
            CGFloat cameraTimeCost = CACurrentMediaTime() - begin;
            self.cameraInitCompleteBlock(self.cameraEntry.error, totalTimeCost, cameraTimeCost);
            self.cameraInitCompleteBlock = nil;
            BMWMLog(@"startCapture timecost: {%lf, %lf}", totalTimeCost, cameraTimeCost);
#if CAMERA_STARTUP_OPT_DEBUG
            dispatch_async(dispatch_get_main_queue(), ^{
                for (BMWGLView *glView in self.containerViews) {
                    NSString *tips = [NSString stringWithFormat:@"相机启动耗时统计\n[是否优化：%d]\n[启动-首帧:%dms]\n[ViewDidLoad-首帧:%dms]\n[相机初始化-首帧%dms]\n[相机启动-首帧%dms]",
                                      self.cameraSettingProfile.cameraStartupOpt,
                                      (int)(cameraTimeCostFromDidFinishLaunch*1000),
                                      (int)(cameraTimeCostFromDidLoad*1000),
                                      (int)(totalTimeCost*1000),
                                      (int)(cameraTimeCost*1000)];
                    [glView showDebugTips:tips];
                }
            });
#endif
        }
        
    }];
    
    if (self.enableClearestFrameSelector) {
        runAsynchronouslyOnRenderingQueue(^{
            [BMWImageContext useImageProcessingContext];
            [self.clearestFrameSelector reset];
        });
    }
}

- (void)startCaptureWithCompleteBlock:(void (^)(NSError* _Nullable error, CGFloat totalTimeCost, CGFloat cameraTimeCost))block;
{
    BMWMLog(@"%s %d", __FUNCTION__, __LINE__);
    [self addObservers];
    CGFloat begin = CACurrentMediaTime();
    @xhm_weakify(self)
    [self.cameraEntry startCapture:^(NSError * _Nonnull error) {
        @xhm_strongify(self)
        self.cameraKitStatus = BMWCameraKitStatusStart;
        CGFloat time = CACurrentMediaTime() - begin;
        SafeBlock(block, error, time, time);
       
    }];
    
    if (self.enableClearestFrameSelector) {
        runAsynchronouslyOnRenderingQueue(^{
            [BMWImageContext useImageProcessingContext];
            [self.clearestFrameSelector reset];
        });
    }
}

- (void)stopCapture
{
    self.lastTimestamp = 0;
    self.lastLowLight = 0;
    self.cameraKitStatus = BMWCameraKitStatusStop;
    [self.cameraEntry stopCapture:nil];
    [self removeObservers];
    
    
    if (self.enableClearestFrameSelector) {
        runAsynchronouslyOnRenderingQueue(^{
            [BMWImageContext useImageProcessingContext];
            [self.clearestFrameSelector reset];
        });
    }
}

- (void)switchCamera
{
    AVCaptureDevicePosition position = AVCaptureDevicePositionBack;
    if (self.cameraEntry.devicePosition == AVCaptureDevicePositionFront) {
        position = AVCaptureDevicePositionBack;
    } else {
        position = AVCaptureDevicePositionFront;
    }
    BOOL isRecording = self.cameraWriter.writerStatus == BMWCameraWriterStatusRecording;
    // ugly 录制暂停处理
    if (isRecording) {
        [self.cameraWriter pauseForSwitching];
        runSynchronouslyRenderingQueue(^{
            // 录制过程中切换摄像头需要重新初始化watermarkRender
            self.cameraWriter.isReady = NO;
            [BMWImageContext useImageProcessingContext];
            [self.watermarkRender reset];
        });
    }
    @xhm_weakify(self);
    [self.cameraEntry setDevicePosition:position completedBlock:^(BOOL suc) {
        @xhm_strongify(self);
        // 录制恢复处理
        if (isRecording) {
            [self.cameraWriter resumeForSwitching];
        }
    }];
    self.hasSwitchCamera = YES;
    [self updateEffectType];
    
    if (self.enableClearestFrameSelector) {
        runAsynchronouslyOnRenderingQueue(^{
            [BMWImageContext useImageProcessingContext];
            [self.clearestFrameSelector reset];
        });
    }
}

+ (void)setLicensePath:(NSString*)path
{

}

+ (NSArray<BMWEffectTypeItem *>*)supportedEffects
{
    NSMutableArray *allEffects = [NSMutableArray arrayWithArray:BMWFrameRender.supportedEffects];
    [allEffects addObject:BMWEffectTypeItem.lutEffectItem];
    [allEffects addObject:BMWEffectTypeItem.brightnessEffectItem];
    return allEffects;
}

- (void)setEffectIntensity:(BMWEffectTypeItem *)item intensity:(float)intensity
{
    if ([item.catigory isEqualToString:@"lut"]) {
        self.filterId = item.id;
        [self updateEffectType];
    }
    [self.frameRender setEffectIntensity:item intensity:intensity];
    [self.imageRender setEffectIntensity:item intensity:intensity];
}

- (void)setEnableClearestFrameSelector:(BOOL)enableClearestFrameSelector {
    if (_enableClearestFrameSelector == enableClearestFrameSelector) {
        return;
    }
    _enableClearestFrameSelector = enableClearestFrameSelector;
    runAsynchronouslyOnRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        if (enableClearestFrameSelector) {
            if (!self.clearestFrameSelector) {
                self.clearestFrameSelector = [[BMWClearestFrameSelector alloc] initWithContext:BMWImageContext.sharedImageProcessingContext];
            }
        } else {
            self.clearestFrameSelector = nil;
        }
    });
}

- (void)setImageResolutionQuality:(BMWImageResolutionQuality)quality
{
    self.imageQuality = quality;
    self.cameraEntry.imageQuality = quality;
    [self.imageRender reset];
}

- (void)changeCameraMode:(BMWCameraKitMode)mode;
{
    if (self.cameraEntry && self.cameraEntry.cameraMode != mode) {
        [self.cameraEntry changeMode:mode];
        [self.imageRender reset];
        
    }
}

- (BOOL)isSupportNightEnhance
{
    if(GPCamConfigurator.sharedInstance.nightModeVer == 2) {
        return YES;
    }
    return BMWDeviceUtils.supportMetalCNN;
}

- (void)enableNightEnhance:(BOOL)enable
{
    enable = [self isSupportNightEnhance] && enable;
    self.isNightEnhanceEnabled = enable;
    self.imageRender.enableNightMode = enable;
    [self.cameraEntry enableNightEnhance:enable];
}

- (void)setLockLandscape:(BOOL)enable
{
    self.isLockLandscape = enable;
    self.imageRender.isLockLandscape = enable;
}

- (void)changeFilter:(BMWCameraMode)mode
{
    BMWMLog(@"changeFilter: %d", mode);
    double startTime = CACurrentMediaTime();
    self.filterMode = mode;
    [self updateEffectType];
    if (mode == BMWCameraModeVideoFront || mode == BMWCameraModeVideoBack || mode == BMWCameraModeVideoFrontMirror) {
        if (!self.cameraSettingProfile.useAudioUnit) {
            [self.cameraEntry addAudioInputsAndOutputs];
        }
    } else {
        if (!self.cameraSettingProfile.useAudioUnit) {
            // [self.cameraEntry removeAudioInputsAndOutputs];
        }
    }
    double costTime = CACurrentMediaTime() - startTime;
    if (self.modeChangeBlock) {
        self.modeChangeBlock(self.filterMode, costTime);
        self.modeChangeBlock = nil;
    }
}

- (void)setRealtimeDeviceOrientation:(BMWDeviceOrientation)realtimeDeviceOrientation
{
    if (realtimeDeviceOrientation != BMWDeviceOrientationUnknown) {
        _realtimeDeviceOrientation = realtimeDeviceOrientation;
    }
}

- (void)startRecordWithWatermarkViewInfo:(nullable BMWWatermarkItem*)watermarkModel profileBuilder:(nullable void(^)(BMWEncodeProfile * profile))builder recordDurationCallBack:(nullable void (^)(CGFloat duration))recordDurationCallBack
{
    BMWMLog(@"startRecordWithWatermarkViewInfo begin..");
    BOOL processVideoBufferAsync = self.cameraSettingProfile.enableLivePhoto &&
                                   self.cameraSettingProfile.enableLivePhotoV2 &&
                                   (self.cameraEntry.cameraMode != BMWCameraKitModeVideo) &&
                                   self.livephotoAsyncProcessVideoFrame;
    BMWMLog(@"processVideoBufferAsync: %d", processVideoBufferAsync);
    
    BMWEncodeProfile * profile = [BMWEncodeProfile defaultProfile];
    !builder ? : builder(profile);
    if (profile.deviceOrientation == BMWDeviceOrientationLeft || profile.deviceOrientation == BMWDeviceOrientationRight) {
        profile.videoSize = CGSizeMake(profile.videoSize.height, profile.videoSize.width);
    } else {
        profile.videoSize = CGSizeMake(profile.videoSize.width, profile.videoSize.height);
    }
    self.enableAudioRecord = profile.enableAudioRecord;
    self.watermark = watermarkModel;
    self.deviceOrientation = profile.deviceOrientation;
    // prepare watermark render
    self.watermarkRender = [BMWWatermarkRender new];
    [self.watermarkRender prepareWatermark:watermarkModel];
    if (watermarkModel) {
        [self.watermarkRender updateWatermarkV2s:[BMWWatermarkItem createWatermarkInfoV2sFromItems:@[watermarkModel] deviceOrientation:self.deviceOrientation]];
    }
    // start audio capture
    if(self.enableAudioRecord &&
       ((self.cameraEntry.cameraMode == BMWCameraKitModeVideo) || (!self.cameraSettingProfile.enableLivePhoto || self.cameraSettingProfile.enableLivePhotoV2))) {
        [self.audioEntry startAudioCaptureWithDelegate:self];
    }
    // config encoder
    self.cameraWriterInited = NO;
    // 关掉水印不支持录制无水印视频
    BOOL hasProductWatermark = !self.hiddenProductWatermark && (self.productWatermark.water != nil || self.productWatermark.waterLayer != nil);
    profile.enableRecordNoWatermarkVideo = profile.enableRecordNoWatermarkVideo && (watermarkModel.water != nil || watermarkModel.waterLayer != nil || hasProductWatermark);
    BMWMLog(@"startRecordWithWatermarkViewInfo .. enableRecordNoWatermarkVideo: %d", profile.enableRecordNoWatermarkVideo);
    self.cameraWriter = [[BMWCameraRecorder alloc] initWithEncodeProfile:profile];
    [self.cameraWriter activateAudioTrack];
    [self.cameraWriter setRecordDurationBlock:recordDurationCallBack];
    [self.cameraWriter start];
    self.cameraWriterInited = YES;
    // request preview image
    [self requestPreviewImage:self.cameraEntry.cameraMode handler:nil];
}

- (void)stopRecord:(void (^)(NSString *_Nullable errorStr))errorBlock
{
    BMWMLog(@"stopRecord sync begin..");
    [self.cameraWriter stop];
    if(self.enableAudioRecord) {
        [self.audioEntry stopAudioCaptureWithDelegate:self];
    }
    runSynchronouslyRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        [self.watermarkRender reset];
        [self.noWatermarkFramebuffer destroy];
        self.noWatermarkFramebuffer = nil;
        [self.noWatermarkDrawer destory];
        self.noWatermarkDrawer = nil;
    });
    if (errorBlock && self.cameraWriter.errorStr) {
        errorBlock(self.cameraWriter.errorStr);
    }
    self.cameraWriterInited = NO;
    BMWMLog(@"stopRecord sync end..");
}

- (void)stopRecord:(void (^)(UIImage *_Nullable previewImage, NSError *_Nullable error))handler completionBlock:(void (^)(BMWVideoMetaData *_Nullable videoMetaData, NSString *_Nullable errorStr))completionBlock
{
    BMWMLog(@"stopRecordWithCompletion begin..");
    self.previewImageCallback = handler;
    @xhm_weakify(self);
    [self.cameraWriter stop:^(BMWVideoMetaData * _Nonnull videoMetaData) {
        @xhm_strongify(self);
        NSString *moviePath = [self.cameraWriter.moviePath copy];
        NSString *errorStr = [self.cameraWriter.errorStr copy];
        [self.audioEntry stopAudioCaptureWithDelegate:self];
        self.cameraWriterInited = NO;
        NSError *error = nil;
        if (self.previewImage == nil) {
            error = [[NSError alloc] initWithDomain:@"capture video preview image fail" code:GPCamTakePhotoImageCreateError userInfo:nil];
        }
        BMWMLog(@"stopRecordWithCompletion.. stop cameraWriter.. preview:%p, path:%@, error:%@", self.previewImage, moviePath, errorStr);
        
        SafeBlock(self.previewImageCallback, self.previewImage, error);
        self.previewImage = nil;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *newErrorStr = [self verifyVideo:moviePath errorStr:errorStr];
            BMWMLog(@"stopRecordWithCompletion.. verifyVideo .. error:%@", newErrorStr);
            SafeBlock(completionBlock, videoMetaData, newErrorStr);
        });
        
        
    }];
    runSynchronouslyRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        [self.watermarkRender reset];
        [self.noWatermarkFramebuffer destroy];
        self.noWatermarkFramebuffer = nil;
        [self.noWatermarkDrawer destory];
        self.noWatermarkDrawer = nil;
    });
    BMWMLog(@"stopRecordWithCompletion end..");
}

- (void)pauseRecord
{
    [self.cameraWriter pause];
    BMWMLog(@"pauseRecord ..");
}

- (void)resumeRecord
{
    [self.cameraWriter resume];
    BMWMLog(@"resumeRecord ..");
}

- (void)cancleRecording
{
    [self.cameraWriter cancelRecording];
    runSynchronouslyRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        [self.watermarkRender reset];
    });
    
    self.cameraWriterInited = NO;
    BMWMLog(@"cancleRecording ..");
}


- (NSString*)verifyVideo:(NSString*)filePath errorStr:(NSString*)errorStr
{
    unsigned long long fileSize = 0;
    __block float duration = 0.;
    __block NSError* videoError = nil;
    NSString *newErrorStr = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    if (fileSize > 0) {
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:filePath] options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
        [asset videoDurationSync:^(float time, NSError * _Nonnull error) {
            duration = time;
            videoError = error;
        }];
    }
    if (errorStr || fileSize == 0 || videoError || duration < 1.e-5) {
        newErrorStr = [NSString stringWithFormat:@"%@, fileSize:%@K, videoValidity:[%@,%@], cameraState:%@", errorStr, @(fileSize/1000.0), @(duration), videoError, [self.cameraEntry cameraStateDic].description];
    }
    return newErrorStr;
}

#pragma mark - BMWCameraKitDelegate

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer
{
    if(self.enableAudioRecord) {
        [self.cameraWriter processAudioBuffer:audioBuffer];
    }
}

- (void)processAudioFrame:(BMWAudioFrame *)audioFrame
{
    if (self.enableAudioRecord) {
        [self.cameraWriter processAudioFrame:audioFrame];
    }
}

- (BOOL)intervalCheck:(double)timestamp refreshInterval:(double)refreshInterval
{
    double currTimestamp = timestamp;
    if (currTimestamp < 0) {
        currTimestamp = CACurrentMediaTime();
    }
    //跳过3次
    if(self.lastTimestamp < 5) {
        self.lastTimestamp++;
        return NO;
    }
    // 4次跳过
    if(self.lastTimestamp == 5) {
        self.lastTimestamp = currTimestamp;
        return NO;
    }
    
    if(currTimestamp - self.lastTimestamp < refreshInterval) {
        return NO;
    }
    self.lastTimestamp = currTimestamp;
    return YES;
}

- (void)processVideoBufferAsync:(BMWCameraKitData *)data {
    CMSampleBufferRef sampleBuffer = data.sampleBuffer;
    NSArray* metadataObjects = data.metadataObjects;
    AVCaptureDevicePosition devicePosition = data.devicePosition;
    BMWCameraKitMode cameraMode = self.cameraEntry.cameraMode;
    BOOL isFront = devicePosition == AVCaptureDevicePositionFront;
    CFDictionaryRef attachments = CMGetAttachment(sampleBuffer, kCGImagePropertyExifDictionary, NULL);
    if (attachments != NULL) {
        NSDictionary *exifDic = (__bridge NSDictionary*)attachments;
        NSString *lensModel = exifDic[@"LensModel"];
        if([lensModel isKindOfClass:[NSString class]] && [lensModel.lowercaseString containsString:@"front"]) {
            isFront = YES;
        }
    }
    BOOL isMirror = self.filterMode == BMWCameraModePhotoFrontMirror || self.filterMode == BMWCameraModeVideoFrontMirror;

    CMTime frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CVPixelBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferRef pipPixelBuffer = CMSampleBufferGetImageBuffer(data.pipSampleBuffer);
    int width = (int)CVPixelBufferGetWidth(cameraFrame);
    int height = (int)CVPixelBufferGetHeight(cameraFrame);
    if (cameraMode == BMWCameraKitModePhoto1x1) {
        width = height = MIN(width, height);
    } else if(cameraMode == BMWCameraKitModePhotoFull) {
        height = width * BMWDeviceUtils.sharedInstance.deviceRatio;
    } else if(cameraMode == BMWCameraKitModePhoto16x9 || cameraMode == BMWCameraKitModeVideo) {
        height = width * RATIO9x16;
    }
    if (self.cameraKitStatus == BMWCameraKitStatusStop ||
        BMWALifeCycleHelper.sharedInstance.appInResignActive ||
        BMWALifeCycleHelper.sharedInstance.appInBackground) return;
    
    if (sampleBuffer) {
        CFRetain(sampleBuffer);
    }
    if (cameraFrame) {
        CVPixelBufferRetain(cameraFrame);
    }
    if (pipPixelBuffer) {
        CVPixelBufferRetain(pipPixelBuffer);
    }
    
    BOOL shouldRecordFrame = NO;
    if (self.cameraWriterInited) {
        if (self.cameraWriter.writerStatus == BMWCameraWriterStatusRecording) {
            if (self.cameraWriter.isReady == NO) {
                self.cameraWriter.isReady = YES;
                runAsynchronouslyOnRenderingQueue(^{
                    [BMWImageContext useImageProcessingContext];
                    [self.watermarkRender setRenderOutputSize:self.cameraWriter.encodeProfile.videoSize];
                    [self.watermarkRender setDeviceOritaion:self.deviceOrientation];
                    [self.watermarkRender setWatermark:self.watermark];
                    [self.watermarkRender setProductWatermark:self.productWatermark];
                    if (self.enableDisplayFrontCameraInSubPreview) {
                        if (self.watermark) {
                            [self.watermarkRender updateWatermarkV2s:[BMWWatermarkItem createWatermarkInfoV2sFromItems:@[self.watermark] deviceOrientation:self.deviceOrientation]];
                        }
                    }
                });
            }
            
            if (self.cameraWriter.writerStatus == BMWCameraWriterStatusRecording) {
                shouldRecordFrame = YES;
            }
        }
    }
    
    runAsynchronouslyOnRenderingQueue(^{
#define CheckStatus() \
        if (self.cameraKitStatus == BMWCameraKitStatusStop || \
            BMWALifeCycleHelper.sharedInstance.appInResignActive || BMWALifeCycleHelper.sharedInstance.appInBackground) { \
            if (sampleBuffer) { \
                CFRelease(sampleBuffer); \
            } \
            if (cameraFrame) { \
                CVPixelBufferRelease(cameraFrame); \
            } \
            if (pipPixelBuffer) { \
                CVPixelBufferRelease(pipPixelBuffer); \
            } \
            return; \
        }
        CheckStatus();
        [BMWImageContext useImageProcessingContext];
        [self.frameRender setRenderOutputSize:CGSizeMake(width, height)];
        [self.frameRender setDeviceOritaion:self.realtimeDeviceOrientation];
        [self.frameRender setExtraScaleRatio:self.cameraEntry.extraZoomFactor];
        BMWDeviceOrientation pipOrientation = self.cameraWriter.writerStatus == BMWCameraWriterStatusRecording ? self.deviceOrientation : self.realtimeDeviceOrientation;
        CheckStatus();
        GLuint textureId = [self processVideoBufferWithCameraMainPixelBuffer:cameraFrame
                                                              subPixelBuffer:pipPixelBuffer
                                                                   frameTime:frameTime
                                                              pipOrientation:pipOrientation
                                                             outputImageSize:CGSizeMake(height, width)
                                                                     isFront:isFront];
        for (BMWGLView *glView in self.containerViews) {
            [glView setInputImageSize:CGSizeMake(height, width)];
            CheckStatus();
            [glView renderTextureId:textureId];
        }
        if (self.enableClearestFrameSelector && self.clearestFrameSelector) {
            [self.clearestFrameSelector onVideoFrameArrived:textureId size:CGSizeMake(height, width) timestamp:frameTime];
        }
      
        CheckStatus();
        [self capturePreviewImageIfNeeded:sampleBuffer cameraMode:cameraMode isFront:isFront isMirror:isMirror orient:(int)self.deviceOrientation extraZoomFactor:self.cameraEntry.extraZoomFactor];
        @xhm_weakify(self);
        [super triggerAllDelegates:^(BMWVideoAlgorithmSourceProfile * _Nonnull profile) {
            @xhm_strongify(self);
            profile.metadataObjects = metadataObjects;
            profile.rectOfInterest = data.rectOfInterest;
            profile.textureId = textureId;
            profile.orientation = self.realtimeDeviceOrientation;
            profile.force = NO;
            profile.timestamp = -1;
            profile.sync = NO;
            profile.enableSmooth = YES;
            profile.isMirror = isFront;
        }];
        [self antiFraudDet:metadataObjects texId:textureId inputSize:CGSizeMake(height, width)];
        [self codeDet:metadataObjects texId:textureId inputSize:CGSizeMake(height, width)];
        if (sampleBuffer) {
            CFRelease(sampleBuffer);
        }
        if (cameraFrame) {
            CVPixelBufferRelease(cameraFrame);
        }
        if (pipPixelBuffer) {
            CVPixelBufferRelease(pipPixelBuffer);
        }
        
        if (shouldRecordFrame) {
            [BMWImageContext useImageProcessingContext];
            BOOL isMirror = self.filterMode == BMWCameraModeVideoFrontMirror;
            self.watermarkRender.isMirror = isMirror;
            [self.watermarkRender setInputTexture:textureId];
            [self.watermarkRender process:CMTimeGetSeconds(frameTime)];
            BOOL shouldProcessNoWatermarkFrame = [self processNoWatermarkFrame:textureId];
            glFinish();
            if (self.cameraWriter.enableRecordNoWatermarkVideo) {
                if (shouldProcessNoWatermarkFrame) {
                    [self.cameraWriter appendNoWatermarkVideoBuffer:self.noWatermarkFramebuffer.renderTarget frameTime:frameTime];
                } else {
                    [self.cameraWriter appendNoWatermarkVideoBuffer:self.frameRender.getOutputPixelBuffer frameTime:frameTime];
                }
            }
            CVPixelBufferRef renderTarget = self.watermarkRender.renderTarget;
            [self captureVideoPreviewImageIfNeeded:renderTarget timestamp:frameTime];
            [self.cameraWriter appendVideoBuffer:renderTarget frameTime:frameTime];
        }
    });

}

- (GLuint)processVideoBufferWithCameraMainPixelBuffer:(CVPixelBufferRef)mainPixelBuffer
                                       subPixelBuffer:(CVPixelBufferRef)subPixelBuffer
                                            frameTime:(CMTime)frameTime
                                       pipOrientation:(BMWDeviceOrientation)pipOrientation
                                      outputImageSize:(CGSize)outputImageSize
                                              isFront:(BOOL)isFront {
    GLuint textureId;
    if (!self.enableDisplayFrontCameraInSubPreview || subPixelBuffer == NULL || self.subCameraPreviewViews.count == 0 ||
        self.subCameraPreviewViews.firstObject.size.width <= 0 ||
        self.subCameraPreviewViews.firstObject.size.height <= 0) {
        [self.frameRender setExtraScaleRatio:self.cameraEntry.extraZoomFactor];
        textureId = [self.frameRender processPixelBuffer:mainPixelBuffer
                                          pipPixelBuffer:subPixelBuffer
                                          pipOrientation:pipOrientation
                                               frameTime:frameTime
                                                 isFront:isFront];
        return textureId;
    }
    
    [self.frameRender setExtraScaleRatio:isFront ? 1.0 : self.cameraEntry.extraZoomFactor];
    textureId = [self.frameRender processPixelBuffer:mainPixelBuffer
                                      pipPixelBuffer:NULL
                                      pipOrientation:pipOrientation
                                           frameTime:frameTime
                                             isFront:isFront];

    GLuint frontTextureId = textureId;
    
    CVPixelBufferRef frontPixelBuffer = isFront ? mainPixelBuffer : subPixelBuffer;
    int width = isFront ? outputImageSize.width / 2 : (int)CVPixelBufferGetHeight(subPixelBuffer);
    int height = isFront ? outputImageSize.height / 2 : (int)CVPixelBufferGetWidth(subPixelBuffer);
    
    int viewWidth = self.subCameraPreviewViews.firstObject.size.width;
    int viewHeight = self.subCameraPreviewViews.firstObject.size.height;
    if (self.realtimeDeviceOrientation == BMWDeviceOrientationLeft || self.realtimeDeviceOrientation == BMWDeviceOrientationRight) {
        viewWidth = self.subCameraPreviewViews.firstObject.size.height;
        viewHeight = self.subCameraPreviewViews.firstObject.size.width;
    }
    float scaleFactorX = 1.0;
    float scaleFactorY = 1.0;
    int targetWidth = width;
    int targetHeight = height;
    if ((float)width / height > (float)viewWidth / viewHeight) {
        targetHeight = height;
        targetWidth = height * viewWidth / viewHeight;
        scaleFactorX = (float)width / targetWidth;
    } else {
        targetWidth = width;
        targetHeight = width * viewHeight / viewWidth;
        scaleFactorY = (float)height / targetHeight;
    }
    
    float cornerRadius = self.subCameraPreviewViews.firstObject.cornerRadius / viewWidth * targetWidth;
    
    if (!self.inputDrawer) {
        self.inputDrawer = [[BMWInputDrawer alloc] initWithContext:BMWImageContext.sharedImageProcessingContext useYUV:self.cameraSettingProfile.useYUV];
    }
    if (!self.subCameraFrameBuffer || !CGSizeEqualToSize(self.subCameraFrameBuffer.bufferSize, CGSizeMake(targetWidth, targetHeight))) {
        [self.subCameraFrameBuffer destroy];
        self.subCameraFrameBuffer = [[BMWFramebuffer alloc] initWithSize:CGSizeMake(targetWidth, targetHeight) imageContext:BMWImageContext.sharedImageProcessingContext];
    }
    if (!self.mainFrameBuffer || !CGSizeEqualToSize(self.subCameraFrameBuffer.bufferSize, self.mainFrameBuffer.bufferSize)) {
        [self.mainFrameBuffer destroy];
        self.mainFrameBuffer = [[BMWFramebuffer alloc] initWithSize:self.subCameraFrameBuffer.bufferSize imageContext:BMWImageContext.sharedImageProcessingContext];
    }
    if (!self.baseDrawer) {
        self.baseDrawer = [[BMWBaseDrawer alloc] init];
    }
    if (!self.roundRectangleDrawer) {
        self.roundRectangleDrawer = [[BMWRoundRectangleDrawer alloc] initWithContext:BMWImageContext.sharedImageProcessingContext];
    }

    frontTextureId = textureId;
    
    if (!isFront) {
        [self.mainFrameBuffer bind];
        [self.inputDrawer setInputPixelBuffer:frontPixelBuffer];
        [self.inputDrawer resetMatrix];
        [self.inputDrawer rotateZ:M_PI_2];
        [self.inputDrawer scaleX:-scaleFactorX scaleY:scaleFactorY];
        [self.inputDrawer draw];
    } else {
        [self.mainFrameBuffer bind];
        [self.baseDrawer resetMatrix];
        [self.baseDrawer scaleX:scaleFactorX scaleY:scaleFactorY];
        [self.baseDrawer setInputTexId:textureId];
        [self.baseDrawer draw];
    }
    
    frontTextureId = self.mainFrameBuffer.texture;
    
    [self.subCameraFrameBuffer bind];
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    [self.roundRectangleDrawer setResolution:CGSizeMake(targetWidth, targetHeight)
                                      radius:cornerRadius
                                 borderWidth:1
                                 borderColor:[UIColor clearColor]];
    [self.roundRectangleDrawer resetMatrix];
    [self.roundRectangleDrawer setInputTexId:frontTextureId];
    [self.roundRectangleDrawer draw];
    
    frontTextureId = self.subCameraFrameBuffer.texture;
    
    {
        for (BMWGLView *glView in self.subCameraPreviewViews) {
            BMWImageRotationMode rotation = kXHImageNoRotation;
            CGSize size = CGSizeMake(targetWidth, targetHeight);
            if (self.realtimeDeviceOrientation == BMWDeviceOrientationLeft) {
                rotation = kXHImageRotateLeft;
                size = CGSizeMake(targetHeight, targetWidth);
            } else if (self.realtimeDeviceOrientation == BMWDeviceOrientationRight) {
                rotation = kXHImageRotateRight;
                size = CGSizeMake(targetHeight, targetWidth);
            } else if (self.realtimeDeviceOrientation == BMWDeviceOrientationDown) {
                rotation = kXHImageFlipVertical;
            }
            glView.displayedFramebuffer = self.subCameraFrameBuffer;
            [glView setInputImageRotation:rotation];
            [glView setInputImageSize:size];
            [glView renderTextureId:frontTextureId];
        }
    }

    if (isFront && (self.cameraEntry.extraZoomFactor > 1.0)){
        textureId = [self.frameRender processWithExtraScaleRatio:self.cameraEntry.extraZoomFactor];
    }
    
    return textureId;
}

- (void)processVideoBuffer:(BMWCameraKitData*)data
{
    // 只有在拍照页开启了LivePhoto走异步模式
    if (self.cameraSettingProfile.enableLivePhoto && self.cameraSettingProfile.enableLivePhotoV2 &&
        (self.cameraEntry.cameraMode != BMWCameraKitModeVideo) &&
        self.livephotoAsyncProcessVideoFrame) {
        return [self processVideoBufferAsync:data];
    }
    CMSampleBufferRef sampleBuffer = data.sampleBuffer;
    NSArray* metadataObjects = data.metadataObjects;
    AVCaptureDevicePosition devicePosition = data.devicePosition;
    BMWCameraKitMode cameraMode = self.cameraEntry.cameraMode;
    BOOL isFront = devicePosition == AVCaptureDevicePositionFront;
    CFDictionaryRef attachments = CMGetAttachment(sampleBuffer, kCGImagePropertyExifDictionary, NULL);
    if (attachments != NULL) {
        NSDictionary *exifDic = (__bridge NSDictionary*)attachments;
        NSString *lensModel = exifDic[@"LensModel"];
        if([lensModel isKindOfClass:[NSString class]] && [lensModel.lowercaseString containsString:@"front"]) {
            isFront = YES;
        }
    }
    BOOL isMirror = self.filterMode == BMWCameraModePhotoFrontMirror || self.filterMode == BMWCameraModeVideoFrontMirror;

    CMTime frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    CVPixelBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferRef pipPixelBuffer = CMSampleBufferGetImageBuffer(data.pipSampleBuffer);
    int width = (int)CVPixelBufferGetWidth(cameraFrame);
    int height = (int)CVPixelBufferGetHeight(cameraFrame);
    if (cameraMode == BMWCameraKitModePhoto1x1) {
        width = height = MIN(width, height);
    } else if(cameraMode == BMWCameraKitModePhotoFull) {
        height = width * BMWDeviceUtils.sharedInstance.deviceRatio;
    } else if(cameraMode == BMWCameraKitModePhoto16x9 || cameraMode == BMWCameraKitModeVideo) {
        height = width * RATIO9x16;
    }
    if (self.cameraKitStatus == BMWCameraKitStatusStop ||
        BMWALifeCycleHelper.sharedInstance.appInResignActive ||
        BMWALifeCycleHelper.sharedInstance.appInBackground) return;
    
    __block GLuint textureId;
    runSynchronouslyRenderingQueue(^{
        if (self.cameraKitStatus == BMWCameraKitStatusStop ||
            BMWALifeCycleHelper.sharedInstance.appInResignActive ||
            BMWALifeCycleHelper.sharedInstance.appInBackground) return;

        [BMWImageContext useImageProcessingContext];
        [self.frameRender setRenderOutputSize:CGSizeMake(width, height)];
        [self.frameRender setDeviceOritaion:self.realtimeDeviceOrientation];
        BMWDeviceOrientation pipOrientation = self.cameraWriter.writerStatus == BMWCameraWriterStatusRecording ? self.deviceOrientation : self.realtimeDeviceOrientation;
        textureId = [self processVideoBufferWithCameraMainPixelBuffer:cameraFrame
                                                       subPixelBuffer:pipPixelBuffer
                                                            frameTime:frameTime
                                                       pipOrientation:pipOrientation
                                                      outputImageSize:CGSizeMake(height, width)
                                                              isFront:isFront];
        for (BMWGLView *glView in self.containerViews) {
            [glView setInputImageSize:CGSizeMake(height, width)];
            [glView renderTextureId:textureId];
        }
        if (self.enableClearestFrameSelector && self.clearestFrameSelector) {
            [self.clearestFrameSelector onVideoFrameArrived:textureId size:CGSizeMake(height, width) timestamp:frameTime];
        }
       
        [self capturePreviewImageIfNeeded:sampleBuffer cameraMode:cameraMode isFront:isFront isMirror:isMirror orient:(int)self.deviceOrientation extraZoomFactor:self.cameraEntry.extraZoomFactor];
        @xhm_weakify(self);
        [super triggerAllDelegates:^(BMWVideoAlgorithmSourceProfile * _Nonnull profile) {
            @xhm_strongify(self);
            profile.metadataObjects = metadataObjects;
            profile.rectOfInterest = data.rectOfInterest;
            profile.textureId = textureId;
            profile.orientation = self.realtimeDeviceOrientation;
            profile.force = NO;
            profile.timestamp = -1;
            profile.sync = NO;
            profile.enableSmooth = YES;
            profile.isMirror = isFront;
        }];
        [self antiFraudDet:metadataObjects texId:textureId inputSize:CGSizeMake(height, width)];
        [self codeDet:metadataObjects texId:textureId inputSize:CGSizeMake(height, width)];
    });
    
    if (self.cameraWriterInited == NO) {
        return;
    }
    
    // 视频录制流程
    if (self.cameraWriter.writerStatus == BMWCameraWriterStatusRecording) {
        
        if (self.cameraWriter.isReady == NO) {
            self.cameraWriter.isReady = YES;
            runSynchronouslyRenderingQueue(^{
                [BMWImageContext useImageProcessingContext];
                [self.watermarkRender setRenderOutputSize:self.cameraWriter.encodeProfile.videoSize];
                [self.watermarkRender setDeviceOritaion:self.deviceOrientation];
                [self.watermarkRender setWatermark:self.watermark];
                [self.watermarkRender setProductWatermark:self.productWatermark];
                if (self.enableDisplayFrontCameraInSubPreview) {
                    if (self.watermark) {
                        [self.watermarkRender updateWatermarkV2s:[BMWWatermarkItem createWatermarkInfoV2sFromItems:@[self.watermark] deviceOrientation:self.deviceOrientation]];
                    }
                }
            });
        }
        
        if (self.cameraWriter.writerStatus == BMWCameraWriterStatusRecording) {
            __block BOOL shouldProcessNoWatermarkFrame = NO;
            runSynchronouslyRenderingQueue(^{
                [BMWImageContext useImageProcessingContext];
                BOOL isMirror = self.filterMode == BMWCameraModeVideoFrontMirror;
                self.watermarkRender.isMirror = isMirror;
                [self.watermarkRender setInputTexture:textureId];
                [self.watermarkRender process:CMTimeGetSeconds(frameTime)];
                shouldProcessNoWatermarkFrame = [self processNoWatermarkFrame:textureId];
                glFinish();
            });
            if (self.cameraWriter.enableRecordNoWatermarkVideo) {
                if (shouldProcessNoWatermarkFrame) {
                    [self.cameraWriter appendNoWatermarkVideoBuffer:self.noWatermarkFramebuffer.renderTarget frameTime:frameTime];
                } else {
                    [self.cameraWriter appendNoWatermarkVideoBuffer:self.frameRender.getOutputPixelBuffer frameTime:frameTime];
                }
            }
            CVPixelBufferRef renderTarget = self.watermarkRender.renderTarget;
            [self captureVideoPreviewImageIfNeeded:renderTarget timestamp:frameTime];
            [self.cameraWriter appendVideoBuffer:renderTarget frameTime:frameTime];
        }
    }
}

- (BOOL)processNoWatermarkFrame:(GLuint)textureId {
    BOOL isMirror = self.filterMode == BMWCameraModeVideoFrontMirror;
    if (!self.cameraWriter.enableRecordNoWatermarkVideo) {
        [self.noWatermarkFramebuffer destroy];
        self.noWatermarkFramebuffer = nil;
        [self.noWatermarkDrawer destory];
        self.noWatermarkDrawer = nil;
        return NO;
    }
    
    if (!isMirror && (self.deviceOrientation == BMWDeviceOrientationPortait)) {
        [self.noWatermarkFramebuffer destroy];
        self.noWatermarkFramebuffer = nil;
        [self.noWatermarkDrawer destory];
        self.noWatermarkDrawer = nil;
        return NO;
    }
    
    CGSize size = self.frameRender.outputSize;
    if (self.deviceOrientation == BMWDeviceOrientationLeft || self.deviceOrientation == BMWDeviceOrientationRight) {
        size = CGSizeMake(size.height, size.width);
    }
    
    if (!CGSizeEqualToSize(self.noWatermarkFramebuffer.bufferSize, size)) {
        [self.noWatermarkFramebuffer destroy];
        self.noWatermarkFramebuffer = [[BMWFramebuffer alloc] initWithSize:size imageContext:BMWImageContext.sharedImageProcessingContext];
    }
    if (!self.noWatermarkDrawer) {
        self.noWatermarkDrawer = [[BMWBaseDrawer alloc] init];
    }
    [self.noWatermarkFramebuffer bind];
    [self.noWatermarkDrawer resetMatrix];
    [self.noWatermarkDrawer setInputTexId:textureId];
    switch (self.deviceOrientation) {
        case BMWDeviceOrientationLeft:
            [self.noWatermarkDrawer rotateZ:-M_PI_2];
            break;
        case BMWDeviceOrientationRight:
            [self.noWatermarkDrawer rotateZ:M_PI_2];
            break;
        case BMWDeviceOrientationDown:
            [self.noWatermarkDrawer rotateZ:M_PI];
            break;
        default:
            break;
    }
    [self.noWatermarkDrawer scaleX:isMirror ? -1 : 1 scaleY:1];
    [self.noWatermarkDrawer draw];
    
    return YES;
}

- (void)cameraChangingStatus:(BMWCameraKitChangingStatus)changingStatus
{
    BOOL showBlur = changingStatus == BMWCameraKitChangingStatusProcessing || changingStatus == BMWCameraKitChangingStatusStop;
    
    CGFloat delay = changingStatus == BMWCameraKitChangingStatusStarted ? 0.1 : 0;
    if(changingStatus == BMWCameraKitChangingStatusSwitchProcessing) return;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (BMWGLView *glView in self.containerViews) {
            [glView showBlur:showBlur delay:delay];
        }
    });
}

- (void)currZoomFactorChanged:(CGFloat)factor
{
    self.currZoomFactor = factor;
}

- (void)simulateCaptureFlashWithCompletion:(void (^)(BOOL flashed))completion {
    if (self.cameraEntry.flashMode != AVCaptureFlashModeAuto && self.cameraEntry.flashMode != AVCaptureFlashModeOn) {
        runAsynchronouslyOnRenderingQueue(^{
            [BMWImageContext useImageProcessingContext];
            SafeBlock(completion, NO);
        });
        return;
    }
    
    [self.cameraEntry simulateCaptureFlashWithCompletion:^(BOOL flashed){
        runAsynchronouslyOnRenderingQueue(^{
            [BMWImageContext useImageProcessingContext];
            SafeBlock(completion, flashed);
        });
    }];
}

extern UIImage *imageFormAlbum;
- (void)capturePhotoWithBuilder:(void (^)(BMWImageCaptureProfile * profile))builder
                 statusCallBack:(void (^)(BMWCameraTakeImageStatus status))statusCallBack
             previewImgCallBack:(void (^)(UIImage * _Nullable, NSError * _Nullable))previewImageCallback
            originalImgCallBack:(void (^)(BMWImageCaptureMetaData* metaData, NSData *_Nullable, NSError * _Nullable))originalImgCallBack
           processedImgCallBack:(void (^)(BMWImageCaptureMetaData* metaData, NSData *_Nullable, NSError * _Nullable))processedImgCallBack
{
    double begin = CACurrentMediaTime();
    self.clearestFrameIndex = -1;
    // parse parameter
    BMWImageCaptureProfile *profile = [BMWImageCaptureProfile new];
    !builder ? : builder(profile);
    __block void (^myPreviewImageCallback)(UIImage * _Nullable, NSError * _Nullable);
    myPreviewImageCallback = previewImageCallback;
    

    {
        self.processedImageCallBack = nil;
        self.processedImageData = nil;
        self.processedImageError = nil;
        self.livePhotoError = nil;
        self.captureImageStatusCallBack = nil;
        self.capturedCameraKitMode = self.cameraEntry.cameraMode;
        self.captureLivePhoto = profile.enableLivePhoto && self.cameraSettingProfile.enableLivePhoto && self.cameraEntry.supportLivePhoto;
        profile.enableDeferredPreviewIamge = profile.enableDeferredPreviewIamge || self.captureLivePhoto;
    }
    BMWCameraKitMode cameraMode = self.cameraEntry.cameraMode;
    BMWDeviceOrientation orientaion = profile.orientaion;
    BMWWatermarkItem *watermark = profile.watermarkModel;
    CGFloat extraZoomFactor = self.cameraEntry.extraZoomFactor;
    BOOL isFront = self.cameraEntry.devicePosition == AVCaptureDevicePositionFront;
    BOOL isMirror = self.filterMode == BMWCameraModePhotoFrontMirror;
    CGSize orignalImageSize = [self.cameraEntry calcResolution:orientaion quality:profile.originalImageQuality ratioMode:cameraMode clampByDevice:YES];
    CGSize processedSize = [self.cameraEntry calcResolution:orientaion quality:self.imageQuality ratioMode:cameraMode clampByDevice:NO];
    // ori >= processed 取ori; ori < processed 取processed，ori另做压缩
    CGSize orignalImageSizeForRender = orignalImageSize;
    if(MAX(orignalImageSize.width, orignalImageSize.height) < MAX(processedSize.width, processedSize.height)) {
        orignalImageSizeForRender = processedSize;
    }
    BOOL useYUV = !self.isNightEnhanceEnabled;
    
    BMWMLog(@"takePhoto begin, orientaion:%d, needOriginal:%d, size:[%@,%@,%@]",orientaion, profile.needOriginalImage, @(orignalImageSizeForRender), @(orignalImageSize), @(processedSize));
    self.capturingImageCount++;
    self.lockSleepSemaphore = dispatch_semaphore_create(0);
    if (orientaion != self.deviceOrientation || self.hasSwitchCamera) {
        self.deviceOrientation = orientaion;
        self.hasSwitchCamera = NO;
    }

    // 根据分辨率设置是否高清水印
    [watermark calculateScaleByQuality:self.imageQuality];
    watermark.beginCapture = ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            SafeBlock(statusCallBack, BMWCameraTakeImageStatusBeginCaptureWatermark);
        });
    };
    
    BOOL enableLivePhoto = self.captureLivePhoto;
    // 构造水印list
    NSMutableArray *watermarks = [[NSMutableArray alloc] init];
    if(watermark) {
        watermark.cacheBuffer = enableLivePhoto;
        [watermarks addObject:watermark];
        if(!profile.enableShopSignRecognition) {
            [self.imageRender prepareWatermark:watermark];
        }
    }
    for (BMWWatermarkItem *item in profile.watermarkList) {
        item.cacheBuffer = enableLivePhoto;
        [watermarks addObject:item];
        [self.imageRender prepareWatermark:item];
    }
    
    if(self.productWatermark && !self.hiddenProductWatermark) {
        self.productWatermark.cacheBuffer = YES;
        [watermarks addObject:self.productWatermark];
        [self.imageRender prepareWatermark:self.productWatermark];
    }
    if (profile.codeDataModel) {
        BMWWatermarkItem *item = [BMWCodeHelper.sharedInstance codeWaterMark:processedSize model:profile.codeDataModel];
        if (item) {
            [watermarks addObject:item];
            item.cacheBuffer = enableLivePhoto;
            [self.imageRender prepareWatermark:item];
        }
    }
    if (enableLivePhoto) {
        self.watermarksForLivePhoto = watermarks;
    }
    
    NSArray<BMWWatermarkInfoV2 *> *watermarkInfoV2s = [BMWWatermarkItem createWatermarkInfoV2sFromItems:watermarks deviceOrientation:orientaion];
    [self.imageRender updateWatermarkInfoV2s:watermarkInfoV2s];
    [self.imageRender setBlindWatermarkModel:profile.blindWatermarkModel];
    self.imageRender.enableSliceImage = profile.enableSliceImage;
    
    BMWImageCaptureMetaData *captureMetaData = [[BMWImageCaptureMetaData alloc] init];
    BMWImageCaptureMetaData *orignalMetaData = [[BMWImageCaptureMetaData alloc] init];
    captureMetaData.preEndTimestamp = CACurrentMediaTime();
    captureMetaData.metadataObjects = orignalMetaData.metadataObjects = [self.cameraEntry fetchMetadataObjects];
    captureMetaData.clearestFrameIndex = -1;
    orignalMetaData.clearestFrameIndex = -1;
    
    BOOL enableDeferredPreviewIamge = (profile.enableDeferredPreviewIamge && self.cameraEntry.flashMode == AVCaptureFlashModeOn) || enableLivePhoto;
    // 获取预览图 && 泉眼检测
    @xhm_weakify(self);
    [self requestPreviewImage:cameraMode handler:^(UIImage * _Nullable image, NSError * _Nullable error) {
        @xhm_strongify(self);
        BMWMLog(@"takePhoto imageLabelingInfer enter");
        if(!enableDeferredPreviewIamge) {
            SafeBlock(previewImageCallback, image, error);
        } else if (enableLivePhoto) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (myPreviewImageCallback) {
                    myPreviewImageCallback(image, error);
                    myPreviewImageCallback = nil;
                }
            });
        }
        captureMetaData.clearestFrameIndex = self.clearestFrameIndex;
        orignalMetaData.clearestFrameIndex = self.clearestFrameIndex;
        [orignalMetaData setPreviewImageReady];
        [captureMetaData setPreviewImageReady];
    }];
    BMWTakePhotoImmediate immediate = BMWTakePhotoImmediateSuggest;

    // 国际化
    if(profile.enableTakePhotoImmediately) {
        immediate = BMWTakePhotoImmediateForce;
    }
    // 夜景模式，需要需要走拍照来提升效果
    if(self.isNightEnhanceEnabled) {
        immediate = BMWTakePhotoImmediateNone;
    }
    
    if(self.cameraSettingProfile.cameraStartupOpt & BMWCameraStartupOptDefaultImmediateMode) {
        immediate = BMWTakePhotoImmediateForce;
    }
    // 文本滤镜条件，硬性条件:滤镜选择推荐1 && 非夜景 && 非闪光灯
    __block BOOL enableTextFilter = profile.enableTextFilter && self.effectType == BMWEffectTypeBackWithTone && !self.isNightEnhanceEnabled && self.cameraEntry.isFlashAndTorchOff;
    BMWMLog(@"takePhoto takePhotoImmediately enter timecost:%lf",(CACurrentMediaTime()-begin)*1000);
    [self.cameraEntry takePhotoImmediately:immediate
                                    useYUV:useYUV
                           enableLivePhoto:enableLivePhoto
                       pairedVideoFilePath:profile.pairedVideoFilePath
                     capturedImageCallback:^(BMWCameraCapturedData *capturedData) {
        CVPixelBufferRef pixelBuffer = capturedData.pixelBuffer;
        CVPixelBufferRef mattePixelBuffer = capturedData.mattePixelBuffer;
        CMTime timestamp = capturedData.time;
        NSError *error = capturedData.error;
        BOOL immediate = capturedData.immediate;
        
        if (immediate && (self.cameraEntry.getMuteTakePhoto == 2)) {
            AudioServicesPlaySystemSound(1108);
        }
        
        @xhm_strongify(self);
        captureMetaData.postBeginTimestamp = CACurrentMediaTime();
        captureMetaData.previewLuminance = immediate ? -1 : self.frameRender.luminance;
        captureMetaData.isAmazingMode = immediate;
        if(profile.enableShopSignRecognition) {
            BMWMLog(@"prepare watermark shopsign:%@", captureMetaData.shopSignResult.toJsonStr);
            [self.imageRender prepareWatermark:watermark];
        }
        [captureMetaData waitPreviewImageReady:1.2];
        // 延迟给预览图
        if(enableDeferredPreviewIamge) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (myPreviewImageCallback) {
                    myPreviewImageCallback(self.previewImage, error);
                    myPreviewImageCallback = nil;
                }
            });
        }
        // 低分辨率 && 摄像头出错，采用摄像头截帧
        if ((error || pixelBuffer == nil) || immediate) {
            if (self.previewImage == nil) {
                if(!error) {
                    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                    userInfo[@"immediate"] = @(immediate);
                    [userInfo addEntriesFromDictionary:[self.cameraEntry cameraStateDic]];
                    error = [[NSError alloc] initWithDomain:@"拍照失败请重试" code:-1 userInfo:userInfo];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    SafeBlock(originalImgCallBack, orignalMetaData, nil, error);
                    self.captureImageStatusCallBack = statusCallBack;
                    self.processedImageData = nil;
                    self.processedImageMetaData = captureMetaData;
                    self.processedImageCallBack = processedImgCallBack;
                    self.processedImageError = error;
                    [self tryFinishImageProcess];
                });
                self.capturingImageCount--;
                dispatch_semaphore_signal(self.lockSleepSemaphore);
            } else {
                UIImage *image = self.previewImage;
#if !POD_CONFIGURATION_RELEASE_ONLINE

#endif
                self.imageRender.ignoreBeauty = self.previewImageHasFilterEffect;
                self.imageRender.ignoreFilter = self.previewImageHasFilterEffect;
                if (!CGSizeEqualToSize(image.size, orignalImageSize)) {
                    image = [image xhm_resizeImage:orignalImageSize];
                }
                CGFloat quality = profile.quality;
                if(profile.snapshotImageQuality > 0) {
                    quality = profile.snapshotImageQuality;
                }
                NSData *oriData = UIImageJPEGRepresentation(image, quality);
                dispatch_async(dispatch_get_main_queue(), ^{
                    SafeBlock(originalImgCallBack, orignalMetaData, oriData, error);
                });
                
                // 极速模式做图像质量检测
                if(profile.enableImageQualityDetect) {
                    captureMetaData.imageQualityAlgorithmResult = [[BMWClarityDetector new] imageQualityDetectWithImage:image];
                }
                [self.imageRender setDeviceOritaion:orientaion];
                [self.imageRender setTimestamp:self.previewImageTimestamp];
                // 文本滤镜条件，场景条件：文本场景或放大场景
                enableTextFilter = enableTextFilter && (orignalMetaData.cameraImageClsResult.isTextScene || self.cameraEntry.currZoomFactor >= 1.1);
                captureMetaData.isTextFilter = enableTextFilter;
                [self processImageInternal:image
                      extraSliceRectsBlock:[self getExtraSliceRectsBlockWithProfile:profile metadata:captureMetaData]
                                watermarks:watermarks processedSize:processedSize sync:NO enableTextFilter:enableTextFilter processedImgCallBack:^(UIImage * _Nullable processedImg, BMWPocessedMetaData * _Nullable pocessedMetaData, NSError * _Nullable error2) {
                    NSData *processedData = nil;
                    CGFloat quality = profile.quality;
                    if(profile.snapshotImageQuality > 0) {
                        quality = profile.snapshotImageQuality;
                    }
                    if (processedImg && !error2) {
                        if (GPCamConfigurator.sharedInstance.jpegCodecSDKForTakePhoto == 1) {
                            processedData = [processedImg xhm_jpegData:quality];
                        } else {
                            processedData = UIImageJPEGRepresentation(processedImg, quality);
                        }
                    }
                    captureMetaData.imageSize = processedImg.size;
                    captureMetaData.sliceDataModel = pocessedMetaData.sliceDataModel;
                    captureMetaData.clarityOptStatus = pocessedMetaData.sliceDataModel.clarityOpt;
                    captureMetaData.capturedMode = 1;
                    captureMetaData.imageFeature = pocessedMetaData.imageFeature;
                    captureMetaData.locationRect = pocessedMetaData.locationRect;
                    captureMetaData.timeRects = pocessedMetaData.timeRects;
                    [self.imageRender reset];
                    CGFloat time = profile.enableShopSignRecognition ? 0.6 : 0.4;
                    BOOL imageClsReady = NO;
                    if(profile.enableImageLabeling) {
                        imageClsReady=  [captureMetaData waitMetaDataReady:time];
                    }
                    BMWMLog(@"takePhoto immediate total timecost:%lf, image cls ready:%d,locationRect:%@",(CACurrentMediaTime()-begin)*1000, imageClsReady, captureMetaData.locationRect);
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.captureImageStatusCallBack = statusCallBack;
                        self.processedImageData = processedData;
                        self.processedImageMetaData = captureMetaData;
                        self.processedImageCallBack = processedImgCallBack;
                        self.processedImageError = error2;
                        [self tryFinishImageProcess];
                    });
                }];
            }
            return;
        }
        // 正常拍照处理流程
        BOOL pngCompress = mattePixelBuffer != nil;
        self.imageRender.isFront = isFront;
        self.imageRender.isMirror = isMirror;
        [self.imageRender setTimestamp:timestamp];
        [self.imageRender setDeviceOritaion:orientaion];
        [self.imageRender setExtraScaleRatio:extraZoomFactor];
        [self.imageRender setRenderOutputSize:orignalImageSizeForRender];
        @xhm_weakify(self);
        [self.imageRender processOrginalWithPixelbuffer:^(BMWOrginalRenderModel * _Nonnull model) {
            model.pipSampleBuffer = self.enableDisplayFrontCameraInSubPreview ? NULL : capturedData.pipSampleBuffer;
            model.pixelBuffer = pixelBuffer;
            model.maskPixelBuffer = mattePixelBuffer;
            model.previewImage = self.previewImage;
            model.clarityDetectMode = BMWClarityDetectModeClose;
            model.enableImageQualityDetect = profile.enableImageQualityDetect;
            BOOL flashOff = self.cameraEntry.isFlashAndTorchOff && self.previewImage != nil;
            if(flashOff && profile.enableClarityOpt) {
                model.clarityDetectMode = GPCamConfigurator.sharedInstance.enableClarityDetect;
                model.previewClarityOffsetForIOS = GPCamConfigurator.sharedInstance.previewClarityOffsetForIOS;
                model.clarityThreshold = GPCamConfigurator.sharedInstance.clarityThreshold;
            }
            if(flashOff) {
                model.enableSimilarityCheck = profile.enableSimilarityCheck;
            }
        } block:^(UIImage * _Nullable image, BMWOrginalMetaData *metaData, NSError * _Nullable error) {
            @xhm_strongify(self);
            captureMetaData.previewCapturedSimilarity = metaData.previewCapturedSimilarity;
            captureMetaData.previewClarity = metaData.previewClarity;
            captureMetaData.capturedClarity = metaData.capturedClarity;
            if (error || image == nil) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    SafeBlock(originalImgCallBack, orignalMetaData, nil, error);
                    self.captureImageStatusCallBack = statusCallBack;
                    self.processedImageMetaData = captureMetaData;
                    self.processedImageCallBack = processedImgCallBack;
                    self.processedImageError = error;
                    [self tryFinishImageProcess];
                });
                self.capturingImageCount--;
                if (self.capturingImageCount <= 0) {
                    self.previewImage = nil;
                }
                dispatch_semaphore_signal(self.lockSleepSemaphore);
                return;
            }
            
            if(profile.needOriginalImage) {
                if(!CGSizeEqualToSize(orignalImageSizeForRender, orignalImageSize)) {
                    image = [image xhm_resizeImage:orignalImageSize];
                }
                NSData *oriData = nil;
                if(pngCompress) {
                    oriData = UIImagePNGRepresentation(image);
                } else {
                    oriData = UIImageJPEGRepresentation(image, profile.quality);
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    SafeBlock(originalImgCallBack, orignalMetaData, oriData, error);
                });
            }
            // 文本滤镜条件，场景条件：文本场景或放大场景
            enableTextFilter = enableTextFilter && (orignalMetaData.cameraImageClsResult.isTextScene || self.cameraEntry.currZoomFactor >= 1.1);
            captureMetaData.isTextFilter = enableTextFilter;
            [self processImageInternal:nil
                  extraSliceRectsBlock:[self getExtraSliceRectsBlockWithProfile:profile metadata:captureMetaData]
                            watermarks:watermarks processedSize:processedSize sync:YES enableTextFilter:enableTextFilter processedImgCallBack:^(UIImage * _Nullable processedImg, BMWPocessedMetaData * _Nullable pocessedMetaData,  NSError * _Nullable error2) {
                NSData *processedData = nil;
                if (processedImg && !error2) {
                    if(pngCompress) {
                        processedData = UIImagePNGRepresentation(processedImg);
                    } else {
                        if (GPCamConfigurator.sharedInstance.jpegCodecSDKForTakePhoto == 1) {
                            processedData = [processedImg xhm_jpegData:profile.quality];
                        } else {
                            processedData = UIImageJPEGRepresentation(processedImg, profile.quality);
                        }
                    }
                }
                captureMetaData.imageSize = processedImg.size;
                captureMetaData.sliceDataModel = pocessedMetaData.sliceDataModel;
                captureMetaData.clarityOptStatus = pocessedMetaData.sliceDataModel.clarityOpt;
                captureMetaData.imageFeature = pocessedMetaData.imageFeature;
                captureMetaData.locationRect = pocessedMetaData.locationRect;
                captureMetaData.timeRects = pocessedMetaData.timeRects;
                [self.imageRender reset];
                BMWMLog(@"takePhoto total timecost:%lf,locationRect:%@",(CACurrentMediaTime()-begin)*1000, captureMetaData.locationRect);
                dispatch_async(dispatch_get_main_queue(), ^{
                    self.captureImageStatusCallBack = statusCallBack;
                    self.processedImageData = processedData;
                    self.processedImageMetaData = captureMetaData;
                    self.processedImageCallBack = processedImgCallBack;
                    self.processedImageError = error2;
                    [self tryFinishImageProcess];
                });
            }];
        }];
    }
           pairedVideoDurationAfterCapture: profile.needConfirm ? 0.5 : 1.0
                     capturedVideoCallback:^(double videoDuration, double photoDisplayTime, NSError * _Nonnull error) {
        @xhm_strongify(self);
        captureMetaData.livePhotoDisplayTime = photoDisplayTime;
        [self processLivePhotoVideoWithDuration:videoDuration
                               photoDisplayTime:photoDisplayTime
                                    orientation:orientaion
                                         mirror:!isMirror && isFront
                                       metadata:profile.pairedVideoMetadata
                              contentIdentifier:profile.livePhotoIdentifier
                                 outputFilePath:profile.pairedVideoFilePath
                                     watermarks:watermarks
                                  videoDuration:videoDuration
                                          error:error];
    }];
    if((GPCamConfigurator.sharedInstance.imageLabelingMethod & BMWImageLabelingMethodOCR) && profile.enableImageLabeling &&
       ![BMWAlgorithmModelManager.sharedInstance isCloudModel:BMWAlgorithmModelManager.sharedInstance.ocrv3Path]) {
        SafeBlock(statusCallBack, BMWCameraTakeImageStatusRequestDownloadModel);
    }
}

- (void)processLivePhotoVideoWithDuration:(double)videoDuration
                         photoDisplayTime:(double)photoDisplayTime
                              orientation:(BMWDeviceOrientation)orientation
                                   mirror:(BOOL)mirror
                                 metadata:(NSString *)metadata
                        contentIdentifier:(NSString *)contentIdentifier
                           outputFilePath:(NSString *)outputFilePath
                               watermarks:(NSArray<BMWWatermarkItem *> *)watermarks
                            videoDuration:(double)videoDuration
                                    error:(NSError *)error {
    // 开闪光灯拍照会报错，但是视频及图片都正常生成了
    if (error && ![NSFileManager.defaultManager fileExistsAtPath:outputFilePath]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.livePhotoError = error;
            [self tryFinishImageProcess];
        });
        return;
    }
    self.cameraEntry.livePhotoCaptureSuspended = YES;
}

- (CGFloat)getWidthAndHeightRatio {
    CGFloat ratio = 3.0f / 4.0f;
    if (self.capturedCameraKitMode == BMWCameraKitModeVideo || self.capturedCameraKitMode == BMWCameraKitModePhoto16x9) {
        ratio = 9.0 / 16.0;
    } else if (self.capturedCameraKitMode == BMWCameraKitModePhoto1x1) {
        ratio = 1.0;
    } else if (self.capturedCameraKitMode == BMWCameraKitModePhotoFull) {
        ratio = BMWDeviceUtils.sharedInstance.deviceRatio;
    }
    return ratio;
}

- (CGFloat)getVideoRotation:(BMWDeviceOrientation)orientation {
    BOOL isFront = self.cameraEntry.devicePosition == AVCaptureDevicePositionFront;
    CGFloat rotation = 0;
    switch (orientation) {
        case BMWDeviceOrientationPortait:
            rotation = 0;
            break;
        case BMWDeviceOrientationLeft:
            rotation = 270;
            break;
        case BMWDeviceOrientationDown:
            rotation = 180;
            break;
        case BMWDeviceOrientationRight:
            rotation = 90;
            break;
        default:
            rotation = 0;
            break;
    }

    return isFront ? 360 - rotation : rotation;
}

- (void)tryFinishImageProcess {
    BOOL videoReady = self.livePhotoError;
    BOOL imageReady = self.processedImageData || self.processedImageError || self.processedImageMetaData;
    if ((!videoReady && self.captureLivePhoto) || !imageReady) {
        return;
    }
    
    for (BMWWatermarkItem *item in self.watermarksForLivePhoto) {
        item.buffer = nil;
        item.cacheBuffer = NO;
    }
    self.watermarksForLivePhoto = nil;
    
    SafeBlock(self.captureImageStatusCallBack, BMWCameraTakeImageStatusReadyForNext);
    NSError *error = self.processedImageError ? self.processedImageError : self.livePhotoError;
    SafeBlock(self.processedImageCallBack, self.processedImageMetaData, self.processedImageData, error);
    
    self.captureImageStatusCallBack = nil;
    self.processedImageData = nil;
    self.processedImageMetaData = nil;
    self.processedImageCallBack = nil;
    self.processedImageError = nil;
    self.captureLivePhoto = NO;
}

- (void)capturePhotoWhenRecording:(void (^)(BMWImageCaptureProfile * profile))builder
             processedImgCallBack:(void (^)(BMWImageCaptureMetaData* metaData, NSData *_Nullable, NSError * _Nullable))processedImgCallBack
{
    double begin = CACurrentMediaTime();
    // parse parameter
    BMWImageCaptureProfile *profile = [BMWImageCaptureProfile new];
    !builder ? : builder(profile);
    BMWDeviceOrientation orientaion = profile.orientaion;
    BMWWatermarkItem *watermark = profile.watermarkModel;
    BOOL isFront = self.cameraEntry.devicePosition == AVCaptureDevicePositionFront;
    BOOL isMirror = self.filterMode == BMWCameraModeVideoFrontMirror;
    CGSize processedSize = [self.cameraEntry calcResolution:orientaion quality:BMWImageResolutionQualityMedium ratioMode:BMWCameraKitModePhoto16x9 clampByDevice:NO];
    BMWMLog(@"takePhoto when recording, orientaion:%d",orientaion);
    // 构造水印list
    NSMutableArray *watermarks = [[NSMutableArray alloc] init];
    if(watermark) {
        [watermarks addObject:watermark];
        [self.imageRender prepareWatermark:watermark];
    }
    for (BMWWatermarkItem *item in profile.watermarkList) {
        [watermarks addObject:item];
        [self.imageRender prepareWatermark:item];
    }
    if(self.productWatermark && !self.hiddenProductWatermark) {
        [watermarks addObject:self.productWatermark];
        [self.imageRender prepareWatermark:self.productWatermark];
    }
    if (profile.codeDataModel) {
        BMWWatermarkItem *item = [BMWCodeHelper.sharedInstance codeWaterMark:processedSize model:profile.codeDataModel];
        if (item) {
            [watermarks addObject:item];
            [self.imageRender prepareWatermark:item];
        }
    }
    NSArray<BMWWatermarkInfoV2 *> *watermarkInfoV2s = [BMWWatermarkItem createWatermarkInfoV2sFromItems:watermarks deviceOrientation:orientaion];
    [self.imageRender updateWatermarkInfoV2s:watermarkInfoV2s];
    [self.imageRender setBlindWatermarkModel:profile.blindWatermarkModel];
    self.imageRender.enableSliceImage = profile.enableSliceImage;
    
    BMWImageCaptureMetaData *captureMetaData = [[BMWImageCaptureMetaData alloc] init];
    BMWImageCaptureMetaData *orignalMetaData = [[BMWImageCaptureMetaData alloc] init];
    captureMetaData.preEndTimestamp = CACurrentMediaTime();
    captureMetaData.postBeginTimestamp = CACurrentMediaTime();
    runAsynchronouslyOnRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        UIImage *capturedImage = [self.frameRender renderPreview:isMirror outputSize:CGSizeZero orientation:orientaion];
        if (capturedImage == nil) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo addEntriesFromDictionary:[self.cameraEntry cameraStateDic]];
            NSError*error = [[NSError alloc] initWithDomain:@"拍照失败请重试" code:-1 userInfo:userInfo];
            dispatch_async(dispatch_get_main_queue(), ^{
                SafeBlock(processedImgCallBack, captureMetaData, nil, error);
            });
            return;
        }
    
        // 预览图上已经有滤镜和美颜了，再叠加一次会效果异常
        self.imageRender.ignoreBeauty = YES;
        self.imageRender.ignoreFilter = YES;
        [self.imageRender setDeviceOritaion:orientaion];
        [self.imageRender setTimestamp:CMTimeMakeWithSeconds(CACurrentMediaTime() / 1000.0, 30)];
        [self.imageRender setRenderOutputSize:processedSize];
        @xhm_weakify(self);
        [self.imageRender processImageWithOriginal:^(BMWProcessRenderModel * _Nonnull model) {
            @xhm_strongify(self);
            model.enableImageFeature = YES;
            model.enableTextFilter = NO;
            model.inEditMode = NO;
            model.image = capturedImage;
            model.sync = NO;
            model.watermarks = watermarks;
            model.effectType = BMWEffectTypeOriginal;
        } textureBlock:nil imageBlock:^(UIImage * _Nullable processedImage, BMWPocessedMetaData *pocessedMetaData, NSError * _Nullable error2) {
            @xhm_strongify(self);
            NSData *processedData = UIImageJPEGRepresentation(processedImage, profile.quality);
            captureMetaData.imageSize = processedImage.size;
            captureMetaData.sliceDataModel = pocessedMetaData.sliceDataModel;
            captureMetaData.clarityOptStatus = pocessedMetaData.sliceDataModel.clarityOpt;
            captureMetaData.imageFeature = pocessedMetaData.imageFeature;
            captureMetaData.locationRect = pocessedMetaData.locationRect;
            captureMetaData.timeRects = pocessedMetaData.timeRects;
            [self.imageRender reset];
            BMWMLog(@"takePhoto when recoding total timecost:%lf,locationRect:%@",(CACurrentMediaTime()-begin)*1000, captureMetaData.locationRect);
            dispatch_async(dispatch_get_main_queue(), ^{
                SafeBlock(processedImgCallBack, captureMetaData, processedData, error2);
            });
        }];
    });
}

- (void)captureCameraFrameImage:(CGSize)outputSize callBack:(void (^)(UIImage* image, NSError * _Nullable))callBack
{
    runAsynchronouslyOnRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        NSError *error = nil;
        UIImage *capturedImage = [self.frameRender renderPreview:NO outputSize:outputSize orientation:self.deviceOrientation];
        if (capturedImage == nil) {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            [userInfo addEntriesFromDictionary:[self.cameraEntry cameraStateDic]];
            error = [[NSError alloc] initWithDomain:@"拍照失败请重试" code:-1 userInfo:userInfo];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            SafeBlock(callBack, capturedImage, error);
        });
    });
}

- (void)captureFaceAttribute:(void (^)(BMWFaceAttributeAlgorithmResult* attribute))callBack
{
//    BMWFaceAttributeAlgorithmResult* r = [BMWFaceAttributeCache.sharedInstance findBestFaceAttribute];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        SafeBlock(callBack, r);
//    });
}

- (NSArray<BMWRect *> *(^)(void))getExtraSliceRectsBlockWithProfile:(BMWImageCaptureProfile *)profile metadata:(BMWImageCaptureMetaData *)metadata {
    if (!profile.shouldOptimizeElectronicScreenCapture) {
        return ^NSArray<BMWRect *> *{
            return @[];
        };
    }
    
    return ^NSArray<BMWRect *> *{
        BMWMLog(@"start waitMetaDataReady");
        [metadata waitMetaDataReady:0.6];
        BMWMLog(@"end waitMetaDataReady");
        
        return [metadata filterImageClsResultWithLabel:@"electronic_scale"];
    };
}

- (void)processImageInternal:(UIImage*)image
        extraSliceRectsBlock:(NSArray<BMWRect *> *(^)(void))extraSliceRectsBlock
                  watermarks:(NSArray<BMWWatermarkItem*>*)watermarks
               processedSize:(CGSize)processedSize
                        sync:(BOOL)sync
            enableTextFilter:(BOOL)enableTextFilter
        processedImgCallBack:(void (^)(UIImage *_Nullable, BMWPocessedMetaData* _Nullable, NSError *_Nullable))processedImgCallBack;
{
    // 重新设置处理后图片尺寸
    [self.imageRender setRenderOutputSize:processedSize];
    @xhm_weakify(self);
    [self.imageRender processImageWithOriginal:^(BMWProcessRenderModel * _Nonnull model) {
        @xhm_strongify(self);
        model.enableImageFeature = YES;
        model.enableTextFilter = enableTextFilter;
        model.inEditMode = NO;
        model.image = image;
        model.sync = sync;
        model.watermarks = watermarks;
        model.extraSliceRectsBlock = extraSliceRectsBlock;
    } textureBlock:nil imageBlock:^(UIImage * _Nullable processedImage, BMWPocessedMetaData* pocessedMetaData, NSError * _Nullable error) {
        @xhm_strongify(self);
        BMWMLog(@"takePhoto process image finish enter");
        processedImgCallBack(processedImage, pocessedMetaData, error);
        self.capturingImageCount--;
        if (self.capturingImageCount <= 0) {
            self.previewImage = nil;
        }
        dispatch_semaphore_signal(self.lockSleepSemaphore);
        BMWMLog(@"takePhoto process image finish leave");
    }];
}

- (void)configureProductWatermarkInfo:(nullable BMWWatermarkItem *)watermarkViewInfo
{
    watermarkViewInfo.highResolution = YES;
    watermarkViewInfo.scale = 4.0;
    _productWatermark = watermarkViewInfo;
}

- (void)setHiddenProductWatermark:(BOOL)hiddenProductWatermark
{
    _hiddenProductWatermark = hiddenProductWatermark;
    _productWatermark.hidden = hiddenProductWatermark;
    BMWMLog(@"hiddenProductWatermark:%d", hiddenProductWatermark);
}

- (void)requestAntiFraud:(void (^)(BMWAntiFraudReslut * _Nullable))callback
{
    if(GPCamConfigurator.sharedInstance.enableAntiFraud == 0) return;
    if(callback) {
        [self.cameraEntry addMetadataOutput:BMWCaptureMetadataTypeAll];
    } else if(self.antiFraudCallback != nil && callback == nil) {
        [self.cameraEntry removeMetadataOutput];
    }
    self.antiFraudCallback = callback;
    self.antiFraudDetectStatus.index = 0;
    self.antiFraudDetectStatus.enable = callback != nil;
    self.antiFraudDetectStatus.processing = NO;
}

- (void)startDetectWithRequestBuilder:(nullable void (^)(BMWCodeRequestModel* model))builder
                        completeBlock:(nullable void (^)(BMWCodeReslutModel* _Nullable reslutModel, NSError *_Nullable error))completeBlock
                       luminanceBlock:(nullable void (^)(CGFloat luminance))luminanceBlock
{
    self.codeDetectRequestModel = nil;
    if(builder) {
        self.codeDetectRequestModel = [[BMWCodeRequestModel alloc] init];
        SafeBlock(builder, self.codeDetectRequestModel);
    }
    self.codeDetectCallback = completeBlock;
    self.luminanceCallback = luminanceBlock;
}

// 关闭实时算法检测
- (void)stopDetect
{
    self.codeDetectRequestModel = nil;
    self.codeDetectCallback = nil;
    self.luminanceCallback = nil;
}

#pragma mark - Utils

- (void)codeDet:(NSArray<BMWOCRMetaData*>*)metadataObjects texId:(int)texId inputSize:(CGSize)inputSize
{
    if(self.codeDetectCallback == nil) return;

    // 处理条形码和二维码
    BMWCodeReslutModel *reslutModel = [[BMWCodeReslutModel alloc] init];
    if((self.codeDetectRequestModel.type & BMWCodeDetectTypeBarCode) == BMWCodeDetectTypeBarCode ||
       (self.codeDetectRequestModel.type & BMWCodeDetectTypeQRCode) == BMWCodeDetectTypeQRCode) {
        [BMWCodeDetectManager.sharedInstance detectV2WithRequestBulder:^(BMWCodeRequestModel * _Nonnull model) {
            model.type = self.codeDetectRequestModel.type;
            model.image = self.frameRender.outputImage;
        } completeBlock:^(BMWCodeReslutModel * _Nullable reslutModel, NSError * _Nullable error) {
            BMWMLog(@"codeDet BarCode:%@",reslutModel);
            dispatch_async(dispatch_get_main_queue(), ^{
                SafeBlock(self.codeDetectCallback, reslutModel, error);
            });
        }];
    } 
    
    
}

- (void)antiFraudDet:(NSArray*)metadataObjects texId:(int)texId inputSize:(CGSize)inputSize
{
    if(self.antiFraudDetectStatus.enable == NO) return;
    if(self.antiFraudCallback == nil) return;
    if(metadataObjects.count == 0) return;
    if(self.cameraWriter.writerStatus == BMWCameraWriterStatusRecording) return;
    if(self.antiFraudDetectStatus.processing == YES) return;
    if(self.antiFraudDetectStatus.index >= self.antiFraudDetectStatus.maxCount) return;
    BMWAntiFraudReslut *antiFraudReslut = [[BMWAntiFraudReslut alloc] init];
    AVMetadataMachineReadableCodeObject* obj = metadataObjects.firstObject;
    if([obj isKindOfClass:[AVMetadataMachineReadableCodeObject class]]) {
        antiFraudReslut.qrCode = obj.stringValue;
    }
    BOOL shouldOCR = (GPCamConfigurator.sharedInstance.enableAntiFraud & 0x2);
   
}

#pragma mark 拍照获取预览图
- (void)requestPreviewImage:(BMWCameraKitMode)cameraMode handler:(void (^)(UIImage* _Nullable, NSError* _Nullable))handler
{
    if ([self.cameraEntry captureImageImmediateIfNeeded:BMWTakePhotoImmediateForce] &&
        self.enableClearestFrameSelector &&
        (GPCamConfigurator.sharedInstance.previewImageGenerateMode & 0x10)) {
        runAsynchronouslyOnRenderingQueue(^{
            [BMWImageContext useImageProcessingContext];
            BOOL mirror = self.filterMode == BMWCameraModePhotoFrontMirror || self.filterMode == BMWCameraModeVideoFrontMirror;
            CMTime timestampe = kCMTimeInvalid;
            NSInteger clearestFrameIndex = -1;
            UIImage *image = [self.clearestFrameSelector getClearestFrameWithMirror:mirror
                                                                        orientation:(int)self.deviceOrientation
                                                                          timestamp:&timestampe
                                                                         frameIndex:&clearestFrameIndex];
            if (image) {
                self.previewImage = image;
                if (GPCamConfigurator.sharedInstance.previewImageGenerateMode & 0x8) {
                    self.previewImage = [self.previewImage xhm_resizeImage:image.size];
                    BMWMLog(@"capture preview image resize clearest frame");
                }
                self.previewImageHasFilterEffect = YES;
                self.previewImageTimestamp = timestampe;
                self.hasGotPreviewImage = YES;
                self.clearestFrameIndex = clearestFrameIndex;
                SafeBlock(handler, image, nil);
            } else {
                [self.frameRender triggerLuminanceDetect:YES];
                self.hasGotPreviewImage = NO;
                self.previewImageCallback = handler;
            }
            BMWMLog(@"capture preview image using clearest frame: %@", image);
        });
        return;
    }
    self.previewImageCallback = handler;
    [self.frameRender triggerLuminanceDetect:YES];
    self.hasGotPreviewImage = NO;
}

- (void)waitingPreviewImageReady
{
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(1.2 * NSEC_PER_SEC));
    if(0 != dispatch_semaphore_wait(self.previewImageFetchSemaphore, timeout))  {
        BMWMLog(@"takePhoto capture preview image timeout ...");
    }
}

- (void)capturePreviewImageIfNeeded:(CMSampleBufferRef)sampleBuffer cameraMode:(BMWCameraKitMode)cameraMode isFront:(BOOL)isFront isMirror:(BOOL)isMirror orient:(BMWDeviceOrientation)orientation extraZoomFactor:(CGFloat)extraZoomFactor
{
    // 非录制状态截预览图
    if (self.hasGotPreviewImage == NO && self.cameraWriterInited == NO) {
        double begin = CACurrentMediaTime();
        self.hasGotPreviewImage = YES;
        int cutMode = 0;
        if (cameraMode == BMWCameraKitModePhoto1x1) {
            cutMode = 1;
        } else if (cameraMode == BMWCameraKitModePhotoFull) {
            cutMode = 3;
        }
        CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        self.previewImageTimestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
        BOOL nwepreviewM = ([BMWDeviceUtils isLowerThaniPhone6] && (GPCamConfigurator.sharedInstance.previewImageGenerateMode & 0x1)) || (GPCamConfigurator.sharedInstance.previewImageGenerateMode & 0x2);
        if (GPCamConfigurator.sharedInstance.previewImageGenerateMode & 0x4) {
            self.previewImage = [self.frameRender renderPreview:isMirror outputSize:CGSizeZero orientation:orientation];
            self.previewImage = [self.previewImage xhm_resizeImage:self.previewImage.size];
            BMWMLog(@"capture preview image with resize preview image");
            self.previewImageHasFilterEffect = YES;
        } else if(nwepreviewM) {
            self.previewImage = [self.frameRender renderPreview:isMirror outputSize:CGSizeZero orientation:orientation];
            BMWMLog(@"capture preview image with frame render");
            self.previewImageHasFilterEffect = YES;
        } else {
            self.previewImage = [BMWBufferUtils createImageFromPixelBuffer:pixelBuffer isFront:isFront isMirror:isMirror orient:orientation scale:extraZoomFactor cut:cutMode];
            BMWMLog(@"capture preview image from pixelbuffer");
            self.previewImageHasFilterEffect = NO;
        }
        NSError *error = nil;
        if (self.previewImage == nil) {
            error = [[NSError alloc] initWithDomain:@"capture preview image fail" code:GPCamTakePhotoImageCreateError userInfo:nil];
        }
        SafeBlock(self.previewImageCallback, self.previewImage, error);
        BMWMLog(@"capturePreviewImageIfNeeded timecost:%lf, nwepreviewM:%d",(CACurrentMediaTime()-begin)*1000, YES);//nwepreviewM);
    }
}

#pragma mark 录制获取预览图
- (void)captureVideoPreviewImageIfNeeded:(CVPixelBufferRef)pixelBuffer timestamp:(CMTime)timestamp
{
    if (self.hasGotPreviewImage == NO) {
        self.hasGotPreviewImage = YES;
        self.previewImageTimestamp = timestamp;
        self.previewImage = [BMWBufferUtils createImageFromPixelBuffer:pixelBuffer];
        self.previewImageHasFilterEffect = YES;
    }
}

- (void)updateEffectType
{
    BMWEffectType effectType = BMWEffectTypeOriginal;
    if (_filterMode == BMWCameraModeNone) {
        effectType = BMWEffectTypeOriginalWithoutSharpen;
    } else {
        if (self.cameraEntry.devicePosition == AVCaptureDevicePositionFront) {
            effectType = BMWEffectTypeFront;
        } else {
            if (self.filterId == RECOMMEND_FILTER_ID) {
                effectType = BMWEffectTypeBackWithTone;
            } else if(self.filterId != NONE_FILTER_ID){
                effectType = BMWEffectTypeBackWithoutTone;
            }
        }
    }
    [self.imageRender setEffectType:effectType];
    [self.frameRender setEffectType:effectType];
    self.effectType = effectType;
}

- (void)addObservers
{
    [BMWALifeCycleHelper.sharedInstance addBackgroundObserver:self];
    [BMWALifeCycleHelper.sharedInstance addWillResignActiveObserver:self];
}

- (void)removeObservers
{
    [BMWALifeCycleHelper.sharedInstance removeBackgroundObserver:self];
    [BMWALifeCycleHelper.sharedInstance removeWillResignActiveObserver:self];
}

- (void)willResignActive
{
    self.lastTimestamp = 0;
    if(GPCamConfigurator.sharedInstance.clearGLContextInMainThread & 0x10) {
        if(EAGLContext.currentContext) {
            [EAGLContext setCurrentContext:nil];
        }
    }
}

- (void)didEnterBackground
{
    BMWMLog(@"BMWCamera didEnterBackgroundNotification enter ...");
    
    if (self.capturingImageCount > 0) {
        dispatch_semaphore_wait(self.lockSleepSemaphore, DISPATCH_TIME_FOREVER);
    }
    self.capturingImageCount = 0;
    [self.imageRender reset];
    
    runSynchronouslyRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        for (BMWGLView *glView in self.containerViews) {
            [glView destoryBuffers];
        }
    });
    [BMWImageContext close];
    BMWMLog(@"BMWCamera didEnterBackgroundNotification leave ...");
}

// override BMWVideoAlgorithmSource
- (NSString*)tag
{
    return @"CameraSource";
}

@end
