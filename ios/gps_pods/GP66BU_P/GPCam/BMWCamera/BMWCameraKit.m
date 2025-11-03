#import "BMWCameraKit.h"
#import "BMWDeviceUtils.h"
#import "GPCamDefine.h"
#import "BMWBufferUtils.h"
#import "BMWCameraKit+Extra.h"
#import "BMWImageContext.h"
#import "BMWALifeCycleHelper.h"
#import "BMWErrorHelper.h"
#import "BMWVideoAlgorithmResult.h"
#import "BMWSliceData.h"
#import "BMWAudioKit.h"
#import "BMWCameraKit+Flash.h"

static BOOL ShouldTakePhotoPreviously = YES;
typedef void(^CaptureImageCompleteBlock)(BMWCameraCapturedData* data);
typedef void(^CaptureVideoCompleteBlock)(double videoDuration, double photoDisplayTime, NSError *error);
static const NSInteger kDefaultRetryRebuildCameraCount = 3;

@interface BMWLivePhotoCapturedVideoInfo : NSObject

@property (nonatomic, assign) double videoDuration;

@property (nonatomic, assign) double photoDisplayTime;

@property (nonatomic, strong) NSError *videoError;

@end

@implementation BMWLivePhotoCapturedVideoInfo

@end

@interface BMWCameraKit () <BMWAudioSource>

@property (nonatomic, strong) AVCaptureSession *captureSession;

@property (nonatomic, strong) NSArray<AVCaptureDeviceType>* deviceTypes;

@property (nonatomic, strong) NSError* error;

// video&image
@property (nonatomic, strong) AVCaptureDevice *inputCamera;
@property (nonatomic, strong) AVCaptureDeviceInput *videoInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoOutput;
@property (nonatomic, strong) AVCapturePhotoOutput* imageOutput;

// audio
@property (nonatomic, strong) AVCaptureDevice *microphone;
@property (nonatomic, strong) AVCaptureDeviceInput *audioInput;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioOutput;
@property (nonatomic, strong) id<BMWAudioKitDelegate> audioDelegate;

// metadata
@property (nonatomic, strong) AVCaptureMetadataOutput *metadataOutput;
@property (nonatomic, strong) NSMutableArray *metadataObjects;

// wide angle
@property (nonatomic, assign) BOOL isSupportWideAngle;

// 显示的Zoom Factor
// 支持广角的情况: currZoomFactor表示当前的缩放比例, [0.5, 1.0)表示广角摄像头, [1, maxZoomFactor]表示普通摄像头
// 不支持支持广角的情况: currZoomFactor表示当前的缩放比例，[1, maxZoomFactor]表示普通摄像头的缩放
@property (nonatomic, assign) CGFloat currZoomFactor;
@property (nonatomic, assign) CGFloat maxZoomFactor;
// Device的Zoom Factor
@property (nonatomic, assign) CGFloat deviceMaxZoomFactor;
@property (nonatomic, assign) CGFloat defaultDeviceZoomFactor;

@property (nonatomic, assign) CGPoint focusPointOfInterest;

//统计
@property (nonatomic, assign) CFAbsoluteTime lastCheckTime;
@property (nonatomic, assign) int framesSinceLastCheck;
@property (nonatomic, assign) int fps;
@property (nonatomic, assign) CFTimeInterval takePhotoBeginStamp;

// others
@property (nonatomic, assign) CGFloat preScale;
@property (nonatomic, assign) BOOL isForSwitchCamera;
@property (nonatomic, assign) AVCaptureFlashMode flashMode;
@property (nonatomic, assign) AVCaptureTorchMode torchMode;
@property (nonatomic, assign) BOOL canSwitchCamera;
@property (nonatomic, assign) BMWCameraKitChangingStatus changingStatus;
@property (nonatomic, assign) BOOL cameraColdInited;
@property (nonatomic, copy) CaptureImageCompleteBlock takePhotoCompleteBlock;
@property (nonatomic, strong) BMWCameraCapturedData *capturedData;
@property (nonatomic, copy) CaptureVideoCompleteBlock captureVideoCompleteBlock;
@property (nonatomic, strong) BMWLivePhotoCapturedVideoInfo *videoInfo;
@property (nonatomic, assign) double pairedVideoDurationAfterCapture;
@property (nonatomic, assign) BOOL livePhotoCaptureEnabled;
@property (nonatomic, strong) AVCaptureSessionPreset curSessionPreset;
@property (nonatomic, assign) BOOL isCameraRuning;
@property (nonatomic, strong) BMWCameraKitSettingProfile *settingProfile;
@property (nonatomic, assign) BOOL started;
@property (nonatomic, assign) BOOL receiveVideoDeviceNotAvailableWithMultipleForegroundAppsError;
@property(nonatomic, assign) NSInteger retryRebuildCameraCount;
@end

@implementation BMWCameraKit

- (void)dealloc
{
    [self removeObservers];
    [self.videoOutput setSampleBufferDelegate:nil queue:nil];
    [self.audioOutput setSampleBufferDelegate:nil queue:nil];
    [self.metadataOutput setMetadataObjectsDelegate:nil queue:nil];
    BMWMLogM(@"BMWCameraKit dealloc ...");
}

- (instancetype)initWithBuilder:(void (^)(BMWCameraKitSettingProfile * profile))builder
{
    BMWCameraKitSettingProfile* profile = [[BMWCameraKitSettingProfile alloc] init];
    SafeBlock(builder, profile);
    return [self initWithProfile:profile];
}

- (instancetype)initWithProfile:(BMWCameraKitSettingProfile *)profile
{
    if (!(self = [super init])) {
        return nil;
    }
    // init property
    _settingProfile = profile;
    _isForSwitchCamera = NO;
    _framesSinceLastCheck = 0;
    _lastCheckTime = -1;
    _preScale = 0.0;
    _cameraMode = profile.cameraMode;
    _devicePosition = profile.position;
    _flashMode = profile.flashMode;
    _torchMode = profile.torchMode;
    _imageQuality = profile.imageQuality;
    _enableLivePhotoV2 = profile.enableLivePhotoV2;
    _logFPS = YES;
    _fps = 0;
    _retryRebuildCameraCount = kDefaultRetryRebuildCameraCount;
    _imageQuality = BMWImageResolutionQualityCurrent;
    BOOL initInBackground = _settingProfile.cameraStartupOpt & BMWCameraStartupOptCameraInitInBackground;
    if (!initInBackground){
        [self checkCameraDevices];
        [self presetPhotoWorkaround];
    }
    // init camera
    [self runAsyncOnOperationQueue:^{
        if (initInBackground){
            [self checkCameraDevices];
            [self presetPhotoWorkaround];
        }
        [self buildCamera];
        [self configureDeviceFlash:self.flashMode];
        [self configureDeviceTorch:self.torchMode];
    }];
    return self;
}

- (void)fetchProfile:(BMWCameraKitSettingProfile *)profile
{
    profile.flashMode = self.flashMode;
    profile.torchMode = self.torchMode;
    profile.cameraMode = self.cameraMode;
    profile.position = self.devicePosition;
    profile.imageQuality = self.imageQuality;
}

- (void)clear
{
    // reset
    [self removeObservers];
    [self.videoOutput setSampleBufferDelegate:nil queue:nil];
    [self.audioOutput setSampleBufferDelegate:nil queue:nil];
}

