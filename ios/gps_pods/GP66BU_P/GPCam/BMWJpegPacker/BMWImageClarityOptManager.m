#import "BMWImageClarityOptManager.h"
#import "BMWMUserCommentModel.h"
#import "BMWRemoveWatermarkManager.h"

@implementation BMWImageClarityOptRequest
- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}
@end

@implementation BMWImageClarityOptReslut
@end


@interface BMWImageClarityOptManager ()
@end

@implementation BMWImageClarityOptManager

- (void)dealloc
{
}

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

- (void)process:(void (^)(BMWImageClarityOptRequest *request))builder completeBlock:(void (^)(BMWImageClarityOptReslut* reslut))completeBlock
{
    BMWImageClarityOptRequest *request = [[BMWImageClarityOptRequest alloc] init];
    SafeBlock(builder, request);
    BMWImageClarityOptReslut *reslut = [[BMWImageClarityOptReslut alloc] init];

    BMWRemoveWatermarkManager *manager = [[BMWRemoveWatermarkManager alloc] init];
    [manager process:^(BMWRemoveWatermarkRequest * _Nonnull request2) {
        request2.removeWatermarkType = BMWRemoveWatermarkTypeGetClarityOptImage;
        request2.inputImageData = request.inputImageData;
        request2.outputSize = request.outputSize;
        request2.userCommentStr = request.userCommentStr;
    } completeBlock:^(BMWRemoveWatermarkReslut * _Nonnull reslut2) {
        reslut.error = reslut2.error;
        reslut.sliceDataModel = reslut2.sliceDataModel;
        SafeBlock(completeBlock, reslut);
    }];
}

@end
