#import "BMWMediaAuthorization.h"
#import <AVFoundation/AVFoundation.h>

@implementation BMWMediaAuthorization

+ (BOOL)isCameraAuthorized
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    return status == AVAuthorizationStatusAuthorized;
}

+ (BOOL)isMicrophoneAuthorized
{
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    return status == AVAuthorizationStatusAuthorized;
}

+ (void)cameraAuthorizationRequest:(HLACameraAuthorziedBlock)authorizedBlock
{
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        if (authStatus == AVAuthorizationStatusNotDetermined) {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    authorizedBlock ? authorizedBlock(granted) : nil;
                });
            }];
        } else if (authStatus == AVAuthorizationStatusAuthorized) {
            dispatch_async(dispatch_get_main_queue(), ^{
                authorizedBlock ? authorizedBlock(YES) : nil;
            });
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                authorizedBlock ? authorizedBlock(NO) : nil;
            });
        }
}

+ (void)microphoneAuthorizationRequest:(HLACameraAuthorziedBlock)authorizedBlock
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    if ([audioSession respondsToSelector:@selector(requestRecordPermission:)]) {
        __weak typeof(audioSession) weakSession = audioSession;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            __strong typeof(weakSession) strongSession = weakSession;
            if (strongSession) {
                [strongSession requestRecordPermission:^(BOOL granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        authorizedBlock ? authorizedBlock(granted) : nil;
                    });
                }];
            }
        });
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            authorizedBlock ? authorizedBlock(YES) : nil;
        });
    }
}

+ (BOOL)isMicrophoneAvailable
{
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    
    if (!([audioSession.category isEqualToString:AVAudioSessionCategoryPlayAndRecord] && (audioSession.categoryOptions & AVAudioSessionCategoryOptionDefaultToSpeaker) &&
          (audioSession.categoryOptions & AVAudioSessionCategoryOptionDuckOthers) && (audioSession.categoryOptions & AVAudioSessionCategoryOptionAllowBluetooth))) {
        if (![audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                           withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionDuckOthers | AVAudioSessionCategoryOptionAllowBluetooth
                                 error:nil]) {
            return NO;
        }
        if (![audioSession setActive:YES error:nil]) {
            return NO;
        }
    }
    
    return YES;
}

@end
