#import "BMWCameraKit+Extra.h"
#import "BMWDeviceUtils.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "BMWMAudioPlayer.h"

const static NSString * VideoStabilizationDefault = @"video_stabilization_default";
const static NSString * HighResolutionStillImageDimensions = @"highResolutionStillImageDimensions";
static NSString * MutePhotoDefault = @"mutePhotoDefault";
static NSString * fastImageCaptureMode = @"fastImageCaptureMode";

@interface BMWCameraKit ()
@property (nonatomic, strong) BMWMAudioPlayer *shutterSoundPlayer;
@end

@implementation BMWCameraKit (Extra)

- (AVCaptureVideoStabilizationMode)getVideoStabilizationMode
{
    NSInteger stabilizationMode = [[NSUserDefaults standardUserDefaults] integerForKey:VideoStabilizationDefault];
    AVCaptureVideoStabilizationMode mode = AVCaptureVideoStabilizationModeOff;
    if (stabilizationMode == 1) {
        mode = AVCaptureVideoStabilizationModeOff;
    }
    if (stabilizationMode == 2) {
        mode = AVCaptureVideoStabilizationModeStandard;
    }
    if (stabilizationMode != 1 && stabilizationMode != 2) {
        stabilizationMode = 2;
        [[NSUserDefaults standardUserDefaults] setInteger:stabilizationMode forKey:VideoStabilizationDefault];
    }
    return mode;
}

- (void)configDefaultDimensions
{
    int width = self.inputCamera.activeFormat.highResolutionStillImageDimensions.width;
    int height = self.inputCamera.activeFormat.highResolutionStillImageDimensions.height;
    
    if (width >= BMWImageResolutionDefalut) {
        width = BMWImageResolutionDefalut;
    }
    
    if ([BMWDeviceUtils isLowerThaniPhone6]) {
        width = BMWImageResolutionDefalut_6;
    } else if ([BMWDeviceUtils isiPhone7Family]) {
        width = BMWImageResolutionDefalut_7;
    }
    [[NSUserDefaults standardUserDefaults] setObject:@(width) forKey:HighResolutionStillImageDimensions];
}

- (CGSize)calcResolution:(BMWDeviceOrientation)orientation quality:(BMWImageResolutionQuality)quality ratioMode:(BMWCameraKitMode)ratioMode clampByDevice:(BOOL)clamp
{
    int height = 0;
    switch (quality) {
        case BMWImageResolutionQualityLow:
            height = BMWImageResolutionLow;
            break;
        case BMWImageResolutionQualityMedium:
            height = BMWImageResolutionMedium;
            break;
        case BMWImageResolutionQualityHigh:
            height = BMWImageResolutionHigh;
            break;
        case BMWImageResolutionQualityBest:
            height = BMWImageResolutionBest;
            break;
        case BMWImageResolutionQualityCurrent:
        {
            height = BMWImageResolutionDefalut;
            if ([BMWDeviceUtils isLowerThaniPhone6]) {
                height = BMWImageResolutionDefalut_6;
            } else if([BMWDeviceUtils isiPhone7Family]) {
                height = BMWImageResolutionDefalut_7;
            }
        }
            break;
        default:
            height = BMWImageResolutionDefalut;
            break;
    }
            
    if (clamp) {
        if([BMWDeviceUtils isLowerThaniPhone6]) {
            height = BMWImageResolutionDefalut_6;
        } else if([BMWDeviceUtils isiPhone7Family]) {
            height = BMWImageResolutionDefalut_7;
        }
    }
    
    int outWidth = 0; int outHeight = 0;
    if (ratioMode == BMWCameraKitModePhoto4x3) {
        outWidth = SIZE_BY_RATIO(height, RATIO3x4);
        outHeight = height;
    } else if (ratioMode == BMWCameraKitModePhoto16x9) {
        outWidth = SIZE_BY_RATIO(height, RATIO9x16);
        outHeight = height;
    } else if (ratioMode == BMWCameraKitModePhoto1x1) {
        outWidth = height;
        outHeight = height;
    } else if (ratioMode == BMWCameraKitModePhotoFull) {
        outWidth = height * BMWDeviceUtils.sharedInstance.deviceRatio;
        outHeight = height;
    } else {
        NSAssert(NO, @"invalid image resolution, ratioMode:%d", ratioMode);
    }
    
    CGSize size;
    if (orientation == BMWDeviceOrientationDown ||
        orientation == BMWDeviceOrientationPortait) {
        size = CGSizeMake(outWidth, outHeight);
    } else {
        size = CGSizeMake(outHeight, outWidth);
    }
    BMWMLog(@"calcResolution:[%lf,%lf] orientation:%d quality:%d ratioMode:%d clampByDevice:%d", size.width, size.height, orientation, quality, ratioMode, clamp);
    return size;
}

