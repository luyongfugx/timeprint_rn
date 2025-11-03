#import <Foundation/Foundation.h>
#import "BMWSliceData.h"
#import "BMWImageContext.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BMWXHSliceImageError) {
    BMWXHSliceImageErrorInvalidParameter = -2000,
};

@interface BMWSliceImageRequest : NSObject
@property (nonatomic) JpegPackType jpegPackerType;
@property (nonatomic) BMWDeviceOrientation orientation;
@property (nonatomic) NSData* imageData;
@property (nonatomic) int scrId;
@property (nonatomic) CGSize texSize;
@property (nonatomic) CGSize outputSize;
@property (nonatomic) NSArray<BMWRect*> *rectList;
@end

@interface BMWSliceImageReslut : NSObject
@property (nonatomic) BMWSliceDataModel *sliceDataModel;
@end

@interface BMWSliceImageProcessor : NSObject

- (instancetype)initWithContext:(BMWImageContext *)imageContext;

- (void)processSlice:(void (^)(BMWSliceImageRequest *request))builder completeBlock:(void (^)(BMWSliceImageReslut* _Nullable reslut))completeBlock;

- (void)processClarityOptImage:(UIImage*)clarityOptImage completeBlock:(void (^)(BMWSliceImageReslut* _Nullable reslut))completeBlock;

@end

NS_ASSUME_NONNULL_END

