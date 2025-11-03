#import "BMWCameraKit+Flash.h"
#import <objc/runtime.h>
#import <Foundation/Foundation.h>

static NSString * const kAdjustingFocusKey = @"adjustingFocus";
static NSString * const kAdjustingExposureKey = @"adjustingExposure";

@interface BMWCameraKit ()

@property (nonatomic, strong) AVCaptureDevice *currentDevice;

@property (nonatomic, copy) CaptureFlashCompletion simulateCaptureFlashCompletion;

@property (nonatomic, assign) AVCaptureTorchMode currentTorchMode;

@end

@implementation BMWCameraKit (Flash)

#pragma mark - Public Methods

- (void)onCameraClosed:(AVCaptureDevice *)device {
    [self unobserveDevice:device];
    self.currentDevice = nil;
}

- (void)onCameraOpened:(AVCaptureDevice *)device {
    [self unobserveDevice:device];
    [device addObserver:self
             forKeyPath:kAdjustingFocusKey
                options:NSKeyValueObservingOptionNew
                context:nil];
    [device addObserver:self
             forKeyPath:kAdjustingExposureKey
                options:NSKeyValueObservingOptionNew
                context:nil];
    self.currentDevice = device;
}

- (void)simulateCaptureFlashWithCompletion:(CaptureFlashCompletion)completion {
    @xhm_weakify(self);
    [self runAsyncOnOperationQueue:^{
        @xhm_strongify(self);
        
        self.simulateCaptureFlashCompletion = nil;

        if (!self.currentDevice ||
            self.currentDevice.flashMode == AVCaptureFlashModeOff ||
            self.currentDevice.torchMode == AVCaptureTorchModeOn) {
            SafeBlock(completion, NO);
            return;
        }
        
        self.currentTorchMode = self.currentDevice.torchMode;
        
        [self configureDeviceTorch:AVCaptureTorchModeOn];
        [self runAsyncOnOperationQueue:^{
            self.simulateCaptureFlashCompletion = completion;
            [self tryFinishCaptureFlash];
        } delay:0.25];
        
        // 超时强制关闭
        [self runAsyncOnOperationQueue:^{
            if (!self.simulateCaptureFlashCompletion) {
                return;
            }

            BMWMLog(@"simulateCaptureFlash timeout");
            SafeBlock(self.simulateCaptureFlashCompletion, YES);
            self.simulateCaptureFlashCompletion = nil;
            [self configureDeviceTorch:self.currentTorchMode];
        } delay:1.0];
    }];
}

#pragma mark - Private Methods

- (void)onAutoFocusDone {
    BMWMLog(@"%s %d", __FUNCTION__, __LINE__);
    [self tryFinishCaptureFlash];
}

- (void)onAutoExposureDone {
    BMWMLog(@"%s %d", __FUNCTION__, __LINE__);
    [self tryFinishCaptureFlash];
}

- (void)tryFinishCaptureFlash {
    [self runAsyncOnOperationQueue:^{
        if (!self.simulateCaptureFlashCompletion) {
            return;
        }
        
        if (!self.currentDevice.adjustingFocus &&
            !self.currentDevice.adjustingExposure) {
            SafeBlock(self.simulateCaptureFlashCompletion, YES);
            BMWMLog(@"simulateCaptureFlash success");
            self.simulateCaptureFlashCompletion = nil;
            [self runAsyncOnOperationQueue:^{
                [self configureDeviceTorch:self.currentTorchMode];
            } delay:0.25];
        }
    }];
}

- (void)unobserveDevice:(AVCaptureDevice *)device {
    @try {
        [self.currentDevice removeObserver:self forKeyPath:kAdjustingFocusKey];
        [self.currentDevice removeObserver:self forKeyPath:kAdjustingExposureKey];
    } @catch (NSException *exception) {
//        BMWMLog(@"unobserveDevice exception:%@", exception);
    }
    @try {
        [device removeObserver:self forKeyPath:kAdjustingFocusKey];
        [device removeObserver:self forKeyPath:kAdjustingExposureKey];
    } @catch (NSException *exception) {
//        BMWMLog(@"unobserveDevice exception:%@", exception);
    }
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    [self runAsyncOnOperationQueue:^{
        if (object != self.currentDevice) {
            return;
        }
        
        if ([keyPath isEqualToString:kAdjustingFocusKey]) {
            BOOL isAdjustingFocus = [change[NSKeyValueChangeNewKey] boolValue];
            if (!isAdjustingFocus) {
                [self onAutoFocusDone];
            }
        } else if ([keyPath isEqualToString:kAdjustingExposureKey]) {
            BOOL isAdjustingExposure = [change[NSKeyValueChangeNewKey] boolValue];
            if (!isAdjustingExposure) {
                [self onAutoExposureDone];
            }
        }
    }];
}

#pragma mark - Getters & Setters

- (AVCaptureDevice *)currentDevice {
    return objc_getAssociatedObject(self, @selector(currentDevice));
}

- (void)setCurrentDevice:(AVCaptureDevice *)currentDevice {
    objc_setAssociatedObject(self, @selector(currentDevice), currentDevice, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (dispatch_block_t)simulateCaptureFlashCompletion {
    return objc_getAssociatedObject(self, @selector(simulateCaptureFlashCompletion));
}

- (void)setSimulateCaptureFlashCompletion:(dispatch_block_t)simulateCaptureFlashCompletion {
    objc_setAssociatedObject(self, @selector(simulateCaptureFlashCompletion), simulateCaptureFlashCompletion, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (AVCaptureTorchMode)currentTorchMode {
    return [objc_getAssociatedObject(self, @selector(currentTorchMode)) integerValue];
}

- (void)setCurrentTorchMode:(AVCaptureTorchMode)currentTorchMode {
    objc_setAssociatedObject(self, @selector(currentTorchMode), @(currentTorchMode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