- (void)buildCamera
{
    BMWMLog(@"buildCamera enter ...");
    [self clear];
    
    // init capture session
    self.captureSession = [[AVCaptureSession alloc] init];
        
    NSArray<AVCaptureDevice *> *devices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:self.deviceTypes mediaType:AVMediaTypeVideo position:self.devicePosition].devices;
    self.inputCamera = devices.firstObject;
    if(self.settingProfile.portraitEffectsMatte && self.devicePosition == AVCaptureDevicePositionFront) {
        for (AVCaptureDevice* device in devices) {
            if (device.position == self.devicePosition && [device.deviceType isEqualToString:AVCaptureDeviceTypeBuiltInTrueDepthCamera]) {
                self.inputCamera = device;
                break;
            }
        }
    }
    devices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:self.deviceTypes mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified].devices;
    self.canSwitchCamera = devices.count > 1;
    
    BMWMLog(@"buildCamera [inputCamera] deviceTypes:%@, devices:%@, used device:%@", self.deviceTypes, devices, self.inputCamera);
    
    if (!self.inputCamera) {
        self.error = [BMWErrorHelper cameraInitErrorDomain:nil code:BMWCameraInitErrorDevicesNotAvailable];
        BMWMLog(@"buildCamera devives not available ..");
        return;
    }
    
    [self.captureSession beginConfiguration];
    
    AVCaptureSessionPreset sessionPreset = [self calcCaptureSessionPreset];
    if ([self.captureSession canSetSessionPreset:sessionPreset]){
        [self.captureSession setSessionPreset:sessionPreset];
    }
    
    [self configDefaultDimensions];
    [self configCameraParameter];
    
    NSError* error = nil;
    self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.inputCamera error:&error];
    if (error) {
        self.error = [BMWErrorHelper cameraInitErrorDomain:error code:BMWCameraInitErrorDeviceInputInitError];
        BMWMLog(@"buildCamera init video input error:%@", error);
    }
    if ([self.captureSession canAddInput:self.videoInput]) {
        [self.captureSession addInput:self.videoInput];
    }
    
    self.videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    // 设置为丢帧
    [self.videoOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.videoOutput setSampleBufferDelegate:self queue:self.videoCaptureQueue];
    if(self.settingProfile.cameraFrameFPS < 30) {
        self.videoOutput.minFrameDuration = CMTimeMake(1, self.settingProfile.cameraFrameFPS);
    }
    // 设置Camera输出格式
    BOOL supportsFullYUVRange = NO;
    NSArray* supportedPixelFormats = self.videoOutput.availableVideoCVPixelFormatTypes;
    for (NSNumber *currentPixelFormat in supportedPixelFormats) {
        if ([currentPixelFormat intValue] == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange) {
            supportsFullYUVRange = YES;
        }
    }
    if (supportsFullYUVRange && self.settingProfile.useYUV) {
        self.pixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    } else {
        self.pixelFormatType = kCVPixelFormatType_32BGRA;
    }
    [self.videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:self.pixelFormatType] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    if ([self.captureSession canAddOutput:self.videoOutput]) {
        [self.captureSession addOutput:self.videoOutput];
    } else {
        self.error = [BMWErrorHelper cameraInitErrorDomain:nil code:BMWCameraInitErrorAddVideoOutputError];
        BMWMLog(@"buildCamera Couldn't add video output");
    }
    BMWMLog(@"buildCamera [videoOutput]");
    
    // init image output
    if(!(self.settingProfile.cameraStartupOpt & BMWCameraStartupOptDefaultImmediateMode)) {
        self.imageOutput = [[AVCapturePhotoOutput alloc] init];
        if ([self.captureSession canAddOutput:self.imageOutput]) {
            [self.captureSession addOutput:self.imageOutput];
        } else {
            self.error = [BMWErrorHelper cameraInitErrorDomain:nil code:BMWCameraInitErrorAddImageOutputError];
            BMWMLog(@"Couldn't add image output");
        }
        self.imageOutput.highResolutionCaptureEnabled = YES;
        if (self.settingProfile.enableLivePhoto && !self.enableLivePhotoV2) {
            self.imageOutput.livePhotoCaptureEnabled = self.settingProfile.enableLivePhoto && self.imageOutput.isLivePhotoCaptureSupported;
        }
        if(self.settingProfile.portraitEffectsMatte && self.devicePosition == AVCaptureDevicePositionFront) {
            self.imageOutput.depthDataDeliveryEnabled = self.imageOutput.isDepthDataDeliverySupported;
            self.imageOutput.portraitEffectsMatteDeliveryEnabled = self.imageOutput.isPortraitEffectsMatteDeliverySupported;
        }
        BMWMLog(@"buildCamera [imageOutput]");
    }
    
    if (self.settingProfile.enableLivePhoto && !self.settingProfile.enableLivePhotoV2
        && self.imageOutput.isLivePhotoCaptureSupported) {
        self.microphone = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInMicrophone] mediaType:AVMediaTypeAudio position:AVCaptureDevicePositionUnspecified].devices.firstObject;
        
        NSError* error = nil;
        self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:self.microphone error:&error];
        if ([self.captureSession canAddInput:self.audioInput]) {
            [self.captureSession addInput:self.audioInput];
        }
        self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        if ([self.captureSession canAddOutput:self.audioOutput]) {
            [self.captureSession addOutput:self.audioOutput];
        }
        
        [self.audioOutput setSampleBufferDelegate:self queue:self.audioCaptureQueue];
    }

    // init metadata output if needed
    if(self.settingProfile.captureMetadataType != BMWCaptureMetadataTypeNone) {
        [self addMetadataOutputInternal:self.settingProfile.captureMetadataType];
        BMWMLog(@"buildCamera [metadataOutput]");
    }
    
    [self takePhotoWorkaround];
    self.curSessionPreset = sessionPreset;
    [self setDeviceZoomFactor:self.defaultDeviceZoomFactor animation:NO];
    [self.captureSession commitConfiguration];
    
    [self onCameraOpened:self.inputCamera];
    [self addObservers];
    BMWMLog(@"buildCamera leave ...");
}

- (void)buildImageOutput
{
    if(self.imageOutput) return;
    // init camera
    [self runAsyncOnOperationQueue:^{
        
        [self.captureSession beginConfiguration];
        // init image output
        self.imageOutput = [[AVCapturePhotoOutput alloc] init];
        if ([self.captureSession canAddOutput:self.imageOutput]) {
            [self.captureSession addOutput:self.imageOutput];
        } else {
            self.error = [BMWErrorHelper cameraInitErrorDomain:nil code:BMWCameraInitErrorAddImageOutputError];
            BMWMLog(@"Couldn't add image output");
        }
        self.imageOutput.highResolutionCaptureEnabled = YES;
        if(self.settingProfile.portraitEffectsMatte && self.devicePosition == AVCaptureDevicePositionFront) {
            self.imageOutput.depthDataDeliveryEnabled = self.imageOutput.isDepthDataDeliverySupported;
            self.imageOutput.portraitEffectsMatteDeliveryEnabled = self.imageOutput.isPortraitEffectsMatteDeliverySupported;
        }
        BMWMLog(@"buildCamera [imageOutput]");
        [self.captureSession commitConfiguration];
    }];
}

