#import <Foundation/Foundation.h>
#import "BMWMediaBaseModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface GPCamNewConfigs: NSObject
@property (nonatomic) BOOL isCheat;
@end

@interface BMWCameraSharpnessConfig : BMWMediaBaseModel

@property (nonatomic, assign) BOOL enable;

@property (nonatomic, assign) NSInteger minAppVersion;

@property (nonatomic, assign) CGFloat captureSharpnessIntensity;

@property (nonatomic, assign) CGFloat previewSharpnessIntensity;

@property (nonatomic, assign) CGFloat captureJpegQuality;

@end

@interface GPCamConfigurator : NSObject

+ (GPCamConfigurator*)sharedInstance;

// setter
- (void)setCloudConfig:(NSString*)config deviceId:(NSString*)deviceId;

// getter
- (BOOL)useAudioUnit;
- (CGFloat)bwmSimilarity;

// jpeg compress default 1
// 0 apple codec; 1 jpeg-turbo codec; 2 spectrum codec;
@property(assign, readonly) NSUInteger jpegCodecSDK;
// default 280
@property(assign, readonly) NSUInteger jpegFileSizeForUpload;

// night mode version config
// 1 old night mode base on metal;
// 2 new night model base on ncnn
@property(assign, readonly) NSUInteger nightModeVer;

// jpeg packer version config
// default 2
@property(assign, readonly) NSUInteger jpegPackerVersion;

// 相似度检测开关
// default NO
@property(assign, readonly) BOOL enableSimilarityDetect;

// 相似度阀值
@property(assign, readonly) CGFloat similarityThreshold;

@property(nonatomic, assign) NSInteger versionCode;

- (void)setLivePhotoV2Config:(NSString *)config;

- (void)setCameraSharpnessConfigStr:(NSString *)config;

// 支持LivePhoto的机器内存阈值
@property (nonatomic, assign) NSInteger livePhotoMemThreshold;
@property (nonatomic, assign) NSInteger livePhotoMemThresholdV2;
@property (nonatomic, assign) BOOL prioritizeLivePhotoV2;
@property (nonatomic, assign) BOOL livephotoAsyncProcessVideoFrame;
@property (nonatomic, assign) BOOL enableAudioKitV2;
@property (nonatomic, assign) NSInteger livePhotoV2SupportMinVersion;
@property (nonatomic, strong) NSArray *livePhotoV2SupportDeviceIdList;
@property (nonatomic, strong) NSArray *livePhotoV2SupportModelIdList;
@property (nonatomic, assign) BOOL enableLivePhotoV3;
@property (nonatomic, assign) BOOL enableLivePhotoContinuousShooting;
@property (nonatomic, assign) BOOL enablePrefetchLivePhotoPreview;
@property (nonatomic, assign) CGFloat prefetchLivePhotoPreviewDelay;
@property (nonatomic, copy) NSString *deviceId;

@property (nonatomic, assign) BOOL enableTakePhotoWorkaround;

// 清晰度检测模式
// default 1
// 0:关闭, 1:检测见模式, 2:离线检测
@property(assign, readonly) NSUInteger enableClarityDetect;
// 清晰度阀值,默认13.5
@property(assign, readonly) CGFloat clarityThreshold;
// 清晰度阀值,默认5.0f
@property(assign, readonly) CGFloat previewClarityOffsetForIOS;

// 视频录制FPS
// default 30
@property(assign, readonly) NSUInteger videoRecordFPS;

// 是否开启擦除水印
// default 1
@property(assign, readonly) NSUInteger enableEraseWatermark;

// 是否开启反诈检测
// default 0b11
@property(assign, readonly) NSUInteger enableAntiFraud;

//【3.0.75】对焦策略开关
// 0为3.0.75前的老对焦策略ContinuousAutoFocus; 1为3.0.75添加的动态AutoFocus模式
@property(assign, readonly) NSUInteger focusStrategy;

//【3.0.75】 缩略图生成方法
// default 1
@property(assign, readonly) NSUInteger previewImageGenerateMode;

//【3.0.75】 拍照不卡预览
// default 0
@property(assign, readonly) NSUInteger smoothPreviewTakingImage;

// [3.0.71]模型解密实现方法
// default 1; 1对应parse; 2对应parseV2
@property(assign, readonly) NSUInteger modelDecryptImpl;

//【3.0.80】原图处理优化
// default 1
@property(assign, readonly) NSUInteger originalImageProcessOpt;

//【3.0.95】门头识别开关
// default 0
@property(assign, readonly) NSUInteger shopSignRecSmooth;

//【3.0.125】边拍边拍走极速模式开关
// default 1
@property(assign, readonly) NSUInteger takePhotoImmediatelyWhenContinueShoot;

//【2.0.40】国际化预拍照
// default 1
@property(assign, readonly) NSUInteger warmupCamera;

//【2.0.40】拍照压缩SDK
// jpeg compress default 1
// 0 apple codec; 1 jpeg-turbo codec; 2 spectrum codec;
@property(assign, readonly) NSUInteger jpegCodecSDKForTakePhoto;

//【3.0.214 】泉眼方法开关，枚举参考XHImageLabelingMethod
@property(assign, readonly) NSUInteger imageLabelingMethod;

/*【3.0.215 】清除主线中的GLContext,
 * BMWCamera.init 0x1
 * BMWCamera.startCapture 0x2
 * BMWCamera.stopCapture 0x4
 * BMWCamera.switchCamera 0x8
 * BMWCamera.willResignActive 0x10
 */
@property(assign, readonly) NSUInteger clearGLContextInMainThread;

@property(nonatomic, assign, readonly) BOOL disableRestartCameraWhenInterruptionEnded;

@property(nonatomic, assign) BOOL disableRecordNoWatermarkVideo;

@property(nonatomic, strong) BMWCameraSharpnessConfig *cameraSharpnessConfig;

@property(nonatomic, readonly, assign) CGFloat captureJpegQuality;

@property(nonatomic, readonly, assign) CGFloat snapshotJpegQuality;

@end

NS_ASSUME_NONNULL_END
