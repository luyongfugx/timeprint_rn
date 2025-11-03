#import "GPCamConfigurator.h"
#import "BMWMediaBaseModel.h"
#import "GPCamDefine.h"


static NSString * BWMSimilarityThreshold = @"BWMSimilarityThreshold";
static NSString * ShouldUseAudioUnit = @"ShouldUseAudioUnit";
static NSString * BMWVideoRecordFPSKey = @"BMWVideoRecordFPSKey";
static NSString * BMWFocusStrategyKey = @"BMWFocusStrategyKey";
static NSString * BMWPreviewImageGenerateModeConfigKey = @"BMWPreviewImageGenerateModeConfigKey";
static NSString * BMWSmoothPreviewTakingImageConfigKey = @"BMWSmoothPreviewTakingImageConfigKey";
static NSString * BMWModelDecryptImplKey = @"BMWModelDecryptImplKey";
static NSString * BMWOriginalImageProcessOptKey = @"BMWOriginalImageProcessOptKey";
static NSString * BMWShopSignRecSmoothKey = @"BMWShopSignRecSmoothKey";
static NSString * BMWTakePhotoImmediatelyWhenContinueShootKey = @"BMWTakePhotoImmediatelyWhenContinueShootKey";
static NSString * BMWWarmupCameraConfigKey = @"BMWWarmupCameraConfigKey";
static NSString * BMWJpegCodecSDKForTakePhotoKey = @"BMWJpegCodecSDKForTakePhotoKey";
static NSString * BMWLivePhotoMemThresholdKey = @"BMWLivePhotoMemThresholdKey";
static NSString * BMWLivePhotoMemThresholdV2Key = @"BMWLivePhotoMemThresholdV2Key";
static NSString * BMWPrioritizeLivePhotoV2Key = @"BMWPrioritizeLivePhotoV2Key";
static NSString * BMWLivePhotoAsyncProcessVideoFrameKey = @"BMWLivePhotoAsyncProcessVideoFrameKey";
static NSString * BMWEnableAudioKitV2Key = @"BMWEnableAudioKitV2Key";
static NSString * BMWVersionCodeKey = @"BMWVersionCodeKey";
static NSString * BMWLivePhotoV2SupportMinVersionKey = @"BMWLivePhotoV2SupportMinVersionKey";
static NSString * BMWLivePhotoV2SupportDeviceIdListKey = @"BMWLivePhotoV2SupportDeviceIdListKey";
static NSString * BMWLivePhotoV2SupportModelIdListKey = @"BMWLivePhotoV2SupportModelIdListKey";
static NSString * BMWLivePhotoDeviceIdKey = @"BMWLivePhotoDeviceIdKey";
static NSString * BMWEnableLivePhotoV3Key = @"BMWEnableLivePhotoV3Key";
static NSString * BMWEnablePrefetchLivePhotoPreviewKey = @"BMWEnablePrefetchLivePhotoPreviewKey";
static NSString * BMWPrefetchLivePhotoPreviewDelayKey = @"BMWPrefetchLivePhotoPreviewDelayKey";
static NSString * BMWEnableLivePhotoContinuousShootingKey = @"BMWEnableLivePhotoContinuousShootingKey";
static NSString * BMWEnableTakePhotoWorkaroundKey = @"BMWEnableTakePhotoWorkaroundKey";
static NSString * BMWImageLabelingMethodKey = @"BMWImageLabelingMethodKey";
static NSString * BMWClearGLContextInMainThreadKey = @"BMWClearGLContextInMainThreadKey";
static NSString * BMWDisableRestartCameraWhenInterruptionEndedKey = @"BMWDisableRestartCameraWhenInterruptionEndedKey";
static NSString * BMWDisableRecordNoWatermarkVideoKey = @"BMWDisableRecordNoWatermarkVideoKey";
static NSString * BMWCameraSharpnessConfigKey = @"BMWCameraSharpnessConfigKey";

@interface XHaudioUnitConfig : BMWMediaBaseModel
@property(strong) NSArray<NSString*> *blackList;
@end

@interface BMWFocusStrategyConfig : BMWMediaBaseModel
@property(assign) NSUInteger value;
@property(strong) NSArray<NSString*> *blackList;
@end

@interface BMWSmoothPreviewTakingImageConfig : BMWMediaBaseModel
@property(assign) NSUInteger value;
@property(strong) NSArray<NSString*> *blackList;
@end

@interface BMWPreviewImageGenerateModeConfig : BMWMediaBaseModel
@property(assign) NSUInteger value;
@property(strong) NSArray<NSString*> *blackList;
@end

@interface BMWMediaWhiteListConfig : BMWMediaBaseModel
@property(assign) NSUInteger value;
@property(strong) NSArray<NSString*> *whiteList;
- (NSUInteger)isHit:(NSString*)deviceId;
@end

