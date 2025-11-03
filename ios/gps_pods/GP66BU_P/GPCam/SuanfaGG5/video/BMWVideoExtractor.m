#import "BMWVideoExtractor.h"
#import "BMWAudioKit.h"
#import "BMWMediaAuthorization.h"
#import "BMWCamera.h"

NSNotificationName const BMWVlprResultNotification = @"BMWVlprResultNotification";
NSNotificationName const BMWFaceDectectResultNotification = @"BMWFaceDectectResultNotification";
NSNotificationName const BMWFaceAttributeResultNotification = @"BMWFaceAttributeResultNotification";
NSNotificationName const BMWSteelDectectResultNotification = @"BMWSteelDectectResultNotification";
NSNotificationName const BMWOCRResultNotification = @"BMWOCRResultNotification";
NSNotificationName const BMWImageClsResultNotification = @"BMWImageClsResultNotification";
NSNotificationName const BMWImageDetResultNotification = @"BMWImageDetResultNotification";
NSNotificationName const BMWShopSignRecResultNotification = @"BMWShopSignRecResultNotification";
NSNotificationName const BMWBarcodeResultNotification = @"BMWBarcodeResultNotification";

@interface BMWVideoExtractor () <BMWVideoProcessDelegate>
{
    dispatch_queue_t operationQueue;
    void *BMWVideoExtractorQueueKey;
}

@property (assign) BOOL running;
@property (strong) NSMutableDictionary<NSString*, id<BMWVideoAlgorithmSourceInterface>>* algorithmDic;
@property (assign) CFTimeInterval lastTimestamp;
@property (assign) BOOL isProcessingFrame;

@property (nonatomic, strong) id<BMWVideoAlgorithmSourceInterface> source;

@end

@implementation BMWVideoExtractor

- (void)setSource:(id<BMWVideoAlgorithmSourceInterface>)source
{
    _source = source;
    _lastTimestamp = -1;
}

