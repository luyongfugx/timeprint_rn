#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^ HLACameraAuthorziedBlock) (BOOL authorzied);

@interface BMWMediaAuthorization : NSObject

+ (BOOL)isCameraAuthorized;

+ (BOOL)isMicrophoneAuthorized;

+ (void)cameraAuthorizationRequest:(HLACameraAuthorziedBlock)authorizedBlock;

+ (void)microphoneAuthorizationRequest:(HLACameraAuthorziedBlock)authorizedBlock;

+ (BOOL)isMicrophoneAvailable;

@end

NS_ASSUME_NONNULL_END
