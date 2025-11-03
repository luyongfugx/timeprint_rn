#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "BMWVideoAlgorithmResult.h"
#import "BMWErrorHelper.h"
#import "BMWCameraProfile.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BMWCodeDetectType) {
    BMWCodeDetectTypeNone = 0x0,
    BMWCodeDetectTypeBarCode = 0x1,
    BMWCodeDetectTypeOCRCode = 0x2,
    BMWCodeDetectTypeLPCode = 0x4,
    BMWCodeDetectTypeQRCode = 0x8,
    BMWCodeDetectTypeQRBarLPCode = (BMWCodeDetectTypeBarCode|BMWCodeDetectTypeLPCode)
};

@interface BMWCodeRequestModel : NSObject
// [可选] 异步还是同步，实时模式不生效
@property (nonatomic) BOOL sync;
// [必填] 检测类型
@property (nonatomic) BMWCodeDetectType type;
// [可选] 归一化的坐标[0-1]，实时模式不需要传，离线必须传
@property (nonatomic) CGRect cropRect;
// [可选] 实时模式不需要传，离线必须传
@property (nonatomic) UIImage* image;
// [可选] 从相机拍照获取到的MetaData，透传过来即可，实时模式不需要传，离线必须传
@property (nonatomic, nullable) BMWImageCaptureMetaData *captureMetaData;
@end

@interface BMWCodeReslutModel : NSObject
@property (nonatomic) BMWCodeDetectType type;
@property (nonatomic) UIImage* cropImage;
@property (nonatomic) NSArray<BMWOCRMetaData*> *data;
@end

@interface BMWCodeDetectManager : NSObject

+ (BMWCodeDetectManager*)sharedInstance;

- (void)clearBuffer;

- (void)detectWithRequestBulder:(void (^)(BMWCodeRequestModel *model))builder completeBlock:(void (^)(BMWCodeReslutModel* _Nullable reslutModel, NSError *_Nullable error))completeBlock;

- (void)detectV2WithRequestBulder:(void (^)(BMWCodeRequestModel *model))builder completeBlock:(void (^)(BMWCodeReslutModel* _Nullable reslutModel, NSError *_Nullable error))completeBlock;

@end

NS_ASSUME_NONNULL_END
