#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT void BMWMLogD(NSString *tag, NSString *format, ...);
FOUNDATION_EXPORT void BMWMLogI(NSString *tag, NSString *format, ...);
FOUNDATION_EXPORT void BMWMLogE(NSString *tag, NSString *format, ...);
FOUNDATION_EXPORT void trace(NSString *event, NSDictionary *propertieDict);
FOUNDATION_EXPORT NSString* getPhotoInfoFromExif(NSString *url);
FOUNDATION_EXPORT void getFileFromGCDWeb(NSString *url);
FOUNDATION_EXPORT void requestModelDownload(NSString *modelName);

@interface GPCamRegistratorFuncs : NSObject

@property (nonatomic, copy) void (^logI)(NSString *msg);
@property (nonatomic, copy) void (^logD)(NSString *msg);
@property (nonatomic, copy) void (^logE)(NSString *msg);
@property (nonatomic, copy) void (^trace)(NSString *event, NSDictionary *propertieDict);
@property (nonatomic, copy) NSString* (^getPhotoInfoFromExif)(NSString *url);
@property (nonatomic, copy) void (^getFileFromGCDWeb)(NSString *url);
@property (nonatomic, copy) void (^requestModelDownload)(NSString *modelName);
@end

@interface GPCamRegistrator : NSObject

+ (GPCamRegistrator*)sharedInstance;

- (void)registryFunc:(void(^)(GPCamRegistratorFuncs *params))maker;

- (void)upadteRegistryFunc:(void(^)(GPCamRegistratorFuncs *params))maker;

@end

NS_ASSUME_NONNULL_END
