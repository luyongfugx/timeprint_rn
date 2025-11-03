#import "BMWDeviceUtils.h"

#import <sys/sysctl.h>
#include <mach/mach.h>

#define isPad          ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)

#define KIsiPhone_X    ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

#define KIsiPhone_XMax ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1242, 2688), [[UIScreen mainScreen] currentMode].size) : NO)

#define KIsiPhone_XS   ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(1125, 2436), [[UIScreen mainScreen] currentMode].size) : NO)

#define KIsiPhone_XR   ([UIScreen instancesRespondToSelector:@selector(currentMode)] ? CGSizeEqualToSize(CGSizeMake(828, 1792), [[UIScreen mainScreen] currentMode].size) && !isPad : NO)

@implementation BMWDeviceUtils

+ (BMWDeviceUtils*)sharedInstance
{
    static BMWDeviceUtils* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[BMWDeviceUtils alloc] init];
        }
    });
    return instance;
}

//base info
+ (NSString *)machineModel
{
    static NSString* machineModel;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        size_t size;
        sysctlbyname("hw.machine", NULL, &size, NULL, 0);
        char *machine = malloc(size);
        sysctlbyname("hw.machine", machine, &size, NULL, 0);
        machineModel = [NSString stringWithUTF8String:machine];
        free(machine);
    });
    
    return machineModel;
}

+ (NSString *)systemVersion
{
    static NSString* systemVersion;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        systemVersion = [[UIDevice currentDevice] systemVersion];
    });
    
    return systemVersion;
}

+ (BOOL)isiPhone7Family
{
    NSString *platformStr = [[self class] machineModel];
    if ([platformStr hasPrefix:@"iPhone9"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isLowerThaniPhone7
{
    return [[self class] isLowerThaniPhone6] || [[self class] isiPhone7Family];
}

+ (BOOL)isLowerThaniPhone6
{
    NSString *platformStr = [[self class] machineModel];
    
    if ([platformStr hasPrefix:@"iPhone8"] ||
        [platformStr hasPrefix:@"iPhone7"] ||
        [platformStr hasPrefix:@"iPhone6"] ||
        [platformStr hasPrefix:@"iPhone5"] ||
        [platformStr hasPrefix:@"iPad"]) {
        return YES;
    }
    return NO;
}

+ (BOOL)isPhoneX
{
    static BOOL isPhoneX = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *iphoneName = [self getDeviceName];

        if ([iphoneName hasPrefix:@"iPhone X"]) {
            isPhoneX = YES;
            return;
        }
        
        if ([iphoneName hasPrefix:@"iPhone 11"]) {
            isPhoneX = YES;
            return;
        }

        if (KIsiPhone_X || KIsiPhone_XMax) {
            isPhoneX = YES;
            return;
        }

        if (KIsiPhone_XR) {
            isPhoneX = YES;
            return;
        }

        isPhoneX = NO;
    });
    return isPhoneX;
}

+ (BOOL)isPhone13OrHigher
{
    static BOOL isPhone11OrHigher = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *iphoneName = [self getDeviceName];
        isPhone11OrHigher = [iphoneName hasPrefix:@"iPhone 13"] ||
                            [iphoneName hasPrefix:@"iPhone 14"] ||
                            [iphoneName hasPrefix:@"iPhone 15"] ||
                            [iphoneName hasPrefix:@"iPhone 16"];
    });
    return isPhone11OrHigher;
}

+ (BOOL)isPhone11OrHigher
{
    static BOOL isPhone11OrHigher = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *iphoneName = [self getDeviceName];
        isPhone11OrHigher = [iphoneName hasPrefix:@"iPhone 11"] ||
                            [iphoneName hasPrefix:@"iPhone 12"] ||
                            [iphoneName hasPrefix:@"iPhone 13"] ||
                            [iphoneName hasPrefix:@"iPhone 14"] ||
                            [iphoneName hasPrefix:@"iPhone 15"] ||
                            [iphoneName hasPrefix:@"iPhone 16"];
    });
    return isPhone11OrHigher;
}