- (void)configCameraParameter
{
    NSError* error = nil;
    
    [self.inputCamera lockForConfiguration:&error];
    
    //自动对焦区域限制 无
    if ([self.inputCamera isAutoFocusRangeRestrictionSupported]) {
        [self.inputCamera setAutoFocusRangeRestriction:AVCaptureAutoFocusRangeRestrictionNone];
    }
    
    // 对焦模式
    if ([self.inputCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
        [self.inputCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
    } else if ([self.inputCamera isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
        [self.inputCamera setFocusMode:AVCaptureFocusModeAutoFocus];
    }
    // 平滑对焦
    if ([self.inputCamera isSmoothAutoFocusSupported]) {
        [self.inputCamera setSmoothAutoFocusEnabled:YES];
    }
    
    // TODO曝光优化
    [self.inputCamera setSubjectAreaChangeMonitoringEnabled:NO];
    
    // 曝光模式
    if ([self.inputCamera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
        [self.inputCamera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
    } else if ([self.inputCamera isExposureModeSupported:AVCaptureExposureModeAutoExpose]) {
        [self.inputCamera setExposureMode:AVCaptureExposureModeAutoExpose];
    }
    
    // 白平衡模式
    if ([self.inputCamera isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
        [self.inputCamera setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
    } else if ([self.inputCamera isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
        [self.inputCamera setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
    }
    
    // 弱光下自动提升亮度
    if ([self.inputCamera isLowLightBoostSupported]) {
        [self.inputCamera setAutomaticallyEnablesLowLightBoostWhenAvailable:YES];
    }
    
    [self.inputCamera unlockForConfiguration];
}

- (void)configCameraParameterLock
{
    NSError* error = nil;
    
    [self.inputCamera lockForConfiguration:&error];

    // 对焦模式
    if ([self.inputCamera isFocusModeSupported:AVCaptureFocusModeLocked]) {
        [self.inputCamera setFocusMode:AVCaptureFocusModeLocked];
    }
    
    // 曝光模式
    if ([self.inputCamera isExposureModeSupported:AVCaptureExposureModeLocked]) {
        [self.inputCamera setExposureMode:AVCaptureExposureModeLocked];
    }

    // 白平衡模式
    if ([self.inputCamera isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeLocked]) { //
        [self.inputCamera setWhiteBalanceMode:AVCaptureWhiteBalanceModeLocked];
    }
    [self.inputCamera unlockForConfiguration];
}

#pragma mark - Camera control

- (void)startCapture:(void(^)(NSError *error))completeBlock;
{
    self.metadataObjects = nil;
    if (BMWALifeCycleHelper.sharedInstance.launchedPassively) return;
    [self runAsyncOnOperationQueue:^{
        self.started = YES;
        self.receiveVideoDeviceNotAvailableWithMultipleForegroundAppsError = NO;
        self.changingStatus = BMWCameraKitChangingStatusProcessing;
        BMWMLog(@"startCapture async enter");
        if (![self.captureSession isRunning]) {
            BMWMLog(@"startCapture startRunning...");
            [self.captureSession startRunning];
        }
        for (AVCaptureInput *input in self.captureSession.inputs) {
            BMWMLog(@"Input: %@", input);
        }
        for (AVCaptureOutput *output in self.captureSession.outputs) {
            BMWMLog(@"Output: %@", output);
        }
        self.changingStatus = BMWCameraKitChangingStatusFinish;
        if(self.isCameraRuning) {
            SafeBlock(completeBlock, nil);
        } else {
            SafeBlock(completeBlock, self.error);
        }
        self.error = nil;
        [self onCameraOpened:self.inputCamera];
        BMWMLog(@"startCapture async leave, isCameraRuning:%d", self.isCameraRuning);
    }];
}

- (void)stopCapture:(void(^)(void))completeBlock
{
    if (BMWALifeCycleHelper.sharedInstance.launchedPassively) return;
    [self runAsyncOnOperationQueue:^{
        self.started = NO;
        BMWMLog(@"stopCapture async enter");
        if ([self.captureSession isRunning]) {
            BMWMLog(@"stopCapture stopRunning...");
            [self.captureSession stopRunning];
        }
        [self onCameraClosed:self.inputCamera];
        SafeBlock(completeBlock);
        BMWMLog(@"stopCapture async leave");
    }];
}

- (void)setDevicePosition:(AVCaptureDevicePosition)devicePosition
{
    _devicePosition = devicePosition;
    [self switchCamera];
}

- (void)setDevicePosition:(AVCaptureDevicePosition)devicePosition completedBlock:(void(^)(BOOL suc))block
{
    _devicePosition = devicePosition;
    [self switchCameraWithBlock:block];
}

- (void)setBackMirrord:(BOOL)backMirrord
{
    _backMirrord = backMirrord;
    [self updateMirror];
}

- (void)setFrontMirrord:(BOOL)frontMirrord
{
    _frontMirrord = frontMirrord;
    [self updateMirror];
}

- (BOOL)isRunning
{
    // 判断处理完才认定为camera running
    return self.isCameraRuning && self.changingStatus == BMWCameraKitChangingStatusFinish;
}

- (void)zoomWithScale:(CGFloat)scale
{
    [self runAsyncOnOperationQueue:^{
        NSError* error = nil;
        // 2倍到10倍，系数乘以8，保持跟2倍一下一样的缩放速度
        CGFloat factor = self.currZoomFactor > 2 ? 15.0 * 8.0 : 15.0;
        CGFloat zoomFactor = self.currZoomFactor + (scale - self.preScale) * factor;
        // clamp to 1 and maxZoomFactor
        zoomFactor = MAX(0.5, MIN(zoomFactor, self.maxZoomFactor));
        CGFloat deviceZoomFactor = [self convertZoomFactor:zoomFactor toDevice:YES];
        [self setDeviceZoomFactor:deviceZoomFactor animation:NO];
        self.preScale = scale;
    }];
}

- (void)zoomBegin:(CGFloat)scale
{
    self.preScale = scale;
}

- (void)zoomEnd:(CGFloat)scale
{
    self.preScale = scale;
}

- (void)cancelZoom
{
    [self runAsyncOnOperationQueue:^{
        NSError* error = nil;
        [self.inputCamera lockForConfiguration:&error];
        [self.inputCamera cancelVideoZoomRamp];
        [self.inputCamera unlockForConfiguration];
    }];
}

- (void)focusAndExposeAtPoint:(CGPoint)point
{
    BOOL monitorSubjectAreaChange = GPCamConfigurator.sharedInstance.focusStrategy != 0;
    AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    if(monitorSubjectAreaChange) {
        focusMode = AVCaptureFocusModeAutoFocus;
        exposureMode = AVCaptureExposureModeAutoExpose;
    }
    [self focusAndExposeAtPoint:point focusMode:focusMode exposeMode:exposureMode monitorSubjectAreaChange:monitorSubjectAreaChange];
}

- (void)focusAndExposeAtPoint:(CGPoint)point isUserInitiated:(BOOL)isUserInitiated
{
    BOOL monitorSubjectAreaChange = GPCamConfigurator.sharedInstance.focusStrategy != 0 && isUserInitiated;
    AVCaptureFocusMode focusMode = AVCaptureFocusModeContinuousAutoFocus;
    AVCaptureExposureMode exposureMode = AVCaptureExposureModeContinuousAutoExposure;
    if(monitorSubjectAreaChange) {
        focusMode = AVCaptureFocusModeAutoFocus;
        exposureMode = AVCaptureExposureModeAutoExpose;
    }
    [self focusAndExposeAtPoint:point focusMode:focusMode exposeMode:exposureMode monitorSubjectAreaChange:monitorSubjectAreaChange];
}

- (void)focusAndExposeAtPoint:(CGPoint)point
                    focusMode:(AVCaptureFocusMode)focusMode
                   exposeMode:(AVCaptureExposureMode)exposureMode
     monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    [self runAsyncOnOperationQueue:^{
        NSError* error = nil;
        self.focusPointOfInterest = CGPointMake(1-point.y, point.x);
        BMWMLog(@"[Focus] focusAndExposeAtPoint: %@, pointOfInterest:%@, focusMode: %@, exposureMode:%@, monitorSubjectAreaChange:%@", @(point), @(self.focusPointOfInterest),@(focusMode), @(exposureMode), @(monitorSubjectAreaChange));

        AVCaptureDevice* device = self.inputCamera;
        if ([device lockForConfiguration:&error]) {
            if (device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode]) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if (device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode]) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        } else {
            BMWMLog(@"[Focus] Could not lock device for configuration: %@", error);
        }
    }];
}

- (void)setExposure:(float)bias
{
    [self runAsyncOnOperationQueue:^{
        NSError* error = nil;
        [_inputCamera lockForConfiguration:&error];
        CGFloat min = _inputCamera.minExposureTargetBias;
        CGFloat max = _inputCamera.maxExposureTargetBias;
        [_inputCamera setExposureTargetBias:min + (max - min) * bias completionHandler:nil];
        [_inputCamera unlockForConfiguration];
    }];
}

- (void)setStabilitizationMode
{
    if(self.settingProfile.ignoreStabilitizationMode) return;
    [self runAsyncOnOperationQueue:^{
        AVCaptureConnection* connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
        if ([connection isVideoStabilizationSupported]) {
            AVCaptureVideoStabilizationMode videoMode = [self getVideoStabilizationMode];
            if ([connection preferredVideoStabilizationMode] == videoMode) {
                return;
            }
            [self.captureSession beginConfiguration];
            [connection setPreferredVideoStabilizationMode:videoMode];
            [self.captureSession commitConfiguration];
        }
    }];
}

- (void)switchCameraWithBlock:(void(^)(BOOL suc))completeBlock
{
    if (!self.canSwitchCamera) {
        BMWMLog(@"switchCamera cann't switch");
        dispatch_async(dispatch_get_main_queue(), ^{
            SafeBlock(completeBlock, NO);
        });
        return;
    }
    if (_inputCamera.position == _devicePosition) {
        dispatch_async(dispatch_get_main_queue(), ^{
            SafeBlock(completeBlock, NO);
        });
        return;
    }
    [self runAsyncOnOperationQueue:^{
        BMWMLog(@"switchCamera enter");
        self.changingStatus = BMWCameraKitChangingStatusSwitchProcessing;
        [self.captureSession beginConfiguration];
        AVCaptureDevice* oldDevice = self.inputCamera;
        AVCaptureDeviceInput* oldDeviceInput = self.videoInput;
        
        [self.captureSession removeInput:self.videoInput];
        
        AVCaptureSessionPreset sessionPreset = [self calcCaptureSessionPreset];
        if ([self.captureSession canSetSessionPreset:sessionPreset]) {
            [self.captureSession setSessionPreset:sessionPreset];
        }
        NSArray<AVCaptureDevice *> *devices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:self.deviceTypes mediaType:AVMediaTypeVideo position:self.devicePosition].devices;
        self.inputCamera = devices.firstObject;
        
        if(self.settingProfile.portraitEffectsMatte && self.devicePosition == AVCaptureDevicePositionFront) {
            for (AVCaptureDevice* device in devices) {
                if (device.position == self.devicePosition && [device.deviceType isEqualToString:AVCaptureDeviceTypeBuiltInTrueDepthCamera]) {
                    self.inputCamera = device;
                    break;
                }
            }
        }
        
        NSError* error = nil;
        self.videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.inputCamera error:&error];
        if (error != nil) {
            self.inputCamera = oldDevice;
            self.videoInput = oldDeviceInput;
        }
        
        [self configDefaultDimensions];
        [self configCameraParameter];
        
        if ([self.captureSession canAddInput:self.videoInput]) {
            if(GPCamConfigurator.sharedInstance.focusStrategy != 0) {
                [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:oldDevice];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChangeNotification:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.inputCamera];
            }
            [self.captureSession addInput:self.videoInput];
        }
        AVCaptureConnection* connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
        if (self.devicePosition == AVCaptureDevicePositionFront) {
            if ([connection isVideoMirroringSupported]) {
                [connection setVideoMirrored:self.isFrontMirrord];
            }
        } else {
            if ([connection isVideoMirroringSupported]) {
                [connection setVideoMirrored:self.isBackMirrord];
            }
        }
        
        if(self.settingProfile.portraitEffectsMatte && self.devicePosition == AVCaptureDevicePositionFront){
            self.imageOutput.depthDataDeliveryEnabled =  self.imageOutput.isDepthDataDeliverySupported;
            self.imageOutput.portraitEffectsMatteDeliveryEnabled = self.imageOutput.isPortraitEffectsMatteDeliverySupported;
        }
        
        if (self.settingProfile.enableLivePhoto && !self.enableLivePhotoV2) {
            self.imageOutput.livePhotoCaptureEnabled = self.settingProfile.enableLivePhoto && self.imageOutput.isLivePhotoCaptureSupported;
        }
        
        [self takePhotoWorkaround];
        self.curSessionPreset = sessionPreset;
        [self setDeviceZoomFactor:self.defaultDeviceZoomFactor animation:NO];
        [self.captureSession commitConfiguration];
        [self onCameraOpened:self.inputCamera];
        
        self.changingStatus = BMWCameraKitChangingStatusFinish;
        CGFloat delay = self.isSupportWideAngle ? 0.68 : 0.5;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            SafeBlock(completeBlock, YES);
        });
        BMWMLog(@"switchCamera leave");
    }];
}

- (void)switchCamera
{
    [self switchCameraWithBlock:nil];
}

- (void)enableNightEnhance:(BOOL)enable
{
    _isNightEnhanceEnabled = enable;
    if(enable && (self.settingProfile.cameraStartupOpt & BMWCameraStartupOptDefaultImmediateMode)) {
        [self buildImageOutput];
    }
}

- (void)configureDeviceFlash:(AVCaptureFlashMode)mode
{
    self.flashMode = mode;
    if(mode != AVCaptureFlashModeOff && (self.settingProfile.cameraStartupOpt & BMWCameraStartupOptDefaultImmediateMode)) {
        [self buildImageOutput];
    }
    [self runAsyncOnOperationQueue:^{
        NSError* error = nil;
        [self.inputCamera lockForConfiguration:&error];
        BMWMLog(@"configureDeviceFlash mode:%d",mode);
        if (error == nil) {
            if ([self.inputCamera isFlashModeSupported:mode]){
                [self.inputCamera setFlashMode:mode];
            }
        } else {
            BMWMLog(@"configureDeviceFlash error:%@",error);
        }
        [self.inputCamera unlockForConfiguration];
    }];
}

- (void)configureDeviceTorch:(AVCaptureTorchMode)mode
{
    self.torchMode = mode;
    if (BMWALifeCycleHelper.sharedInstance.appInBackground) {
        return;
    }
    [self runAsyncOnOperationQueue:^{
        NSError* error = nil;
        BMWMLog(@"configureDeviceTorch mode: %d",mode);
        [self.inputCamera lockForConfiguration:&error];
        if (error == nil) {
            if ([self.inputCamera isTorchModeSupported:mode]){
                [self.inputCamera setTorchMode:mode];
            }
        } else {
            BMWMLog(@"configureDeviceTorch error:%@",error);
        }
        [self.inputCamera unlockForConfiguration];
    } delay:0.05];
}

- (void)updateMirror
{
    [self runAsyncOnOperationQueue:^{
        AVCaptureConnection* connection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
        if (self.devicePosition == AVCaptureDevicePositionBack) {
            if ([connection isVideoMirrored] == self.isBackMirrord) {
                return;
            }
        } else if (self.devicePosition == AVCaptureDevicePositionFront){
            if ([connection isVideoMirrored] == self.isFrontMirrord) {
                return;
            }
        }
        [self.captureSession beginConfiguration];
        
        if (self.devicePosition == AVCaptureDevicePositionFront) {
            if ([connection isVideoMirroringSupported]) {
                [connection setVideoMirrored:self.isFrontMirrord];
            }
        } else {
            if ([connection isVideoMirroringSupported]) {
                [connection setVideoMirrored:self.isBackMirrord];
            }
        }
        [self.captureSession commitConfiguration];
    }];
}

- (void)setEnableLivePhoto:(BOOL)enableLivePhoto {
    _enableLivePhoto = enableLivePhoto;
    self.settingProfile.enableLivePhoto = enableLivePhoto;
    if (self.cameraMode == BMWCameraKitModeVideo) {
        return;
    }

    if (self.enableLivePhotoV2) {
        return;
    }
    if (enableLivePhoto) {
        [self addAudioInputsAndOutputs];
    } else {
        [self removeAudioInputsAndOutputs];
    }
    [self runAsyncOnOperationQueue:^{
        self.imageOutput.livePhotoCaptureEnabled = enableLivePhoto && self.imageOutput.isLivePhotoCaptureSupported;
    }];
}

- (BOOL)isEnableLivePhoto {
    return self.settingProfile.enableLivePhoto;
}

- (void)changeMode:(BMWCameraKitMode)mode
{
    if (self.cameraMode == mode) {
        return;
    }
    self.cameraMode = mode;
    
    [self runAsyncOnOperationQueue:^{
        BMWMLog(@"changeMode enter:%d",mode);
        self.changingStatus = BMWCameraKitChangingStatusProcessing;
        
        void (^updateAudio)() = ^{
            if (self.settingProfile.enableLivePhoto && !self.settingProfile.enableLivePhotoV2) {
                if (self.cameraMode == BMWCameraKitModeVideo) {
                    self.imageOutput.livePhotoCaptureEnabled = NO;
                    if (self.settingProfile.useAudioUnit) {
                        [self removeAudioInputsAndOutputs];
                    }
                } else {
                    self.imageOutput.livePhotoCaptureEnabled = self.imageOutput.livePhotoCaptureSupported && self.settingProfile.enableLivePhoto;
                    [self addAudioInputsAndOutputs];
                }
            }
        };
        
        AVCaptureSessionPreset sessionPreset = [self calcCaptureSessionPreset];
        if (![sessionPreset isEqualToString:self.curSessionPreset]) {
            [self.captureSession beginConfiguration];
            if ([self.captureSession canSetSessionPreset:sessionPreset]) {
                [self.captureSession setSessionPreset:sessionPreset];
            }
            [self takePhotoWorkaround];
            self.curSessionPreset = sessionPreset;
            [self setDeviceZoomFactor:self.defaultDeviceZoomFactor animation:NO];
            updateAudio();
            [self.captureSession commitConfiguration];
            [self configDefaultDimensions];
        } else {
            [self setDeviceZoomFactor:self.defaultDeviceZoomFactor animation:NO];
            updateAudio();
        }
        self.changingStatus = BMWCameraKitChangingStatusFinish;
        BMWMLog(@"changeMode leave...");
    }];
}

- (void)addAudioInputsAndOutputs
{
    // If use AudioUnit just return
    if (self.settingProfile.useAudioUnit && (!self.settingProfile.enableLivePhoto || self.enableLivePhotoV2)) {
        return;
    }
    [self runAsyncOnOperationQueue:^{
        if (self.audioOutput != nil) {
            return;
        }

        [self.captureSession beginConfiguration];
        self.microphone = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInMicrophone] mediaType:AVMediaTypeAudio position:AVCaptureDevicePositionUnspecified].devices.firstObject;
        
        NSError* error = nil;
        self.audioInput = [AVCaptureDeviceInput deviceInputWithDevice:self.microphone error:&error];
        if ([self.captureSession canAddInput:self.audioInput]) {
            [self.captureSession addInput:self.audioInput];
        }
        [self takePhotoWorkaround];
        [self setDeviceZoomFactor:self.defaultDeviceZoomFactor animation:NO];
        self.audioOutput = [[AVCaptureAudioDataOutput alloc] init];
        if ([self.captureSession canAddOutput:self.audioOutput]) {
            [self.captureSession addOutput:self.audioOutput];
        }
        
        [self.audioOutput setSampleBufferDelegate:self queue:self.audioCaptureQueue];
        
        [self.captureSession commitConfiguration];
    }];
}

