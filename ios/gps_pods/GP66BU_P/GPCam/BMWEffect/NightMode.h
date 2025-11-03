#import <Foundation/Foundation.h>
#import <CoreML/CoreML.h>
#include <stdint.h>
#include <os/log.h>

NS_ASSUME_NONNULL_BEGIN


/// Model Prediction Input Type
API_AVAILABLE(macos(10.15), ios(13.0), watchos(6.0), tvos(13.0)) __attribute__((visibility("hidden")))
@interface NightModeInput : NSObject<MLFeatureProvider>

/// Image to input as color (kCVPixelFormatType_32BGRA) image buffer, 224 pixels wide by 224 pixels high
@property (readwrite, nonatomic) CVPixelBufferRef inputImage;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithInputImage:(CVPixelBufferRef)inputImage NS_DESIGNATED_INITIALIZER;

- (nullable instancetype)initWithInputImageFromCGImage:(CGImageRef)inputImage error:(NSError * _Nullable __autoreleasing * _Nullable)error;

- (nullable instancetype)initWithInputImageAtURL:(NSURL *)inputImageURL error:(NSError * _Nullable __autoreleasing * _Nullable)error;

-(BOOL)setInputImageWithCGImage:(CGImageRef)inputImage error:(NSError * _Nullable __autoreleasing * _Nullable)error ;
-(BOOL)setInputImageWithURL:(NSURL *)inputImageURL error:(NSError * _Nullable __autoreleasing * _Nullable)error ;
@end


/// Model Prediction Output Type
API_AVAILABLE(macos(10.15), ios(13.0), watchos(6.0), tvos(13.0)) __attribute__((visibility("hidden")))
@interface NightModeOutput : NSObject<MLFeatureProvider>

/// params for outputImage as color (kCVPixelFormatType_32BGRA) image buffer, 672 pixels wide by 672 pixels high
@property (readwrite, nonatomic) CVPixelBufferRef output;
- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithOutput:(CVPixelBufferRef)output NS_DESIGNATED_INITIALIZER;

@end


/// Class for model loading and prediction
API_AVAILABLE(macos(10.15), ios(13.0), watchos(6.0), tvos(13.0)) __attribute__((visibility("hidden")))
@interface NightMode : NSObject
@property (readonly, nonatomic, nullable) MLModel * model;

/**
    URL of the underlying .mlmodelc directory.
*/
+ (nullable NSURL *)URLOfModelInThisBundle;

/**
    Initialize NightMode instance from an existing MLModel object.

    Usually the application does not use this initializer unless it makes a subclass of NightMode.
    Such application may want to use `-[MLModel initWithContentsOfURL:configuration:error:]` and `+URLOfModelInThisBundle` to create a MLModel object to pass-in.
*/
- (instancetype)initWithMLModel:(MLModel *)model NS_DESIGNATED_INITIALIZER;

/**
    Initialize NightMode instance with the model in this bundle.
*/
- (nullable instancetype)init;

/**
    Initialize NightMode instance with the model in this bundle.

    @param configuration The model configuration object
    @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
*/
- (nullable instancetype)initWithConfiguration:(MLModelConfiguration *)configuration error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
    Initialize NightMode instance from the model URL.

    @param modelURL URL to the .mlmodelc directory for NightMode.
    @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
*/
- (nullable instancetype)initWithContentsOfURL:(NSURL *)modelURL error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
    Initialize NightMode instance from the model URL.

    @param modelURL URL to the .mlmodelc directory for NightMode.
    @param configuration The model configuration object
    @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
*/
- (nullable instancetype)initWithContentsOfURL:(NSURL *)modelURL configuration:(MLModelConfiguration *)configuration error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
    Construct NightMode instance asynchronously with configuration.
    Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

    @param configuration The model configuration
    @param handler When the model load completes successfully or unsuccessfully, the completion handler is invoked with a valid NightMode instance or NSError object.
*/
+ (void)loadWithConfiguration:(MLModelConfiguration *)configuration completionHandler:(void (^)(NightMode * _Nullable model, NSError * _Nullable error))handler API_AVAILABLE(macos(11.0), ios(14.0), watchos(7.0), tvos(14.0)) __attribute__((visibility("hidden")));

/**
    Construct NightMode instance asynchronously with URL of .mlmodelc directory and optional configuration.

    Model loading may take time when the model content is not immediately available (e.g. encrypted model). Use this factory method especially when the caller is on the main thread.

    @param modelURL The model URL.
    @param configuration The model configuration
    @param handler When the model load completes successfully or unsuccessfully, the completion handler is invoked with a valid NightMode instance or NSError object.
*/
+ (void)loadContentsOfURL:(NSURL *)modelURL configuration:(MLModelConfiguration *)configuration completionHandler:(void (^)(NightMode * _Nullable model, NSError * _Nullable error))handler API_AVAILABLE(macos(11.0), ios(14.0), watchos(7.0), tvos(14.0)) __attribute__((visibility("hidden")));

/**
    Make a prediction using the standard interface
    @param input an instance of NightModeInput to predict from
    @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
    @return the prediction as NightModeOutput
*/
- (nullable NightModeOutput *)predictionFromFeatures:(NightModeInput *)input error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
    Make a prediction using the standard interface
    @param input an instance of NightModeInput to predict from
    @param options prediction options
    @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
    @return the prediction as NightModeOutput
*/
- (nullable NightModeOutput *)predictionFromFeatures:(NightModeInput *)input options:(MLPredictionOptions *)options error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
    Make a prediction using the convenience interface
    @param inputImage Image to input as color (kCVPixelFormatType_32BGRA) image buffer, 224 pixels wide by 224 pixels high:
    @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
    @return the prediction as NightModeOutput
*/
- (nullable NightModeOutput *)predictionFromInputImage:(CVPixelBufferRef)inputImage error:(NSError * _Nullable __autoreleasing * _Nullable)error;

/**
    Batch prediction
    @param inputArray array of NightModeInput instances to obtain predictions from
    @param options prediction options
    @param error If an error occurs, upon return contains an NSError object that describes the problem. If you are not interested in possible errors, pass in NULL.
    @return the predictions as NSArray<NightModeOutput *>
*/
- (nullable NSArray<NightModeOutput *> *)predictionsFromInputs:(NSArray<NightModeInput*> *)inputArray options:(MLPredictionOptions *)options error:(NSError * _Nullable __autoreleasing * _Nullable)error;
@end

NS_ASSUME_NONNULL_END
