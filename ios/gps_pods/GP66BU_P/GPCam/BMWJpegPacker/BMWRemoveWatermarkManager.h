#import <Foundation/Foundation.h>
#import "BMWSliceData.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BMWRemoveWatermarkError) {
    // 接口请求无效的参数
    BMWRemoveWatermarkErrorInvalidParameter = -2000,
    BMWRemoveWatermarkErrorNativeDecodeError = -3000,
    BMWRemoveWatermarkErrorRemoveWMError = -4000,
    BMWRemoveWatermarkErrorInvalidParameter2 = -4001,
    BMWRemoveWatermarkErrorRenderingError = -4002,
    BMWRemoveWatermarkErrorReadImageError = -4003,
    BMWRemoveWatermarkErrorGetClarityOptError = -4004,
};

typedef NS_ENUM(NSInteger, BMWRemoveWatermarkType) {
    BMWRemoveWatermarkTypeAll = 0,
    BMWRemoveWatermarkTypeOfficalWatermark = 1,
    BMWRemoveWatermarkTypeGetClarityOptImage = 2
};

@interface BMWRemoveWatermarkRequest : NSObject
@property (nonatomic)BMWRemoveWatermarkType removeWatermarkType;
@property (nonatomic) NSData* inputImageData;
@property (nonatomic) CGSize outputSize;
@property (nonatomic) NSString* userCommentStr;
@property (nonatomic) BOOL sync;

@end

@interface BMWRemoveWatermarkReslut : NSObject
@property (nonatomic) NSError* error;
@property (nonatomic) BMWSliceDataModel* sliceDataModel;
@end

@interface BMWRemoveWatermarkManager : NSObject

- (void)process:(void (^)(BMWRemoveWatermarkRequest *request))builder completeBlock:(void (^)(BMWRemoveWatermarkReslut* reslut))completeBlock;

- (void)detectClarityOffline:(NSURL*)srcUrl completeBlock:(void (^)(BMWClarityOptStatus reslut))completeBlock;

@end

NS_ASSUME_NONNULL_END