- (void)removeAudioInputsAndOutputs
{
    [self runAsyncOnOperationQueue:^{
        if (self.audioOutput == nil) {
            return;
        }

        [self.captureSession beginConfiguration];
        [self.audioOutput setSampleBufferDelegate:nil queue:nil];
        [self.captureSession removeInput:self.audioInput];
        [self.captureSession removeOutput:self.audioOutput];
        self.audioInput = nil;
        self.audioOutput = nil;
        self.microphone = nil;
        [self.captureSession commitConfiguration];
    }];
}

- (void)addMetadataOutput:(BMWCaptureMetadataType)type
{
    if (self.metadataOutput != nil) {
        return;
    }
    [self runAsyncOnOperationQueue:^{
        [self.captureSession beginConfiguration];
        [self addMetadataOutputInternal:type];
        [self.captureSession commitConfiguration];
    }];
}

- (void)addMetadataOutputInternal:(BMWCaptureMetadataType)type
{
    self.metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    if ([self.captureSession canAddOutput:self.metadataOutput]) {
        [self.captureSession addOutput:self.metadataOutput];
    }
    NSMutableArray *wantTypes = [[NSMutableArray alloc] init];
    if(type & BMWCaptureMetadataTypeQrCode) {
        [wantTypes addObject:AVMetadataObjectTypeQRCode];
    }
    if(type & BMWCaptureMetadataTypeBarCode) {
        NSMutableArray *wantTypes2 = [NSMutableArray arrayWithObjects:AVMetadataObjectTypeUPCECode,
                                     AVMetadataObjectTypeCode39Code,
                                     AVMetadataObjectTypeCode39Mod43Code,
                                     AVMetadataObjectTypeEAN13Code,
                                     AVMetadataObjectTypeEAN8Code,
                                     AVMetadataObjectTypeCode93Code,
                                     AVMetadataObjectTypeCode128Code,
                                     AVMetadataObjectTypePDF417Code,
                                    // AVMetadataObjectTypeAztecCode,
                                     AVMetadataObjectTypeInterleaved2of5Code,
                                     AVMetadataObjectTypeITF14Code,
                                    // AVMetadataObjectTypeDataMatrixCode,
                                      nil];
        [wantTypes addObjectsFromArray:wantTypes2];
    }
    if(@available(iOS 15.4, *)) {
        if(type & BMWCaptureMetadataTypeQrCode) {
            [wantTypes addObject:AVMetadataObjectTypeMicroQRCode];
        }
        if(type & BMWCaptureMetadataTypeBarCode) {
            [wantTypes addObject:AVMetadataObjectTypeCodabarCode];
            [wantTypes addObject:AVMetadataObjectTypeGS1DataBarCode];
            [wantTypes addObject:AVMetadataObjectTypeGS1DataBarExpandedCode];
            [wantTypes addObject:AVMetadataObjectTypeGS1DataBarLimitedCode];
            [wantTypes addObject:AVMetadataObjectTypeMicroPDF417Code];
        }
    }
    NSMutableArray *supportedTypes = [[NSMutableArray alloc] init];
    for (AVMetadataObjectType type in wantTypes) {
        if([self.metadataOutput.availableMetadataObjectTypes containsObject:type]) {
            [supportedTypes addObject:type];
        }
    }
#if 0
    CGRect rect = self.settingProfile.validRect;
    [self.metadataOutput setRectOfInterest:CGRectMake(rect.origin.y, rect.origin.x, rect.size.height, rect.size.width)];
#endif
    [self.metadataOutput setMetadataObjectTypes:supportedTypes];
    [self.metadataOutput setMetadataObjectsDelegate:self queue:self.videoCaptureQueue];
}

- (void)removeMetadataOutput
{
    if (self.metadataOutput == nil) {
        return;
    }
    [self runAsyncOnOperationQueue:^{
        [self.captureSession beginConfiguration];
        [self.metadataOutput setMetadataObjectsDelegate:nil queue:nil];
        [self.captureSession removeOutput:self.metadataOutput];
        self.metadataOutput = nil;
        [self.captureSession commitConfiguration];
    }];
}

- (void)updateMetadataRectOfInterest
{
    static int rectIdx = 0;
    if (self.metadataOutput == nil) {
        return;
    }
    [self runAsyncOnOperationQueue:^{
        [self.captureSession beginConfiguration];
        [self.metadataOutput setRectOfInterest:CGRectMake(rectIdx * 0.05, 0.0, 0.45, 1.0)];
        [self.captureSession commitConfiguration];
        rectIdx = (rectIdx + 1) % 12;
    }];
}

