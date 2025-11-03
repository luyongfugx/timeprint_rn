#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "GPCamDefine.h"
#import "BMWCameraProfile.h"

NS_ASSUME_NONNULL_BEGIN

FOUNDATION_EXPORT NSNotificationName _Nonnull const BMWCameraKitZoomFactorChangedNotification;

@protocol BMWCameraKitDelegate <NSObject>

- (void)processAudioBuffer:(CMSampleBufferRef)audioBuffer;
- (void)processVideoBuffer:(BMWCameraKitData*)data;
- (void)cameraChangingStatus:(BMWCameraKitChangingStatus)changingStatus;
- (void)currZoomFactorChanged:(CGFloat)factor;
@end

typedef NS_ENUM(NSInteger, BMWTakePhotoImmediate) {
    BMWTakePhotoImmediateNone,
    BMWTakePhotoImmediateSuggest,
    BMWTakePhotoImmediateForce
};

@interface BMWCameraKitBase : NSObject
@property (nonatomic, strong) dispatch_queue_t operationQueue;
@property (nonatomic, strong) dispatch_queue_t videoCaptureQueue;
@property (nonatomic, strong) dispatch_queue_t audioCaptureQueue;
@property (nonatomic, strong) dispatch_queue_t imageCaptureQueue;
@property (nonatomic, strong) dispatch_queue_t metadataCaptureQueue;
+ (dispatch_queue_t)sharedImageCaptureQueue;
- (void)runSyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block;
- (void)runAsyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block;
- (void)runAsyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block delay:(CGFloat)delaySec;
- (void)runSyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block tag:(NSString*)tag;
- (void)runAsyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block tag:(NSString*)tag;
- (void)runAsyncOnOperationQueue:(DISPATCH_NOESCAPE dispatch_block_t)block delay:(CGFloat)delaySec tag:(NSString*)tag;
- (void)fetchProfile:(BMWCameraKitSettingProfile*)profile;
@end

NS_ASSUME_NONNULL_END
