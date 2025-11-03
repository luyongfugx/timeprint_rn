#import <Foundation/Foundation.h>
#import "GPCamDefine.h"
#import <AVFoundation/AVFoundation.h>
#import "BMWVideoAlgorithmResult.h"

@class BMWEncodeProfile;
@class BMWRect;
@class BMWWatermarkItem;
@class BMWCodeDataModel;
@class BMWBlindWatermarkModel;
@class BMWSliceDataModel;
NS_ASSUME_NONNULL_BEGIN

@interface BMWCameraKitData : NSObject
@property (nonatomic) CMSampleBufferRef pipSampleBuffer;
@property (nonatomic) CMSampleBufferRef sampleBuffer;
@property (nonatomic) BMWRect *rectOfInterest;
@property (nonatomic) NSArray * metadataObjects;
@property (nonatomic) AVCaptureDevicePosition devicePosition;
@end

@interface BMWCameraCapturedData : NSObject
@property (nonatomic) BOOL immediate;
@property (nonatomic) CMSampleBufferRef pipSampleBuffer;
@property (nonatomic) CVPixelBufferRef pixelBuffer;
@property (nonatomic) CVPixelBufferRef mattePixelBuffer;
@property (nonatomic) CMTime time;
@property (nonatomic) NSError* error;
+ (BMWCameraCapturedData*)buildWithPixelBuffer:(CVPixelBufferRef)pixelBuffer  mattePixelBuffer:(CVPixelBufferRef)mattePixelBuffer pipSampleBuffer:(CMSampleBufferRef)pipSampleBuffer time:(CMTime)time immediate:(BOOL)immediate;
+ (BMWCameraCapturedData*)buildWithError:(NSError*)error immediate:(BOOL)immediate;
@end

typedef NS_ENUM(NSInteger, BMWCameraStartupOpt) {
    BMWCameraStartupOptNone = 0,
    BMWCameraStartupOptDefaultImmediateMode = 0x1, //不初始化拍照流
    BMWCameraStartupOptCameraInitInBackground = 0x2, //
    BMWCameraStartupOptCameraInitWithoutUI = 0x4,
};
@interface BMWCameraKitSettingProfile : NSObject
@property (nonatomic) NSUInteger cameraStartupOpt;
@property (nonatomic) CGRect validRect;
@property (nonatomic) AVCaptureDevicePosition position;
@property (nonatomic) AVCaptureFlashMode flashMode;
@property (nonatomic) AVCaptureFlashMode torchMode;
@property (nonatomic) BMWCameraKitMode cameraMode;
@property (nonatomic) BMWImageResolutionQuality imageQuality;
@property (nonatomic) BOOL useYUV;
@property (nonatomic) BMWCaptureMetadataType captureMetadataType;
@property (nonatomic) NSUInteger cameraFrameFPS;
@property (nonatomic) BOOL ignoreStabilitizationMode;
@property (nonatomic) BOOL portraitEffectsMatte;
@property (nonatomic) BOOL enableLuminanceDetect;
@property (nonatomic) BOOL useAudioUnit;
@property (nonatomic, assign) BOOL enableLivePhoto;
@property (nonatomic, assign) BOOL enableLivePhotoV2;
@property (nonatomic, assign) double viewDidLoadBegin;
@property (nonatomic, assign) double didFinishLaunchBegin;
@property (nonatomic, assign) BOOL enableDisplayFrontCameraInSubPreview;
@end

@interface BMWCameraSettingProfile : BMWCameraKitSettingProfile
@property (nonatomic) UIView* containView;
@property (nonatomic) BOOL enableFaceAttribute;
@property (nonatomic, copy, nullable) void (^cameraInitCompleteBlock)(NSError* _Nullable error, CGFloat totalTimeCost, CGFloat cameraTimeCost);
@end

@interface BMWEncodeProfile : NSObject

@property (nonatomic, assign) BMWDeviceOrientation deviceOrientation;
// 是否同时录制无水印视频
@property (nonatomic, assign) BOOL enableRecordNoWatermarkVideo;
// 同时录制无水印视频的最大时长
@property (nonatomic, assign) NSUInteger noWatermarkVideoMaxDuration;
// 带水印的视频URL
@property (nonatomic, strong) NSURL* videoUrl;
// 不带水印的视频URL
@property (nonatomic, strong) NSURL* noWatermarkVideoUrl;