- (void)checkCameraDevices
{
    double bg = CACurrentMediaTime();
    NSMutableArray<AVCaptureDeviceType>* deviceTypes = [[NSMutableArray alloc] initWithObjects:AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInTelephotoCamera, nil];
    self.maxZoomFactor = 10.0;
    BOOL isSupportWideAngle = NO;
    if ([BMWDeviceUtils isPhone11OrHigher] && @available(iOS 13.0, *)) {
        BOOL initInBackground = self.settingProfile.cameraStartupOpt & BMWCameraStartupOptCameraInitInBackground;
        if(!initInBackground) {
            NSArray<AVCaptureDevice *> *devices = [AVCaptureDeviceDiscoverySession discoverySessionWithDeviceTypes:@[AVCaptureDeviceTypeBuiltInDualWideCamera, AVCaptureDeviceTypeBuiltInTripleCamera] mediaType:AVMediaTypeVideo position:AVCaptureDevicePositionUnspecified].devices;
            isSupportWideAngle = devices.count > 0;
        } else {
            isSupportWideAngle = YES;
        }
    }
    if (isSupportWideAngle) {
        deviceTypes = [[NSMutableArray alloc] initWithObjects:AVCaptureDeviceTypeBuiltInTripleCamera, AVCaptureDeviceTypeBuiltInDualWideCamera, AVCaptureDeviceTypeBuiltInWideAngleCamera, AVCaptureDeviceTypeBuiltInTelephotoCamera, nil];
    }
    if(self.settingProfile.portraitEffectsMatte) {
        [deviceTypes addObject:AVCaptureDeviceTypeBuiltInTrueDepthCamera];
    }
    self.deviceTypes = deviceTypes;
    self.isSupportWideAngle = isSupportWideAngle;
    double end = CACurrentMediaTime();
    BMWMLog(@"checkCameraDevices:%lf", 1000*(end - bg));
}

- (void)configMaxZoomFactor:(CGFloat)factor
{
    self.maxZoomFactor = factor;
}

- (CGFloat)getMaxZoomFactor:(AVCaptureDevicePosition)position
{
    CGFloat ret = 10.0;
    if([BMWDeviceUtils isPhone13OrHigher]) {
        ret = 15;
    }
    return ret;
}

- (CGFloat)getMinZoomFactor:(AVCaptureDevicePosition)position
{
    CGFloat ret = 1.0;
    if (_isSupportWideAngle) {
        if(position == AVCaptureDevicePositionFront) {
            ret = 0.7;
        } else {
            ret = 0.5;
        }
    }
    return ret;
}

- (void)enableWideAngle:(BOOL)enable
{
    if (!self.isSupportWideAngle) {
        return;
    }
    [self runAsyncOnOperationQueue:^{
        NSError* error = nil;
        [self.inputCamera lockForConfiguration:&error];
        // 后置:1.0 广角;2.0是主摄
        // 前置:1.0 广角;1.3是主摄
        if(self.devicePosition == AVCaptureDevicePositionFront) {
            [self setDeviceZoomFactor:enable ? 1.0: 1.3 animation:YES];
        } else {
            [self setDeviceZoomFactor:enable ? 1.0: 2.0 animation:YES];
        }
        [self.inputCamera unlockForConfiguration];
    }];
}

- (BOOL)isInWideAngle
{
    BOOL ret = self.currZoomFactor < 1.0;
    return ret;
}

- (CGFloat)convertZoomFactor:(CGFloat)zoomFactor toDevice:(BOOL)toDevice
{
    // 内部比例:
    //   后置:[1.0, 2.0)表示广角摄像头, [2, max]表示普通摄像头
    //   前置:[1.0, 1.3)表示广角摄,    [1.3, max)表示普通
    // 外部比例:
    //   后置:[0.5, 1.0)表示广角摄像头, [1, max]表示普通摄像头
    //   前置:[0.7, 1.0)表示广角摄像头, [1, max]表示普通摄像头
    CGFloat ret = zoomFactor;
    if (self.isSupportWideAngle) {
        if (toDevice) {
            if(self.devicePosition == AVCaptureDevicePositionBack) {
                ret = zoomFactor * 2.0;
            } else {
                ret = zoomFactor + 0.3;
            }
        } else {
            if(self.devicePosition == AVCaptureDevicePositionBack) {
                ret = zoomFactor * 0.5;
            } else {
                ret = zoomFactor - 0.3;
            }
       }
    }
    return ret;
}

- (void)setCurrZoomFactor:(CGFloat)currZoomFactor
{
    _currZoomFactor = currZoomFactor;
    if (self.delegate && [self.delegate respondsToSelector:@selector(currZoomFactorChanged:)]) {
        [self.delegate currZoomFactorChanged:currZoomFactor];
    }
}

- (void)setCurrZoomFactor:(CGFloat)zoomFactor animation:(BOOL)animation
{
    [self runAsyncOnOperationQueue:^{
        CGFloat factor = [self convertZoomFactor:zoomFactor toDevice:YES];
        [self setDeviceZoomFactor:factor animation:animation];
    }];
}

- (void)setDeviceZoomFactor:(CGFloat)deviceZoomFactor animation:(BOOL)animation
{
    NSError *error = nil;
    [self.inputCamera lockForConfiguration:&error];
    self.deviceMaxZoomFactor = self.inputCamera.activeFormat.videoMaxZoomFactor;
    NSAssert(self.deviceMaxZoomFactor >= 10, @"self.deviceMaxZoomFactor < 10");
    
    // clamp to 1 and deviceMaxZoomFactor
    CGFloat clampDeviceZoomFactor = MAX(1, MIN(deviceZoomFactor, self.deviceMaxZoomFactor));
    @try {
        if (animation) {
            [self.inputCamera rampToVideoZoomFactor:clampDeviceZoomFactor withRate:5.0];
        } else {
            [self.inputCamera setVideoZoomFactor:clampDeviceZoomFactor];
        }
    } @catch (NSException *exception) {
        BMWMLog(@"setVideoZoomFactor fail:%@",exception);
    }
    [self.inputCamera unlockForConfiguration];
    self.currZoomFactor = [self convertZoomFactor:deviceZoomFactor toDevice:NO];
    BMWMLog(@"setZoomFactor:%lf, currZoomFactor:%lf, deviceMaxZoomFactor:%lf", clampDeviceZoomFactor, self.currZoomFactor, self.deviceMaxZoomFactor);
}

- (CGFloat)extraZoomFactor
{
    CGFloat curZoom = self.currZoomFactor;
    CGFloat maxZoom = self.deviceMaxZoomFactor;
    CGFloat extraZoom = 1.0f;
    if (curZoom > maxZoom && self.deviceMaxZoomFactor > 0) {
        extraZoom = 1.0f + (curZoom - maxZoom) / maxZoom;
        BMWMLog(@"extraZoomFactor curZoom:%lf, maxZoom:%lf, extraZoom:%lf", curZoom, maxZoom, extraZoom);
    }
    return extraZoom;
}

- (CGFloat)defaultDeviceZoomFactor
{
    if(self.devicePosition == AVCaptureDevicePositionFront) {
        return _isSupportWideAngle ? 1.3 : 1.0;
    } else {
        return _isSupportWideAngle ? 2.0 : 1.0;
    }
}

- (BOOL)isFlashAndTorchOff
{
    return self.flashMode == AVCaptureFlashModeOff && self.torchMode == AVCaptureTorchModeOff;
}

#pragma mark - 拍照