- (BOOL)captureImageImmediateIfNeeded:(BMWTakePhotoImmediate)takePhotoImmediate
{
    BOOL immediate = NO;
    do {
        // 拍闪光灯「开或自动」走拍照
        if(self.flashMode != AVCaptureFlashModeOff || self.isNightEnhanceEnabled) {
            break;
        }
        if(self.settingProfile.cameraStartupOpt & BMWCameraStartupOptDefaultImmediateMode){
            immediate = YES;
            break;
        }
        // 人像分割需要走拍照
        if(self.settingProfile.portraitEffectsMatte) {
            break;
        }
        // immediate模式下没有拍照声音，故需要判断无拍照声音的case下才能使immediate模式
        NSInteger mutePhotoDefault = [[NSUserDefaults standardUserDefaults] integerForKey:MutePhotoDefault];
        BOOL mute = (mutePhotoDefault == 1 || mutePhotoDefault == 0);
        if(!mute) {
            break;
        }
        
        if(takePhotoImmediate == BMWTakePhotoImmediateNone) {
            immediate = NO;
        } else if(takePhotoImmediate == BMWTakePhotoImmediateForce) {
            immediate = YES;
        } else if(takePhotoImmediate == BMWTakePhotoImmediateSuggest) {
            if(self.imageQuality == BMWImageResolutionQualityLow || self.imageQuality == BMWImageResolutionQualityMedium) {
                immediate = YES;
            } else if(self.imageQuality == BMWImageResolutionQualityCurrent) {
                if ([BMWDeviceUtils isLowerThaniPhone6]) {
                    immediate = YES;
                }
            }
        }
    } while (NO);
    return immediate;
}

- (void)playShutterSound
{
    if(self.shutterSoundPlayer == nil) {
        NSString *bundlePath = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:@"CCameraLib.bundle"];
        NSString *shutterSoundPath = [bundlePath stringByAppendingPathComponent:@"mdj_takephoto_sound.mp3"];
        self.shutterSoundPlayer = [[BMWMAudioPlayer alloc] initWithFilePath:shutterSoundPath];
        self.shutterSoundPlayer.delegate = self;
        self.shutterSoundPlayer.volume = 0.1f;
    }
    
    NSError *sessionError = nil;
    [AVAudioSession.sharedInstance setCategory:AVAudioSessionCategoryPlayback error:&sessionError];
    if (sessionError) {
       return;
    }
    [AVAudioSession.sharedInstance setActive:YES error:&sessionError];
    if (sessionError) {
       return;
    }
    [self.shutterSoundPlayer play];
}

- (NSInteger)getMuteTakePhoto
{
    NSInteger v = [[NSUserDefaults standardUserDefaults] integerForKey:MutePhotoDefault];
    return v;
}

- (NSInteger)getFastImageCaptureMode
{
    NSInteger v = [[NSUserDefaults standardUserDefaults] integerForKey:fastImageCaptureMode];
    return v;
}

// hook capture iamge流程中结果返回，强制同步到图片捕获线程，默认为主线程
+ (void)load
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSData *a = [[NSData alloc] initWithBase64EncodedString:@"QVZXZWFrUmVmZXJlbmNpbmdEZWxlZ2F0ZVN0b3JhZ2U=" options:0];
        NSString *b = [[NSString alloc] initWithData:a encoding:NSUTF8StringEncoding];
        Class c1 = objc_getClass(b.UTF8String);
        Method origMethod = class_getInstanceMethod(c1, NSSelectorFromString(@"invokeDelegateCallbackWithBlock:"));
        class_addMethod(c1, NSSelectorFromString(@"xh_invokeDelegateCallbackWithBlock:"), method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
        Method swizzledMethod = class_getInstanceMethod(self, NSSelectorFromString(@"xh_invokeDelegateCallbackWithBlock:"));
        IMP origIMP = method_getImplementation(origMethod);
        method_exchangeImplementations(origMethod, swizzledMethod);
#if HACK_DISABLE_SHUTTER_SOUND
        [self disableShutterSound];
#endif
    });
}

- (void)xh_invokeDelegateCallbackWithBlock:(id)block
{
    if ([self valueForKey:@"_delegateQueue"] == dispatch_get_main_queue()) {
        [self setValue:[BMWCameraKit sharedImageCaptureQueue] forKey:@"_delegateQueue"];
    }
    [self xh_invokeDelegateCallbackWithBlock:block];
}

#if HACK_DISABLE_SHUTTER_SOUND
+ (void)disableShutterSound
{
    // -[AVCapturePhotoSettings shutterSound]
    NSData *a = [[NSData alloc] initWithBase64EncodedString:@"QVZDYXB0dXJlUGhvdG9TZXR0aW5ncw==" options:0];
    NSString *b = [[NSString alloc] initWithData:a encoding:NSUTF8StringEncoding];
    Class c1 = objc_getClass(b.UTF8String);
    Method origMethod = class_getInstanceMethod(c1, NSSelectorFromString(@"shutterSound"));
    class_addMethod(c1, NSSelectorFromString(@"xh_shutterSound"), method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    Method swizzledMethod = class_getInstanceMethod(self, NSSelectorFromString(@"xh_shutterSound"));
    IMP origIMP = method_getImplementation(origMethod);
    method_exchangeImplementations(origMethod, swizzledMethod);
}

- (int)xh_shutterSound
{
    dispatch_queue_t queue = dispatch_get_current_queue();
    char* label = dispatch_queue_get_label(queue);
    NSString *name = [NSString stringWithCString:label encoding:NSUTF8StringEncoding];
    BOOL isTriggerSound = [name isEqualToString:@"com.apple.coremedia.capturesession.notifications"];
    NSInteger mutePhotoDefault = [[NSUserDefaults standardUserDefaults] integerForKey:MutePhotoDefault];
    if ((mutePhotoDefault == 1 || mutePhotoDefault == 0) && isTriggerSound) {
        return 0;
    } else {
        return [self xh_shutterSound];
    }
}
#endif

#pragma mark - Getters & Setters

- (BMWMAudioPlayer *)shutterSoundPlayer {
    return objc_getAssociatedObject(self, @selector(shutterSoundPlayer));
}

- (void)setShutterSoundPlayer:(AVCaptureDevice *)shutterSoundPlayer {
    objc_setAssociatedObject(self, @selector(shutterSoundPlayer), shutterSoundPlayer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
