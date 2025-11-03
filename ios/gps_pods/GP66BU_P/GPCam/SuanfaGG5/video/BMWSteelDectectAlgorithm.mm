#import "BMWSteelDectectAlgorithm.h"
#import "BMWDeviceUtils.h"
#import "GPCamDefine.h"
#import "BMWBufferUtils.h"
#import <AVFoundation/AVFoundation.h>
#import "BMWVideoAlgorithmResult.h"
#import "BMWAlgorithmModelManager.h"
#if CVAlgorithmgEnable
#import "SteelDetectImp.h"
#import "SteelDetectImpV2.h"
#import "SteelDetectImpV3.h"
#define IMP_V3 1
#define IMP_V2 0

#if IMP_V2
#define SteelDetectImp SteelDetectImpV2
#elif IMP_V3
#define SteelDetectImp SteelDetectImpV3
#else
#define SteelDetectImp SteelDetectImp
#endif
@interface BMWSteelDectectAlgorithm ()
{
    std::shared_ptr<SteelDetectImp> stealDetect;
}
@property(nonatomic) BOOL algorithmInited;
@property(nonatomic) CGSize inputSize;
@end

@implementation BMWSteelDectectAlgorithm
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"steel_dectect";
}

- (void)dealloc
{
    }

- (instancetype)init
{
    if (self = [super init]) {
        /**
         (320, 448)
         (480, 640)
         (544, 736)
         (640, 896)
         (720, 960)
         */
    self.inputSize = [BMWDeviceUtils isLowerThaniPhone7] ? CGSizeMake(480, 640) : CGSizeMake(544, 736);
    }
    return self;
}

- (void)initAlgorithm
{
    if (self.algorithmInited) return;
    NSString *modelDir = BMWAlgorithmModelManager.sharedInstance.steelPath;
    // 3 yolo for vlpr
#if 0
    const char* param_path = [[modelDir stringByAppendingPathComponent:@"vpd/yolo_vpd_opt_fp16.param"] UTF8String];
    const char* bin_path = [[modelDir stringByAppendingPathComponent:@"vpd/yolo_vpd_opt_fp16.bin"] UTF8String];
#endif
#if IMP_V2
    const char* param_path = [[modelDir stringByAppendingPathComponent:@"steel_bar_detect.param"] UTF8String];
    const char* bin_path = [[modelDir stringByAppendingPathComponent:@"steel_bar_detect.bin"] UTF8String];
    stealDetect.reset(new SteelDetectImp());
    stealDetect->init(param_path, bin_path);
#elif IMP_V3
    const char* param_path = [[modelDir stringByAppendingPathComponent:@"steel_bar_detect_v7_tiny_opt_fp16.param"] UTF8String];
    const char* bin_path = [[modelDir stringByAppendingPathComponent:@"steel_bar_detect_v7_tiny_opt_fp16.bin"] UTF8String];
    stealDetect.reset(new SteelDetectImp());
    stealDetect->init(param_path, bin_path);
#else
    // 2 yolo for steel
    const char* param_path = [[modelDir stringByAppendingPathComponent:@"steel_detect-opt-fp16.param"] UTF8String];
    const char* bin_path = [[modelDir stringByAppendingPathComponent:@"steel_detect-opt-fp16.bin"] UTF8String];
    stealDetect.reset(new SteelDetectImp());
    stealDetect->init(param_path, bin_path);
#endif
    self.algorithmInited = YES;
}

- (void)destroyAlgorithm
{
    if (!self.algorithmInited) return;
    stealDetect.reset();
    self.algorithmInited = NO;
}

