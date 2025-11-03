#import "NightMode.h"

@implementation NightModeInput

- (instancetype)initWithInputImage:(CVPixelBufferRef)inputImage {
    self = [super init];
    if (self) {
        _inputImage = inputImage;
        CVPixelBufferRetain(_inputImage);
    }
    return self;
}

- (void)dealloc {
    CVPixelBufferRelease(_inputImage);
}

- (nullable instancetype)initWithInputImageFromCGImage:(CGImageRef)inputImage error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    if (self) {
        NSError *localError;
        BOOL result = YES;
        id retVal = nil;
        @autoreleasepool {
            do {
                MLFeatureValue * __inputImage = [MLFeatureValue featureValueWithCGImage:inputImage pixelsWide:224 pixelsHigh:224 pixelFormatType:kCVPixelFormatType_32BGRA options:nil error:&localError];
                if (__inputImage == nil) {
                    result = NO;
                    break;
                }
                retVal = [self initWithInputImage:(CVPixelBufferRef)__inputImage.imageBufferValue];
            }
            while(0);
        }
        if (error != NULL) {
            *error = localError;
        }
        return result ? retVal : nil;
    }
    return self;
}

- (nullable instancetype)initWithInputImageAtURL:(NSURL *)inputImageURL error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    if (self) {
        NSError *localError;
        BOOL result = YES;
        id retVal = nil;
        @autoreleasepool {
            do {
                MLFeatureValue * __inputImage = [MLFeatureValue featureValueWithImageAtURL:inputImageURL pixelsWide:224 pixelsHigh:224 pixelFormatType:kCVPixelFormatType_32BGRA options:nil error:&localError];
                if (__inputImage == nil) {
                    result = NO;
                    break;
                }
                retVal = [self initWithInputImage:(CVPixelBufferRef)__inputImage.imageBufferValue];
            }
            while(0);
        }
        if (error != NULL) {
            *error = localError;
        }
        return result ? retVal : nil;
    }
    return self;
}

-(BOOL)setInputImageWithCGImage:(CGImageRef)inputImage error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NSError *localError;
    BOOL result = NO;
    @autoreleasepool {
        MLFeatureValue * __inputImage = [MLFeatureValue featureValueWithCGImage:inputImage pixelsWide:224 pixelsHigh:224 pixelFormatType:kCVPixelFormatType_32BGRA options:nil error:&localError];
        if (__inputImage != nil) {
            CVPixelBufferRelease(_inputImage);
            _inputImage =  (CVPixelBufferRef)__inputImage.imageBufferValue;
            CVPixelBufferRetain(_inputImage);
            result = YES;
        }
    }
    if (error != NULL) {
        *error = localError;
    }
    return result;
}

-(BOOL)setInputImageWithURL:(NSURL *)inputImageURL error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NSError *localError;
    BOOL result = NO;
    @autoreleasepool {
        MLFeatureValue * __inputImage = [MLFeatureValue featureValueWithImageAtURL:inputImageURL pixelsWide:224 pixelsHigh:224 pixelFormatType:kCVPixelFormatType_32BGRA options:nil error:&localError];
        if (__inputImage != nil) {
            CVPixelBufferRelease(_inputImage);
            _inputImage =  (CVPixelBufferRef)__inputImage.imageBufferValue;
            CVPixelBufferRetain(_inputImage);
            result = YES;
        }
    }
    if (error != NULL) {
        *error = localError;
    }
    return result;
}

- (NSSet<NSString *> *)featureNames {
    return [NSSet setWithArray:@[@"inputImage"]];
}

- (nullable MLFeatureValue *)featureValueForName:(NSString *)featureName {
    if ([featureName isEqualToString:@"inputImage"]) {
        return [MLFeatureValue featureValueWithPixelBuffer:_inputImage];
    }
    return nil;
}

@end

@implementation NightModeOutput

- (instancetype)initWithOutput:(CVPixelBufferRef)output {
    self = [super init];
    if (self) {
        _output = output;
        CVPixelBufferRetain(_output);
    }
    return self;
}

- (void)dealloc {
    CVPixelBufferRelease(_output);
}

- (NSSet<NSString *> *)featureNames {
    return [NSSet setWithArray:@[@"output"]];
}

- (nullable MLFeatureValue *)featureValueForName:(NSString *)featureName {
    if ([featureName isEqualToString:@"output"]) {
        return [MLFeatureValue featureValueWithPixelBuffer:_output];
    }
    return nil;
}

@end

@implementation NightMode


/**
    URL of the underlying .mlmodelc directory.
*/
+ (nullable NSURL *)URLOfModelInThisBundle {
//    NSString *assetPath = [[NSBundle bundleForClass:[self class]] pathForResource:@"NightMode" ofType:@"mlmodelc"];
    NSString* assetPath = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:@"CCameraLib.bundle/DsdN_Mo.mlmodelc"];
    if (nil == assetPath) { os_log_error(OS_LOG_DEFAULT, "Could not load DsdN_Mo.mlmodelc in the bundle resource"); return nil; }
    return [NSURL fileURLWithPath:assetPath];
}


