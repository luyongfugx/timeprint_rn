#ifndef GPCamDefine_h
#define GPCamDefine_h

#import "metamacros.h"

#define CAMERA_STARTUP_OPT_DEBUG 0

#define DEBUG_IMAGE_LABELING 1
#define ANTI_BOOM_ENABLE_REBIND 1
#define ANTI_BOOM_ENABLE_FOPEN_REBIND 1
#define ANTI_BOOM_ENABLE_EXIT 1

#define HACK_DISABLE_SHUTTER_SOUND 1

#define VIDEO_TIMESCALE 600
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

#define RECOMMEND_FILTER_ID 94
#define NONE_FILTER_ID -10000

#define FRONT_FILTER_INTENSITY 0.65
#define BACK_FILTER_INTENSITY 0.8
#define SHARPEN_INTENSITY 1.0
#define SATURATION_INTENSITY 1.1

#define RATIO9x16 0.5625
#define RATIO3x4 0.75
#define SIZE_BY_RATIO(size, ratio) ((size) * (ratio))

#define PIP_SCALE  (114 / 375.0f)
#define PIP_RATIO  (0.75f)
#define PIP_OFFSET_X  (10.0f / 375.0f)
#define PIP_OFFSET_Y  (10.0f / 375.0f)
#define PIP_RADIUS  (6.0f / 114.0f)
#define PIP_BORDER  (1.0f / 114.0f)

#define IMAGE_EDIT_MIN_RESOLUTION 1280

#define CLAMP(v, min, max) MIN(MAX(0.0, (v)), 1.0)

#define INVALID_TEXTURE -1

typedef NS_ENUM(NSInteger, GPCamError) {
    GPCamTakePhotoCVPixelBufferCreateError = 1999,
    GPCamTakePhotoCVOpenGLESTextureCacheError = 2000,
    GPCamTakePhotoImageCreateError  = 2001
};

typedef NS_ENUM(NSInteger, BMWCameraMode) {
    BMWCameraModePhotoFront    = 0,
    BMWCameraModePhotoBack     = 1,
    BMWCameraModeVideoFront    = 2,
    BMWCameraModeVideoBack     = 3,
    BMWCameraModePhotoFrontMirror = 8,
    BMWCameraModeVideoFrontMirror = 9,
    BMWCameraModeNone = 10
};

typedef NS_ENUM(NSInteger, BMWDeviceOrientation) {
    BMWDeviceOrientationPortait     = 1,
    BMWDeviceOrientationDown        = 2,
    BMWDeviceOrientationLeft        = 3,
    BMWDeviceOrientationRight       = 4,
    BMWDeviceOrientationUnknown     = 5
};

typedef NS_ENUM(NSInteger, BMWImageResolutionQuality) {
    BMWImageResolutionQualityCurrent,
    BMWImageResolutionQualityLow,
    BMWImageResolutionQualityMedium,
    BMWImageResolutionQualityHigh,
    BMWImageResolutionQualityBest
};

typedef NS_ENUM(NSInteger, BMWImageResolution) {
    BMWImageResolutionDefalut = 4032,
    BMWImageResolutionDefalut_6 = 2560,
    BMWImageResolutionDefalut_7 = 2592,
    BMWImageResolutionLow = 640,
    BMWImageResolutionMedium = 1600,
    BMWImageResolutionHigh = 2560,
    BMWImageResolutionBest = 4160
};

typedef NS_ENUM(NSInteger, BMWCameraTakeImageStatus) {
    BMWCameraTakeImageStatusReadyForNext = 0x0,
    BMWCameraTakeImageStatusBeginCaptureWatermark,
    BMWCameraTakeImageStatusRequestDownloadModel,
    BMWCameraTakeImageStatusSimulateCaptureFlashFinished,
};

typedef NS_ENUM(NSInteger, BMWCameraWriterStatus) {
    BMWCameraWriterStatusInited = 0,
    BMWCameraWriterStatusRecording = 1,
    BMWCameraWriterStatusPaused  = 2,
    BMWCameraWriterStatusSwitchingPaused = 3,
};

