#import "BMWErrorHelper.h"

@implementation BMWErrorHelper

+ (NSError*)cameraInitErrorDomain:(NSError*)error code:(NSUInteger)code
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (error.userInfo) {
        [userInfo addEntriesFromDictionary:error.userInfo];
    }
    
    NSError *newError = [NSError errorWithDomain:BMWCameraInitErrorDomain
                                            code:code
                                        userInfo:userInfo];
    return newError;
}

+ (NSError*)antiCodeErrorDomain:(NSError* _Nullable)error code:(NSUInteger)code msg:(NSString*)msg;
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (error.userInfo) {
        [userInfo addEntriesFromDictionary:error.userInfo];
    }
    userInfo[@"message"] = msg;
    NSError *newError = [NSError errorWithDomain:BMWAntiCodeErrorDomain
                                            code:code
                                        userInfo:userInfo];
    return newError;
}


+ (NSError*)certificateErrorDomain:(NSError* _Nullable)error code:(NSUInteger)code toast:(NSString*)toast
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (error.userInfo) {
        [userInfo addEntriesFromDictionary:error.userInfo];
    }
    userInfo[@"toast"] = toast;
    NSError *newError = [NSError errorWithDomain:BMWCertificateErrorDomain
                                            code:code
                                        userInfo:userInfo];
    return newError;
}

+ (NSError*)codeDetectErrorDomain:(NSError* _Nullable)error code:(NSUInteger)code toast:(NSString*)toast;
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    if (error.userInfo) {
        [userInfo addEntriesFromDictionary:error.userInfo];
    }
    userInfo[@"toast"] = toast;
    NSError *newError = [NSError errorWithDomain:BMWCodeDetectErrorDomain
                                            code:code
                                        userInfo:userInfo];
    return newError;
}

@end
