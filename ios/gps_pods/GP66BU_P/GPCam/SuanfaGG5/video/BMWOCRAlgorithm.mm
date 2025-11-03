#if BMWOCR2AlgorithmEnable
#import "common.h"
#import "paddleocr.h"
#include <opencv2/opencv.hpp>
#import "BMWOCRAlgorithm.h"
#import "BMWDeviceUtils.h"
#import "GPCamDefine.h"
#import "BMWBufferUtils.h"
#import <AVFoundation/AVFoundation.h>
#import "BMWVideoAlgorithmResult.h"
#import "BMWCodeHelper.h"
#import "BMWGLUtils.h"
#import "BMWAlgorithmModelManager.h"

extern UIImage* mat2Image(const ncnn::Mat& m);
using namespace paddleocr;

@interface BMWOCRAlgorithm()
{
    std::shared_ptr<PaddleOCR> predictor;
}
@property(nonatomic) NSArray *labels;
@property(nonatomic) BOOL algorithmInited;
@property(nonatomic) CGSize inputSize;
@property(nonatomic) NSDictionary<NSString*, NSString*> *characterMaping;
@property(nonatomic) NSArray<NSString*> *illegalCharacterArray;
@end

@implementation BMWOCRAlgorithm

@synthesize tag = _tag;

- (NSString*)tag
{
    return @"pp_ocr";
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

        self.characterMaping = @{
            @"O" : @"D",
            @"0" : @"D",
            @"Q" : @"D",
            @"k" : @"K",
            @"8" : @"B",
            @"b" : @"B",
            @"Z" : @"2",
            @"7" : @"2",
            @"i" : @"1",
            @"I" : @"1",
            @"j" : @"1",
            @"J" : @"1",
            @"s" : @"6",
            @"F" : @"E",
            @"V" : @"U",
            @"×" : @"X"
        };
        self.illegalCharacterArray = @[@"0", @"5", @"7", @"8", @"F", @"I", @"J", @"O", @"Q", @"S", @"V", @"Z"];
        self.justRec = YES;
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
    self.labels = [self readLabelsFromFile:labelPath];
    predictor.reset(new PaddleOCR());
    predictor->init("", "", rec_param_path, rec_bin_path, [labelPath UTF8String]);
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
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    int bytesPerRow = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    const unsigned char* data = (GLubyte *)CVPixelBufferGetBaseAddress(pixelBuffer);
    ncnn::Mat origin = ncnn::Mat::from_pixels(data, ncnn::Mat::PIXEL_BGRA2RGB, width, height, bytesPerRow);

#if 0
    ncnn::Mat crop_img;
    int top = box_t[0][1] < 0 ? 0 : box_t[0][1];
    int bottom = (origin.h - box_t[2][1]) < 0 ? 0 : (origin.h - box_t[2][1]);
    int left = box_t[0][0] < 0 ? 0 : box_t[0][0];
    int right = (origin.w - box_t[2][0]) < 0 ? 0 : (origin.w - box_t[2][0]);
    ncnn:copy_cut_border(origin, crop_img, top, bottom, left, right);
    UIImage *corpImage = mat2Image(crop_img);
#endif

    std::vector<TextBox> textBoxs;
    if(self.justRec) {
        predictor->inferCrnn(origin, textBoxs);
    } else {
        predictor->infer(origin, textBoxs, nullptr);
    }
    NSMutableArray<BMWOCRMetaData*>*metaDatas = [[NSMutableArray alloc] init];
    for (int i = 0; i < textBoxs.size(); i++) {
        NSMutableString *rawText = [[NSMutableString alloc] init];
        NSMutableString *text = [[NSMutableString alloc] init];
        TextBox obj = textBoxs[i];
        for (int j = 0; j < obj.wordIndexs.size(); j++) {
            int wordIndex = obj.wordIndexs[j];
            NSString *one = nil;
            if (wordIndex >= 0 && wordIndex < self.labels.count) {
                one = self.labels[wordIndex];
            } else {
                continue;
            }
            [rawText appendString:one];
            // 容易混淆字母替换
            NSString *mapping = self.characterMaping[one];
            NSString *mod = mapping ? mapping : one;
            // 转化为大写
            NSString *upper = mod.uppercaseString;
            [text appendString:upper];
        }
        text = [text stringByReplacingOccurrencesOfString:@"." withString:@""];
        BMWOCRMetaData *meta = [[BMWOCRMetaData alloc] init];
        meta.label = text;
        meta.rawLabel = rawText;
        meta.score = obj.score;
        meta.image = [BMWBufferUtils genImageFromPixelBuffer:pixelBuffer];

        for (NSString *ch in self.illegalCharacterArray) {
            if ([rawText containsString:ch]) {
                meta.containIllegalWord = YES;
                break;
            }
        }
        CGRect rect = [BMWCodeHelper.sharedInstance codeRect:width/height isCode:YES];
        meta.rect = rect;
        [metaDatas addObject:meta];
    }
    BMWOCRAlgorithmResult *result = [[BMWOCRAlgorithmResult alloc] init];
    result.status = 0;

    if (metaDatas.count > 0) {
        result.status = 2;
        result.data = [metaDatas copy];
    } else {
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

- (NSArray *)readLabelsFromFile:(NSString *)labelFilePath
{
    NSString *content = [NSString stringWithContentsOfFile:labelFilePath encoding:NSUTF8StringEncoding error:nil];
    NSArray *lines = [content componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *ret = [[NSMutableArray alloc] init];
    for (int i = 0; i < lines.count; ++i) {
        [ret addObject:@""];
    }
    NSUInteger cnt = 0;
    for (id line in lines) {
        NSString *l = [(NSString *) line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([l length] == 0)
            continue;
        NSArray *segs = [l componentsSeparatedByString:@":"];
        NSUInteger key;
        NSString *value;
        if ([segs count] != 2) {
            key = cnt;
            value = [segs[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        } else {
            key = [[segs[0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] integerValue];
            value = [segs[1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }

        ret[key] = value;
        cnt += 1;
    }
    return [NSArray arrayWithArray:ret];
}

@end
#else
#import "BMWVideoAlgorithmResult.h"
#import "BMWOCRAlgorithm.h"
@implementation BMWOCRAlgorithm

@synthesize tag = _tag;

- (NSString*)tag
{
    return @"pp_ocr";
}

- (void)start
{
}

- (void)stop
{
}

- (id<BMWVideoAlgorithmResultInterface>)process:(void (^)(BMWAlgorithmProcessProfile * profile))builder
{
    BMWAlgorithmProcessProfile *profile = [[BMWAlgorithmProcessProfile alloc] init];
    SafeBlock(builder, profile);
    CVPixelBufferRef pixelBuffer = profile.pixelBuffer;
    BMWOCRAlgorithmResult *result = [[BMWOCRAlgorithmResult alloc] init];
    return result;
}

@end

#endif
