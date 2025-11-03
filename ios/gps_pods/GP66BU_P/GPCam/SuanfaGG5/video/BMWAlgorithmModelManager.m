#import "BMWAlgorithmModelManager.h"
#define CLOUD_MODEL 1
@interface BMWAlgorithmModelManager()

@property (nonatomic) NSString* bundleDir;
@property (nonatomic) NSString* ocrBundleDir;
@property (nonatomic) NSString* modelDir;
@property (nonatomic) NSString* vlprSubPath;
@property (nonatomic) NSString* faceDetectSubPath;
@property (nonatomic) NSString* ocrSubPath;
@property (nonatomic) NSString* ocrv3SubPath;
@property (nonatomic) NSString* steelSubPath;
@property (nonatomic) NSString* imageDetSubPath;
@property (nonatomic) BOOL vlprLocal;
@property (nonatomic) BOOL faceDetectLocal;
@property (nonatomic) BOOL ocrLocal;
@property (nonatomic) BOOL ocrv3Local;
@property (nonatomic) BOOL steelLocal;
@property (nonatomic) BOOL imageDetLocal;
@end
@implementation BMWAlgorithmModelManager

+ (BMWAlgorithmModelManager*)sharedInstance
{
    static BMWAlgorithmModelManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[BMWAlgorithmModelManager alloc] init];
        }
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.bundleDir = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:@"BMWAlgorithm.bundle"];
        _ocrBundleDir =  [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:@"BMWAlgorithm.bundle"];
        _vlprSubPath = @"lpr_models";
        _faceDetectSubPath = @"face_detect_models";
        _ocrSubPath = @"paddle_ocr";
        _ocrv3SubPath = @"pp-ocrv3";
        _steelSubPath = @"steel_detect_models";
        _imageDetSubPath = @"image_cls";
        _vlprLocal = YES;
        _faceDetectLocal = YES;
        _ocrLocal = YES;
        _steelLocal = YES;
        _ocrv3Local = YES;
        _imageDetLocal = YES;
    }
    return self;
}

- (void)setModeDir:(NSString *)dir
{
    if (dir.length) {
        _modelDir = dir;
    }
}

- (void)setVlprSubPath:(NSString *)vlprSubPath
{
    if (vlprSubPath.length) {
        _vlprSubPath = vlprSubPath;
        _vlprLocal = NO;
    }
}

- (void)setFaceDetectSubPath:(NSString *)faceDetectSubPath
{
    if (faceDetectSubPath.length > 0) {
        _faceDetectSubPath = faceDetectSubPath;
        _faceDetectLocal = NO;
    }
}

- (void)setOcrSubPath:(NSString *)ocrSubPath
{
    if (ocrSubPath.length) {
        _ocrSubPath = ocrSubPath;
        _ocrLocal = NO;
    }
}

- (void)setOcrv3SubPath:(NSString *)ocrv3SubPath;
{
    if (ocrv3SubPath.length) {
        _ocrv3SubPath = ocrv3SubPath;
        _ocrv3Local = NO;
    }
}

- (void)setSteelSubPath:(NSString *)steelSubPath
{
#if CLOUD_MODEL
    if (steelSubPath.length > 0) {
        _steelSubPath = steelSubPath;
        _steelLocal = NO;
    }
#endif
}

- (void)setImageDetSubPath:(NSString *)imageDetSubPath
{
    if (imageDetSubPath.length > 0) {
        _imageDetSubPath = imageDetSubPath;
        _imageDetLocal = NO;
    }
}

- (NSString *)vlprPath
{
    NSString *path = self.vlprSubPath;
    if (_vlprLocal) {
        path = [self.bundleDir stringByAppendingPathComponent:self.vlprSubPath];
    }
    return path;
}

- (NSString *)faceDetectPath
{
    NSString *path = self.faceDetectSubPath;
    if (_faceDetectLocal) {
        path = [self.bundleDir stringByAppendingPathComponent:self.faceDetectSubPath];
    }
    return path;
}

- (NSString *)ocrPath
{
    NSString *path = self.ocrSubPath;
    if (_ocrLocal) {
        path = [self.bundleDir stringByAppendingPathComponent:self.ocrSubPath];
    }
    return path;
}

- (NSString *)ocrv3Path
{
    NSString *path = self.ocrv3SubPath;
    if (_ocrv3Local) {
        path = [self.bundleDir stringByAppendingPathComponent:self.ocrv3SubPath];
    }
    return path;
}

- (NSString *)steelPath
{
    NSString *path = self.steelSubPath;
    if (_steelLocal) {
        path = [self.bundleDir stringByAppendingPathComponent:self.steelSubPath];
    }
    return path;
}

- (NSString *)imageDetPath
{
    NSString *path = self.imageDetSubPath;
    if (_imageDetLocal) {
        path = [self.bundleDir stringByAppendingPathComponent:self.imageDetSubPath];
    }
    return path;
}

- (BOOL)isCloudModel:(NSString*)path
{
    return ![path containsString:self.bundleDir];
}

@end