+ (BOOL)isPhoneXOrHigher
{
    static BOOL isPhone11OrHigher = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *iphoneName = [self getDeviceName];
        isPhone11OrHigher = [iphoneName hasPrefix:@"iPhone X"] ||
                            [iphoneName hasPrefix:@"iPhone 11"] ||
                            [iphoneName hasPrefix:@"iPhone 12"] ||
                            [iphoneName hasPrefix:@"iPhone 13"] ||
                            [iphoneName hasPrefix:@"iPhone SE3"] ||
                            [iphoneName hasPrefix:@"iPhone 14"] ||
                            [iphoneName hasPrefix:@"iPhone 15"] ||
                            [iphoneName hasPrefix:@"iPhone 16"];
    });
    return isPhone11OrHigher;
}

+ (BOOL)isIOS12orHigher
{
    static BOOL iOS12orHigher;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        iOS12orHigher = [[[self class] systemVersion] compare:@"12.0" options:NSNumericSearch] != NSOrderedAscending;
    });
    return iOS12orHigher;
}

+ (BOOL)isPhone12
{
    static BOOL isPhone12 = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *iphoneName = [self getDeviceName];
        isPhone12 = [iphoneName hasPrefix:@"iPhone 12"];
    });
    return isPhone12;
}

+ (BOOL)isPhone13mini
{
    static BOOL isPhone13mini = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *iphoneName = [self getDeviceName];
        isPhone13mini = [iphoneName hasPrefix:@"iPhone 13 Mini"];
    });
    return isPhone13mini;
}


+ (BOOL)supportMetalCNN
{
    static BOOL hasMetalCNN = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *platformStr = [[self class] machineModel];
        if ([platformStr hasPrefix:@"iPhone3"] || [platformStr hasPrefix:@"iPhone4"] ||
            [platformStr hasPrefix:@"iPhone5"] || [platformStr hasPrefix:@"iPhone6"] ||
            [platformStr hasPrefix:@"iPhone7"] /*6*/||
            [platformStr hasPrefix:@"iPod"] ||
            [platformStr hasPrefix:@"iPad1"] || [platformStr hasPrefix:@"iPad2"] ||
            [platformStr hasPrefix:@"iPad3"] || [platformStr hasPrefix:@"iPad"] ) {
            hasMetalCNN = NO;
        } else {
            hasMetalCNN = [[[UIDevice currentDevice] systemVersion] floatValue] >= 10.0;
        }
    });
    return hasMetalCNN;
}