@interface BMWMediaBlackListConfig : BMWMediaBaseModel
@property(assign) NSUInteger value;
@property(strong) NSArray<NSString*> *blackList;
- (NSUInteger)isHit:(NSString*)deviceId;
@end

@interface BMWCloldMeidaSDKConfigModel : BMWMediaBaseModel
@property(assign) CGFloat bwmSimilarity;
@property(strong) XHaudioUnitConfig* audioUnit;

// jpeg upload size config
@property(strong) NSString* jpegCodecSDK;
@property(strong) NSString* jpegFileSizeForUpload;

// night mode version config
@property(strong) NSString* nightModeVer;

// jpeg packer version config
@property(strong) NSString* jpegPackerVersion;

// 相似度检测开关
@property(strong) NSString* enableSimilarityDetect;

// 相似度阀值
@property(strong) NSString* similarityThreshold;

// 清晰度检测模式；0:关闭，1:检测见模式, 2:离线检测
@property(strong) NSString* enableClarityDetect;
@property(strong) NSString* clarityThreshold;
@property(strong) NSString* previewClarityOffsetForIOS;

// 视频FPS
@property(strong) NSString* videoRecordFPS;

// 是否开启擦除水印
@property(strong) NSString* enableEraseWatermark;

// 是否开启反诈检测
@property(strong) NSString* enableAntiFraud;

// 对焦策略开关
@property(strong) BMWFocusStrategyConfig* focusStrategyV2;

// 3.0.75 拍照不卡预览
@property(strong) BMWSmoothPreviewTakingImageConfig* smoothPreviewTakingImage;

// 3.0.75 新缩略图生成方法
@property(strong) BMWPreviewImageGenerateModeConfig* previewImageGenerateMode;

// 3.0.71 模型解密实现方法
@property(strong) NSString* modelDecryptImpl;

//【3.0.80】原图处理优化
// default 0
@property(strong) BMWMediaBlackListConfig* originalImageProcessOpt;

//【3.0.95】门头识别开关
// default 0
@property(strong) BMWMediaBlackListConfig* shopSignRecSmooth;

//【3.0.125】边拍边拍走极速模式开关
// default 1
@property(strong) BMWMediaBlackListConfig* takePhotoImmediatelyWhenContinueShoot;

//【2.0.40】国际化预拍照开关
// default 1
@property(strong) BMWMediaBlackListConfig* warmupCamera;

// 2.0.40】国际化预拍照开关
// 0 apple codec; 1 jpeg-turbo codec; 2 spectrum codec;
@property(strong) BMWMediaBlackListConfig* jpegCodecSDKForTakePhoto;

// 【3.0.180】支持LivePhoto机器内存阀值
@property (nonatomic, assign) NSInteger livePhotoMemThreshold;

//【3.0.214 】泉眼方法开关，枚举参考XHImageLabelingMethod
@property(strong) NSString* imageLabelingMethod;

//【3.0.215 】清除主线中的GLContext
@property(strong) NSString* clearGLContextInMainThread;

@property(copy) NSString* disableRestartCameraWhenInterruptionEnded;

@end

@implementation XHaudioUnitConfig
@end
@implementation BMWFocusStrategyConfig
@end
@implementation BMWSmoothPreviewTakingImageConfig
@end
@implementation BMWPreviewImageGenerateModeConfig
@end
@implementation BMWMediaWhiteListConfig

- (NSUInteger)isHit:(NSString*)deviceId
{
    if(self.value == 0) return 0;
    NSUInteger support = 0;
    for (NSString *data in self.whiteList) {
        if ([data isEqualToString:deviceId]) {
            support = 1;
            BMWMLog(@"BMWMediaWhiteListConfig hit whiteList, %@", deviceId);
            break;
        }
    }
    return support;
}

@end

@implementation BMWMediaBlackListConfig

- (NSUInteger)isHit:(NSString*)deviceId
{
    if(self.value == 0) return 0;
    NSUInteger support = 1;
    for (NSString *data in self.blackList) {
        if ([data isEqualToString:deviceId]) {
            support = 0;
            BMWMLog(@"BMWMediaBlackListConfig hit blackList, %@", deviceId);
            break;
        }
    }
    return support;
}

@end


