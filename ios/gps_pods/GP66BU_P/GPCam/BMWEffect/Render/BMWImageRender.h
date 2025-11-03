#import <AVFoundation/AVFoundation.h>
#import "BMWRenderInterface.h"
#import "BMWImageContext.h"
#import "BMWImageProcessRequest.h"
#import "BMWBlindWatermarkModel.h"
#import "BMWSliceData.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWImageRender : NSObject <BMWRenderInterface>
// 全局设置
@property (nonatomic) BOOL isFront;
@property (nonatomic) BOOL isMirror;
@property (nonatomic) BOOL enableNightMode;
@property (nonatomic) BOOL enableSliceImage;
@property (nonatomic) BOOL ignoreFilter;
@property (nonatomic) BOOL ignoreBeauty;
@property (nonatomic) BOOL isLockLandscape;
@property (nonatomic, readonly) BMWImageContext *imageContext;

- (instancetype)initWithContext:(BMWImageContext *)imageContext;

- (void)processOrginalWithPixelbuffer:(void (^)(BMWOrginalRenderModel *model))builder block:(void (^)(UIImage *_Nullable image, BMWOrginalMetaData *orginalMetaData, NSError *_Nullable error))block;

- (void)processImageWithOriginal:(void (^)(BMWProcessRenderModel *model))builder textureBlock:(void (^ _Nullable )(GLuint textId, NSError *_Nullable error))textureBlock imageBlock:(void (^ _Nullable )(UIImage *_Nullable processedImage, BMWPocessedMetaData *pocessedMetaData, NSError *_Nullable error))imageBlock;

- (void)prepareWatermark:(BMWWatermarkItem *)watermark;

- (void)updateWatermarkInfoV2s:(NSArray<BMWWatermarkInfoV2 *> *)watermarkInfos;

- (void)setBlindWatermarkModel:(BMWBlindWatermarkModel*)blindWatermarkModel;

- (void)setExtraScaleRatio:(CGFloat)factor;

- (void)setTimestamp:(CMTime)timestamp;

@end

NS_ASSUME_NONNULL_END