- (AVCapturePhotoSettings*)createPhotoSettings:(BOOL)useYUV ignoreFlash:(BOOL)ignoreFlash
                               enableLivePhoto:(BOOL)enableLivePhoto
                           pairedVideoFilePath:(NSString *)pairedVideoFilePath
{
    // TODO 在这里可以对拍照做很多优化
    OSType pixelFormatType;
    if (useYUV) {
        pixelFormatType = kCVPixelFormatType_420YpCbCr8BiPlanarFullRange;
    } else {
        pixelFormatType = kCVPixelFormatType_32BGRA;
    }
    AVCapturePhotoSettings* photoSettings = [AVCapturePhotoSettings photoSettingsWithFormat:[NSDictionary dictionaryWithObject:@(pixelFormatType) forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    if ([self.imageOutput.supportedFlashModes containsObject:@(self.flashMode)] && !ignoreFlash) {
        photoSettings.flashMode = self.flashMode;
    }
    photoSettings.highResolutionPhotoEnabled = YES;
    photoSettings.autoStillImageStabilizationEnabled = !self.getFastImageCaptureMode;
    if(self.settingProfile.portraitEffectsMatte && self.devicePosition == AVCaptureDevicePositionFront){
        photoSettings.depthDataDeliveryEnabled = self.imageOutput.isDepthDataDeliveryEnabled;
        photoSettings.portraitEffectsMatteDeliveryEnabled = self.imageOutput.isPortraitEffectsMatteDeliveryEnabled;
    }
    if (enableLivePhoto) {
        photoSettings.livePhotoMovieFileURL = [NSURL fileURLWithPath:pairedVideoFilePath];
    }
#if 0
    if (photoSettings.availablePreviewPhotoPixelFormatTypes.count > 0) {
        photoSettings.previewPhotoFormat = @{
            (NSString*)kCVPixelBufferPixelFormatTypeKey : photoSettings.availablePreviewPhotoPixelFormatTypes.firstObject,
            (id)kCVPixelBufferWidthKey: @(640),
            (id)kCVPixelBufferHeightKey: @(640)
        };
    }
#endif
    return photoSettings;
}

- (void)takePhotoImmediately:(BMWTakePhotoImmediate)immediate
                      useYUV:(BOOL)useYUV
             enableLivePhoto:(BOOL)enableLivePhoto
         pairedVideoFilePath:(NSString *)videoFilePath
       capturedImageCallback:(void (^)(BMWCameraCapturedData *data))capturedImageCallback
pairedVideoDurationAfterCapture:(double)pairedVideoDurationAfterCapture
       capturedVideoCallback:(void (^)(double videoDuration, double photoDisplayTime, NSError *error))capturedVideoCallback {
    // 开启LivePhoto后不支持极速模式
    if (enableLivePhoto && videoFilePath != nil) {
        immediate = BMWTakePhotoImmediateNone;
    }
    self.takePhotoBeginStamp = CACurrentMediaTime();
    self.takePhotoCompleteBlock = capturedImageCallback;
    self.captureVideoCompleteBlock = capturedVideoCallback;
    self.livePhotoCaptureEnabled = enableLivePhoto;
    self.videoInfo = nil;
    self.pairedVideoDurationAfterCapture = pairedVideoDurationAfterCapture;
    self.capturedData = nil;
    if ([self captureImageImmediateIfNeeded:immediate]) {
        dispatch_async(self.imageCaptureQueue, ^{
            CFTimeInterval end = CACurrentMediaTime();
            BMWMLog(@"takePhotoWithCompletionBlock immediately timecost: %lf", 1000 * (end - self.takePhotoBeginStamp));
            BMWCameraCapturedData *capturedData = [BMWCameraCapturedData buildWithError:nil immediate:YES];
            SafeBlock(self.takePhotoCompleteBlock, capturedData);
        });
    } else {
        [self takePhotoInternal:useYUV ignoreFlash:NO enableLivePhoto:enableLivePhoto pairedVideoFilePath:videoFilePath];
    }
}

- (void)takePhotoInternal:(BOOL)useYUV ignoreFlash:(BOOL)ignoreFlash
          enableLivePhoto:(BOOL)enableLivePhoto
      pairedVideoFilePath:(NSString *)pairedVideoFilePath
{
    [self runAsyncOnOperationQueue:^{
        @try {
            AVCapturePhotoSettings* settings = [self createPhotoSettings:useYUV ignoreFlash:ignoreFlash
                                                         enableLivePhoto:enableLivePhoto
                                                     pairedVideoFilePath:pairedVideoFilePath];
            if (enableLivePhoto && self.imageOutput.livePhotoCaptureEnabled && self.imageOutput.livePhotoCaptureSuspended) {
                self.imageOutput.livePhotoCaptureSuspended = NO;
            }
            BMWMLog(@"takePhotoInternal: %@", self.imageOutput);
            [self.imageOutput capturePhotoWithSettings:settings delegate:self];
        } @catch (NSException *exception) {
            NSDictionary *userInfo = exception ? @{@"exception": exception} : nil;
            NSError *error = [[NSError alloc] initWithDomain:@"拍照异常" code:-1 userInfo:userInfo];
           dispatch_async(self.imageCaptureQueue, ^{
               NSError *newError = [self captureImageError:error];
               BMWCameraCapturedData *capturedData = [BMWCameraCapturedData buildWithError:newError immediate:NO];
               SafeBlock(self.takePhotoCompleteBlock, capturedData);
           });
        }
    }];
    if (enableLivePhoto) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.pairedVideoDurationAfterCapture * NSEC_PER_SEC)), self.imageCaptureQueue, ^{
            if (self.imageOutput.livePhotoCaptureEnabled) {
                BMWMLog(@"self.imageOutput.livePhotoCaptureSuspended = YES;");
                if (self.captureVideoCompleteBlock != nil) {
                    self.imageOutput.livePhotoCaptureSuspended = YES;
                }
            }
        });
    }
}

- (void)takePhotoPreviously
{
    if(ShouldTakePhotoPreviously == NO) return;
    if(GPCamConfigurator.sharedInstance.warmupCamera == 0) return;
    if(self.isRunning) {
        BMWMLog(@"takePhotoPreviously enter");
        ShouldTakePhotoPreviously = NO;
        if ([self captureImageImmediateIfNeeded:BMWTakePhotoImmediateForce] && self.cameraMode != BMWCameraKitModeVideo) {
            self.takePhotoBeginStamp = CACurrentMediaTime();
            [self takePhotoInternal:self.settingProfile.useYUV ignoreFlash:YES enableLivePhoto:NO pairedVideoFilePath:nil];
        }
    }
}

- (void)captureOutput:(AVCapturePhotoOutput *)output willCapturePhotoForResolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
{
    NSUInteger mutePhotoDefault  = [self getMuteTakePhoto];
    if (mutePhotoDefault == 1 || mutePhotoDefault == 0){
        AudioServicesDisposeSystemSoundID(1108);
    }
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhotoSampleBuffer:(CMSampleBufferRef)photoSampleBuffer previewPhotoSampleBuffer:(CMSampleBufferRef)previewPhotoSampleBuffer resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings bracketSettings:(AVCaptureBracketedStillImageSettings *)bracketSettings error:(NSError *)error
{
    CFTimeInterval end = CACurrentMediaTime();
    BMWMLog(@"takePhotoWithCompletionBlock timecost: %lums", (NSUInteger)(1000 * (end - self.takePhotoBeginStamp)));
    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(photoSampleBuffer);
    CMTime timestamp = CMSampleBufferGetOutputPresentationTimeStamp(photoSampleBuffer);
    [self capturedImage:pixelBuffer mattePixelBuffer:nil time:timestamp error:error];
}

- (void)captureOutput:(AVCapturePhotoOutput *)photoOutput didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error
{
    CFTimeInterval end = CACurrentMediaTime();
    BMWMLog(@"takePhotoWithCompletionBlock timecost: %lums", (NSUInteger)(1000 * (end - self.takePhotoBeginStamp)));
    CVPixelBufferRef portraitEffectsMattePixelBuffer = nil;
    if(self.settingProfile.portraitEffectsMatte) {
        if (photo.portraitEffectsMatte != nil ) {
            portraitEffectsMattePixelBuffer = [photo.portraitEffectsMatte mattingImage];
        } else {

        }
    }
    if(portraitEffectsMattePixelBuffer) CFRetain(portraitEffectsMattePixelBuffer);
    [self capturedImage:photo.pixelBuffer mattePixelBuffer:portraitEffectsMattePixelBuffer time:photo.timestamp error:error];
}

- (void)capturedImage:(CVPixelBufferRef)pixelBuffer mattePixelBuffer:(CVPixelBufferRef)mattePixelBuffer time:(CMTime)time error:(NSError*)error
{
    if (error) {
        NSError *newError = [self captureImageError:error];
        BMWMLog(@"capture image error:%@",newError);
        BMWCameraCapturedData *capturedData = [BMWCameraCapturedData buildWithError:newError immediate:NO];
        SafeBlock(self.takePhotoCompleteBlock, capturedData);
        self.takePhotoCompleteBlock = nil;
        return;
    }
    CVPixelBufferRetain(pixelBuffer);
    CVPixelBufferRetain(mattePixelBuffer);
    dispatch_async(self.imageCaptureQueue, ^{
        self.capturedData = [BMWCameraCapturedData buildWithPixelBuffer:pixelBuffer mattePixelBuffer:mattePixelBuffer pipSampleBuffer:nil time:time immediate:NO];
        [self tryFinishImageCapture];
    });
}

- (void)setLivePhotoCaptureSuspended:(BOOL)livePhotoCaptureSuspended {
    _livePhotoCaptureSuspended = livePhotoCaptureSuspended;
    [self runAsyncOnOperationQueue:^{
        if (self.imageOutput.livePhotoCaptureEnabled) {
            self.imageOutput.livePhotoCaptureSuspended = livePhotoCaptureSuspended;
        }
    }];
}

- (void)captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingLivePhotoToMovieFileAtURL:(NSURL *)outputFileURL
             duration:(CMTime)duration photoDisplayTime:(CMTime)photoDisplayTime resolvedSettings:(AVCaptureResolvedPhotoSettings *)resolvedSettings
                error:(nullable NSError *)error {
    BMWMLog(@"didFinishProcessingLivePhotoToMovieFileAtURL:%@, duration:%@, photoDisplayTime:%@, error:%@",
           outputFileURL,
           @(CMTimeGetSeconds(duration)),
           @(CMTimeGetSeconds(photoDisplayTime)),
           error);
    dispatch_async(self.imageCaptureQueue, ^{
        self.videoInfo = [BMWLivePhotoCapturedVideoInfo new];
        self.videoInfo.videoError = error;
        self.imageOutput.livePhotoCaptureSuspended = NO;
        self.videoInfo.videoDuration = CMTimeGetSeconds(duration);
        self.videoInfo.photoDisplayTime = CMTimeGetSeconds(photoDisplayTime);
        [self tryFinishImageCapture];
    });
}

- (void)tryFinishImageCapture {
    BOOL imageReady = self.capturedData != nil;
    BOOL videoReady = !self.livePhotoCaptureEnabled || self.videoInfo != nil;
    if (!imageReady || !videoReady) {
        return;
    }
    
    SafeBlock(self.takePhotoCompleteBlock, self.capturedData);
    
    CVPixelBufferRelease(self.capturedData.pixelBuffer);
    CVPixelBufferRelease(self.capturedData.mattePixelBuffer);
    self.takePhotoCompleteBlock = nil;
    
    if (self.livePhotoCaptureEnabled) {
        SafeBlock(self.captureVideoCompleteBlock,
                  self.videoInfo.videoDuration,
                  self.videoInfo.photoDisplayTime,
                  self.videoInfo.videoError);
    }
    self.captureVideoCompleteBlock = nil;
    self.videoInfo = nil;
}

#pragma mark - 视频流 & 音频流

- (void)captureOutput:(AVCaptureOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    @autoreleasepool {
        
        if (self.changingStatus != BMWCameraKitChangingStatusFinish) {
            BMWMLog(@"captureOutput come, but camera is processing");
        }
        if (!self.isCameraRuning) {
            BMWMLog(@"captureOutput come, but camera is not running");
        }
        if(self.changingStatus == BMWCameraKitChangingStatusSwitchProcessing) {
            BMWMLog(@"captureOutput come, but switch camera, return...");
            return;
        }
        if(!self.cameraColdInited) {
            BMWMLog(@"captureOutput come, but camera cold init not finish ...");
            return;
        }
        if (output == self.audioOutput) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(processAudioBuffer:)]) {
                [self.delegate processAudioBuffer:sampleBuffer];
            }
            if (self.audioDelegate && [self.audioDelegate respondsToSelector:@selector(processAudioBuffer:)]) {
                [self.audioDelegate processAudioBuffer:sampleBuffer];
            }
        } else if(output == self.videoOutput) {
            CMTime frameTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            if (!CMSampleBufferIsValid(sampleBuffer) ||
                pixelBuffer == NULL &&
                CMTIME_IS_INVALID(frameTime)) {
                BMWMLog(@"sample buffer invalid");
                return;
            }
            CFRetain(sampleBuffer);
            if (self.delegate && [self.delegate respondsToSelector:@selector(processVideoBuffer:)]) {
                BMWCameraKitData* data = [[BMWCameraKitData alloc] init];
                data.sampleBuffer = sampleBuffer;
                data.devicePosition = self.inputCamera.position;
                data.metadataObjects = self.fetchMetadataObjects;
                data.rectOfInterest = BMWMakeRectFromCGPoint(self.focusPointOfInterest, CGSizeMake(0.05, 0.05));
                [self.delegate processVideoBuffer:data];
                self.metadataObjects = nil;
            }
            CFRelease(sampleBuffer);
            // 预拍照
            if(!(self.settingProfile.cameraStartupOpt & BMWCameraStartupOptDefaultImmediateMode)) {
                [self takePhotoPreviously];
            }
            
            if (self.logFPS) {
                if (self.lastCheckTime < 0) {
                    self.lastCheckTime = CFAbsoluteTimeGetCurrent();
                }
                if ((CFAbsoluteTimeGetCurrent() - self.lastCheckTime) > 1.0)  {
                    self.lastCheckTime = CFAbsoluteTimeGetCurrent();
                    self.fps = self.framesSinceLastCheck;
                    self.framesSinceLastCheck = 0;
                }
                self.framesSinceLastCheck += 1;
            }
        }
    }
}