/**
    Initialize NightMode instance from an existing MLModel object.

    Usually the application does not use this initializer unless it makes a subclass of NightMode.
    Such application may want to use `-[MLModel initWithContentsOfURL:configuration:error:]` and `+URLOfModelInThisBundle` to create a MLModel object to pass-in.
*/
- (instancetype)initWithMLModel:(MLModel *)model {
    self = [super init];
    if (!self) { return nil; }
    _model = model;
    if (_model == nil) { return nil; }
    return self;
}


/**
    Initialize NightMode instance with the model in this bundle.
*/
- (nullable instancetype)init {
    return [self initWithContentsOfURL:self.class.URLOfModelInThisBundle error:nil];
}


/**
    Initialize NightMode instance with the model in this bundle.

    @param configuration The model configuration object
    @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
*/
- (nullable instancetype)initWithConfiguration:(MLModelConfiguration *)configuration error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return [self initWithContentsOfURL:self.class.URLOfModelInThisBundle configuration:configuration error:error];
}


/**
    Initialize NightMode instance from the model URL.

    @param modelURL URL to the .mlmodelc directory for NightMode.
    @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
*/
- (nullable instancetype)initWithContentsOfURL:(NSURL *)modelURL error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    MLModel *model = [MLModel modelWithContentsOfURL:modelURL error:error];
    if (model == nil) { return nil; }
    return [self initWithMLModel:model];
}


/**
    Initialize NightMode instance from the model URL.

    @param modelURL URL to the .mlmodelc directory for NightMode.
    @param configuration The model configuration object
    @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
*/
- (nullable instancetype)initWithContentsOfURL:(NSURL *)modelURL configuration:(MLModelConfiguration *)configuration error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    MLModel *model = [MLModel modelWithContentsOfURL:modelURL configuration:configuration error:error];
    if (model == nil) { return nil; }
    return [self initWithMLModel:model];
}


/**
    Construct NightMode instance asynchronously with configuration.
    Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

    @param configuration The model configuration
    @param handler When the model load completes successfully or unsuccessfully, the completion handler is invoked with a valid NightMode instance or NSError object.
*/
+ (void)loadWithConfiguration:(MLModelConfiguration *)configuration completionHandler:(void (^)(NightMode * _Nullable model, NSError * _Nullable error))handler {
    [self loadContentsOfURL:[self URLOfModelInThisBundle]
              configuration:configuration
          completionHandler:handler];
}


/**
    Construct NightMode instance asynchronously with URL of .mlmodelc directory and optional configuration.

    Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

    @param modelURL The model URL.
    @param configuration The model configuration
    @param handler When the model load completes successfully or unsuccessfully, the completion handler is invoked with a valid NightMode instance or NSError object.
*/
+ (void)loadContentsOfURL:(NSURL *)modelURL configuration:(MLModelConfiguration *)configuration completionHandler:(void (^)(NightMode * _Nullable model, NSError * _Nullable error))handler {
    [MLModel loadContentsOfURL:modelURL
                 configuration:configuration
             completionHandler:^(MLModel *model, NSError *error) {
        if (model != nil) {
            NightMode *typedModel = [[NightMode alloc] initWithMLModel:model];
            handler(typedModel, nil);
        } else {
            handler(nil, error);
        }
    }];
}

- (nullable NightModeOutput *)predictionFromFeatures:(NightModeInput *)input error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    return [self predictionFromFeatures:input options:[[MLPredictionOptions alloc] init] error:error];
}

- (nullable NightModeOutput *)predictionFromFeatures:(NightModeInput *)input options:(MLPredictionOptions *)options error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    id<MLFeatureProvider> outFeatures = [_model predictionFromFeatures:input options:options error:error];
    return [[NightModeOutput alloc] initWithOutput:(CVPixelBufferRef)[outFeatures featureValueForName:@"output"].imageBufferValue];
}

- (nullable NightModeOutput *)predictionFromInputImage:(CVPixelBufferRef)inputImage error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    NightModeInput *input_ = [[NightModeInput alloc] initWithInputImage:inputImage];
    return [self predictionFromFeatures:input_ error:error];
}

- (nullable NSArray<NightModeOutput *> *)predictionsFromInputs:(NSArray<NightModeInput*> *)inputArray options:(MLPredictionOptions *)options error:(NSError * _Nullable __autoreleasing * _Nullable)error {
    id<MLBatchProvider> inBatch = [[MLArrayBatchProvider alloc] initWithFeatureProviderArray:inputArray];
    id<MLBatchProvider> outBatch = [_model predictionsFromBatch:inBatch options:options error:error];
    NSMutableArray<NightModeOutput*> *results = [NSMutableArray arrayWithCapacity:(NSUInteger)outBatch.count];
    for (NSInteger i = 0; i < outBatch.count; i++) {
        id<MLFeatureProvider> resultProvider = [outBatch featuresAtIndex:i];
        NightModeOutput * result = [[NightModeOutput alloc] initWithOutput:(CVPixelBufferRef)[resultProvider featureValueForName:@"output"].imageBufferValue];
        [results addObject:result];
    }
    return results;
}

@end
