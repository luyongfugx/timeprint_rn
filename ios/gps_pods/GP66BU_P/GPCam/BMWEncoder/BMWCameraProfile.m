#import "BMWCameraProfile.h"
#import "BMWDeviceUtils.h"
#import "BMWCodeDataModel.h"
#import "GPCamConfigurator.h"
#import "BMWWatermarkItem.h"

@implementation BMWCameraKitData
@end

@implementation BMWCameraCapturedData

+ (BMWCameraCapturedData*)buildWithError:(NSError*)error immediate:(BOOL)immediate
{
    BMWCameraCapturedData *model = [[BMWCameraCapturedData alloc] init];
    model.immediate = immediate;
    model.error = error;
    model.time = kCMTimeInvalid;
    return model;
}

+ (BMWCameraCapturedData*)buildWithPixelBuffer:(CVPixelBufferRef)pixelBuffer mattePixelBuffer:(CVPixelBufferRef)mattePixelBuffer pipSampleBuffer:(CMSampleBufferRef)pipSampleBuffer time:(CMTime)time immediate:(BOOL)immediate
{
    BMWCameraCapturedData *model = [[BMWCameraCapturedData alloc] init];
    model.immediate = immediate;
    model.pixelBuffer = pixelBuffer;
    model.mattePixelBuffer = mattePixelBuffer;
    model.pipSampleBuffer = pipSampleBuffer;
    model.time = time;
    return model;
}

@end

@implementation BMWCameraKitSettingProfile
- (instancetype)init
{
    self = [super init];
    if(self) {
        self.cameraFrameFPS = GPCamConfigurator.sharedInstance.videoRecordFPS;
        self.useAudioUnit = GPCamConfigurator.sharedInstance.useAudioUnit;
        self.validRect = CGRectMake(0, 0, 1, 1);
        self.imageQuality = BMWImageResolutionQualityCurrent;
        self.enableLivePhoto = NO;
        self.enableDisplayFrontCameraInSubPreview = NO;
    }
    return self;
}
@end

@implementation BMWCameraSettingProfile
- (instancetype)init
{
    self = [super init];
    if(self) {
    }
    return self;
}
@end

@implementation BMWEncodeProfile

- (instancetype)init
{
    self = [super init];
    if(self) {
        if ([BMWDeviceUtils isLowerThaniPhone6]) {
            self.videoSize = CGSizeMake(720, 1280);
            self.bitrate = 2*1024.0*1024;
        } else {
            self.videoSize = CGSizeMake(1080, 1920);
            self.bitrate = 8*1024.0*1024;
        }
        self.enableRecordNoWatermarkVideo = NO;
        self.frameRate = 30.0f;
        self.shouldOptimizeForNetworkUse = YES;
        self.enableAudioRecord = YES;
        self.pixelFormat = kCVPixelFormatType_32BGRA;
        self.noWatermarkVideoMaxDuration = 120;
    }
    return self;
}

+ (BMWEncodeProfile*)defaultProfile
{
    BMWEncodeProfile *profile = [[BMWEncodeProfile alloc] init];
    return profile;
}

+ (NSDictionary*)videoColorProperties
{
    //AVVideoColorPropertiesKey
    NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
       AVVideoColorPrimaries_ITU_R_709_2, AVVideoColorPrimariesKey,
       AVVideoTransferFunction_ITU_R_709_2, AVVideoTransferFunctionKey,
       AVVideoYCbCrMatrix_ITU_R_709_2, AVVideoYCbCrMatrixKey, nil];
    return dic;
}

- (NSURL*)generateNoWatermarkVideoUrl:(NSURL *)originalURL
{
    NSString *originalFilePath = [originalURL path];
    NSString *fileName = [originalFilePath lastPathComponent];
    NSString *fileExtension = [originalFilePath pathExtension];
    
    NSString *newFileName = [@"nowatermark_record_" stringByAppendingString:[fileName stringByDeletingPathExtension]];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    
    NSString *cacheDirectory = [paths firstObject];
    
    NSString *dstDir = [NSString stringWithFormat:@"%@/XCameraCache/video/nowatermark", cacheDirectory];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dstDir]) {
        NSError *error;
        if (![[NSFileManager defaultManager] createDirectoryAtPath:dstDir withIntermediateDirectories:YES attributes:nil error:&error]) {
            BMWMLog(@"Create directory error: %@", error);
        }
    }
    
    NSString *newFilePath = [dstDir stringByAppendingPathComponent:[newFileName stringByAppendingPathExtension:fileExtension]];
    
    NSURL *newURL = [NSURL fileURLWithPath:newFilePath];
    
    return newURL;
}

@end


@implementation BMWVideoMetaData
- (instancetype)init:(BMWSliceDataModel*)sliceDataModel
{
    self = [super init];
    if(self) {
        self.sliceDataModel = sliceDataModel;
    }
    return self;
}
@end

@implementation BMWImageCaptureProfile