@implementation BMWCloldMeidaSDKConfigModel
+ (NSValueTransformer *)audioUnitJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        XHaudioUnitConfig *info = [MTLJSONAdapter modelOfClass:[XHaudioUnitConfig class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(XHaudioUnitConfig *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

+ (NSValueTransformer *)focusStrategyV2JSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWFocusStrategyConfig *info = [MTLJSONAdapter modelOfClass:[BMWFocusStrategyConfig class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWFocusStrategyConfig *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

+ (NSValueTransformer *)smoothPreviewTakingImageJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWSmoothPreviewTakingImageConfig *info = [MTLJSONAdapter modelOfClass:[BMWSmoothPreviewTakingImageConfig class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWSmoothPreviewTakingImageConfig *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

+ (NSValueTransformer *)previewImageGenerateModeJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWPreviewImageGenerateModeConfig *info = [MTLJSONAdapter modelOfClass:[BMWPreviewImageGenerateModeConfig class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWPreviewImageGenerateModeConfig *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

+ (NSValueTransformer *)originalImageProcessOptJSONTransformer
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWMediaBlackListConfig *info = [MTLJSONAdapter modelOfClass:[BMWMediaBlackListConfig class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWMediaBlackListConfig *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

+ (NSValueTransformer *)shopSignRecSmoothJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWMediaBlackListConfig *info = [MTLJSONAdapter modelOfClass:[BMWMediaBlackListConfig class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWMediaBlackListConfig *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

+ (NSValueTransformer *)warmupCameraJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWMediaBlackListConfig *info = [MTLJSONAdapter modelOfClass:[BMWMediaBlackListConfig class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWMediaBlackListConfig *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

+ (NSValueTransformer *)jpegCodecSDKForTakePhotoJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWMediaBlackListConfig *info = [MTLJSONAdapter modelOfClass:[BMWMediaBlackListConfig class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWMediaBlackListConfig *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

@end

@implementation BMWCameraSharpnessConfig

@end

@interface GPCamConfigurator ()
// jpeg compress default 1
// 0 apple codec; 1 jpeg-turbo codec; 2 spectrum codec
@property(assign) NSUInteger jpegCodecSDK;
// default 320
@property(assign) NSUInteger jpegFileSizeForUpload;

// default 2
@property(assign) NSUInteger nightModeVer;

// default 2
@property(assign) NSUInteger jpegPackerVersion;

// default NO
@property(assign) BOOL enableSimilarityDetect;

// default 0.1
@property(assign) CGFloat similarityThreshold;

// 清晰度检测模式
// default 1
// 0:关闭, 1:检测见模式, 2:离线检测
@property(assign) NSUInteger enableClarityDetect;
@property(assign) CGFloat clarityThreshold;
@property(assign) CGFloat previewClarityOffsetForIOS;

// default 30
@property(assign) NSUInteger videoRecordFPS;

// 是否开启擦除水印
@property(assign) NSUInteger enableEraseWatermark;

// 是否开启反诈检测
@property(assign) NSUInteger enableAntiFraud;

// 对焦策略开关
@property(assign) NSUInteger focusStrategy;

// 3.0.75 拍照不卡预览
@property(assign) NSUInteger smoothPreviewTakingImage;

// 3.0.75 缩略图生成方法
@property(assign) NSUInteger previewImageGenerateMode;

// [3.0.71]模型解密实现方法
// default 1; 1对应parse; 2对应parseV2
@property(assign) NSUInteger modelDecryptImpl;

//【3.0.80】原图处理优化
// default 1
@property(assign) NSUInteger originalImageProcessOpt;

//【3.0.95】门头识别开关
// default 0
@property(assign) NSUInteger shopSignRecSmooth;

//【3.0.125】边拍边拍走极速模式开关
// default 1
@property(assign) NSUInteger takePhotoImmediatelyWhenContinueShoot;

//【2.0.40】国际化预拍照
// default 1
@property(assign) NSUInteger warmupCamera;

// 2.0.40】国际化预拍照
// jpeg compress default 1
// 0 apple codec; 1 jpeg-turbo codec; 2 spectrum codec;
@property(assign) NSUInteger jpegCodecSDKForTakePhoto;

//【3.0.214 】泉眼方法开关，枚举参考XHImageLabelingMethod
@property(assign) NSUInteger imageLabelingMethod;

//【3.0.215 】清除主线中的GLContext
@property(assign) NSUInteger clearGLContextInMainThread;

@property(assign) BOOL disableRestartCameraWhenInterruptionEnded;

@end

@implementation GPCamConfigurator

+ (GPCamConfigurator*)sharedInstance
{
    static GPCamConfigurator* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[GPCamConfigurator alloc] init];
        }
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.jpegCodecSDK = 1;
        self.jpegFileSizeForUpload = 320*1024;
        self.nightModeVer = 2;
        self.jpegPackerVersion = 2;
        self.enableSimilarityDetect = NO;
        self.similarityThreshold = -1.0;
        self.clarityThreshold = 15.0f;
        self.previewClarityOffsetForIOS = 5.0f;
        self.videoRecordFPS = 30;

        self.enableClarityDetect = 0;
        self.previewImageGenerateMode = 2;
        self.warmupCamera = 1;
        self.jpegCodecSDKForTakePhoto = 1;
        self.enableEraseWatermark = 1;
        self.enableAntiFraud = 3;
        self.focusStrategy = 0;
        self.smoothPreviewTakingImage = 1;
        self.modelDecryptImpl = 1;
        self.originalImageProcessOpt = 1;
        self.disableRestartCameraWhenInterruptionEnded = NO;
    }
    return self;
}

- (void)setCloudConfig:(NSString*)jsonStr deviceId:(NSString*)deviceId
{
    if (jsonStr.length == 0) {
        return;
    }
    self.deviceId = deviceId;
    NSError *error;
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if(error) {
        BMWMLog(@"cloud config str2dic error:%@", error);
        return;
    }
  
    BMWCloldMeidaSDKConfigModel *model = [MTLJSONAdapter modelOfClass:[BMWCloldMeidaSDKConfigModel class] fromJSONDictionary:jsonDic error:&error];
    
    if(error || model == nil) {
        BMWMLog(@"cloud config dic2model error:%@", error);
        return;
    }
    
    BOOL useAudioUnit = YES;
    for (NSString *data in model.audioUnit.blackList) {
        if ([data isEqualToString:deviceId]) {
            useAudioUnit = NO;
            BMWMLog(@"useAudioUnit hit blackList, %@", deviceId);
            break;
        }
    }
    [[NSUserDefaults standardUserDefaults] setValue:@(useAudioUnit).stringValue forKey:ShouldUseAudioUnit];
    [[NSUserDefaults standardUserDefaults] setValue:@(model.bwmSimilarity).stringValue forKey:BWMSimilarityThreshold];
    if (model.jpegCodecSDK.length > 0) {
        self.jpegCodecSDK = model.jpegCodecSDK.integerValue;
    }
    if (model.jpegFileSizeForUpload.length > 0) {
        self.jpegFileSizeForUpload = model.jpegFileSizeForUpload.integerValue;
    }
    
    if (model.nightModeVer.length > 0) {
        self.nightModeVer = model.nightModeVer.integerValue;
    }
    
    if (model.jpegPackerVersion.length > 0) {
        self.jpegPackerVersion = model.jpegPackerVersion.integerValue;
    }
    
    if (model.enableSimilarityDetect.length > 0) {
        self.enableSimilarityDetect = model.enableSimilarityDetect.integerValue;
    }
    if (model.similarityThreshold.length > 0) {
        self.similarityThreshold = model.similarityThreshold.floatValue;
    }
    
    if (model.enableClarityDetect.length > 0) {
        self.enableClarityDetect = model.enableClarityDetect.integerValue;
    }
    if (model.clarityThreshold.length > 0) {
        self.clarityThreshold = model.clarityThreshold.floatValue;
    }
    if (model.previewClarityOffsetForIOS.length > 0) {
        self.previewClarityOffsetForIOS = model.previewClarityOffsetForIOS.floatValue;
    }
    
    if (model.enableEraseWatermark.length > 0) {
        self.enableEraseWatermark = model.enableEraseWatermark.integerValue;
    }
    
    if (model.enableAntiFraud.length > 0) {
        self.enableAntiFraud = model.enableAntiFraud.integerValue;
    }
    
    if(model.videoRecordFPS.length > 0) {
        [[NSUserDefaults standardUserDefaults] setValue:model.videoRecordFPS forKey:BMWVideoRecordFPSKey];
    }
    
    //【3.0.75】对焦策略开关
    NSUInteger focusStrategyV2 = model.focusStrategyV2 != nil ? model.focusStrategyV2.value : 0;
    for (NSString *data in model.focusStrategyV2.blackList) {
        if ([data isEqualToString:deviceId]) {
            focusStrategyV2 = 0;
            BMWMLog(@"focusStrategy hit blackList, %@", deviceId);
            break;
        }
    }
    [[NSUserDefaults standardUserDefaults] setValue:@(focusStrategyV2).stringValue forKey:BMWFocusStrategyKey];
    
    //【3.0.75】 拍照不卡预览
    NSUInteger smoothPreviewTakingImage = model.smoothPreviewTakingImage != nil ? model.smoothPreviewTakingImage.value : 1;
    for (NSString *data in model.smoothPreviewTakingImage.blackList) {
        if ([data isEqualToString:deviceId]) {
            smoothPreviewTakingImage = 0;
            BMWMLog(@"smoothPreviewTakingImage hit blackList, %@", deviceId);
            break;
        }
    }
    [[NSUserDefaults standardUserDefaults] setValue:@(smoothPreviewTakingImage).stringValue forKey:BMWSmoothPreviewTakingImageConfigKey];
    
    //【3.0.75】 缩略图生成方法
    NSUInteger previewImageGenerateMode = model.previewImageGenerateMode != nil ? model.previewImageGenerateMode.value : _previewImageGenerateMode;
    for (NSString *data in model.previewImageGenerateMode.blackList) {
        if ([data isEqualToString:deviceId]) {
            previewImageGenerateMode = 0;
            BMWMLog(@"previewImageGenerateMode hit blackList, %@", deviceId);
            break;
        }
    }
    [[NSUserDefaults standardUserDefaults] setValue:@(previewImageGenerateMode).stringValue forKey:BMWPreviewImageGenerateModeConfigKey];
    
    // 【3.0.95】门头识别开关
    NSUInteger shopSignRecSmooth = model.shopSignRecSmooth != nil ? model.shopSignRecSmooth.value : 0;
    for (NSString *data in model.shopSignRecSmooth.blackList) {
        if ([data isEqualToString:deviceId]) {
            shopSignRecSmooth = 0;
            BMWMLog(@"shopSignRecSmooth hit blackList, %@", deviceId);
            break;
        }
    }
    [[NSUserDefaults standardUserDefaults] setValue:@(shopSignRecSmooth).stringValue forKey:BMWShopSignRecSmoothKey];
    
    //【3.0.125】边拍边拍走极速模式开关
    NSUInteger takePhotoImmediately = model.takePhotoImmediatelyWhenContinueShoot != nil ? model.takePhotoImmediatelyWhenContinueShoot.value : 1;
    for (NSString *data in model.takePhotoImmediatelyWhenContinueShoot.blackList) {
        if ([data isEqualToString:deviceId]) {
            takePhotoImmediately = 0;
            BMWMLog(@"takePhotoImmediatelyWhenContinueShoot hit blackList, %@", deviceId);
            break;
        }
    }
    [[NSUserDefaults standardUserDefaults] setValue:@(takePhotoImmediately).stringValue forKey:BMWTakePhotoImmediatelyWhenContinueShootKey];
    
    //【3.0.80】原图处理优化
    NSUInteger originalImageProcessOpt = [model.originalImageProcessOpt isHit:deviceId];
    [[NSUserDefaults standardUserDefaults] setValue:@(originalImageProcessOpt).stringValue forKey:BMWOriginalImageProcessOptKey];
    
    //【2.0.40】国际化预拍照
    // default 1
    NSUInteger warmupCamera = model.warmupCamera != nil ? model.warmupCamera.value : _warmupCamera;
    for (NSString *data in model.warmupCamera.blackList) {
        if ([data isEqualToString:deviceId]) {
            shopSignRecSmooth = 0;
            BMWMLog(@"warmupCamera hit blackList, %@", deviceId);
            break;
        }
    }
    [[NSUserDefaults standardUserDefaults] setValue:@(warmupCamera).stringValue forKey:BMWWarmupCameraConfigKey];
    
    //【2.0.40】拍照压缩SDK
    NSUInteger jpegCodecSDKForTakePhoto = model.jpegCodecSDKForTakePhoto != nil ? model.jpegCodecSDKForTakePhoto.value : _jpegCodecSDKForTakePhoto;
    for (NSString *data in model.jpegCodecSDKForTakePhoto.blackList) {
        if ([data isEqualToString:deviceId]) {
            shopSignRecSmooth = 0;
            BMWMLog(@"jpegCodecSDKForTakePhoto hit blackList, %@", deviceId);
            break;
        }
    }
    [[NSUserDefaults standardUserDefaults] setValue:@(jpegCodecSDKForTakePhoto).stringValue forKey:BMWJpegCodecSDKForTakePhotoKey];
    
    if (model.modelDecryptImpl.length > 0) {
        [[NSUserDefaults standardUserDefaults] setValue:model.modelDecryptImpl forKey:BMWModelDecryptImplKey];
    }
    
    //【3.0.214 】泉眼方法开关，枚举参考XHImageLabelingMethod
    if(model.imageLabelingMethod.length > 0) {
        [[NSUserDefaults standardUserDefaults] setValue:model.imageLabelingMethod forKey:BMWImageLabelingMethodKey];
    }
    
    //【3.0.215 】清除主线中的GLContext
    if(model.clearGLContextInMainThread.length > 0) {
        [[NSUserDefaults standardUserDefaults] setValue:model.clearGLContextInMainThread forKey:BMWClearGLContextInMainThreadKey];
    }
    
    if(model.disableRestartCameraWhenInterruptionEnded.length > 0) {
        self.disableRestartCameraWhenInterruptionEnded = [model.disableRestartCameraWhenInterruptionEnded boolValue];
    }
}

- (BOOL)useAudioUnit
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:ShouldUseAudioUnit];
    if (value == nil) {
        return YES;
    }
    return value.boolValue;
}

- (CGFloat)bwmSimilarity
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BWMSimilarityThreshold];
    if (value == nil) {
        return 0.2f;
    }
    return value.floatValue;
}

- (NSUInteger)videoRecordFPS
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWVideoRecordFPSKey];
    if (value == nil) {
        return _videoRecordFPS;
    }
    return value.floatValue;
}

- (NSUInteger)focusStrategy
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWFocusStrategyKey];
    if(value == nil) {
        return _focusStrategy;
    }
    return value.integerValue;
}

- (NSUInteger)smoothPreviewTakingImage
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWSmoothPreviewTakingImageConfigKey];
    if(value == nil) {
        return _smoothPreviewTakingImage;
    }
    return value.integerValue;
}

- (NSUInteger)previewImageGenerateMode
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWPreviewImageGenerateModeConfigKey];
    if(value == nil) {
        return _previewImageGenerateMode;
    }
    return value.integerValue;
}

- (NSUInteger)originalImageProcessOpt
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWOriginalImageProcessOptKey];
    if(value == nil) {
        return _originalImageProcessOpt;
    }
    return value.integerValue;
}

