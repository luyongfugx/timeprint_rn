#import <Foundation/Foundation.h>
#import "BMWCameraKit.h"
#import "BMWCameraKit+Extra.h"
#import "GPCamDefine.h"
#import "BMWWatermarkItem.h"
#import "BMWCameraProfile.h"
#import "BMWVideoAlgorithmSource.h"
#import "BMWEffectTypeItem.h"
#import "BMWCodeDetectManager.h"

NS_ASSUME_NONNULL_BEGIN

// userInfo : @{ @"facecount" : NSNumber}
FOUNDATION_EXPORT NSNotificationName _Nonnull const BMWCameraFaceCountNotification;
// userInfo : @{ @"luminance" : NSNumber}
FOUNDATION_EXPORT NSNotificationName _Nonnull const BMWCameraLuminanceNotification;

@class BMWGLView;

typedef void(^BMWCameraModeChangeBlock)(BMWCameraMode mode, double time);

@interface BMWCamera : BMWVideoAlgorithmSource
@property (nonatomic, readonly) CGFloat currZoomFactor;
@property (nonatomic, readonly) BMWCameraKit *cameraEntry;
// CV algorithm使用的 realtime orientation
@property (nonatomic, assign) BMWDeviceOrientation realtimeDeviceOrientation;
@property (nonatomic, readonly) BMWImageResolutionQuality imageQuality;
@property (nonatomic, assign) BMWCameraMode filterMode;
@property (nonatomic, assign) BOOL isNightEnhanceEnabled;
@property (nonatomic, assign) BOOL isLockLandscape;
@property (nonatomic, copy, nullable) BMWCameraModeChangeBlock modeChangeBlock;
@property (nonatomic, assign) BOOL hiddenProductWatermark;
// 开启极速拍照模式，开启后会缓存预览帧，拍照时返回一张最清晰的图片
@property (nonatomic, assign) BOOL enableClearestFrameSelector;
@property (nonatomic, assign) BOOL enableDisplayFrontCameraInSubPreview;

// init
- (instancetype)initWithBuilder:(void (^)(BMWCameraSettingProfile* profile))builder;

- (void)addCameraPreview:(nullable BMWGLView*)view;
- (void)removeCameraPreview:(nullable BMWGLView*)view;

- (void)addSubCameraPreviewView:(nullable BMWGLView*)view;
- (void)removeSubCameraPreviewView:(nullable BMWGLView*)view;
- (void)removeAllSubCameraPreviewViews;

// reset
- (void)clear;

// camera control
- (void)switchCamera;
- (void)setImageResolutionQuality:(BMWImageResolutionQuality)quality;
- (void)startCapture;
- (void)startCaptureWithCompleteBlock:(void (^)(NSError* _Nullable error, CGFloat totalTimeCost, CGFloat cameraTimeCost))block;
- (void)stopCapture;

// night mode
- (void)enableNightEnhance:(BOOL)enable;
- (BOOL)isSupportNightEnhance;

- (void)setLockLandscape:(BOOL)enable;

// effect
- (void)changeFilter:(BMWCameraMode)mode;
- (void)changeCameraMode:(BMWCameraKitMode)mode;

// call before init BMWCamera
+ (void)setLicensePath:(NSString*)path;
+ (NSArray<BMWEffectTypeItem *>*)supportedEffects;
- (void)setEffectIntensity:(BMWEffectTypeItem *)item intensity:(float)intensity;

- (void)configureProductWatermarkInfo:(nullable BMWWatermarkItem*)watermarkModel;

// video record v2
- (void)startRecordWithWatermarkViewInfo:(nullable BMWWatermarkItem*)watermarkModel profileBuilder:(nullable void(^)(BMWEncodeProfile * profile))builder recordDurationCallBack:(nullable void (^)(CGFloat duration))recordDurationCallBack;

- (void)pauseRecord;

- (void)resumeRecord;

- (void)stopRecord:(void (^)(UIImage *_Nullable previewImage, NSError *_Nullable error))handler completionBlock:(void (^)(BMWVideoMetaData *_Nullable videoMetaData, NSString *_Nullable errorStr))completionBlock;

- (void)stopRecord:(void (^)(NSString *_Nullable errorStr))errorBlock;
- (void)cancleRecording;

// image capture v2
- (void)capturePhotoWithBuilder:(void (^)(BMWImageCaptureProfile * profile))builder
                 statusCallBack:(void (^)(BMWCameraTakeImageStatus status))statusCallBack
             previewImgCallBack:(void (^)(UIImage * _Nullable, NSError * _Nullable))previewImgCallBack
            originalImgCallBack:(void (^)(BMWImageCaptureMetaData* metaData, NSData *_Nullable, NSError * _Nullable))originalImgCallBack
           processedImgCallBack:(void (^)(BMWImageCaptureMetaData* metaData, NSData *_Nullable, NSError * _Nullable))processedImgCallBack;
// 录制中拍照
- (void)capturePhotoWhenRecording:(void (^)(BMWImageCaptureProfile * profile))builder
             processedImgCallBack:(void (^)(BMWImageCaptureMetaData* metaData, NSData *_Nullable, NSError * _Nullable))processedImgCallBack;

// 截取预览帧
- (void)captureCameraFrameImage:(CGSize)size callBack:(void (^)(UIImage* image, NSError * _Nullable))callBack;

// 获取人脸属性
- (void)captureFaceAttribute:(void (^)(BMWFaceAttributeAlgorithmResult* attribute))callBack;

// 启动OCR模型下载
- (void)requestAntiFraud:(nullable void (^)(BMWAntiFraudReslut * _Nullable))callback;

// 相机测，启动实时算法检测
// 注意：如果启动OCR，需要提前下载模型
- (void)startDetectWithRequestBuilder:(nullable void (^)(BMWCodeRequestModel* model))builder
                        completeBlock:(nullable void (^)(BMWCodeReslutModel* _Nullable reslutModel, NSError *_Nullable error))completeBlock
                       luminanceBlock:(nullable void (^)(CGFloat luminance))luminanceBlock;

// 关闭实时算法检测
- (void)stopDetect;

@end

NS_ASSUME_NONNULL_END
