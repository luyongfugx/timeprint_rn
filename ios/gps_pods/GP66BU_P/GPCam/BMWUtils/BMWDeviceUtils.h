#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMWDeviceUtils : NSObject

+ (BMWDeviceUtils*)sharedInstance;

@property (nonatomic) CGSize deviceSize;
@property (nonatomic) CGFloat deviceRatio;

+ (BOOL)isIOS12orHigher;

+ (BOOL)isiPhone7Family;

+ (BOOL)isLowerThaniPhone6;

+ (BOOL)isLowerThaniPhone7;

+ (BOOL)isPhoneX;

+ (BOOL)isPhone13OrHigher;

+ (BOOL)isPhone11OrHigher;

+ (BOOL)isPhoneXOrHigher;

+ (BOOL)isPhone12;

+ (BOOL)isPhone13mini;

+ (double)availableMemoryMB;

+ (BOOL)supportMetalCNN;


+ (NSString *)machineModel;

@end

NS_ASSUME_NONNULL_END
