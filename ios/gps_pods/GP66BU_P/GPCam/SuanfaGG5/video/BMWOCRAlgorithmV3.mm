#if BMWOCR2AlgorithmEnable
#import "common.h"
#import "paddleocr.h"
#import "BMWOCRAlgorithmV3.h"
#import "BMWDeviceUtils.h"
#import "GPCamDefine.h"
#import "BMWBufferUtils.h"
#import <AVFoundation/AVFoundation.h>
#import "BMWVideoAlgorithmResult.h"
#import "BMWCodeHelper.h"
#import "BMWGLUtils.h"
#import "BMWAlgorithmModelManager.h"
#import "BMWSliceData.h"

extern UIImage* mat2Image(const ncnn::Mat& m);
extern UIImage* cvMat2Image(cv::Mat& cvMat);
using namespace paddleocr;

@interface BMWOCRAlgorithmV3()
{
    std::shared_ptr<PaddleOCR> predictor;
}
@property(nonatomic) BOOL algorithmInited;
@end

@implementation BMWOCRAlgorithmV3

@synthesize tag = _tag;

- (NSString*)tag
{
    return @"pp_ocrv3_ncnn";
}

- (void)dealloc
{
    }

- (instancetype)init
{
    if (self = [super init]) {
        self.boxLimit = 15;
    }
    return self;
}

- (void)initAlgorithm
{
    if (self.algorithmInited) return;
    NSString *modelDir = BMWAlgorithmModelManager.sharedInstance.ocrv3Path;
    const char* det_param_path = [[modelDir stringByAppendingPathComponent:@"ch_PP-OCRv3_det.param"] UTF8String];
    const char* det_bin_path = [[modelDir stringByAppendingPathComponent:@"ch_PP-OCRv3_det.bin"] UTF8String];
    const char* rec_param_path = [[modelDir stringByAppendingPathComponent:@"ch_PP-OCRv3_rec.param"] UTF8String];
    const char* rec_bin_path = [[modelDir stringByAppendingPathComponent:@"ch_PP-OCRv3_rec.bin"] UTF8String];
    NSString *labelPath = [modelDir stringByAppendingPathComponent:@"paddleocr_keys.txt"];

    predictor.reset(new PaddleOCR());

    predictor->init(det_param_path, det_bin_path, rec_param_path, rec_bin_path, [labelPath UTF8String], false);
    self.algorithmInited = YES;
}

- (void)destroyAlgorithm
{
    if (!self.algorithmInited) return;
    predictor.reset();
    self.algorithmInited = NO;
}