// ref:https://gist.github.com/adamawolf/3048717
+ (NSString *)getDeviceName
{
    NSString *deviceString = [[self class] machineModel];

    if ([deviceString isEqualToString:@"iPhone3,1"]) return @"iPhone 4";

    if ([deviceString isEqualToString:@"iPhone3,2"]) return @"iPhone 4";

    if ([deviceString isEqualToString:@"iPhone3,3"]) return @"iPhone 4";

    if ([deviceString isEqualToString:@"iPhone4,1"]) return @"iPhone 4S";

    if ([deviceString isEqualToString:@"iPhone5,1"]) return @"iPhone 5";

    if ([deviceString isEqualToString:@"iPhone5,2"]) return @"iPhone 5 (GSM+CDMA)";

    if ([deviceString isEqualToString:@"iPhone5,3"]) return @"iPhone 5c (GSM)";

    if ([deviceString isEqualToString:@"iPhone5,4"]) return @"iPhone 5c (GSM+CDMA)";

    if ([deviceString isEqualToString:@"iPhone6,1"]) return @"iPhone 5s (GSM)";

    if ([deviceString isEqualToString:@"iPhone6,2"]) return @"iPhone 5s (GSM+CDMA)";

    if ([deviceString isEqualToString:@"iPhone7,1"]) return @"iPhone 6 Plus";

    if ([deviceString isEqualToString:@"iPhone7,2"]) return @"iPhone 6";

    if ([deviceString isEqualToString:@"iPhone8,1"]) return @"iPhone 6s";

    if ([deviceString isEqualToString:@"iPhone8,2"]) return @"iPhone 6s Plus";

    if ([deviceString isEqualToString:@"iPhone8,4"]) return @"iPhone SE";

    if ([deviceString isEqualToString:@"iPhone9,1"]) return @"iPhone 7";

    if ([deviceString isEqualToString:@"iPhone9,2"]) return @"iPhone 7 Plus";

    if ([deviceString isEqualToString:@"iPhone10,1"] || [deviceString isEqualToString:@"iPhone10,4"]) return @"iPhone 8";

    if ([deviceString isEqualToString:@"iPhone10,2"] || [deviceString isEqualToString:@"iPhone10,5"]) return @"iPhone 8 Plus";

    if ([deviceString isEqualToString:@"iPhone10,3"] || [deviceString isEqualToString:@"iPhone10,6"]) return @"iPhone X";

    if ([deviceString isEqualToString:@"iPhone11,2"]) return @"iPhone XS";

    if ([deviceString isEqualToString:@"iPhone11,4"] || [deviceString isEqualToString:@"iPhone11,6"]) return @"iPhone XS Max";

    if ([deviceString isEqualToString:@"iPhone11,8"]) return @"iPhone XR";
    
    if ([deviceString isEqualToString:@"iPhone12,1"]) return @"iPhone 11";
    if ([deviceString isEqualToString:@"iPhone12,3"]) return @"iPhone 11 Pro";
    if ([deviceString isEqualToString:@"iPhone12,5"]) return @"iPhone 11 Pro Max";
    if ([deviceString isEqualToString:@"iPhone13,1"]) return @"iPhone 12 Mini";
    if ([deviceString isEqualToString:@"iPhone13,2"]) return @"iPhone 12";
    if ([deviceString isEqualToString:@"iPhone13,3"]) return @"iPhone 12 Pro";
    if ([deviceString isEqualToString:@"iPhone13,4"]) return @"iPhone 12 Max";
    if ([deviceString isEqualToString:@"iPhone14,2"]) return @"iPhone 13 Pro";
    if ([deviceString isEqualToString:@"iPhone14,3"]) return @"iPhone 13 Pro Max";
    if ([deviceString isEqualToString:@"iPhone14,4"]) return @"iPhone 13 Mini";
    if ([deviceString isEqualToString:@"iPhone14,5"]) return @"iPhone 13";
    if ([deviceString isEqualToString:@"iPhone14,6"]) return @"iPhone SE3";
    // iphone 14
    if ([deviceString isEqualToString:@"iPhone14,7"]) return @"iPhone 14";
    if ([deviceString isEqualToString:@"iPhone14,8"]) return @"iPhone 14 Plus";
    if ([deviceString isEqualToString:@"iPhone15,2"]) return @"iPhone 14 Pro";
    if ([deviceString isEqualToString:@"iPhone15,3"]) return @"iPhone 14 Pro Max";
    // iPhone15
    if ([deviceString isEqualToString:@"iPhone15,4"]) return @"iPhone 15";
    if ([deviceString isEqualToString:@"iPhone15,5"]) return @"iPhone 15 Plus";
    if ([deviceString isEqualToString:@"iPhone16,1"]) return @"iPhone 15 Pro";
    if ([deviceString isEqualToString:@"iPhone16,2"]) return @"iPhone 15 Pro Max";
    // iPhone16
    if ([deviceString isEqualToString:@"iPhone17,1"]) return @"iPhone 16 Pro";
    if ([deviceString isEqualToString:@"iPhone17,2"]) return @"iPhone 16 Pro Max";
    if ([deviceString isEqualToString:@"iPhone17,3"]) return @"iPhone 16";
    if ([deviceString isEqualToString:@"iPhone17,4"]) return @"iPhone 16 Plus";
    
    if ([deviceString isEqualToString:@"i386"] || [deviceString isEqualToString:@"x86_64"]) return @"Simulator";
    
    return @"";
}

static BOOL memoryInfo(vm_statistics_data_t *vmStats)
{
    mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
    kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)vmStats, &infoCount);
    return kernReturn == KERN_SUCCESS;
}

+ (double)availableMemoryMB
{
    vm_statistics_data_t vmStats;
    BOOL ret = memoryInfo(&vmStats);
    if (!ret) {
        return 0;
    }
    double size = (vm_page_size * vmStats.free_count) + (vmStats.inactive_count * vm_page_size);
    return size / 1024.0 / 1024.0;
}

- (void)setDeviceSize:(CGSize)deviceSize
{
    _deviceSize = deviceSize;
    _deviceRatio = deviceSize.width /  deviceSize.height;
}

@end
