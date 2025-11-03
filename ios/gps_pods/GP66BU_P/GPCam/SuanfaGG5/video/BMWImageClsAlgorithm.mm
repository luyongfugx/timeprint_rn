#import "BMWImageClsAlgorithm.h"
#import "BMWDeviceUtils.h"
#import "GPCamDefine.h"
#import "BMWBufferUtils.h"
#import <AVFoundation/AVFoundation.h>
#import "BMWVideoAlgorithmResult.h"
#import "BMWAlgorithmModelManager.h"
#if CVAlgorithmgEnable
#import "yolov8_cls.h"
#import "BMWGLUtils.h"
#import "BMWAlgorithmUtils.h"

extern UIImage* mat2Image(const ncnn::Mat& m);
@interface BMWImageClsAlgorithm ()
{
    std::shared_ptr<YOLOV8Cls> clsInfer;
}
@property(nonatomic) BOOL algorithmInited;
@property(nonatomic) CGSize inputSize;
@property(nonatomic) NSArray* labelNamesV1;
@property(nonatomic) NSArray* labelNamesV2;
@property(nonatomic) NSArray* usefulLabelNames;
@property(nonatomic) NSArray* shelfLabelNames;
@property(nonatomic) NSArray* headLabelNames;
@property(nonatomic) NSArray* textSceneLabelNames;
@end

@implementation BMWImageClsAlgorithm
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"image_cls";
}

- (void)dealloc
{
    }

- (instancetype)init
{
    if (self = [super init]) {
        self.labelNamesV1 = [NSArray arrayWithObjects:@"head", @"unknown", @"shelf", nil];
        self.labelNamesV2 = [NSArray arrayWithObjects:
                                 @"parking-indoor", //停车场-室内
                                 @"parking-outdoor", //停车场-室外
                                 @"others-others", //其他-其他
                                 @"animal-dogcat", //动物-猫狗
                                 @"animal-livestock", //动物-畜类
                                 @"animal-bird", //动物-禽类
                                 @"bicycle-bicycle", //单车-单车
                                 @"worksite-indoor", //工地-室内
                                 @"worksite-outdoor", //工地-室外
                                 @"dashboard-others", //标志物-其他仪表盘
                                 @"dashboard-civilian", //标志物-水电燃气表
                                 @"group-training", //聚集-培训
                                 @"group-standing", //聚集-站会
                                 @"group-dinner", //聚集-聚餐
                                 @"field-field", //野外-野外
                                 @"head-head", //门头-门头
                                 @"display-box", //陈列-堆头
                                 @"display-loose", //陈列-散台
                                 @"display-shelf", //陈列-货架
                                 @"display-outlook", //陈列-远景
                                 @"display-food", //陈列-食物
                                 @"plane-plane", //飞机-飞机
                                 @"diner-indoor", //餐饮店-室内
                                 nil];
        self.usefulLabelNames = [NSArray arrayWithObjects:
                                @"bicycle-bicycle",
                                @"worksite-indoor", //工地-室内
                                @"worksite-outdoor", //工地-室外
                                @"group-dinner",
                                @"head-head",
                                @"display-box",
                                @"display-loose",
                                @"display-shelf",
                                @"display-outlook",
                                @"display-food",
                                @"plane-plane",
                                @"diner-indoor",
                                @"dashboard-others",
                                @"dashboard-civilian", nil];
        self.shelfLabelNames = [NSArray arrayWithObjects:
                                @"display-box",
                                @"display-loose",
                                @"display-shelf",
                                @"display-outlook", nil];
        self.headLabelNames = [NSArray arrayWithObjects:
                                @"head-head", nil];

        self.textSceneLabelNames = [NSArray arrayWithObjects:
                                    @"dashboard-others",
                                    @"dashboard-civilian", nil];

        self.inputSize = CGSizeMake(224, 224);
    }
    return self;
}