- (id<BMWVideoAlgorithmResultInterface>)process:(void (^)(BMWAlgorithmProcessProfile * profile))builder
{
    BMWAlgorithmProcessProfile *profile = [[BMWAlgorithmProcessProfile alloc] init];
    SafeBlock(builder, profile);
    CVPixelBufferRef pixelBuffer = profile.pixelBuffer;
    BMWRect *rectOfInterest = profile.rectOfInterest;
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    int bytesPerRow = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    const unsigned char* data = (GLubyte *)CVPixelBufferGetBaseAddress(pixelBuffer);
    ncnn::Mat origin = ncnn::Mat::from_pixels(data, ncnn::Mat::PIXEL_BGRA2RGB, width, height, bytesPerRow);
    std::vector<TextBox> textBoxs;

    int cropTop = rectOfInterest.top * height;
    int cropBottom = rectOfInterest.bottom * height;
    int cropLeft = rectOfInterest.left * width;
    int cropLight = rectOfInterest.right * width;
    if(!rectOfInterest.isNormOne) {
        ncnn::Mat originOfInterest;
        ncnn:copy_cut_border(origin, originOfInterest,
                             cropTop < 0 ? 0 : cropTop,
                             (height - cropBottom) < 0 ? 0 : (height - cropBottom),
                             cropLeft < 0 ? 0 : cropLeft,
                             (width - cropLight) < 0 ? 0 : (width - cropLight));
        origin = originOfInterest;
    }

    int boxLimit = self.boxLimit;
    const auto limit_box_block = [boxLimit] (std::vector<TextBox>& rawObjects) {
        std::vector<TextBox> objects;
        for (auto &obj: rawObjects) {
            // 过滤无效数据
            if (obj.boxPoint.size() < 4) {
                continue;
            }
            objects.emplace_back(obj);
        }
        rawObjects.clear();
        if (objects.size() < boxLimit) {
            rawObjects.insert(rawObjects.begin(), objects.begin(), objects.end());
        }
    };

    const auto max_box_block = [boxLimit] (std::vector<TextBox>& rawObjects) {
        std::vector<TextBox> objects;
        // 过滤无效数据
        for (auto &obj: rawObjects) {
            if (obj.boxPoint.size() < 4) {
                continue;
            }
            objects.emplace_back(obj);
        }
        std::sort(objects.begin(), objects.end(), [](TextBox lbox, TextBox rbox) {
            //倒序
            float lerea = BMWRectMake(MIN(lbox.boxPoint[0].x, lbox.boxPoint[3].x),
                                     MIN(lbox.boxPoint[0].y, lbox.boxPoint[1].y),
                                     MAX(lbox.boxPoint[1].x, lbox.boxPoint[2].x),
                                     MAX(lbox.boxPoint[2].y, lbox.boxPoint[3].y)).erea;
            float rerea = BMWRectMake(MIN(rbox.boxPoint[0].x, rbox.boxPoint[3].x),
                                     MIN(rbox.boxPoint[0].y, rbox.boxPoint[1].y),
                                     MAX(rbox.boxPoint[1].x, rbox.boxPoint[2].x),
                                     MAX(rbox.boxPoint[2].y, rbox.boxPoint[3].y)).erea;
            return lerea > rerea;
        });

        rawObjects.clear();
        if(objects.size() == 0) return;

        int count = MIN(boxLimit, objects.size());
        for (int idx = 0; idx < count; idx++) {
            rawObjects.emplace_back(objects[idx]);
        }
    };
    bool withImage = false;
#if GPCamDebuger
    withImage = true;
#endif
    if(self.justMaxBox == YES) {
        predictor->infer(origin, textBoxs, max_box_block, withImage);
    } else {
        predictor->infer(origin, textBoxs, limit_box_block, withImage);
        // 按照Y标排序
        std::sort(textBoxs.begin(), textBoxs.end(), [](TextBox l, TextBox r) {
            if (l.boxPoint.size() < 4 || r.boxPoint.size() < 4) {
                return false;
            }
            return l.boxPoint[0].y < r.boxPoint[0].y;
        });
    }
    NSMutableArray<BMWOCRMetaData*>*metaDatas = [[NSMutableArray alloc] init];
    for (int i = 0; i < textBoxs.size(); i++) {
        TextBox obj = textBoxs[i];
        if(obj.text == "") continue;
        BMWOCRMetaData *meta = [[BMWOCRMetaData alloc] init];
        meta.rawLabel = [NSString stringWithCString:obj.text.data() encoding:NSUTF8StringEncoding];
        meta.label = [meta.rawLabel copy];
        meta.score = obj.score != NAN ? obj.score : 1.0f;

        for (int idx = 0; idx < 4; idx++) {
            // 处理裁剪
            if(!rectOfInterest.isNormOne) {
                obj.boxPoint[idx].x += cropLeft;
                obj.boxPoint[idx].y += cropTop;
            }
        }

        meta.corners = BMWMakeCornersForList(@[
            @(obj.boxPoint[0].x), @(obj.boxPoint[0].y),
            @(obj.boxPoint[1].x), @(obj.boxPoint[1].y),
            @(obj.boxPoint[2].x), @(obj.boxPoint[2].y),
            @(obj.boxPoint[3].x), @(obj.boxPoint[3].y)]);
        // 归一化
        meta.corners = [meta.corners norm:CGSizeMake(width, height)];
        // 校准方向 & 校准镜像
        meta.corners = [meta.corners adjustWithOrient:profile.orient mirrorX:profile.isMirror];
        BMWRect *xhrect = [meta.corners xhrect];
        meta.rect = xhrect.CGrect;
        meta.angleScore = (ABS(meta.corners.point0.y - meta.corners.point3.y)/xhrect.height +
                           ABS(meta.corners.point1.y - meta.corners.point2.y)/xhrect.height) / 2.0;
#if GPCamDebuger
        if(!obj.image.empty()) {
            meta.image = cvMat2Image(obj.image);
        }
#endif
        [metaDatas addObject:meta];
    }
    BMWOCRAlgorithmResult *result = [[BMWOCRAlgorithmResult alloc] init];
    result.status = 0;

    if (metaDatas.count > 0) {
        result.status = 2;
        result.data = [metaDatas copy];
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
#import "BMWVideoAlgorithmResult.h"
#import "BMWOCRAlgorithmV3.h"
@implementation BMWOCRAlgorithmV3
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"pp_ocrv3_ncnn";
}

- (void)start
{
}

- (void)stop
{
}

- (id<BMWVideoAlgorithmResultInterface>)process:(void (^)(BMWAlgorithmProcessProfile * profile))builder
{
    BMWOCRAlgorithmResult *result = [[BMWOCRAlgorithmResult alloc] init];
    return result;
}

@end

#endif
