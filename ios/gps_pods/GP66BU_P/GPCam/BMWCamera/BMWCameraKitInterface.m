#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPCamDefine.h"
#import "BMWCameraKitInterface.h"

NSNotificationName const BMWCameraKitZoomFactorChangedNotification = @"BMWCameraKitZoomFactorChangedNotification";
static void *_operationQueueKey;
static void *_imageCaptureQueueKey;
@interface BMWCameraKitBase () <AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate>
@end

@implementation BMWCameraKitBase

- (instancetype)init
{
    if (!(self = [super init])) {
        return nil;
    }
    // init queue
    self.videoCaptureQueue = dispatch_queue_create("com.CAD.camera.capture.video", 0);
    self.audioCaptureQueue = dispatch_queue_create("com.CAD.camera.capture.audio", 0);
    self.metadataCaptureQueue = dispatch_queue_create("com.CAD.camera.capture.metadata", 0);
    self.imageCaptureQueue = [self.class sharedImageCaptureQueue];
    self.operationQueue = [self.class sharedOperationQueue];
    return self;
}

#pragma mark - Utils

- (void)runSyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block
{
    if (dispatch_get_specific(_operationQueueKey)) {
        block();
    } else {
        dispatch_sync(_operationQueue, block);
    }
}

- (void)runAsyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block
{
    if (dispatch_get_specific(_operationQueueKey)) {
        block();
    } else {
        dispatch_async(_operationQueue, block);
    }
}

- (void)runAsyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block delay:(CGFloat)delaySec
{
    if (delaySec > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySec * NSEC_PER_SEC)), _operationQueue, ^{
            block();
        });
    } else {
        [self runAsyncOnOperationQueue:block];
    }
}

- (void)runSyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block tag:(NSString*)tag
{
    void(^block_)(void) = ^(void) {
        double begin = CACurrentMediaTime();
        block();
        BMWMLog(@"%@ OP[%@] timecost:%lf", [NSString stringWithUTF8String:object_getClassName(self)], tag, 1000 * (CACurrentMediaTime() - begin));
    };
    if (dispatch_get_specific(_operationQueueKey)) {
        block_();
    } else {
        dispatch_sync(_operationQueue, block_);
    }
}

- (void)runAsyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block tag:(NSString*)tag
{
    void(^block_)(void) = ^(void) {
        double begin = CACurrentMediaTime();
        block();
        BMWMLog(@"%@ OP[%@] timecost:%lf", [NSString stringWithUTF8String:object_getClassName(self)], tag, 1000 * (CACurrentMediaTime() - begin));
    };
    if (dispatch_get_specific(_operationQueueKey)) {
        block_();
    } else {
        dispatch_async(_operationQueue, block_);
    }
}

- (void)runAsyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block delay:(CGFloat)delaySec tag:(NSString*)tag
{
    void(^block_)(void) = ^(void) {
        double begin = CACurrentMediaTime();
        block();
        BMWMLog(@"%@ OP[%@] timecost:%lf", [NSString stringWithUTF8String:object_getClassName(self)], tag, 1000 * (CACurrentMediaTime() - begin));
    };
    if (delaySec > 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delaySec * NSEC_PER_SEC)), _operationQueue, ^{
            block_();
        });
    } else {
        [self runAsyncOnOperationQueue:block_ tag:tag];
    }
}

+ (dispatch_queue_t)sharedImageCaptureQueue
{
    static dispatch_queue_t imageCaptureQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!imageCaptureQueue) {
            _imageCaptureQueueKey = &_imageCaptureQueueKey;
            imageCaptureQueue = dispatch_queue_create("com.CAD.camera.capture.image", 0);
            dispatch_queue_set_specific(imageCaptureQueue, _imageCaptureQueueKey, (__bridge void *_Nullable)(self), NULL);
        }
    });
    return imageCaptureQueue;
}

+ (dispatch_queue_t)sharedOperationQueue
{
    static dispatch_queue_t operationQueue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!operationQueue) {
            _operationQueueKey = &_operationQueueKey;
            dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
            operationQueue = dispatch_queue_create("com.CAD.capture.operation", attr);
            dispatch_queue_set_specific(operationQueue, _operationQueueKey, (__bridge void *_Nullable)(self), NULL);
        }
    });
    return operationQueue;
}

@end
