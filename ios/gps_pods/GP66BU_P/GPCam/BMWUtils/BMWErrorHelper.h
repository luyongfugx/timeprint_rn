#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const BMWCameraInitErrorDomain = @"com.cad.camera.init.error";

typedef NS_ENUM(NSInteger, BMWCameraInitError) {
    BMWCameraInitErrorDevicesNotAvailable = -1000,
    BMWCameraInitErrorDeviceInputInitError = -1001,
    BMWCameraInitErrorAddVideoOutputError = -1002,
    BMWCameraInitErrorAddImageOutputError = -1003,
    BMWCameraInitErrorInterruptionAudioDeviceInUseByAnotherClient = -1004,
    BMWCameraInitErrorInterruptionVideoDeviceInUseByAnotherClient = -1005,
    BMWCameraInitErrorInterruptionVideoDeviceNotAvailableWithMultipleForegroundApps = -1006,
    BMWCameraInitErrorInterruptionVideoDeviceNotAvailableDueToSystemPressure = -1007,
    BMWCameraInitErrorMultiCameraNotSupported = -1008,
    BMWCameraInitErrorMultiCameraFrontDevicesNotAvailable = -1009,
    BMWCameraInitErrorCameraFrontDeviceInputInit = -1010,
    BMWCameraInitErrorCameraNotRunning = -1011,
};

static NSString * const BMWAntiCodeErrorDomain = @"com.cad.anti.code.error";

typedef NS_ENUM(NSInteger, BMWAntiCodeError) {
    // 接口请求无效的参数
    BMWAntiCodeErrorDomainAntiCodeInvalidParameter = -2100,
    
    // 防伪码提取失败
    BMWAntiCodeErrorDomainBWMFail = -2200,
    
    // OCR相关错误
    BMWAntiCodeErrorDomainOCRDetectInitError = -2300,
    BMWAntiCodeErrorDomainOCRDetectNull = -2301,
    BMWAntiCodeErrorDomainOCRDetectPreProcessError  = -2302,
    BMWAntiCodeErrorDomainOCRDetectLenError = -2303,
    
    // 防伪码有效性检查
    BMWAntiCodeErrorDomainInvalidCode = -2400,          // 防伪码内部检查，时间范围无效或地点范围无效
    BMWAntiCodeErrorDomainInvalidStimetamp = -2401,     // 防伪码外部检查，时间戳无效
    BMWAntiCodeErrorDomainInvalidLocation = -2402,      // 防伪码外部检查，地点无效
    
    // 防伪码检测到作弊
    BMWAntiCodeErrorDomainCodeCheat = -2403,
    
    BMWAntiCodeErrorDomainBusy = -2500
};

static NSString * const BMWCertificateErrorDomain = @"com.cad.certificate.code.error";
typedef NS_ENUM(NSInteger, BMWCertificateError) {
    // tips:人脸裁切过程中失败, toast:检测失败，请重试
    BMWCertificateErrorCrop = -1012,
    // tips:未检测到人脸, toast:未检测到人脸
    BMWCertificateErrorNoFace = -1010,
    // tips:检测到多个人脸, toast:检测到多个人脸
    BMWCertificateErrorMoreFace = -1011
};


static NSString * const BMWCodeDetectErrorDomain = @"com.cad.code.detect.error";
typedef NS_ENUM(NSInteger, BMWCodeDetectError) {
    BMWCodeDetectErrorBarCode = -1000,
    BMWCodeDetectErrorLP = -2000,
    BMWCodeDetectErrorOCR = -3000,
};

@interface BMWErrorHelper : NSObject

+ (NSError*)cameraInitErrorDomain:(NSError* _Nullable)error code:(NSUInteger)code;

+ (NSError*)antiCodeErrorDomain:(NSError* _Nullable)error code:(NSUInteger)code msg:(NSString*)msg;

+ (NSError*)certificateErrorDomain:(NSError* _Nullable)error code:(NSUInteger)code toast:(NSString*)toast;

+ (NSError*)codeDetectErrorDomain:(NSError* _Nullable)error code:(NSUInteger)code toast:(NSString*)toast;
@end

NS_ASSUME_NONNULL_END
