#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPCamDefine.h"
#import "GPCamConfigurator.h"
#import "BMWCameraProfile.h"
#import "BMWCameraKitInterface.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWCameraKit : BMWCameraKitBase

@property (nonatomic, readonly) NSError* error;

@property (nonatomic, readonly) AVCaptureDevice *inputCamera;
@property (nonatomic, weak) id<BMWCameraKitDelegate> delegate;
@property (nonatomic, assign) BMWCameraKitMode cameraMode;
@property (nonatomic, assign) AVCaptureDevicePosition devicePosition;
@property (nonatomic, getter=isBackMirrord) BOOL backMirrord;
@property (nonatomic, getter=isFrontMirrord) BOOL frontMirrord;
@property (nonatomic, assign) OSType pixelFormatType;
@property (nonatomic, assign) BOOL logFPS;
@property (nonatomic, assign) BMWImageResolutionQuality imageQuality;
@property (nonatomic, readonly) BMWCameraKitSettingProfile *settingProfile;
@property (nonatomic, readonly) AVCaptureFlashMode flashMode;
@property (nonatomic, assign) BOOL enableLivePhoto;
@property (nonatomic, assign) BOOL enableLivePhotoV2;
@property (nonatomic, assign) BOOL livePhotoCaptureSuspended;
@property (nonatomic, readonly) BOOL supportLivePhoto;
// 是否支持Wide Angle
@property (nonatomic, readonly) BOOL isSupportWideAngle;
@property (nonatomic, readonly) BOOL isInWideAngle;
@property (nonatomic, assign) BOOL isNightEnhanceEnabled;
@property (nonatomic, assign) BOOL enableDisplayFrontCameraInSubPreview;

// 支持广角的情况: currZoomFactor表示当前的缩放比例, [0.5, 1.0)表示广角摄像头, [1, maxZoomFactor]表示普通摄像头(v2.9.185之前为[1,5])
// 不支持支持广角的情况: currZoomFactor表示当前的缩放比例，[1, maxZoomFactor]表示普通摄像头的缩放 (v2.9.185之前为[1,3])
@property (nonatomic, readonly) CGFloat currZoomFactor;

// 设置缩放倍数
- (void)setCurrZoomFactor:(CGFloat)zoomFactor animation:(BOOL)animation;

// 开关wide angle
- (void)enableWideAngle:(BOOL)enable;

// 设置App支持的最大放大倍数，默认为10, 若Camera不支持，将通过软缩放支持
- (void)configMaxZoomFactor:(CGFloat)factor;

// 获取App支持的最小放大倍数
- (CGFloat)getMinZoomFactor:(AVCaptureDevicePosition)position;

// 判断是否支持闪光灯，因为camera操作都是异步，所以这里采用block来支持
- (void)canSupportFlash:(void(^)(BOOL enable))block;

- (BOOL)isFlashAndTorchOff;

+ (dispatch_queue_t)sharedImageCaptureQueue;

- (instancetype)initWithBuilder:(void (^)(BMWCameraKitSettingProfile * profile))builder;
- (instancetype)initWithProfile:(BMWCameraKitSettingProfile *)profile;

// Camera control
- (void)setDevicePosition:(AVCaptureDevicePosition)devicePosition completedBlock:(void(^)(BOOL suc))block;
- (void)startCapture:(void(^)(NSError *error))completeBlock;
- (void)stopCapture:(void(^)(void))completeBlock;
- (void)setStabilitizationMode;
- (void)focusAndExposeAtPoint:(CGPoint)point;
- (void)focusAndExposeAtPoint:(CGPoint)point isUserInitiated:(BOOL)isUserInitiated;
- (void)zoomBegin:(CGFloat)scale;
- (void)zoomEnd:(CGFloat)scale;
- (void)zoomWithScale:(CGFloat)scale;
- (void)configureDeviceFlash:(AVCaptureFlashMode)mode;
- (void)configureDeviceTorch:(AVCaptureTorchMode)mode;
- (void)changeMode:(BMWCameraKitMode)mode;

- (void)addAudioInputsAndOutputs;
- (void)removeAudioInputsAndOutputs;

- (void)addMetadataOutput:(BMWCaptureMetadataType)type;
- (void)removeMetadataOutput;
- (void)updateMetadataRectOfInterest;
- (void)enableNightEnhance:(BOOL)enable;

// take photo
- (void)takePhotoImmediately:(BMWTakePhotoImmediate)immediate
                      useYUV:(BOOL)useYUV
             enableLivePhoto:(BOOL)enableLivePhoto
         pairedVideoFilePath:(NSString *)videoFilePath
       capturedImageCallback:(void (^)(BMWCameraCapturedData *data))capturedImageCallback
pairedVideoDurationAfterCapture:(double)pairedVideoDurationAfterCapture
       capturedVideoCallback:(void (^)(double videoDuration, double photoDisplayTime, NSError *error))capturedVideoCallback;

- (BOOL)isRunning;
- (NSDictionary*)cameraStateDic;

- (CGFloat)extraZoomFactor;

- (NSArray*)fetchMetadataObjects;

- (void)clear;

@end

NS_ASSUME_NONNULL_END
