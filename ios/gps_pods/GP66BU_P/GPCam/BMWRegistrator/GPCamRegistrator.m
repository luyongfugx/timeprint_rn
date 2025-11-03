#import "GPCamRegistrator.h"
#import "GPCamDefine.h"
#import <pthread.h>

@implementation GPCamRegistratorFuncs
@end

@interface GPCamRegistrator ()

@property (nonatomic, strong) GPCamRegistratorFuncs *registratorFunc;

@end

@implementation GPCamRegistrator

+ (GPCamRegistrator*)sharedInstance
{
    static GPCamRegistrator* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[GPCamRegistrator alloc] init];
            [instance registryFunc:^(GPCamRegistratorFuncs * _Nonnull params) {
                params.logI = ^(NSString * _Nonnull msg) {
                    NSLog(@"%@", msg);
                };
                params.logD = ^(NSString * _Nonnull msg) {
                    NSLog(@"%@", msg);
                };
                params.logE = ^(NSString * _Nonnull msg) {
                    NSLog(@"%@", msg);
                };
                params.trace = ^(NSString * _Nonnull event, NSDictionary * _Nonnull propertieDict) {
                    BMWMLogI(@"GPCamTrace", @"event:%@ propertie:%@", event, propertieDict);
                };
            }];
        }
    });
    return instance;
}

- (void)registryFunc:(void(^)(GPCamRegistratorFuncs *params))maker
{
    GPCamRegistratorFuncs *registratorFunc = [[GPCamRegistratorFuncs alloc] init];
    SafeBlock(maker, registratorFunc);
    self.registratorFunc = registratorFunc;
}

- (void)upadteRegistryFunc:(void(^)(GPCamRegistratorFuncs *params))maker
{
    SafeBlock(maker, self.registratorFunc);
}

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

@end

void BMWMLogD(NSString *tag, NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    message = [NSString stringWithFormat:@"[%@] %@",tag, message];
    SafeBlock(GPCamRegistrator.sharedInstance.registratorFunc.logD, message);
}

void BMWMLogI(NSString *tag, NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    uint64_t threadId = 0;
    pthread_threadid_np(NULL, &threadId);
    message = [NSString stringWithFormat:@"[%llu][%d][%@] %@", threadId, [NSThread isMainThread], tag, message];
    SafeBlock(GPCamRegistrator.sharedInstance.registratorFunc.logI, message);
}

void BMWMLogE(NSString *tag, NSString *format, ...)
{
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    message = [NSString stringWithFormat:@"[%@] %@",tag, message];
    SafeBlock(GPCamRegistrator.sharedInstance.registratorFunc.logE, message);
}

void trace(NSString *event, NSDictionary *propertieDict)
{
    if (event.length == 0) {
        return;
    }
    if(propertieDict == nil) {
        propertieDict = @{};
    }
    BMWMLogI(@"GPCamTrace", @"event:%@ propertie:%@", event, propertieDict);
    SafeBlock(GPCamRegistrator.sharedInstance.registratorFunc.trace, event, propertieDict);
}

NSString* getPhotoInfoFromExif(NSString *url)
{
    if (url.length == 0) {
        return nil;
    }
    if (GPCamRegistrator.sharedInstance.registratorFunc.getPhotoInfoFromExif == nil) {
        return nil;
    }
    return GPCamRegistrator.sharedInstance.registratorFunc.getPhotoInfoFromExif(url);
}

void getFileFromGCDWeb(NSString *url)
{
    if(GPCamRegistrator.sharedInstance.registratorFunc.getFileFromGCDWeb) {
        GPCamRegistrator.sharedInstance.registratorFunc.getFileFromGCDWeb(url);
    }
}

void requestModelDownload(NSString *modelName)
{
    if(GPCamRegistrator.sharedInstance.registratorFunc.requestModelDownload) {
        GPCamRegistrator.sharedInstance.registratorFunc.requestModelDownload(modelName);
    }
}