- (void)dealloc
{
    [self.source removeDelegate:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        BMWVideoExtractorQueueKey = &BMWVideoExtractorQueueKey;
        operationQueue = dispatch_queue_create("CAD.VideoExtractor", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(operationQueue, BMWVideoExtractorQueueKey, (__bridge void *) (self), NULL);
        self.lastTimestamp = -1;
        self.algorithmDic = NSMutableDictionary.new;
    }
    return self;
}

+ (BMWVideoExtractor*)vlprExtractor;
{
    BMWVideoExtractor *extractor = [BMWVideoExtractor new];
    BMWVlprAlgorithm *algorithm = [BMWVlprAlgorithm new];
    [extractor registerAlgorithm:algorithm];
    return extractor;
}

+ (BMWVideoExtractor*)faceDectectExtractor
{
    BMWVideoExtractor *extractor = [BMWVideoExtractor new];
    BMWFaceDectectAlgorithm *algorithm = [BMWFaceDectectAlgorithm new];
    [extractor registerAlgorithm:algorithm];
    return extractor;
}

+ (BMWVideoExtractor*)FaceAttributeExtractor
{
    BMWVideoExtractor *extractor = [BMWVideoExtractor new];
    BMWFaceAttributeAlgorithm *algorithm = [BMWFaceAttributeAlgorithm new];
    [extractor registerAlgorithm:algorithm];
    return extractor;
}

+ (BMWVideoExtractor*)steelDectectExtractor
{
    BMWVideoExtractor *extractor = [BMWVideoExtractor new];
    BMWSteelDectectAlgorithm *algorithm = [BMWSteelDectectAlgorithm new];
    [extractor registerAlgorithm:algorithm];
    return extractor;
}

+ (BMWVideoExtractor*)ocrExtractor
{
    BMWVideoExtractor *extractor = [BMWVideoExtractor new];
    BMWOCRAlgorithm *algorithm = [BMWOCRAlgorithm new];
    [extractor registerAlgorithm:algorithm];
    return extractor;
}

+ (BMWVideoExtractor*)imageClsExtractor
{
    BMWVideoExtractor *extractor = [BMWVideoExtractor new];
    BMWImageClsAlgorithm *algorithm = [BMWImageClsAlgorithm new];
    [extractor registerAlgorithm:algorithm];
    return extractor;
}

+ (BMWVideoExtractor*)barcodeExtractor
{
    BMWVideoExtractor *extractor = [BMWVideoExtractor new];
    BMWBarcodeAlgorithm *algorithm = [BMWBarcodeAlgorithm new];
    [extractor registerAlgorithm:algorithm];
    return extractor;
}

+ (BMWVideoExtractor*)extractor
{
    BMWVideoExtractor *extractor = [BMWVideoExtractor new];
    return extractor;
}

- (void)registerAlgorithm:(id<BMWVideoAlgorithmInterface>)algorithm
{
    [self runAsyncInOperationQueue:^{
        NSString *key = [algorithm tag];
        self.algorithmDic[key] = (id<BMWVideoAlgorithmInterface>)algorithm;
    }];
}

- (void)startDetect
{
    if(!self.running) {
        self.running = YES;
        self.isProcessingFrame = NO;
        [self.source addDelegate:self];
        [self.source pull];
        [self runAsyncInOperationQueue:^{
            for (id<BMWVideoAlgorithmInterface> a in self.algorithmDic.allValues) {
                if([a isKindOfClass:[BMWBarcodeAlgorithm class]]) {
                    if([self.source.tag isEqualToString:@"CameraSource"]) {
                                                [[(BMWCamera*)self.source cameraEntry] addMetadataOutput:BMWCaptureMetadataTypeBarCode];
                    }
                }
                [a start];
                            }
        }];
    }
}

- (void)stopDetect
{
    if(self.running) {
        self.running = NO;
        self.isProcessingFrame = NO;
        self.lastTimestamp = -1;
        [self.source removeDelegate:self];
        [self runAsyncInOperationQueue:^{
            for (id<BMWVideoAlgorithmInterface> a in self.algorithmDic.allValues) {
                if([a isKindOfClass:[BMWBarcodeAlgorithm class]]) {
                    if([self.source.tag isEqualToString:@"CameraSource"]) {
                        [[(BMWCamera*)self.source cameraEntry] removeMetadataOutput];
                    }
                }
                [a stop];
                            }
        }];
    }
}

- (void)resetTimestamp
{
    self.lastTimestamp = -1;
}

- (BOOL)shouldTrigger:(double)timestamp
{
    Float64 currTimestamp = timestamp;
    if (currTimestamp < 0) {
        currTimestamp = CACurrentMediaTime();
    }
    if(self.lastTimestamp > 0 &&
       currTimestamp - self.lastTimestamp < self.refreshInterval) {
        return NO;
    }
    self.lastTimestamp = currTimestamp;
    return YES;
}

- (void)processWithbuilder:(void (^)(BMWAlgorithmProcessProfile * profile))builder
{
    BMWAlgorithmProcessProfile *profile = [[BMWAlgorithmProcessProfile alloc] init];
    SafeBlock(builder, profile);

    CVPixelBufferRef pixelBuffer = profile.pixelBuffer;
    BOOL sync = profile.sync;
    if (self.isProcessingFrame && sync == NO && pixelBuffer == NULL) {
        return;
    }
    CFRetain(pixelBuffer);
    [self runInOperationQueue:^{
        self.isProcessingFrame = YES;
        for (id<BMWVideoAlgorithmInterface> a in self.algorithmDic.allValues) {
            double bg = CACurrentMediaTime();
            id<BMWVideoAlgorithmResultInterface> result = nil;
            if([a respondsToSelector:@selector(process:)]) {
                result = [a process:^(BMWAlgorithmProcessProfile * _Nonnull processProfile) {
                    processProfile.pixelBuffer = profile.pixelBuffer;
                    processProfile.metadataObjects = profile.metadataObjects;
                    processProfile.rectOfInterest = profile.rectOfInterest;
                    processProfile.isMirror = profile.isMirror;
                    processProfile.orient = profile.orient;
                    processProfile.enableSmooth = profile.enableSmooth;
                    processProfile.sync = profile.sync;
                }];
                NSString *notificationName = nil;
                if ([result isKindOfClass:[BMWVlprAlgorithmResult class]]) {
                    notificationName = BMWVlprResultNotification;
                    if ([self.source.tag isEqualToString:@"ImageSource"] && !result.isValid) {
                        bool ret = [self.source retry];
                        if (ret) {
                            CFRelease(pixelBuffer);
                            self.isProcessingFrame = NO;
                            double end = CACurrentMediaTime();
                                                        return;
                        }
                    }
                } else if ([result isKindOfClass:[BMWFaceDectectAlgorithmResult class]]) {
                    notificationName = BMWFaceDectectResultNotification;
                } else if ([result isKindOfClass:[BMWSteelDectectAlgorithmResult class]]) {
                    notificationName = BMWSteelDectectResultNotification;
                } else if ([result isKindOfClass:[BMWOCRAlgorithmResult class]]) {
                    if([(BMWOCRAlgorithmResult*)result isShopSign]) {
                        notificationName = BMWShopSignRecResultNotification;
                    } else {
                        notificationName = BMWOCRResultNotification;
                    }
                } else if ([result isKindOfClass:[BMWImageClsAlgorithmResult class]]) {
                    if([(BMWImageClsAlgorithmResult*)result isClassification]) {
                        notificationName = BMWImageClsResultNotification;
                    } else {
                        notificationName = BMWImageDetResultNotification;
                    }
                } else if ([result isKindOfClass:[BMWCodeAlgorithmResult class]]) {
                    notificationName = BMWBarcodeResultNotification;
                }
                result.source = _source.tag;
                [self _postPtsNotification:result tag:a.tag notificationName:notificationName];
            }
            double end = CACurrentMediaTime();
//            BMWMLog(@"BMWVideoExtractor[%@,%x] %@ process:%@ timecost:%lf", result.source, self, a.tag, result, 1000 * (end - bg));
        }
        CFRelease(pixelBuffer);
        self.isProcessingFrame = NO;
        if(self.autoStop) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self stopDetect];
            });
        }
    } sync:sync];
}

-(NSString *)id
{
    return [NSString stringWithFormat:@"%x", self];
}

- (void)_postPtsNotification:(id)result tag:(NSString*)tag notificationName:(NSString*)notificationName
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userInfo = @{tag : result};
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:userInfo];
    });
}

- (void)runInOperationQueue:(dispatch_block_t)block sync:(BOOL)sync
{
    if (sync) {
        [self runSyncInOperationQueue:block];
    } else {
        [self runAsyncInOperationQueue:block];
    }
}

- (void)runSyncInOperationQueue:(dispatch_block_t)block
{
    if (dispatch_get_specific(BMWVideoExtractorQueueKey)) {
        block();
    } else {
        dispatch_sync(operationQueue, block);
    }
}

- (void)runAsyncInOperationQueue:(dispatch_block_t)block
{
    dispatch_async(operationQueue, block);
}

@end
