#import "GPCamUtils.h"

@implementation GPCamUtils

+ (NSString *)workDirPath
{
    NSString *cachePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"MediaSDK"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cachePath
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:nil];
    }
    return cachePath;
}

+ (NSString *)filterWithRegex:(NSString*)pattern inputStr:(NSString*)inputStr
{
    if (inputStr.length == 0) return inputStr;
    NSError *error = nil;
    NSString *filterdStr = [inputStr copy];
    do {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
        if (error) {
            BMWMLog(@"error creating regex: %@", error.localizedDescription);
            break;
        }
        NSRange range = NSMakeRange(0, inputStr.length);
        NSString *matched = nil;
        NSArray<NSTextCheckingResult *>*matchArray = [regex matchesInString:inputStr options:0 range:range];
        for (NSTextCheckingResult *match in matchArray) {
            matched = [inputStr substringWithRange:match.range];
            filterdStr = [filterdStr stringByReplacingOccurrencesOfString:matched withString:@""];
        }
    } while (0);
    
    return filterdStr;
}

@end
