#import "BMWFaceDectectAlgorithm.h"
#import "BMWDeviceUtils.h"
#import "GPCamDefine.h"
#import "BMWBufferUtils.h"
#import <AVFoundation/AVFoundation.h>
#import "BMWVideoAlgorithmResult.h"
#if CVAlgorithmgEnable
#import "Centerface.h"
#import "BMWAlgorithmModelManager.h"

@interface BMWFaceDectectAlgorithm()
{
    std::shared_ptr<Centerface> faceDetector;
}
@property(nonatomic) BOOL algorithmInited;
@property(nonatomic) CGSize inputSize;
@end

@implementation BMWFaceDectectAlgorithm
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"face_dectect";
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
        self.inputSize = YES ? CGSizeMake(480, 640) : CGSizeMake(544, 736);
    }
    return self;
}

- (void)initAlgorithm
{
    if (self.algorithmInited) return;
    NSString *modelDir = BMWAlgorithmModelManager.sharedInstance.faceDetectPath;
#if 1
    const char* param_path = [[modelDir stringByAppendingPathComponent:@"face_detect-opt-fp16.param"] UTF8String];
    const char* bin_path = [[modelDir stringByAppendingPathComponent:@"face_detect-opt-fp16.bin"] UTF8String];
#else
    const char* param_path = [[modelDir stringByAppendingPathComponent:@"face_detect.param"] UTF8String];
    const char* bin_path = [[modelDir stringByAppendingPathComponent:@"face_detect.bin"] UTF8String];
#endif
    faceDetector.reset(new Centerface());
    faceDetector->init(param_path, bin_path);
    self.algorithmInited = YES;
}

- (void)destroyAlgorithm
{
    if (!self.algorithmInited) return;
    faceDetector.reset();
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
    std::vector<FaceInfo> face_info;
    int scaledW = self.inputSize.width;
    int scaledH = self.inputSize.height;
    if(width > height) {
        scaledW = self.inputSize.height;
        scaledH = self.inputSize.width;
    }
    faceDetector->detect(sample, face_info, scaledW, scaledH);

    BMWFaceDectectAlgorithmResult *result = [[BMWFaceDectectAlgorithmResult alloc] init];
    result.status = 0;
    NSMutableArray<BMWRectMetaData*>*metaDatas = [NSMutableArray new];
    CGRect rectTotal = CGRectZero;
    for (int i = 0; i < face_info.size(); i++) {
        FaceInfo info = face_info[i];
        CGFloat x = info.x1 / width;
        CGFloat y = info.y1 / height;
        CGFloat w = (info.x2 - info.x1) / width;
        CGFloat h = (info.y2 - info.y1) / height;
        BMWRectMetaData *metaData = [BMWRectMetaData new];
        metaData.score = info.score;
        metaData.orientation = profile.orient;
        CGFloat scale = 0.5; CGFloat offset = 0.8;
        CGFloat SCALE = h * scale;
        CGFloat OFFSET = h * scale * offset;
        CGFloat OFFSET2 = h * scale * (1 - offset);
        metaData.rectForImage = CGRectMake(x, y - OFFSET, w, h + SCALE);
        if (profile.orient == BMWDeviceOrientationPortait) {
            metaData.rect = CGRectMake(x, y - OFFSET, w, h + SCALE);
        } else if (profile.orient == BMWDeviceOrientationLeft) {
            metaData.rect = CGRectMake(1 - y - h - OFFSET2, x, h + SCALE, w);
        } else if (profile.orient == BMWDeviceOrientationRight) {
            metaData.rect = CGRectMake(y - OFFSET, 1 - x - w, h + SCALE, w);
        } else if (profile.orient == BMWDeviceOrientationDown) {
            metaData.rect = CGRectMake(1 - x - w, 1 - y - h - OFFSET2, w, h + SCALE);
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
@implementation BMWFaceDectectAlgorithm
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"face_dectect";
}

- (void)start
{
}

- (void)stop
{
}

- (id<BMWVideoAlgorithmResultInterface>)process:(void (^)(BMWAlgorithmProcessProfile * profile))builder
{
    BMWFaceDectectAlgorithmResult *result = [[BMWFaceDectectAlgorithmResult alloc] init];
    return result;
}

@end
#endif