- (NSUInteger)shopSignRecSmooth
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWShopSignRecSmoothKey];
    if(value == nil) {
        return _shopSignRecSmooth;
    }
    return value.integerValue;
}

- (NSUInteger)takePhotoImmediatelyWhenContinueShoot
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWTakePhotoImmediatelyWhenContinueShootKey];
    if(value == nil) {
        return _takePhotoImmediatelyWhenContinueShoot;
    }
    return value.integerValue;
}

- (NSUInteger)warmupCamera
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWWarmupCameraConfigKey];
    if(value == nil) {
        return _warmupCamera;
    }
    return value.integerValue;
}

- (NSUInteger)jpegCodecSDKForTakePhoto
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWJpegCodecSDKForTakePhotoKey];
    if(value == nil) {
        return _jpegCodecSDKForTakePhoto;
    }
    return value.integerValue;
}
    
- (NSUInteger)modelDecryptImpl
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWModelDecryptImplKey];
    if(value == nil) {
        return _modelDecryptImpl;
    }
    return value.integerValue;
}

- (NSInteger)livePhotoMemThreshold
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWLivePhotoMemThresholdKey];
    if(value == nil) {
        return NSIntegerMax;
    }
    return value.integerValue;
}

- (void)setLivePhotoMemThreshold:(NSInteger)livePhotoMemThreshold {
    [[NSUserDefaults standardUserDefaults] setValue:@(livePhotoMemThreshold).stringValue forKey:BMWLivePhotoMemThresholdKey];
}

