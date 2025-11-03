#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMWAlgorithmModelManager : NSObject

+ (BMWAlgorithmModelManager*)sharedInstance;
@property (nonatomic, readonly) NSString* bundleDir;
@property (nonatomic, readonly) NSString* modelDir;
@property (nonatomic, readonly) NSString* vlprPath;
@property (nonatomic, readonly) NSString* faceDetectPath;
@property (nonatomic, readonly) NSString* ocrPath;
@property (nonatomic, readonly) NSString* ocrv3Path;
@property (nonatomic, readonly) NSString* steelPath;
@property (nonatomic, readonly) NSString* imageDetPath;

- (void)setModeDir:(NSString*)dir;

- (void)setVlprSubPath:(NSString *)vlprSubPath;

- (void)setFaceDetectSubPath:(NSString *)faceDetectSubPath;

- (void)setOcrSubPath:(NSString *)ocrSubPath;

- (void)setOcrv3SubPath:(NSString *)ocrv3SubPath;

- (void)setSteelSubPath:(NSString *)steelSubPath;

- (void)setImageDetSubPath:(NSString *)imageDetSubPath;

- (BOOL)isCloudModel:(NSString*)path;

@end

NS_ASSUME_NONNULL_END