// 从外面构造出视频的sliceModel来写到视频的usercommnet里
@property (nonatomic, strong) BMWSliceDataModel *sliceDataModel;

// 默认录制音频，设置为NO,不录制音频
@property (nonatomic, assign) BOOL enableAudioRecord;

// 如果开启了同步网络，需要设置为YES
@property (nonatomic, assign) BOOL shouldOptimizeForNetworkUse;

@property (nonatomic, assign) CGSize videoSize;

@property (nonatomic, assign) int bitrate;

@property (nonatomic, assign) CGFloat frameRate;

@property (nonatomic, copy) NSString *metaData;
@property (nonatomic, copy) NSString *noWatermarkMetaData;

@property (nonatomic, strong) NSDictionary *internalConfiguration;

@property (nonatomic, strong, nullable) BMWCodeDataModel* codeDataModel;

@property (nonatomic, assign) FourCharCode pixelFormat;

- (instancetype)init;

- (NSURL*)generateNoWatermarkVideoUrl:(NSURL *)originalURL;

+ (BMWEncodeProfile*)defaultProfile;

+ (NSDictionary*)videoColorProperties;

@end

@interface BMWVideoMetaData : NSObject

@property (nonatomic, strong, nullable) BMWSliceDataModel *sliceDataModel;

- (instancetype)init:(BMWSliceDataModel*)sliceDataModel;

@end


@interface BMWImageCaptureProfile : NSObject

// 高清拍照的照片的质量，0.0-1.0
@property (nonatomic, assign) CGFloat quality;

// 预览截屏时的图片质量，0.0-1.0
@property(nonatomic, assign) CGFloat snapshotImageQuality;

@property (nonatomic, assign) BOOL needOriginalImage;

@property (nonatomic, assign) BMWImageResolutionQuality originalImageQuality;

@property (nonatomic, assign) BMWImageResolutionQuality processedImageQuality;

@property (nonatomic, strong, nullable) BMWWatermarkItem* watermarkModel;

//watermarkList的层级在watermarkModel下面
@property (nonatomic, strong, nullable) NSArray<BMWWatermarkItem*>* watermarkList;

@property (nonatomic, assign) BMWDeviceOrientation orientaion;

@property (nonatomic, assign) BMWCameraKitMode mode;

@property (nonatomic, assign, nullable) CGImageMetadataRef metadata;

@property (nonatomic, strong, nullable) BMWCodeDataModel* codeDataModel;

@property (nonatomic, strong, nullable) BMWBlindWatermarkModel* blindWatermarkModel;

@property (nonatomic, assign) BOOL enableSliceImage;

@property (nonatomic, assign) BOOL enableClarityOpt;
@property (nonatomic, assign) BOOL enableSimilarityCheck;

@property (nonatomic, assign) BOOL enableImageLabeling;

@property (nonatomic, assign) BOOL enableShopSignRecognition;
@property (nonatomic, assign) BOOL enableTextFilter;

@property (nonatomic, assign) BOOL shouldOptimizeElectronicScreenCapture;

// int 极速模式场景，1：对照组 2：自拍快速拍照 3：光线不足快速拍照 4：边拍边拍走极速模式
@property (nonatomic, assign) NSUInteger enableTakePhotoImmediately;

@property (nonatomic, assign) BOOL enableDeferredPreviewIamge;

@property (nonatomic, assign) BOOL enableLivePhoto;

@property (nonatomic, copy) NSString *livePhotoIdentifier;

@property (nonatomic, copy) NSString *pairedVideoFilePath;

@property (nonatomic, copy) NSString *pairedVideoMetadata;

// 是否需要拍照确认
@property (nonatomic, assign) BOOL needConfirm;

// 是否开启图像质量检测，默认打开
@property (nonatomic, assign) BOOL enableImageQualityDetect;

@property (nonatomic, copy) void (^statusCallBack)(BMWCameraTakeImageStatus status);
@property (nonatomic, copy) void (^previewImgCallBack)(UIImage* _Nullable previewImage, NSError* _Nullable error);
@property (nonatomic, copy) void (^originalImgCallBack)(NSData* _Nullable originalImageData, NSError* _Nullable error);
@property (nonatomic, copy) void (^processedImgCallBack)(NSData* _Nullable processedImageData, NSError* _Nullable error);
@end