typedef NS_ENUM(NSInteger, BMWCameraKitMode) {
    BMWCameraKitModeVideo = 0,
    BMWCameraKitModePhoto4x3 = 1,
    BMWCameraKitModePhoto16x9 = 2,
    BMWCameraKitModePhoto1x1 = 3,
    BMWCameraKitModePhotoFull = 4
};

typedef NS_ENUM(NSInteger, BMWCameraKitChangingStatus) {
    BMWCameraKitChangingStatusProcessing = 0x0,
    BMWCameraKitChangingStatusSwitchProcessing,
    BMWCameraKitChangingStatusFinish,
    BMWCameraKitChangingStatusStop,
    BMWCameraKitChangingStatusStarted
};

typedef NS_ENUM(NSInteger, BMWCameraKitStatus) {
    BMWCameraKitStatusStart = 0x0,
    BMWCameraKitStatusStop
};

typedef NS_ENUM(NSInteger, BMWEditImageStatus) {
    BMWEditImageStatusReadyForNext = 0x0,
    BMWEditImageStatusBeginCaptureWatermark
};

typedef NS_ENUM(NSInteger, BMWSimpleVideoEditorStatus) {
    BMWSimpleVideoEditorStatusInited = 0,
    BMWSimpleVideoEditorStatusFirstFrame = 1,
    BMWSimpleVideoEditorStatusPause = 2,
    BMWSimpleVideoEditorStatusPlaying = 3,
    BMWSimpleVideoEditorStatusStop  = 4,
    BMWSimpleVideoEditorStatusPlayEnd  = 5,
    BMWSimpleVideoEditorStatusExporting  = 6
};

typedef NS_ENUM(NSUInteger, BMWImageFillModeType) {
    kXHImageFillModeStretch,
    kXHImageFillModePreserveAspectRatio,
    kXHImageFillModePreserveAspectRatioAndFill
};

typedef NS_ENUM(NSUInteger, BMWImageRotationMode) {
    kXHImageNoRotation,
    kXHImageRotateLeft,
    kXHImageRotateRight,
    kXHImageFlipVertical,
    kXHImageFlipHorizonal,
    kXHImageRotateRightFlipVertical,
    kXHImageRotateRightFlipHorizontal,
    kXHImageRotate180
};

typedef NS_ENUM(NSInteger, BMWThirdPartBeautifyType) {
    BMWThirdPartBeautifyTypeRedden = 0x1<<0,// 红润
    BMWThirdPartBeautifyTypeSmooth2 = 0x1<<1,// 磨皮2
    BMWThirdPartBeautifyTypeWhiten3 = 0x1<<2,// 美白
    BMWThirdPartBeautifyTypeSharpen = 0x1<<3,//锐化

    BMWThirdPartBeautifyTypeEnlargeEye = 0x1<<4,// 大眼
    BMWThirdPartBeautifyTypeShrinkFace = 0x1<<5,// 瘦脸
    BMWThirdPartBeautifyTypeForehead = 0x1<<6,// 小脸
    BMWThirdPartBeautifyTypebone = 0x1<<7,// 下额
    BMWThirdPartBeautifyTypeNose = 0x1<<8,// 鼻子
    BMWThirdPartBeautifyTypeMouth = 0x1<<9,// 嘴巴
    BMWThirdPartBeautifyTypeBrightenEye = 0x1<<10,// 亮眼
    BMWThirdPartBeautifyTypeWhitenTeeth = 0x1<<11,// 亮牙

    BMWThirdPartBeautifyTypeShrinkJaw = 0x1<<12,// 小脸
    BMWThirdPartBeautifyTypeThinFaceShape = 0x1<<13,//瘦脸型
    BMWThirdPartBeautifyTypeNarrowFace = 0x1<<14,//窄脸
    BMWThirdPartBeautifyTypeRoundEye = 0x1<<15,//圆眼
};

typedef NS_ENUM(NSInteger, BMWSignatureStatus) {
    BMWSignatureStatusBegin,
    BMWSignatureStatusEnded
};

