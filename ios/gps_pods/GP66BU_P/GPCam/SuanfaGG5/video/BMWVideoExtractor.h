#import <Foundation/Foundation.h>
#import "BMWVideoAlgorithmInterface.h"
#import "BMWVideoAlgorithmResult.h"
#import "BMWVideoAlgorithmSourceInterface.h"
#import "BMWVlprAlgorithm.h"
#import "BMWFaceDectectAlgorithm.h"
#import "BMWSteelDectectAlgorithm.h"
#import "BMWOCRAlgorithm.h"
#import "BMWImageClsAlgorithm.h"
#import "BMWBarcodeAlgorithm.h"
#import "BMWFaceAttributeAlgorithm.h"

NS_ASSUME_NONNULL_BEGIN

// userInfo : @{ @"vplr" : BMWVideoAlgorithmResult}
FOUNDATION_EXPORT NSNotificationName _Nonnull const BMWVlprResultNotification;

// userInfo : @{ @"face_dectect" : BMWFaceDectectAlgorithmResult}
FOUNDATION_EXPORT NSNotificationName _Nonnull const BMWFaceDectectResultNotification;

// userInfo : @{ @"face_attribute" : BMWFaceAttributeAlgorithmResult}
FOUNDATION_EXPORT NSNotificationName _Nonnull const BMWFaceAttributeResultNotification;

// userInfo : @{ @"steel_dectect" : BMWSteelDectectAlgorithmResult}
FOUNDATION_EXPORT NSNotificationName _Nonnull const BMWSteelDectectResultNotification;

// userInfo : @{ @"pp_ocr" : BMWOCRAlgorithmResult}
FOUNDATION_EXPORT NSNotificationName _Nonnull const BMWOCRResultNotification;

// userInfo : @{ @"image_cls" : BMWImageClsAlgorithmResult}
FOUNDATION_EXPORT NSNotificationName _Nonnull const BMWImageClsResultNotification;

// userInfo : @{ @"image_det" : BMWImageClsAlgorithmResult}
FOUNDATION_EXPORT NSNotificationName _Nonnull const BMWImageDetResultNotification;

// userInfo : @{ @"shop_sign_rec" : BMWOCRAlgorithmResult}
FOUNDATION_EXPORT NSNotificationName _Nonnull const BMWShopSignRecResultNotification;

// userInfo : @{ @"barcode" : BMWCodeAlgorithmResult}
FOUNDATION_EXPORT NSNotificationName _Nonnull const BMWBarcodeResultNotification;

@interface BMWVideoExtractor : NSObject

@property(assign) CFTimeInterval refreshInterval;

// 触发一次检测后自动调用stopDetect
@property(assign) BOOL autoStop;

+ (BMWVideoExtractor*)vlprExtractor;

+ (BMWVideoExtractor*)faceDectectExtractor;

+ (BMWVideoExtractor*)steelDectectExtractor;

+ (BMWVideoExtractor*)ocrExtractor;

+ (BMWVideoExtractor*)imageClsExtractor;

+ (BMWVideoExtractor*)barcodeExtractor;

+ (BMWVideoExtractor*)FaceAttributeExtractor;

+ (BMWVideoExtractor*)extractor;

- (void)registerAlgorithm:(id<BMWVideoAlgorithmInterface>)algorithm;

- (void)setSource:(nullable id<BMWVideoAlgorithmSourceInterface>)source;

- (void)startDetect;

- (void)stopDetect;

@end

NS_ASSUME_NONNULL_END