- (void)initAlgorithm
{
    if (self.algorithmInited) return;
#if 1
    NSString *bundleDir = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:@"BMWAlgorithm.bundle"];
    const char* param_path = [[bundleDir stringByAppendingPathComponent:@"image_cls/v95_v3_23cls_yolov8n.param"] UTF8String];
    const char* bin_path = [[bundleDir stringByAppendingPathComponent:@"image_cls/v95_v3_23cls_yolov8n.bin"] UTF8String];
#else
    NSString *modelDir = BMWAlgorithmModelManager.sharedInstance.steelPath;
    const char* param_path = [[modelDir stringByAppendingPathComponent:@"image_cls.param"] UTF8String];
    const char* bin_path = [[modelDir stringByAppendingPathComponent:@"image_cls.bin"] UTF8String];
#endif
    clsInfer.reset(new YOLOV8Cls());
    clsInfer->init(param_path, bin_path);
    self.algorithmInited = YES;
}

- (void)destroyAlgorithm
{
    if (!self.algorithmInited) return;
    clsInfer.reset();
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
    int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    const unsigned char* data = (GLubyte *)CVPixelBufferGetBaseAddress(pixelBuffer);
    ncnn::Mat sample = ncnn::Mat::from_pixels_resize(data, ncnn::Mat::PIXEL_BGRA2RGB, width, height, stride, self.inputSize.width, self.inputSize.height);
    std::vector<detseries::Classification> cls_info;

    clsInfer->infer(sample, cls_info);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    BMWImageClsAlgorithmResult *result = [[BMWImageClsAlgorithmResult alloc] init];
    result.status = 0;
    result.isMirror = profile.isMirror;
    result.isClassification = YES;
    NSMutableArray<BMWRectMetaData*>*metaDatas = [NSMutableArray new];

    for (int i = 0; i < cls_info.size(); i++) {
        detseries::Classification info = cls_info[i];
        BMWRectMetaData *metaData = [BMWRectMetaData new];
        metaData.label = info.label;
        metaData.score = info.prob;
        metaData.orientation = profile.orient;
        NSString *label = @"unknown";
        if (metaData.label < self.labelNamesV2.count) {
            NSString *rawLabel = self.labelNamesV2[metaData.label];
            if([self.usefulLabelNames containsObject:rawLabel]) {
                label = rawLabel;
            }
//            BMWMLog(@"image labeling cls, label:%@, rawLabel:%@, score:%lf", label, rawLabel, metaData.score);
        }
        metaData.labelName = label;
        [metaDatas addObject:metaData];
    }

    // 构造是否为陈列
    for (NSInteger i = 0; i < metaDatas.count; i++) {
        BMWRectMetaData *metaData = metaDatas[i];
        for (NSString *l in self.shelfLabelNames) {
            if([metaData.labelName isEqualToString:l]) {
                result.isShelf = YES;
                break;
            }
        }
    }

    // 构造是否为门头
    for (NSInteger i = 0; i < metaDatas.count; i++) {
        BMWRectMetaData *metaData = metaDatas[i];
        for (NSString *l in self.headLabelNames) {
            if([metaData.labelName isEqualToString:l]) {
                result.isHead = YES;
                break;
            }
        }
    }

    // 构造是否为文本场景
    for (NSInteger i = 0; i < metaDatas.count; i++) {
        BMWRectMetaData *metaData = metaDatas[i];
        for (NSString *l in self.textSceneLabelNames) {
            if([metaData.labelName isEqualToString:l]) {
                result.isTextScene = YES;
                break;
            }
        }
    }

    if (metaDatas.count > 0) {
        result.status = 2;
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
@implementation BMWImageClsAlgorithm
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"image_cls";
}

- (void)start
{
}

- (void)stop
{
}

- (id<BMWVideoAlgorithmResultInterface>)process:(void (^)(BMWAlgorithmProcessProfile * profile))builder
{
    BMWImageClsAlgorithmResult *result = [[BMWImageClsAlgorithmResult alloc] init];
    return result;
}

@end
#endif