@interface BMWImageCaptureMetaData : NSObject
@property (nonatomic, assign) CGSize imageSize;
@property (nonatomic, assign) CGFloat preEndTimestamp;

@property (nonatomic, assign) CGFloat postBeginTimestamp;

@property (nonatomic, strong, nullable) BMWSliceDataModel *sliceDataModel;

// captured image和 preview image的相似度
@property (nonatomic, assign) CGFloat previewCapturedSimilarity;
// preview image的模糊度
@property (nonatomic, assign) CGFloat previewClarity;
// captured image的模糊度
@property (nonatomic, assign) CGFloat capturedClarity;

// 0，不可做清晰度优化；1，可做清晰度优化；2，是否可以做清晰度优化未知，需要做离线检测
@property (nonatomic, assign) NSInteger clarityOptStatus;
// 拍照模式：0为cameraAPi; 1为cameraAPi失败而截帧；2为预览和拍照相似度低而截帧
@property (nonatomic, assign) NSUInteger capturedMode;
// 拍照时的预览亮度,正成范围为0,255
@property (nonatomic, assign) CGFloat previewLuminance;
// 泉眼特征，分类检测原始数据
@property (atomic, strong) BMWImageClsAlgorithmResult *cameraImageClsResult;
// 泉眼特征，分类检测打包数据
@property (nonatomic, strong) NSString* cameraImageClsLabel;
// 泉眼特征，分类检测打包数据带坐标和阈值
@property (nonatomic, strong) NSString* cameraImageEvaLabel;
// 泉眼特征，OCR打包数据
@property (nonatomic, strong) NSString* cameraImageOCRText;

//@property (nonatomic, strong, nullable) NSString *shopSignStr;

@property (nonatomic, strong, nullable) BMWShopSignRecognitionResult *shopSignResult;

// 从系统获取到的metadata,主要用户条形码和二维码等等
@property (nonatomic, strong) NSArray *metadataObjects;

// int 0是关，1是开
@property (nonatomic, assign) int isAmazingMode;
// int 0不是文本滤镜，1是文本滤镜
@property (nonatomic, assign) int isTextFilter;

// int 极速模式场景，1：对照组 2：自拍快速拍照 3：光线不足快速拍照 4：边拍边拍走极速模式
@property (nonatomic, assign) int canAmazingModeAB;
@property (nonatomic, assign) int didAmazingModeAB;
// [3.0.148] 修改协议
// 协议: "FilterType"+"imageFeature"+";"+"FilterType"+"imageFeature"+";"
@property (nonatomic, strong, nullable) NSString *imageFeature;

// [3.0.130] 水印地址Rect
@property (nonatomic, strong, nullable) BMWRect* locationRect;

// [3.0.140] 水印时间Rect
// [3.0.220] 水印时间可能分两部分所以改为数组，如果是两部分则日期在前时间在后
@property (nonatomic, strong, nullable) NSArray<BMWRect*>* timeRects;

// [3.0.185] LivePhoto图片的时间戳，单位秒
@property (nonatomic, assign) double livePhotoDisplayTime;

// [3.0.215] 极速模式返回的最清晰图片下标，-1的话是普通截屏模式
@property (nonatomic, assign) NSInteger clearestFrameIndex;

@property (nonatomic, assign) CMTime frameTime;

@property (nonatomic, strong) BMWImageQualityAlgorithmResult *imageQualityAlgorithmResult;

// 主要用来保证泉眼相关的算法数据ready
- (void)setMetaDataReady;
- (BOOL)waitMetaDataReady:(CGFloat)time;

- (void)setPreviewImageReady;
- (BOOL)waitPreviewImageReady:(CGFloat)time;

- (NSArray<BMWRect *> *)filterImageClsResultWithLabel:(NSString *)label;

@end

@interface BMWAntiFraudDetectStatus : NSObject
@property (nonatomic, assign) BOOL enable;
@property (nonatomic, assign) BOOL processing;
@property (nonatomic, assign) NSUInteger index;
@property (nonatomic, assign) NSUInteger maxCount;
@end

@interface BMWAntiFraudReslut : NSObject
@property (nonatomic, strong) NSString* qrCode;
@property (nonatomic, strong) NSString* ocrText;
@end

NS_ASSUME_NONNULL_END
