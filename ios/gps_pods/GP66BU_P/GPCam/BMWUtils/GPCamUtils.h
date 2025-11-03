#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GPCamUtils : NSObject

+ (NSString *)workDirPath;

+ (NSString *)filterWithRegex:(NSString*)pattern inputStr:(NSString*)inputStr;

@end

NS_ASSUME_NONNULL_END
