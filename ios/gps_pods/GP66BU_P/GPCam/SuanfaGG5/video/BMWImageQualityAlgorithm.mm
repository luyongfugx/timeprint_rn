#import "BMWImageQualityAlgorithm.h"
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
@interface BMWImageQualityAlgorithm ()
{
    std::shared_ptr<YOLOV8Cls> imageQualityInfer;
    std::shared_ptr<YOLOV8Cls> recaptureInfer;
}
@property(nonatomic) BOOL algorithmInited;
@property(nonatomic) CGSize inputSize;
@property(nonatomic) NSArray* imageQualityLabelNames;
@property(nonatomic) NSArray* recaptureLabelNames;
@end

@implementation BMWImageQualityAlgorithm
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"image_quality";
}

- (void)dealloc
{
    }

- (instancetype)init
{
    if (self = [super init]) {
        self.imageQualityLabelNames = [NSArray arrayWithObjects:@"defocus", @"motion", @"normal", @"over", nil];
        self.recaptureLabelNames = [NSArray arrayWithObjects:@"normal", @"recapture", nil];
        self.inputSize = CGSizeMake(480, 480);
    }
    return self;
}

- (void)initAlgorithm
{
    if (self.algorithmInited) return;
    NSString *bundleDir = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:@"BMWAlgorithm.bundle"];
    {
        const char* param_path = [[bundleDir stringByAppendingPathComponent:@"image_cls/v100_v1_4cls_yolov8n_picture_quality_op12_fp16.param"] UTF8String];
        const char* bin_path = [[bundleDir stringByAppendingPathComponent:@"image_cls/v100_v1_4cls_yolov8n_picture_quality_op12_fp16.bin"] UTF8String];
        imageQualityInfer.reset(new YOLOV8Cls());
        imageQualityInfer->init(param_path, bin_path);
    }
    {
        const char* param_path = [[bundleDir stringByAppendingPathComponent:@"image_cls/recapture_fp16.param"] UTF8String];
        const char* bin_path = [[bundleDir stringByAppendingPathComponent:@"image_cls/recapture_fp16.bin"] UTF8String];
        recaptureInfer.reset(new YOLOV8Cls());
        recaptureInfer->init(param_path, bin_path);
    }
    self.algorithmInited = YES;
}

- (void)destroyAlgorithm
{
    if (!self.algorithmInited) return;
    imageQualityInfer.reset();
    recaptureInfer.reset();
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

    std::vector<detseries::Classification> image_quality_info;
    std::vector<detseries::Classification> recapture_info;
    imageQualityInfer->infer(sample, image_quality_info, 224, 224);
    recaptureInfer->infer(sample, recapture_info, 480, 480);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    BMWImageQualityAlgorithmResult *result = [[BMWImageQualityAlgorithmResult alloc] init];
    result.status = 0;
    NSMutableArray<BMWRectMetaData*>*metaDatas = [NSMutableArray new];
    for (int i = 0; i < image_quality_info.size(); i++) {
        detseries::Classification info = image_quality_info[i];
        BMWRectMetaData *metaData = [BMWRectMetaData new];
        metaData.label = info.label;
        metaData.score = info.prob;
        metaData.orientation = profile.orient;
        NSString *label = @"unknown";
        if (metaData.label < self.imageQualityLabelNames.count) {
            NSString *rawLabel = self.imageQualityLabelNames[metaData.label];
            if([self.imageQualityLabelNames containsObject:rawLabel]) {
                label = rawLabel;
            }
        }
        metaData.labelName = label;
        [metaDatas addObject:metaData];
    }
    result.imageQualityData = metaDatas;

    metaDatas = [NSMutableArray new];
    for (int i = 0; i < recapture_info.size(); i++) {
        detseries::Classification info = recapture_info[i];
        BMWRectMetaData *metaData = [BMWRectMetaData new];
        metaData.label = info.label;
        metaData.score = info.prob;
        metaData.orientation = profile.orient;
        NSString *label = @"unknown";
        if (metaData.label < self.recaptureLabelNames.count) {
            NSString *rawLabel = self.recaptureLabelNames[metaData.label];
            if([self.recaptureLabelNames containsObject:rawLabel]) {
                label = rawLabel;
            }
        }
        metaData.labelName = label;
        [metaDatas addObject:metaData];
    }
    result.recaptureData = metaDatas;

    if (result.imageQualityData.count > 0 && result.recaptureData.count > 0) {
        result.status = 2;
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
@implementation BMWImageQualityAlgorithm
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"image_quality";
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
