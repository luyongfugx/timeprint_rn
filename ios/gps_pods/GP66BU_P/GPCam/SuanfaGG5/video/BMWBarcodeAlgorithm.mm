#import "BMWBarcodeAlgorithm.h"
#import "GPCamDefine.h"
#import "BMWBufferUtils.h"
#import "BMWAlgorithmUtils.h"
#import <AVFoundation/AVFoundation.h>
#import "BMWVideoAlgorithmResult.h"
#import "GPCamRegistrator.h"
#import "BMWSliceData.h"
#import "BMWCodeDetectManager.h"
#import "BMWBufferUtils.h"

#define ScanBarcodeByVision 1
@interface BMWBarcodeAlgorithm()
@property(nonatomic) BMWOCRAlgorithmResult* lastResult;
@property(nonatomic) BOOL algorithmInited;

@property(nonatomic) BMWRect *lastRectOfInterest;;

@end
@implementation BMWBarcodeAlgorithm
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"barcode";
}

- (void)dealloc
{
}

- (instancetype)init
{
    if (self = [super init]) {
        self.lastRectOfInterest = BMWMakeRectFromCGPoint(CGPointMake(0.5, 0.5), CGSizeMake(0.05, 0.05));
        return self;
    }
    return nil;
}

- (void)start
{
    if (self.algorithmInited) return;
    self.algorithmInited = YES;
}

- (void)stop
{
    if (!self.algorithmInited) return;

    self.algorithmInited = NO;
}

- (id<BMWVideoAlgorithmResultInterface>)process:(void (^)(BMWAlgorithmProcessProfile * profile))builder
{
    double begin = CACurrentMediaTime();
    double end = CACurrentMediaTime();
    BMWAlgorithmProcessProfile *profile = [[BMWAlgorithmProcessProfile alloc] init];
    SafeBlock(builder, profile);

    CVPixelBufferRef pixelBuffer = profile.pixelBuffer;
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    NSArray *metadataObjects = profile.metadataObjects;
    BMWCodeAlgorithmResult *result = [[BMWCodeAlgorithmResult alloc] init];
    result.status = 0;
    result.pointOfInterest = profile.rectOfInterest.center;
    NSMutableArray<BMWOCRMetaData*>* array = [[NSMutableArray alloc] init];
    do {

        // 处理条形码和二维码
        dispatch_semaphore_t sync = dispatch_semaphore_create(0);
        [BMWCodeDetectManager.sharedInstance detectV2WithRequestBulder:^(BMWCodeRequestModel * _Nonnull codeRequestModel) {
            codeRequestModel.type = BMWCodeDetectTypeBarCode;
            codeRequestModel.image = [BMWBufferUtils createImageFromPixelBuffer:profile.pixelBuffer];
        } completeBlock:^(BMWCodeReslutModel * _Nullable codeReslutModel, NSError * _Nullable error) {
            [array addObjectsFromArray:codeReslutModel.data];
            dispatch_semaphore_signal(sync);
        }];
        dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(0.5 * NSEC_PER_SEC));
        BOOL ret = (0 != dispatch_semaphore_wait(sync, timeout));
        if(ret) {
                    }

        CGFloat min = MAXFLOAT;
        NSUInteger minIdx = NSIntegerMax;
        for(int idx = 0; idx < array.count; idx++) {
            BMWOCRMetaData* data = array[idx];
            BMWRect *one = BMWMakeRectFromCGRect(data.rect);
            CGFloat d = BMWRectDistance(one, profile.rectOfInterest);
            if(d < min) {
                min = d;
                minIdx = idx;
            }
        }

        if(minIdx != NSIntegerMax) {
            result.dataOfInterest = array[minIdx];
        }
        result.data = array;
    } while (0);
    result.isAdjusted = result.data.count > 1 &&
    (ABS(profile.rectOfInterest.center.x - self.lastRectOfInterest.center.x) > 1e-2 &&
     ABS(profile.rectOfInterest.center.y - self.lastRectOfInterest.center.y) > 1e-2);
    self.lastRectOfInterest = profile.rectOfInterest;
    if(result.data.count > 0) {
        result.status = 2;
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    result.timecost = (CACurrentMediaTime() - begin) * 1000;
        return result;
}

@end