- (void)setLivePhotoV2Config:(NSString *)config {
    if (config.length == 0) {
        return;
    }
    NSError *error;
    NSData *jsonData = [config dataUsingEncoding:NSUTF8StringEncoding];
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if(error) {
        BMWMLog(@"cloud config str2dic error:%@, config: %@", error, config);
        return;
    }
    
    self.livePhotoMemThresholdV2 = [jsonDic[@"memory_threshold"] integerValue];
    self.prioritizeLivePhotoV2 = [jsonDic[@"prioritize_v2_version"] boolValue];
    self.livePhotoV2SupportMinVersion = [jsonDic[@"support_min_version"] integerValue];
    self.livePhotoV2SupportModelIdList = jsonDic[@"model_white_list"];
    if (self.livePhotoV2SupportModelIdList == nil) {
        self.livePhotoV2SupportModelIdList = @[];
    }
    self.livePhotoV2SupportDeviceIdList = jsonDic[@"device_id_list"];
    if (self.livePhotoV2SupportDeviceIdList == nil) {
        self.livePhotoV2SupportDeviceIdList = @[];
    }
    self.enableLivePhotoV3 = [jsonDic[@"enable_v3"] boolValue];
    self.enableLivePhotoContinuousShooting = [jsonDic[@"enable_continuous_shooting"] boolValue];
    self.enablePrefetchLivePhotoPreview = [jsonDic[@"enable_prefetch_preview"] boolValue];
    self.prefetchLivePhotoPreviewDelay = [jsonDic[@"prefetch_preview_delay"] floatValue];
}

