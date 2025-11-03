#import "BMWVlprAlgorithm.h"
#import "GPCamDefine.h"
#import "BMWBufferUtils.h"
#import "BMWAlgorithmUtils.h"
#import <AVFoundation/AVFoundation.h>
#import "BMWVideoAlgorithmResult.h"
#if CVAlgorithmgEnable
#include "plate_detectors.h"
#include "plate_recognizers.h"
#import "BMWAlgorithmModelManager.h"
#undef GPCamDebuger
#if GPCamDebuger
#import "BMWDetectDebugerView.h"
#endif
extern UIImage* mat2Image(const ncnn::Mat& m);

@interface BMWVlprAlgorithm()
{
    nnpr::PlateDetector detector;
    nnpr::LPRRecognizer lpr;
}
@property(nonatomic) BMWVlprAlgorithmResult* lastResult;
@property(nonatomic) BOOL algorithmInited;
@end
@implementation BMWVlprAlgorithm

@synthesize tag = _tag;

- (NSString*)tag
{
    return @"vlpr";
}

- (void)dealloc
{
    detector.reset();
    lpr.reset();
}

- (instancetype)init
{
    if (self = [super init]) {
        return self;
    }
    return nil;
}

- (void)initAlgorithm
{
    if (self.algorithmInited) return;
    NSString *vlprPath = BMWAlgorithmModelManager.sharedInstance.vlprPath;
    const char* cpath = [vlprPath UTF8String];
    // mtcnn
#if 0
    nnpr::MtcnnPlateDetectorConfig mtcnnconfig = nnpr::mtcnn_int8_detector;
    nnpr::fix_mtcnn_detector(cpath, mtcnnconfig);
    detector = nnpr::IPlateDetector::create_plate_detector(mtcnnconfig);
#endif

    // ssd
#if 0
    nnpr::fix_ssd_detector(cpath, nnpr::ssd_int8_detector);
    detector = nnpr::IPlateDetector::create_plate_detector(nnpr::ssd_int8_detector);
#endif
#if 0
    nnpr::fix_ssd_detector(cpath, nnpr::ssd_float_detector);
    detector = nnpr::IPlateDetector::create_plate_detector(nnpr::ssd_float_detector);
#endif

    // lffd
#if 0
    nnpr::LFFDPlateDetectorConfig lffdconfig = nnpr::lffd_fp16_detector;
    nnpr::fix_lffd_detector(cpath, lffdconfig);
    detector = nnpr::IPlateDetector::create_plate_detector(lffdconfig);
#endif

    // yolo
#if 1
    nnpr::YOLOPlateDetectorConfig yoloconfig = nnpr::yolo_fp16_detector;
    nnpr::fix_yolo_detector(cpath, yoloconfig);
    detector = nnpr::IPlateDetector::create_plate_detector(yoloconfig);
#endif

    // lpc/lpr
#if 1
    nnpr::LPRRecognizerConfig lprConfig = nnpr::float_lpr_recognizer;
    nnpr::fix_lpr_recognizer(cpath, lprConfig);
    lpr = lprConfig.create_recognizer();
#endif

    // lpc/lpr v2
#if 0
    nnpr::LPRRecognizerConfig lprV2Config = nnpr::opt_lpr_recognizer_v2;
    nnpr::fix_lpr_recognizer_v2(cpath, lprV2Config);
    lpr = lprV2Config.create_recognizer_v2();
#endif
    self.algorithmInited = YES;
}