#pragma mark - meta data
- (void)captureOutput:(AVCaptureMetadataOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
#if 0
    if(metadataObjects.count > 0) {
        self.metadataObjects = [[NSMutableArray alloc] init];
        for (AVMetadataMachineReadableCodeObject *obj in metadataObjects) {
            BMWMLog(@"didOutputMetadataObjects:%@,%@", @(CMTimeGetSeconds(obj.time)), obj);
            BMWOCRMetaData* data = [[BMWOCRMetaData alloc] init];
            data.label = obj.stringValue;
            data.rect = CGRectMake(obj.bounds.origin.y, obj.bounds.origin.x, obj.bounds.size.height, obj.bounds.size.width);
            [self.metadataObjects addObject:data];
        }
    }
#else
    if(metadataObjects.count > 0) {
        BMWMLog(@"didOutputMetadataObjects:%d, %@", metadataObjects.count, metadataObjects);
        self.metadataObjects = [[NSMutableArray alloc] init];
        for (AVMetadataMachineReadableCodeObject *obj in metadataObjects) {
            [self.metadataObjects addObject:obj];
        }
    }
#endif
}

- (NSString*)calcCaptureSessionPreset
{
    if (self.cameraMode != BMWCameraKitModeVideo && self.settingProfile.enableLivePhoto && !self.settingProfile.enableLivePhotoV2) {
        return AVCaptureSessionPresetPhoto;
    }
    AVCaptureSessionPreset videoPresent = (self.devicePosition == AVCaptureDevicePositionBack ? ([BMWDeviceUtils isLowerThaniPhone6] ? AVCaptureSessionPreset1280x720 : AVCaptureSessionPreset1920x1080) : AVCaptureSessionPreset1280x720);
    AVCaptureSessionPreset imagePresent = (_cameraMode == BMWCameraKitModePhoto4x3 || _cameraMode == BMWCameraKitModePhoto1x1) ? AVCaptureSessionPresetPhoto : ([BMWDeviceUtils isLowerThaniPhone6] ? AVCaptureSessionPreset1280x720 : AVCaptureSessionPreset1920x1080);
    AVCaptureSessionPreset sessionPreset = self.cameraMode == BMWCameraKitModeVideo ? videoPresent : imagePresent;
    return sessionPreset;
}

- (void)canSupportFlash:(void(^)(BOOL enable))block
{
    [self runAsyncOnOperationQueue:^{
        BOOL support = [self.imageOutput.supportedFlashModes containsObject:@(AVCaptureFlashModeOn)];
        if (self.settingProfile.enableLivePhoto && self.settingProfile.enableLivePhotoV2 && self.devicePosition == AVCaptureDevicePositionFront) {
            support = NO;
        }
        if(self.settingProfile.cameraStartupOpt & BMWCameraStartupOptDefaultImmediateMode) {
            support = YES;
        }
         dispatch_async(dispatch_get_main_queue(), ^{
             !block ? : block(support);
         });
    }];
}

- (NSArray*)fetchMetadataObjects
{
    NSArray* objs = [self.metadataObjects copy];
    return objs;
}

#pragma mark - Utils

- (void)setChangingStatus:(BMWCameraKitChangingStatus)changingStatus
{
    if(changingStatus == BMWCameraKitChangingStatusFinish) {
        [self runAsyncOnOperationQueue:^{
            _changingStatus = changingStatus;
            BMWMLog(@"setChangingStatus:%@",@(changingStatus));
            // 冷启动不做模糊处理
            if(!self.cameraColdInited) return;
            if (self.delegate && [self.delegate respondsToSelector:@selector(cameraChangingStatus:)]) {
                [self.delegate cameraChangingStatus:changingStatus];
            }
        } delay:0.06f];
    } else {
        _changingStatus = changingStatus;
        BMWMLog(@"setChangingStatus:%@",@(changingStatus));
        // 冷启动不做模糊处理
        if(!self.cameraColdInited) return;
        if (self.delegate && [self.delegate respondsToSelector:@selector(cameraChangingStatus:)]) {
            [self.delegate cameraChangingStatus:changingStatus];
        }
    }
}

- (void)addObservers
{
    if (self.captureSession) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionRuntimeErrorNotification:) name:AVCaptureSessionRuntimeErrorNotification object:self.captureSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionDidStartRunningNotification:) name:AVCaptureSessionDidStartRunningNotification object:self.captureSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(captureSessionDidStopRunningNotification:) name:AVCaptureSessionDidStopRunningNotification object:self.captureSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(wasInterruptedNotification:) name:AVCaptureSessionWasInterruptedNotification object:self.captureSession];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interruptionEndedNotification:) name:AVCaptureSessionInterruptionEndedNotification object:self.captureSession];
    }
    if(GPCamConfigurator.sharedInstance.focusStrategy != 0) {
        if(self.inputCamera) {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChangeNotification:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.inputCamera];
        }
    }
}

- (void)removeObservers
{
    if (self.captureSession) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionRuntimeErrorNotification object:self.captureSession];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStartRunningNotification object:self.captureSession];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionDidStopRunningNotification object:self.captureSession];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionWasInterruptedNotification object:self.captureSession];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureSessionInterruptionEndedNotification object:self.captureSession];
    }
    if(GPCamConfigurator.sharedInstance.focusStrategy != 0) {
        if(self.inputCamera) {
            [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:self.inputCamera];
        }
    }
}

- (void)captureSessionRuntimeErrorNotification:(NSNotification*)notification
{
    if (self.changingStatus == BMWCameraKitChangingStatusProcessing) {
        BMWMLog(@"captureSessionRuntimeErrorNotification return while busy:%@", notification.userInfo);
        return;
    }
    
    if (BMWALifeCycleHelper.sharedInstance.appInResignActive || BMWALifeCycleHelper.sharedInstance.launchedPassively) {
        BMWMLog(@"captureSessionRuntimeErrorNotification, but appInResignActive!");
        return;
    }
    [self presetPhotoWorkaround];
    [self buildCameraIfNeed];
    BMWMLog(@"captureSessionRuntimeErrorNotification:%@", notification.userInfo);
}

- (void)captureSessionDidStartRunningNotification:(NSNotification*)notification
{
    // 相机冷启动，延迟60ms防止黑帧
    if(!self.cameraColdInited) {
        [self runAsyncOnOperationQueue:^{
            self.cameraColdInited = YES;
        } delay:0.03f];
    }
    self.isCameraRuning = YES;
    self.retryRebuildCameraCount = kDefaultRetryRebuildCameraCount;
    self.receiveVideoDeviceNotAvailableWithMultipleForegroundAppsError = NO;
    [self configureDeviceFlash:self.flashMode];
    [self configureDeviceTorch:self.torchMode];
    self.changingStatus = BMWCameraKitChangingStatusFinish;
    BMWMLog(@"Notification isCameraRuning:YES");
}

- (void)captureSessionDidStopRunningNotification:(NSNotification*)notification
{
    self.isCameraRuning = NO;
    self.changingStatus = BMWCameraKitChangingStatusStop;
    BMWMLog(@"Notification isCameraRuning:NO");
}