- (void)setCameraSharpnessConfigStr:(NSString *)config {
    [[NSUserDefaults standardUserDefaults] setValue:config forKey:BMWCameraSharpnessConfigKey];
    _cameraSharpnessConfig = nil;
}

- (BMWCameraSharpnessConfig *)cameraSharpnessConfig {
    if (_cameraSharpnessConfig == nil) {
        NSString *config = [[NSUserDefaults standardUserDefaults] stringForKey:BMWCameraSharpnessConfigKey];
        if (config.length > 0) {
            NSError *error;
            NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:[config dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:&error];
            if (error) {
                BMWMLog(@"camera sharpness config str2dic error:%@", error);
                return nil;
            }
            _cameraSharpnessConfig = [MTLJSONAdapter modelOfClass:[BMWCameraSharpnessConfig class] fromJSONDictionary:jsonDic error:&error];
            if (error) {
                BMWMLog(@"camera sharpness config dic2model error:%@", error);
                return nil;
            }
        }
    }
    
    if (_cameraSharpnessConfig == nil) {
        _cameraSharpnessConfig = [[BMWCameraSharpnessConfig alloc] init];
    }
    
    return _cameraSharpnessConfig;
}

- (BOOL)enableTakePhotoWorkaround
{
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWEnableTakePhotoWorkaroundKey];
    if (value == nil) {
        return NO;
    }
    return value.boolValue;
}

