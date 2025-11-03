#import <Foundation/Foundation.h>
#import "BMWSliceData.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BMWImageClarityOptError) {
    // 接口请求无效的参数
    BMWImageClarityOptErrorInvalidParameter = -2000,
    BMWImageClarityOptErrorNativeDecodeError = -3000,
    BMWImageClarityOptErrorRemoveWMError = -4000,
    BMWImageClarityOptErrorInvalidParameter2 = -4001,
    BMWImageClarityOptErrorRenderingError = -4002,
    BMWImageClarityOptErrorReadImageError = -4003,
    BMWImageClarityOptErrorGetClarityOptError = -4004,
};

@interface BMWImageClarityOptRequest : NSObject
@property (nonatomic) NSData* inputImageData;
@property (nonatomic) CGSize outputSize;
@property (nonatomic) NSString* userCommentStr;

@end

@interface BMWImageClarityOptReslut : NSObject
@property (nonatomic) NSError* error;
@property (nonatomic) BMWSliceDataModel* sliceDataModel;
@end

@interface BMWImageClarityOptManager : NSObject

- (void)process:(void (^)(BMWImageClarityOptRequest *request))builder completeBlock:(void (^)(BMWImageClarityOptReslut* reslut))completeBlock;

@end

NS_ASSUME_NONNULL_END