- (instancetype)init
{
    self = [super init];
    if(self) {
        self.quality = 0.8;
        self.snapshotImageQuality = -1.0;
        self.enableClarityOpt = YES;
        self.enableImageLabeling = NO;
        self.enableLivePhoto = NO;
        self.needConfirm = NO;
        self.shouldOptimizeElectronicScreenCapture = NO;
        self.enableImageQualityDetect = YES;
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    BMWImageCaptureProfile *data = [[BMWImageCaptureProfile allocWithZone:zone] init];
    data.quality = self.quality;
    data.watermarkModel = self.watermarkModel;
    data.orientaion = self.orientaion;
    data.mode = self.mode;
    data.metadata = self.metadata;
    data.codeDataModel = self.codeDataModel;
    data.blindWatermarkModel = self.blindWatermarkModel;
    data.enableSliceImage = self.enableSliceImage;
    data.enableClarityOpt = self.enableClarityOpt;
    data.enableImageLabeling = self.enableImageLabeling;
    data.enableShopSignRecognition = self.enableShopSignRecognition;
    data.statusCallBack = self.statusCallBack;
    data.previewImgCallBack = self.previewImgCallBack;
    data.originalImgCallBack = self.originalImgCallBack;
    data.processedImgCallBack = self.processedImgCallBack;
    data.enableLivePhoto = self.enableLivePhoto;
    data.livePhotoIdentifier = self.livePhotoIdentifier;
    data.pairedVideoMetadata = self.pairedVideoMetadata;
    data.pairedVideoFilePath = self.pairedVideoFilePath;
    data.watermarkList = [self.watermarkList copy];
    return data;
}
@end

@interface BMWImageCaptureMetaData ()

@property (nonatomic, strong) dispatch_semaphore_t previewSemaphore;

@property (nonatomic, strong) NSCondition *condition;
@property (nonatomic, assign) BOOL metaDataReady;

@end

@implementation BMWImageCaptureMetaData

- (instancetype)init
{
    self = [super init];
    if(self) {
        self.previewCapturedSimilarity = 1.0;
        self.previewClarity = -1;
        self.capturedClarity = -1;
        self.clarityOptStatus = 0;
        self.previewLuminance = -1;
        self.cameraImageClsLabel = @"";
        self.cameraImageEvaLabel = @"";
        self.cameraImageOCRText = @"";
        self.locationRect = BMWRectFull();
        self.condition = [[NSCondition alloc] init];
        self.metaDataReady = NO;
        self.previewSemaphore = dispatch_semaphore_create(0);
    }
    return self;
}

// 主要用来保证泉眼相关的算法数据ready
- (void)setMetaDataReady
{
    [self.condition lock];
    self.metaDataReady = YES;
    BMWMLog(@"setMetaDataReady： %@", self);
    [self.condition broadcast];
    [self.condition unlock];
}

- (BOOL)waitMetaDataReady:(CGFloat)timeout
{
    [self.condition lock];
    NSDate *timeoutDate = [NSDate dateWithTimeIntervalSinceNow:timeout];
    while (!self.metaDataReady) {
        // 如果超时则返回NO
        if (![self.condition waitUntilDate:timeoutDate]) {
            [self.condition unlock];
            BMWMLog(@"MetaData waitForReady timeout ...: %@", self);
            return NO;
        }
    }
    BMWMLog(@"MetaData waitForReady done, %@", self);
    [self.condition unlock];
    return YES;
}

- (void)setPreviewImageReady
{
    dispatch_semaphore_signal(self.previewSemaphore);
}

- (BOOL)waitPreviewImageReady:(CGFloat)time
{
    dispatch_time_t timeout = dispatch_time(DISPATCH_TIME_NOW, (uint64_t)(time * NSEC_PER_SEC));
    BOOL ret = (0 != dispatch_semaphore_wait(self.previewSemaphore, timeout));
    if(ret)  {
        BMWMLog(@"PreviewImage waitForReady timeout ...");
    }
    return ret;
}

- (NSArray<BMWRect *> *)filterImageClsResultWithLabel:(NSString *)label
{
    NSArray<BMWRectMetaData*>* labels = [self.cameraImageClsResult filterWithLabels:@[label]];
    if (labels.count <= 0) {
        return @[];
    }
    
    NSMutableArray<BMWRect *> *rects = [NSMutableArray array];
    for (BMWRectMetaData* label in labels) {
        BMWRect *rect = [[BMWRect alloc] init];
        rect.left = label.rect.origin.x;
        rect.top = label.rect.origin.y;
        rect.right = label.rect.origin.x + label.rect.size.width;
        rect.bottom = label.rect.origin.y + label.rect.size.height;
        rect.tag = BMWWatermarkTagElectronicScreen;
        [rects addObject:rect];
    }
    
    return rects;
}

@end

@implementation BMWAntiFraudDetectStatus

- (instancetype)init
{
    self = [super init];
    if(self) {
        self.enable = NO;
        self.processing = NO;
        self.maxCount = 5;
        self.index = 0;
    }
    return self;
}
@end

@implementation BMWAntiFraudReslut
@end