- (void)setEnableTakePhotoWorkaround:(BOOL)enableTakePhotoWorkaround {
    [[NSUserDefaults standardUserDefaults] setValue:@(enableTakePhotoWorkaround).stringValue forKey:BMWEnableTakePhotoWorkaroundKey];
}

- (BOOL)enableLivePhotoContinuousShooting
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWEnableLivePhotoContinuousShootingKey];
    if(value == nil) {
        return NO;
    }
    return value.boolValue;
}

- (void)setEnableLivePhotoContinuousShooting:(BOOL)enableLivePhotoContinuousShooting
{
    [[NSUserDefaults standardUserDefaults] setValue:@(enableLivePhotoContinuousShooting).stringValue forKey:BMWEnableLivePhotoContinuousShootingKey];
}

- (BOOL)enableLivePhotoV3
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWEnableLivePhotoV3Key];
    if(value == nil) {
        return NO;
    }
    return value.boolValue;
}

- (void)setEnableLivePhotoV3:(BOOL)enableLivePhotoV3
{
    [[NSUserDefaults standardUserDefaults] setValue:@(enableLivePhotoV3).stringValue forKey:BMWEnableLivePhotoV3Key];
}

- (BOOL)enablePrefetchLivePhotoPreview
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWEnablePrefetchLivePhotoPreviewKey];
    if(value == nil) {
        return NO;
    }
    return value.boolValue;
}

- (void)setEnablePrefetchLivePhotoPreview:(BOOL)enablePrefetchLivePhotoPreview
{
    [[NSUserDefaults standardUserDefaults] setValue:@(enablePrefetchLivePhotoPreview).stringValue forKey:BMWEnablePrefetchLivePhotoPreviewKey];
}

- (CGFloat)prefetchLivePhotoPreviewDelay
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWPrefetchLivePhotoPreviewDelayKey];
    if(value == nil) {
        return 0.5;
    }
    return value.floatValue;
}

- (void)setPrefetchLivePhotoPreviewDelay:(CGFloat)prefetchLivePhotoPreviewDelay
{
    [[NSUserDefaults standardUserDefaults] setValue:@(prefetchLivePhotoPreviewDelay).stringValue forKey:BMWPrefetchLivePhotoPreviewDelayKey];
}

- (NSInteger)livePhotoMemThresholdV2
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWLivePhotoMemThresholdV2Key];
    if(value == nil) {
        return NSIntegerMax;
    }
    return value.integerValue;
}

- (void)setLivePhotoMemThresholdV2:(NSInteger)livePhotoMemThresholdV2 {
    [[NSUserDefaults standardUserDefaults] setValue:@(livePhotoMemThresholdV2).stringValue forKey:BMWLivePhotoMemThresholdV2Key];
}

- (NSArray *)livePhotoV2SupportModelIdList
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWLivePhotoV2SupportModelIdListKey];
    if(value == nil) {
        return @[];
    }
    return [value componentsSeparatedByString:@"###"];
}

- (void)setLivePhotoV2SupportModelIdList:(NSArray *)livePhotoV2SupportModelIdList {
    if (livePhotoV2SupportModelIdList == nil) {
        livePhotoV2SupportModelIdList = @[];
    }
    [[NSUserDefaults standardUserDefaults] setValue:[livePhotoV2SupportModelIdList componentsJoinedByString:@"###"] forKey:BMWLivePhotoV2SupportModelIdListKey];
}

- (NSArray *)livePhotoV2SupportDeviceIdList
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWLivePhotoV2SupportDeviceIdListKey];
    if(value == nil) {
        return @[];
    }
    return [value componentsSeparatedByString:@"###"];
}

- (void)setLivePhotoV2SupportDeviceIdList:(NSArray *)livePhotoV2SupportDeviceIdList {
    if (livePhotoV2SupportDeviceIdList == nil) {
        livePhotoV2SupportDeviceIdList = @[];
    }
    [[NSUserDefaults standardUserDefaults] setValue:[livePhotoV2SupportDeviceIdList componentsJoinedByString:@"###"] forKey:BMWLivePhotoV2SupportDeviceIdListKey];
}