- (id<BMWVideoAlgorithmResultInterface>)process:(void (^)(BMWAlgorithmProcessProfile * profile))builder
{
    BMWAlgorithmProcessProfile *profile = [[BMWAlgorithmProcessProfile alloc] init];
    SafeBlock(builder, profile);
    CVPixelBufferRef pixelBuffer = profile.pixelBuffer;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    const unsigned char* data = (GLubyte *)CVPixelBufferGetBaseAddress(pixelBuffer);
    ncnn::Mat sample = ncnn::Mat::from_pixels(data, ncnn::Mat::PIXEL_BGRA2RGB, width, height);
    std::vector<detseries::effect_det> steal_info;
    int scaledW = self.inputSize.width;
    int scaledH = self.inputSize.height;
    if(width > height) {
        scaledW = self.inputSize.height;
        scaledH = self.inputSize.width;
    }
    stealDetect->detect(sample, steal_info);
    BMWSteelDectectAlgorithmResult *result = [[BMWSteelDectectAlgorithmResult alloc] init];
    result.status = 0;
    NSMutableArray<BMWRectMetaData*>*metaDatas = [NSMutableArray new];
    CGRect rectTotal = CGRectZero;
    for (int i = 0; i < steal_info.size(); i++) {
        detseries::effect_det info = steal_info[i];
        CGFloat W = (CGFloat)(info.bbox.right - info.bbox.left);
        CGFloat H = (CGFloat)(info.bbox.bottom - info.bbox.top);
        // 处理为正方形rect
        CGFloat offsetX = 0; CGFloat offsetY = 0; CGFloat minWH;
        if (H > W) {
            offsetY = (H - W) / 2.0;
            minWH = W;
        } else {
            offsetX = (W - H) / 2.0;
            minWH = H;
        }
        CGFloat x = ((CGFloat)info.bbox.left + offsetX) / width;
        CGFloat y = ((CGFloat)info.bbox.top + offsetY) / height;
        CGFloat w = minWH / width;
        CGFloat h = minWH / height;
        BMWRectMetaData *metaData = [BMWRectMetaData new];
        metaData.label = info.label;
        metaData.score = info.score;
        metaData.orientation = profile.orient;

        metaData.rectForImage = CGRectMake(x, y, w, h);
        if (profile.orient == BMWDeviceOrientationPortait) {
            metaData.rect = CGRectMake(x, y, w, h);
        } else if (profile.orient == BMWDeviceOrientationLeft) {
            metaData.rect = CGRectMake(1 - y - h, x, h, w);
        } else if (profile.orient == BMWDeviceOrientationRight) {
            metaData.rect = CGRectMake(y, 1 - x - w, h, w);
        } else if (profile.orient == BMWDeviceOrientationDown) {
            metaData.rect = CGRectMake(1 - x - w, 1 - y - h, w, h);
        }
        if(profile.isMirror) {
            metaData.rect = CGRectMake(1.0 - metaData.rect.origin.x - metaData.rect.size.width,
                                       metaData.rect.origin.y,
                                       metaData.rect.size.width,
                                       metaData.rect.size.height);
        }
        metaData.id = i;
        rectTotal = CGRectMake(rectTotal.origin.x + metaData.rect.origin.x,
                               rectTotal.origin.y + metaData.rect.origin.y,
                               rectTotal.size.width + metaData.rect.size.width,
                               rectTotal.size.height + metaData.rect.size.height);
        [metaDatas addObject:metaData];
    }
    if (metaDatas.count > 0) {
        result.status = 2;
        result.meanRect = CGRectMake(rectTotal.origin.x / metaDatas.count,
                               rectTotal.origin.y / metaDatas.count,
                               rectTotal.size.width / metaDatas.count,
                               rectTotal.size.height / metaDatas.count);
        result.data = [metaDatas copy];
    }
    if (profile.orient == BMWDeviceOrientationLeft || profile.orient == BMWDeviceOrientationRight) {
        result.sourceRatio = (float) height / width;
    } else {
        result.sourceRatio = (float) width / height;
    }

    return result;
}

- (void)start
{
    [self initAlgorithm];
}

- (void)stop
{
    [self destroyAlgorithm];
}

@end
#else
@implementation BMWSteelDectectAlgorithm
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"steel_dectect";
}

- (void)start
{
}

- (void)stop
{
}

- (id<BMWVideoAlgorithmResultInterface>)process:(void (^)(BMWAlgorithmProcessProfile * profile))builder
{
    BMWSteelDectectAlgorithmResult *result = [[BMWSteelDectectAlgorithmResult alloc] init];
    return result;
}

@end
#endif
