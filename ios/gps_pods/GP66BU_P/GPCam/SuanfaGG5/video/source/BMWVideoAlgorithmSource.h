#import <Foundation/Foundation.h>
#import "BMWVideoAlgorithmSourceInterface.h"
#import "BMWImageContext.h"
#import "BMWLittleImageDrawer.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWVideoAlgorithmSourceProfile : NSObject
@property (nonatomic) GLint textureId;
@property (nonatomic) NSArray* metadataObjects;
@property (nonatomic) BMWRect *rectOfInterest;
@property (nonatomic) BMWDeviceOrientation orientation;
@property (nonatomic) BOOL isMirror;
@property (nonatomic) BOOL force;
@property (nonatomic) BOOL sync;
@property (nonatomic) BOOL enableSmooth;
@property (nonatomic) double timestamp;
@end

@interface BMWVideoAlgorithmSource : NSObject<BMWVideoAlgorithmSourceInterface>

@property (nonatomic, readonly) BMWLittleImageDrawer *littleImageDrawer;

- (void)clear;

- (void)setup:(BMWImageContext*)context;

- (void)setup:(BMWImageContext*)context size:(CGSize)size;

- (void)setup:(BMWImageContext*)context mode:(BMWCameraKitMode)mode;

- (void)triggerAllDelegates:(GLint)textureId orientation:(BMWDeviceOrientation)orient;

- (void)triggerAllDelegates:(GLint)textureId orientation:(BMWDeviceOrientation)orientation force:(BOOL)force timestamp:(double) timestamp;

- (void)triggerAllDelegates:(GLint)textureId orientation:(BMWDeviceOrientation)orientation force:(BOOL)force timestamp:(double) timestamp sync:(BOOL)sync;

- (void)triggerAllDelegates:(void (^)(BMWVideoAlgorithmSourceProfile * profile))builder;

- (void)resetTimestamp;

- (CVPixelBufferRef)render:(BMWVideoAlgorithmSourceProfile*)profile;

@end

NS_ASSUME_NONNULL_END