- (NSString *)deviceId {
    NSString *value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWLivePhotoDeviceIdKey];
    if(value == nil) {
        return @"";
    }
    return value;
}

- (void)setDeviceId:(NSString *)deviceId {
    [[NSUserDefaults standardUserDefaults] setValue:deviceId forKey:BMWLivePhotoDeviceIdKey];
}

- (BOOL)prioritizeLivePhotoV2
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWPrioritizeLivePhotoV2Key];
    if(value == nil) {
        return NO;
    }
    return value.boolValue;
}

- (void)setPrioritizeLivePhotoV2:(BOOL)prioritizeLivePhotoV2 {
    [[NSUserDefaults standardUserDefaults] setValue:@(prioritizeLivePhotoV2).stringValue forKey:BMWPrioritizeLivePhotoV2Key];
}

- (NSInteger)versionCode
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWVersionCodeKey];
    if(value == nil) {
        return NSIntegerMax;
    }
    return value.integerValue;
}

- (void)setVersionCode:(NSInteger)versionCode {
    [[NSUserDefaults standardUserDefaults] setValue:@(versionCode).stringValue forKey:BMWVersionCodeKey];
}

- (NSInteger)livePhotoV2SupportMinVersion
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWLivePhotoV2SupportMinVersionKey];
    if(value == nil) {
        return 0;
    }
    return value.integerValue;
}

- (void)setLivePhotoV2SupportMinVersion:(NSInteger)livePhotoV2SupportMinVersion {
    [[NSUserDefaults standardUserDefaults] setValue:@(livePhotoV2SupportMinVersion).stringValue forKey:BMWLivePhotoV2SupportMinVersionKey];
}

- (BOOL)livephotoAsyncProcessVideoFrame {
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWLivePhotoAsyncProcessVideoFrameKey];
    if(value == nil) {
        return NO;
    }
    return value.boolValue;
}

- (void)setLivephotoAsyncProcessVideoFrame:(BOOL)livephotoAsyncProcessVideoFrame {
    [[NSUserDefaults standardUserDefaults] setValue:@(livephotoAsyncProcessVideoFrame).stringValue forKey:BMWLivePhotoAsyncProcessVideoFrameKey];
}

- (BOOL)enableAudioKitV2 {
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWEnableAudioKitV2Key];
    if(value == nil) {
        return NO;
    }
    return value.boolValue;
}

- (NSUInteger)imageLabelingMethod
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWImageLabelingMethodKey];
    if (value == nil) {
        return _imageLabelingMethod;
    }
    return value.integerValue;
}

- (NSUInteger)clearGLContextInMainThread
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWClearGLContextInMainThreadKey];
    if (value == nil) {
        return _clearGLContextInMainThread;
    }
    return value.integerValue;
}

- (BOOL)disableRestartCameraWhenInterruptionEnded
{
    NSString* value = [[NSUserDefaults standardUserDefaults] stringForKey:BMWDisableRestartCameraWhenInterruptionEndedKey];
    if (value == nil) {
        return NO;
    }
    return value.boolValue;
}

- (void)setDisableRestartCameraWhenInterruptionEnded:(BOOL)disableRestartCameraWhenInterruptionEnded
{
    [[NSUserDefaults standardUserDefaults] setValue:@(disableRestartCameraWhenInterruptionEnded).stringValue forKey:BMWDisableRestartCameraWhenInterruptionEndedKey];
}

- (void)setEnableAudioKitV2:(BOOL)enableAudioKitV2 {
    [[NSUserDefaults standardUserDefaults] setValue:@(enableAudioKitV2).stringValue forKey:BMWEnableAudioKitV2Key];
}

- (BOOL)disableRecordNoWatermarkVideo
{
    NSNumber* value = [[NSUserDefaults standardUserDefaults] objectForKey:BMWDisableRecordNoWatermarkVideoKey];
    if(value == nil) {
        return NO;
    }
    return value.boolValue;
}

- (void)setDisableRecordNoWatermarkVideo:(BOOL)disableRecordNoWatermarkVideo {
    [[NSUserDefaults standardUserDefaults] setObject:@(disableRecordNoWatermarkVideo) forKey:BMWDisableRecordNoWatermarkVideoKey];
}

- (CGFloat)captureJpegQuality {
    if (!self.cameraSharpnessConfig.enable || self.cameraSharpnessConfig.minAppVersion > [self versionCode]) {
        return 0.7f;
    }
    
    return self.cameraSharpnessConfig.captureJpegQuality;
}

- (CGFloat)snapshotJpegQuality {
    return 0.99f;
}

@end

@implementation GPCamNewConfigs
@end
