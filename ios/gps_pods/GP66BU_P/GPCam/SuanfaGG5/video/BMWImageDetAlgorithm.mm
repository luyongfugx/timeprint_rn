#import "BMWImageDetAlgorithm.h"
#import "BMWDeviceUtils.h"
#import "GPCamDefine.h"
#import "BMWBufferUtils.h"
#import <AVFoundation/AVFoundation.h>
#import "BMWVideoAlgorithmResult.h"
#import "BMWAlgorithmModelManager.h"
#if CVAlgorithmgEnable
#import "yolov8_det.h"
#import "BMWGLUtils.h"
#import "BMWAlgorithmUtils.h"
#import "BMWAlgorithmProfile.h"
#import "GPCamConfigurator.h"

extern UIImage* mat2Image(const ncnn::Mat& m);
@interface BMWImageDetAlgorithm ()
{
    std::shared_ptr<YOLOV8Det> detInfer;
    DetParam detParam;
}
@property(nonatomic) BOOL algorithmInited;
@property(nonatomic) CGSize inputSize;
@property(nonatomic) BMWAlgorithmConfigModel *configModel;
@property(nonatomic) NSArray* headSceneLabelNames;
@property(nonatomic) NSArray* faceSceneLabelNames;
@property(nonatomic) NSArray* textSceneLabelNames;
@end

@implementation BMWImageDetAlgorithm
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"image_det";
}

- (void)dealloc
{
    }

- (instancetype)init
{
    if (self = [super init]) {
        self.textSceneLabelNames = [NSArray arrayWithObjects:
                                    @"license_plate",
                                    @"car_dashboard",
                                    @"id_card",
                                    @"electronic_scale",
                                    @"table",
                                    @"acceptance_card", nil];
        self.headSceneLabelNames = [NSArray arrayWithObjects:
                                @"shop_sign", nil];
        self.faceSceneLabelNames = [NSArray arrayWithObjects:
                                   @"face", nil];
    }
    return self;
}

- (void)initAlgorithm
{
    if (self.algorithmInited) return;
    // build from local
    NSString *bundleDir = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:@"BMWAlgorithm.bundle"];
    const char* param_path = [[bundleDir stringByAppendingPathComponent:@"image_cls/v95_v27_41det_135yolov8n_train_op12_fp16.param"] UTF8String];
    const char* bin_path = [[bundleDir stringByAppendingPathComponent:@"image_cls/v95_v27_41det_135yolov8n_train_op12_fp16.bin"] UTF8String];
    NSString* config_path = [bundleDir stringByAppendingPathComponent:@"image_cls/image_det_config.txt"];
    self.configModel = [BMWAlgorithmConfigModel buildModelFromJsonPath:config_path];
    // build from cloud
    NSString *modelDir = BMWAlgorithmModelManager.sharedInstance.imageDetPath;
    if([BMWAlgorithmModelManager.sharedInstance isCloudModel:modelDir]) {
        NSString* configPath = [modelDir stringByAppendingPathComponent:@"image_det_config.txt"];
        BMWAlgorithmConfigModel *configModel = [BMWAlgorithmConfigModel buildModelFromJsonPath:configPath];
        if(configModel) {
            self.configModel = configModel;
            param_path = [[modelDir stringByAppendingPathComponent:@"image_det.param"] UTF8String];
            bin_path = [[modelDir stringByAppendingPathComponent:@"image_det.bin"] UTF8String];
        }
    }
    buildDetParam(detParam, self.configModel);
    detInfer.reset(new YOLOV8Det());
    detInfer->init(param_path, bin_path, detParam);
    self.algorithmInited = YES;
}

- (void)destroyAlgorithm
{
    if (!self.algorithmInited) return;
    detInfer.reset();
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
    std::vector<detseries::effect_det> det_info;
    int scaledW = self.inputSize.width;
    int scaledH = self.inputSize.height;
    if(width > height) {
        scaledW = self.inputSize.height;
        scaledH = self.inputSize.width;
    }
    detInfer->infer(sample, det_info);

    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    BMWImageClsAlgorithmResult *result = [[BMWImageClsAlgorithmResult alloc] init];
    result.status = 0;
    result.isMirror = profile.isMirror;
    NSMutableArray<BMWRectMetaData*>*metaDatas = [NSMutableArray new];
    CGRect rectTotal = CGRectZero;
    for (int i = 0; i < det_info.size(); i++) {
        detseries::effect_det info = det_info[i];
        CGFloat x = ((CGFloat)info.bbox.left) / width;
        CGFloat y = ((CGFloat)info.bbox.top) / height;
        CGFloat w = (CGFloat)(info.bbox.right - info.bbox.left) / width;
        CGFloat h = (CGFloat)(info.bbox.bottom - info.bbox.top) / height;
        BMWRectMetaData *metaData = [BMWRectMetaData new];
        metaData.label = info.label;
        metaData.score = info.score;
        metaData.orientation = profile.orient;
        metaData.labelName = @"unknown";
        if(metaData.label < self.configModel.labels.count ) {
            metaData.labelName = self.configModel.labels[metaData.label];
        }
        metaData.rectForImage = CGRectMake(x, y, w, h);
        if (profile.orient == BMWDeviceOrientationPortait) {
            metaData.rect = CGRectMake(x, y, w, h);
        } else if (profile.orient == BMWDeviceOrientationLeft) {
            metaData.rect = CGRectMake(1 - y - h, x, h, w);
        } else if (profile.orient == BMWDeviceOrientationRight) {
            metaData.rect = CGRectMake(y, 1 - x - w, h, w);
        } else if (profile.orient == BMWDeviceOrientationDown) {
            metaData.rect = CGRectMake(1 - x - w, 1 - y - h, w, h);
        } else {
            metaData.rect = CGRectMake(x, y, w, h);
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

    // 构造是否人脸场景
    BOOL isFaceScene = NO;
    for (NSInteger i = 0; i < metaDatas.count; i++) {
        BMWRectMetaData *metaData = metaDatas[i];
        for (NSString *l in self.faceSceneLabelNames) {
            if([metaData.labelName isEqualToString:l]) {
                isFaceScene = YES;
                break;
            }
        }
    }

    // 构造是否为门头场景
    for (NSInteger i = 0; i < metaDatas.count; i++) {
        BMWRectMetaData *metaData = metaDatas[i];
        for (NSString *l in self.headSceneLabelNames) {
            if([metaData.labelName isEqualToString:l] && (metaData.score > 0.3 || isFaceScene)) {
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

void buildDetParam(DetParam& detParam, BMWAlgorithmConfigModel *configModel) {
    detParam.prob_threshold = configModel.probThreshold;
    detParam.nms_threshold = configModel.nmsThreshold;
    detParam.net_w = configModel.size;
    detParam.net_h = configModel.size;
    detParam.encrypt = configModel.encrypt;
    if(GPCamConfigurator.sharedInstance.modelDecryptImpl == 2) {
        detParam.encrypt = 2;
    }
    for(NSString* label in configModel.labels) {
        detParam.labels.emplace_back(label.UTF8String);
        detParam.label_prob_thresholds.emplace_back(configModel.probThreshold);
    }
    for(int i = 0; i < MIN(configModel.labels.count, configModel.labelProbThresholds.count); i++) {
        detParam.label_prob_thresholds[i] = configModel.labelProbThresholds[i].floatValue;
    }
}
@end
#else
@implementation BMWImageDetAlgorithm
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"image_det";
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