- (void)wasInterruptedNotification:(NSNotification*)notification
{
    self.receiveVideoDeviceNotAvailableWithMultipleForegroundAppsError = NO;
    AVCaptureSessionInterruptionReason reason = [notification.userInfo[AVCaptureSessionInterruptionReasonKey] integerValue];
    if(reason == AVCaptureSessionInterruptionReasonAudioDeviceInUseByAnotherClient) {
        self.error = [BMWErrorHelper cameraInitErrorDomain:nil code:BMWCameraInitErrorInterruptionAudioDeviceInUseByAnotherClient];
    } else if(reason == AVCaptureSessionInterruptionReasonVideoDeviceInUseByAnotherClient) {
        self.error = [BMWErrorHelper cameraInitErrorDomain:nil code:BMWCameraInitErrorInterruptionVideoDeviceInUseByAnotherClient];
    } else if(reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableWithMultipleForegroundApps) {
        self.error = [BMWErrorHelper cameraInitErrorDomain:nil code:BMWCameraInitErrorInterruptionVideoDeviceNotAvailableWithMultipleForegroundApps];
        self.receiveVideoDeviceNotAvailableWithMultipleForegroundAppsError = YES;
    }
    if(@available(iOS 11.1, *)) {
        if(reason == AVCaptureSessionInterruptionReasonVideoDeviceNotAvailableDueToSystemPressure) {
            self.error = [BMWErrorHelper cameraInitErrorDomain:nil code:BMWCameraInitErrorInterruptionVideoDeviceNotAvailableDueToSystemPressure];
        }
    }

    [self tryRebuildCamera];
    BMWMLog(@"Notification wasInterruptedNotification reason:%ld", (long)reason);
}

- (void)tryRebuildCamera {
    BMWMLog(@"%s %d, retry count: %d", __FUNCTION__, __LINE__, self.retryRebuildCameraCount);

    if (!self.receiveVideoDeviceNotAvailableWithMultipleForegroundAppsError) {
        BMWMLog(@"not receive VideoDeviceNotAvailableWithMultipleForegroundApps error.");
        return;
    }

    if (GPCamConfigurator.sharedInstance.disableRestartCameraWhenInterruptionEnded) {
        BMWMLog(@"%s %d disableRestartCameraWhenInterruptionEnded", __FUNCTION__, __LINE__);
        return;
    }
    
    if (self.retryRebuildCameraCount <= 0) {
        BMWMLog(@"retry build count is 0, return");
        return;
    }

    if (self.captureSession.isRunning) {
        BMWMLog(@"%s %d Already running.", __FUNCTION__, __LINE__);
        return;
    }

    if (!self.started) {
        BMWMLog(@"%s %d current session not started.", __FUNCTION__, __LINE__);
        return;
    }
    
    if (BMWALifeCycleHelper.sharedInstance.appInResignActive || BMWALifeCycleHelper.sharedInstance.appInBackground) {
        BMWMLog(@"%s %d app not active: %d %d", __FUNCTION__, __LINE__, BMWALifeCycleHelper.sharedInstance.appInResignActive, BMWALifeCycleHelper.sharedInstance.appInBackground);
        return;
    }

    self.retryRebuildCameraCount--;
    [self buildCameraIfNeed];
}

- (void)interruptionEndedNotification:(NSNotification *)notification
{
    BMWMLog(@"%s %d: %@", __FUNCTION__, __LINE__, notification);
    if (notification.object != self.captureSession) {
        BMWMLog(@"Wrong session with: %@, captureSession: %@", notification.object, self.captureSession);
        return;
    }
    
    if (GPCamConfigurator.sharedInstance.disableRestartCameraWhenInterruptionEnded) {
        BMWMLog(@"%s %d disableRestartCameraWhenInterruptionEnded", __FUNCTION__, __LINE__);
        return;
    }
    
    [self runAsyncOnOperationQueue:^{
        if (self.captureSession.isRunning) {
            BMWMLog(@"%s %d Already running.", __FUNCTION__, __LINE__);
            return;
        }
        
        if (!self.started) {
            BMWMLog(@"%s %d current session not started.", __FUNCTION__, __LINE__);
            return;
        }
        
        if (BMWALifeCycleHelper.sharedInstance.appInResignActive || BMWALifeCycleHelper.sharedInstance.appInBackground) {
            BMWMLog(@"%s %d app not active: %d %d", __FUNCTION__, __LINE__, BMWALifeCycleHelper.sharedInstance.appInResignActive, BMWALifeCycleHelper.sharedInstance.appInBackground);
            return;
        }
        
        if (self.receiveVideoDeviceNotAvailableWithMultipleForegroundAppsError) {
            BMWMLog(@"%s %d restart camera due to receiveVideoDeviceNotAvailableWithMultipleForegroundAppsError", __FUNCTION__, __LINE__);
            [self buildCameraIfNeed];
        }
        
        BMWMLog(@"%s %d do nothing.", __FUNCTION__, __LINE__);
    }];
}

- (void)subjectAreaDidChangeNotification:(NSNotification*)notification
{
    BMWMLog(@"[Focus] subjectAreaDidChangeNotification: %@", notification);
    if(GPCamConfigurator.sharedInstance.focusStrategy == 0) return;
    CGPoint devicePoint = CGPointMake(0.5, 0.5);
    [self focusAndExposeAtPoint:devicePoint focusMode:AVCaptureFocusModeContinuousAutoFocus exposeMode:AVCaptureExposureModeContinuousAutoExposure monitorSubjectAreaChange:NO];
}

- (BOOL)supportLivePhoto {
    return self.imageOutput.livePhotoCaptureSupported;
}

- (void)buildCameraIfNeed
{
    [self runAsyncOnOperationQueue:^{
        BMWMLog(@"buildCameraIfNeed async enter ...");
        if (self.cameraMode == BMWCameraKitModeVideo) {
            [self removeAudioInputsAndOutputs];
        }
        [self buildCamera];
        [self configureDeviceFlash:self.flashMode];
        [self configureDeviceTorch:self.torchMode];
        [self setStabilitizationMode];
        if (self.cameraMode == BMWCameraKitModeVideo) {
            [self addAudioInputsAndOutputs];
        }
        [self startCapture:nil];
        BMWMLog(@"buildCameraIfNeed async leave ...");
    }];
}

// case1:ios13+ && iphone7以后【调用拍照+退后台】机率性后置摄像头卡死
// case2:6s && ios14+前置摄像头会出现花屏
// 设置livePhotoCaptureEnabled可以绕过
// 需要在 beginConfiguration/commitConfiguration之间调用，且设置了preset后需要重新设置
- (void)takePhotoWorkaround
{
    if ((@available(iOS 13.0, *) && ![BMWDeviceUtils isLowerThaniPhone7]) ||
        (@available(iOS 14.0, *) && [BMWDeviceUtils isLowerThaniPhone6])) {
        if ((!(@available(iOS 15.4.1, *) && [BMWDeviceUtils isPhone12])) &&
            (!(@available(iOS 15.6.1, *) && [BMWDeviceUtils isPhone13mini])) &&
            !(@available(iOS 16.0, *) && !@available(iOS 17.0, *))) {
            if(!self.settingProfile.portraitEffectsMatte) {
                if (GPCamConfigurator.sharedInstance.enableTakePhotoWorkaround ||
                    !(@available(iOS 18.0, *) && [BMWDeviceUtils isPhone13OrHigher])) {
                    @try {
                        self.imageOutput.livePhotoCaptureEnabled = self.imageOutput.livePhotoCaptureSupported;
                    } @catch (NSException *exception) {
                        BMWMLog(@"takePhotoWorkaround fail:%@",exception);
                    }
                    BMWMLog(@"takePhotoWorkaround livePhoto=ON");
                }
            }
        }
    }
}

// 6以前的机器(ex:6s,11.4.1)切换摄像头比较容易出现photo preset不可用的状况
// 系统相机反复在视频和拍照之间切换也会出现photo preset不可用，这是系统级别的不可用
// 此workaround只能修复photo preset假死的case，真正不可用的case唯有等待或是重启手机
- (void)presetPhotoWorkaround
{
    if([BMWDeviceUtils isLowerThaniPhone6]) {
        [self runAsyncOnOperationQueue:^{
            self.captureSession = [[AVCaptureSession alloc] init];
            [self.captureSession beginConfiguration];
            if ([self.captureSession canSetSessionPreset:AVCaptureSessionPreset1280x720]){
                [self.captureSession setSessionPreset:AVCaptureSessionPreset1280x720];
            }
            [self.captureSession commitConfiguration];
        }];
    }
}

- (NSError*)captureImageError:(NSError*)error
{
    if (error == nil) {
        error = [[NSError alloc] initWithDomain:@"invalid error when do image captureOutput" code:-1 userInfo:nil];
    }
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (error.userInfo) {
        [userInfo addEntriesFromDictionary:error.userInfo];
    }
    [userInfo addEntriesFromDictionary:[self cameraStateDic]];
    NSError *newError = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
    return newError;
}

- (NSDictionary*)cameraStateDic
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic setValue:@(self.fps) forKey:@"fps"];
    [dic setValue:@(self.flashMode) forKey:@"flashMode"];
    [dic setValue:@(self.torchMode) forKey:@"torchMode"];
    [dic setValue:self.curSessionPreset forKey:@"preset"];
    [dic setValue:@(self.devicePosition) forKey:@"positon"];
    [dic setValue:@(self.getVideoStabilizationMode) forKey:@"stabilizationMode"];
    [dic setValue:@(self.cameraMode) forKey:@"cameraMode"];
    [dic setValue:@(!BMWALifeCycleHelper.sharedInstance.appInResignActive) forKey:@"appActive"];
    [dic setValue:@(self.isCameraRuning) forKey:@"isCameraRuning"];
    [dic setValue:@([BMWDeviceUtils availableMemoryMB]) forKey:@"freeMemory"];
    [dic setValue:@(self.imageQuality) forKey:@"imageQuality"];
    [dic setValue:@(self.livePhotoCaptureEnabled) forKey:@"livePhotoCaptureEnabled"];
    [dic setValue:@(self.settingProfile.enableLivePhoto) forKey:@"enableLivePhoto"];
    [dic setValue:@(self.settingProfile.enableLivePhotoV2) forKey:@"enableLivePhotoV2"];
    return dic;
}


#pragma mark - BMWAudioSource

- (void)startAudioCaptureWithDelegate:(id<BMWAudioKitDelegate>)delegate {
    self.audioDelegate = delegate;
}

- (void)stopAudioCaptureWithDelegate:(id<BMWAudioKitDelegate>)delegate {
    self.audioDelegate = nil;
}

@end