typedef NS_ENUM(NSInteger, BMWImageLabelingMethod) {
    BMWImageLabelingMethodNone = 0,
    // 快消等分类算法
    BMWImageLabelingMethodCls = 0x1,
    // 建筑等检测算法
    BMWImageLabelingMethodDet = 0x2,
    // OCR算法
    BMWImageLabelingMethodOCR = 0x4,
    // 车牌算法
    BMWImageLabelingMethodVLPR = 0x8,
    // 条形码
    BMWImageLabelingMethodBarCode = 0x10,//16
    // 二维码
    BMWImageLabelingMethodQRCode = 0x20, //32
    // 图像质量
    BMWImageLabelingMethodImageQuality = 0x40, //64

    BMWImageLabelingMethodAll = 0x7f
};

typedef NS_ENUM(NSInteger, BMWOfficalWatermarkStyle) {
    //3.0.45：单行右边真实时间官方水印
    BMWOfficalWatermarkStyleOneLineYellowRealTimeFix = 10010,
    //2.9.45：蓝色真实时间官方水印
    BMWOfficalWatermarkStyleBlueRealTimeFix = 10011,
};

typedef NS_ENUM(NSInteger, BMWCaptureMetadataType) {
    BMWCaptureMetadataTypeNone = 0x0,
    BMWCaptureMetadataTypeQrCode = 0x1,
    BMWCaptureMetadataTypeBarCode = 0x2,
    BMWCaptureMetadataTypeAll = 0x3
};

#define BMWAudioFormat_Integer                      int16_t
#define kXHAudioStreamDescription_SampleRate       44100
#define kXHAudioStreamDescription_FormatID         kAudioFormatLinearPCM
#define kXHAudioStreamDescription_FormatFlags      (kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked)
#define kXHAudioStreamDescription_ChannelsPerFrame 1
#define kXHAudioStreamDescription_FramesPerPacket  1
#define kXHAudioStreamDescription_BitsPerChannel   (8 * sizeof(BMWAudioFormat_Integer))
#define kXHAudioStreamDescription_BytesPerFrame    (sizeof(BMWAudioFormat_Integer))
#define kXHAudioStreamDescription_BytesPerPacket   (sizeof(BMWAudioFormat_Integer))

#define SafeBlock(block,...)\
do { \
if (block) { \
block(__VA_ARGS__); \
} \
} while (0)

#define UNUSED(VALUE)     (void)(VALUE)

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

#if USE_NSLOG
#define BMWMLog(frmt, ...) #define BMWMLogM(frmt, ...) #define BMWMLogInterval(interval, frmt, ...) do { \
    static int logCount = 0; \
    if (logCount % (interval) == 0) { \
        \
    } \
    logCount++; \
} while(0)
#else
#define BMWMLog(frmt, ...) BMWMLogI(@"GPCam", frmt, ##__VA_ARGS__)
#define BMWMLogM(frmt, ...) BMWMLogI(@"GPCam Mem", frmt, ##__VA_ARGS__)
#define BMWMLogInterval(interval, frmt, ...) do { \
    static int logCount = 0; \
    if (logCount % (interval) == 0) { \
        BMWMLogI(@"GPCam", frmt, ##__VA_ARGS__); \
    } \
    logCount++; \
} while(0)
#endif

#ifndef weakify
#if DEBUG
#if __has_feature(objc_arc)
#define xhm_weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
#else
#define xhm_weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
#endif
#else
#if __has_feature(objc_arc)
#define xhm_weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
#else
#define xhm_weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
#endif
#endif
#endif

#ifndef strongify
#if DEBUG
#if __has_feature(objc_arc)
#define xhm_strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
#else
#define xhm_strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
#endif
#else
#if __has_feature(objc_arc)
#define xhm_strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
#else
#define xhm_strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
#endif
#endif
#endif

typedef void (^mtl_cleanupBlock_t)();

void mtl_executeCleanupBlock (__strong mtl_cleanupBlock_t *block);

#define onExit \
    try {} @finally {} \
    __strong mtl_cleanupBlock_t metamacro_concat(mtl_exitBlock_, __LINE__) __attribute__((cleanup(mtl_executeCleanupBlock), unused)) = ^

#endif /* GPCamDefine_h */