- (void)destroyAlgorithm
{
    if (!self.algorithmInited) return;
    detector.reset();
    lpr.reset();
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
    std::vector<nnpr::PlateInfo> rawObjects;

#if 1
    detector->plate_detect(sample, rawObjects);
    std::vector<nnpr::PlateInfo> objects = detector->align_plates(sample, rawObjects);
    for (auto &obj: objects) {
        obj.aligned = true;
    }
    detector->crop_plates(sample, objects);

    ncnn::Mat sample2 = ncnn::Mat::from_pixels(data, ncnn::Mat::PIXEL_BGRA2BGR, width, height);
    std::vector<nnpr::PlateInfo> objects2 = detector->align_plates(sample2, rawObjects);
    for (auto &obj: objects2) {
        obj.aligned = true;
    }
    detector->crop_plates(sample2, objects2);

    objects.insert(objects.end(), objects2.begin(), objects2.end());
    if(objects.size() == 0 && rawObjects.size() > 0) {
        detector->crop_plates(sample2, rawObjects);
        objects.insert(objects.end(), rawObjects.begin(), rawObjects.end());
        for (auto &obj: objects) {
            obj.aligned = false;
        }
    }
#endif

#if 0
    std::vector<nnpr::PlateInfo> objects;
    detector->plate_detect(sample, objects);
    detector->crop_plates_v2(sample, objects);
#endif

    lpr->decode_plate_infos(objects);
    std::sort(objects.begin(), objects.end(), [](auto l, auto r) {
        return l.bbox.score > r.bbox.score;
    });
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    NSMutableArray *metaDatas = [[NSMutableArray alloc] init];
    BMWVlprAlgorithmResult *result = [[BMWVlprAlgorithmResult alloc] init];
    result.status = 0;
    for (auto pi : objects) {
        BMWVlprMetaData *metaData = [BMWVlprMetaData new];
        metaData.type = [NSString stringWithCString:pi.plate_color.c_str() encoding:NSUTF8StringEncoding];
        CGFloat x = pi.bbox.xmin / width;
        CGFloat y = pi.bbox.ymin / height;
        CGFloat w = (pi.bbox.xmax - pi.bbox.xmin) / width;
        CGFloat h = (pi.bbox.ymax - pi.bbox.ymin) / height;
        metaData.rect = CGRectMake(x, y, w, h);
        metaData.rectForImage = CGRectMake(x, y, w, h);
        if (profile.orient == BMWDeviceOrientationLeft) {
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
        NSString *character = [NSString stringWithCString:pi.plate_no.c_str() encoding:NSUTF8StringEncoding];
        // TODO 省份+地区代码+5位数字/字母（或者数字字母混合）特殊车牌暂不支持。
        //  绿牌为9位,其他蓝白黑牌位8位(包括分隔符)
        if(character.length > 6 && character.length < 9) {
            metaData.formatCharacter = [NSString stringWithFormat:@"%@·%@",[character substringToIndex:2], [character substringFromIndex:2]];
            metaData.score = pi.bbox.score;
            [metaDatas addObject:metaData];
#if GPCamDebuger
            metaData.plateImage = mat2Image(pi.license_plate);
#endif
        }
        break;
    }
    if (metaDatas.count > 0) {
        result.status = 2;
        result.data = [metaDatas copy];
    }
    if(profile.enableSmooth) {
        result = [self smooth:result];
    }

#if GPCamDebuger
    if(metaDatas.count > 0 && result.status == 2) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [BMWDetectDebugerView.sharedInstance showImage:result.data.firstObject.plateImage];
            [BMWDetectDebugerView.sharedInstance setColor:result.data.firstObject.type];
        });
    }
#endif

        return result;
}

- (void)start
{
    self.lastResult = nil;
    [self initAlgorithm];
#if GPCamDebuger
    dispatch_async(dispatch_get_main_queue(), ^{
        [BMWDetectDebugerView.sharedInstance start];
    });
#endif
}

- (void)stop
{
    [self destroyAlgorithm];
    self.lastResult = nil;
}

- (BMWVlprAlgorithmResult*)smooth:(BMWVlprAlgorithmResult*)result
{
    int currResultStatus = result.status;
    if (self.lastResult != nil) {
        if(self.lastResult.status != currResultStatus) {
            result.status = 0;
        } else if(currResultStatus > 0) {
            if(![self.lastResult.data.firstObject.formatCharacter isEqualToString:result.data.firstObject.formatCharacter]) {
                result.status = 0;
            }
        }
    } else {
        result.status = 0;
    }
    self.lastResult = [[BMWVlprAlgorithmResult alloc] init];
    self.lastResult.data = result.data;
    self.lastResult.status = currResultStatus;
    return result;
}

@end
#else
@implementation BMWVlprAlgorithm
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"vlpr";
}

- (void)start
{
}

- (void)stop
{
}

- (id<BMWVideoAlgorithmResultInterface>)process:(void (^)(BMWAlgorithmProcessProfile * profile))builder
{
    BMWVlprAlgorithmResult *result = [[BMWVlprAlgorithmResult alloc] init];
    return result;
}

@end
#endif
