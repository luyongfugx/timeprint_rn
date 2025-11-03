#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPCamDefine.h"
#import "BMWWatermarkItem.h"
#import "BMWSliceData.h"
#import "BMWRenderInterface.h"

NS_ASSUME_NONNULL_BEGIN
@interface BMWOrginalRenderModel : NSObject
@property (nonatomic) CVPixelBufferRef pixelBuffer;
@property (nonatomic) CVPixelBufferRef maskPixelBuffer;
@property (nonatomic) CMSampleBufferRef pipSampleBuffer;
@property (nonatomic) UIImage *previewImage;
@property (nonatomic) BMWClarityDetectMode clarityDetectMode;
@property (nonatomic) CGFloat clarityThreshold;
@property (nonatomic) CGFloat previewClarityOffsetForIOS;
@property (nonatomic) BOOL enableSimilarityCheck;
@property (nonatomic) int imageLabelingMethod;
@property (nonatomic) BOOL shopSignRecognition;
@property (nonatomic) BOOL enableImageQualityDetect;
@end

@interface BMWProcessRenderModel : NSObject

@property (nonatomic) BOOL inEditMode;
@property (nonatomic) BOOL sync;
@property (nonatomic) BMWEffectType effectType;
@property (nonatomic) NSArray<BMWWatermarkItem*> *watermarks;
@property (nonatomic) BOOL enableImageFeature;
@property (nonatomic) BOOL enableSliceImage;
@property (nonatomic) BOOL enableTextFilter;
@property (nonatomic) BOOL redrawImage;
@property (nonatomic) UIImage* image;
@property (nonatomic, copy) NSArray<BMWRect *> *(^extraSliceRectsBlock)(void);
@end

@interface BMWOrginalMetaData : NSObject
// captured image和 preview image的相似度
@property (nonatomic, assign) CGFloat previewCapturedSimilarity;
// preview image的模糊度
@property (nonatomic, assign) CGFloat previewClarity;
// captured image的模糊度
@property (nonatomic, assign) CGFloat capturedClarity;

@end

@interface BMWPocessedMetaData : NSObject
// 图像特征
@property (nonatomic, nullable) NSString* imageFeature;
// 图种
@property (nonatomic, nullable) BMWSliceDataModel *sliceDataModel;

@property (nonatomic, nullable) BMWRect* locationRect;
// [3.0.220] 水印时间可能分两部分所以改为数组，如果是两部分则日期在前时间在后
@property (nonatomic, nullable) NSArray<BMWRect*>* timeRects;

@end

@interface BMWImageProcessRequest : NSObject
@property (nonatomic, readonly) long long requesId;
@property (nonatomic) BOOL sync;
@property (nonatomic) BOOL isFront;
@property (nonatomic) BOOL isMirror;
@property (nonatomic) BOOL isNightEnhanceEnabled;
@property (nonatomic) BMWDeviceOrientation deviceOrientation;
@property (nonatomic) CVPixelBufferRef data;
@property (nonatomic) UIImage* image;
@property (nonatomic) NSArray<BMWWatermarkItem*> *watermarks;
@end

@interface BMWImageProcessBuilder : NSObject
+ (BMWImageProcessRequest*)build:(void(^)(BMWImageProcessRequest * maker))block;
@end

NS_ASSUME_NONNULL_END
