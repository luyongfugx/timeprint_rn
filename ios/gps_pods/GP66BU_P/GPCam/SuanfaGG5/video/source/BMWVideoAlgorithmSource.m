#import "BMWVideoAlgorithmSource.h"
#import "BMWImageContext.h"
#import "BMWGLUtils.h"
#import "BMWDeviceUtils.h"

@implementation BMWVideoAlgorithmSourceProfile
- (instancetype)init
{
    if (self = [super init]) {
        self.textureId = -1;
        self.orientation = BMWDeviceOrientationPortait;
        self.force = NO;
        self.timestamp = -1;
        self.sync = NO;
        self.isMirror = NO;
        return self;
    }
    return nil;
}
@end

@interface BMWVideoAlgorithmSource ()

@property (nonatomic) NSMutableDictionary<NSNumber*, id<BMWVideoProcessDelegate>>* delegatesDic;
@property (nonatomic) NSRecursiveLock* delegatesLock;
@property (nonatomic) BMWLittleImageDrawer *littleImageDrawer;

// todo ugly ratio为1特殊,预览使用3:4, 业务通过遮挡生产的1:1效果
@property (nonatomic) BOOL ratio1x1;

@end

@implementation BMWVideoAlgorithmSource

- (void)clear
{
    if (self.littleImageDrawer) {
        [self.littleImageDrawer destory];
        self.littleImageDrawer = nil;
    }
}

- (void)setup:(BMWImageContext*)context mode:(BMWCameraKitMode)mode
{
    CGFloat ratio = 3.0f / 4.0f;
    if (mode == BMWCameraKitModeVideo || mode == BMWCameraKitModePhoto16x9 ) {
        ratio = 9.0 / 16.0f;
    } else if (mode == BMWCameraKitModePhoto1x1) {
        ratio = 1.0f;
    } else if (mode == BMWCameraKitModePhotoFull) {
        ratio = BMWDeviceUtils.sharedInstance.deviceRatio;
    }
    CGFloat low = [BMWDeviceUtils isLowerThaniPhone7] ? 480 : 720;
    CGSize size = CGSizeMake(low, low/ratio);
    self.littleImageDrawer = [[BMWLittleImageDrawer alloc] initWithContext:context size:size];
}

- (void)setup:(BMWImageContext*)context size:(CGSize)size
{
    self.littleImageDrawer = [[BMWLittleImageDrawer alloc] initWithContext:context size:size];
}

- (void)setup:(BMWImageContext*)context
{
    [self setup:context size:[BMWDeviceUtils isLowerThaniPhone7] ? CGSizeMake(480, 640) : CGSizeMake(720, 960)];
}

- (BOOL)addDelegate:(id<BMWVideoProcessDelegate>)delegate
{
    [self.delegatesLock lock];
    NSNumber *key = @((int64_t)delegate);
    if (!self.delegatesDic[key]) {
        self.delegatesDic[key] = delegate;
    }
    NSUInteger count = self.delegatesDic.allKeys.count;
    [self.delegatesLock unlock];
    return count > 0;
}

- (BOOL)removeDelegate:(id<BMWVideoProcessDelegate>)delegate
{
    [self.delegatesLock lock];
    NSNumber *key = @((int64_t)delegate);
    [self.delegatesDic removeObjectForKey:key];
    NSUInteger count = self.delegatesDic.allKeys.count;
    [self.delegatesLock unlock];
    return count > 0;
}

- (void)triggerAllDelegates:(void (^)(BMWVideoAlgorithmSourceProfile * profile))builder
{
    BMWVideoAlgorithmSourceProfile *profile = [BMWVideoAlgorithmSourceProfile new];
    SafeBlock(builder, profile);
    [self.delegatesLock lock];
    
    NSMutableDictionary<NSString*, NSNumber*> *shouldTriggerDic = [[NSMutableDictionary alloc] init];
    for (id<BMWVideoProcessDelegate> l in self.delegatesDic.allValues) {
        NSString *key = l.id;
        BOOL trigger = [l shouldTrigger:profile.timestamp] || profile.force;
        shouldTriggerDic[key] = @(trigger);
    }
    BOOL shouldTrigger = NO;
    for (NSNumber *l in shouldTriggerDic.allValues) {
        if(l.intValue == 1) {
            shouldTrigger = YES;
            break;
        }
    }
    if(!shouldTrigger) {
        [self.delegatesLock unlock];
        return;
    }
    
    if (shouldTrigger) {
        CVPixelBufferRef pixelBuffer = [self render:profile];
        if(pixelBuffer) {
            for (id<BMWVideoProcessDelegate> l in self.delegatesDic.allValues) {
                NSString *key = l.id;
                if(!shouldTriggerDic[key].intValue) continue;
                @xhm_weakify(self);
                if([l respondsToSelector:@selector(processWithbuilder:)]) {
                    @xhm_strongify(self);
                    [l processWithbuilder:^(BMWAlgorithmProcessProfile * _Nonnull preProcessProfile) {
                        preProcessProfile.pixelBuffer = pixelBuffer;
                        preProcessProfile.metadataObjects = profile.metadataObjects;
                        preProcessProfile.rectOfInterest = profile.rectOfInterest;
                        preProcessProfile.orient =  profile.orientation;
                        preProcessProfile.isMirror = profile.isMirror;
                        preProcessProfile.enableSmooth = profile.enableSmooth;
                        preProcessProfile.sync = profile.sync;
                    }];
                }
            }
        }
    }
    [self.delegatesLock unlock];
}

- (void)triggerAllDelegates:(GLint)textureId orientation:(BMWDeviceOrientation)orientation
{
    [self triggerAllDelegates:^(BMWVideoAlgorithmSourceProfile * _Nonnull profile) {
        profile.textureId = textureId;
        profile.orientation = orientation;
        profile.force = NO;
        profile.timestamp = -1;
        profile.sync = NO;
    }];
}

- (void)triggerAllDelegates:(GLint)textureId orientation:(BMWDeviceOrientation)orientation force:(BOOL)force timestamp:(double)timestamp
{
    [self triggerAllDelegates:^(BMWVideoAlgorithmSourceProfile * _Nonnull profile) {
        profile.textureId = textureId;
        profile.orientation = orientation;
        profile.force = force;
        profile.timestamp = -1;
        profile.sync = NO;
    }];
}

- (void)triggerAllDelegates:(GLint)textureId orientation:(BMWDeviceOrientation)orientation force:(BOOL)force timestamp:(double)timestamp sync:(BOOL)sync
{
    [self triggerAllDelegates:^(BMWVideoAlgorithmSourceProfile * _Nonnull profile) {
        profile.textureId = textureId;
        profile.orientation = orientation;
        profile.force = force;
        profile.timestamp = timestamp;
        profile.sync = sync;
    }];
}

- (void)resetTimestamp
{
    for (id<BMWVideoProcessDelegate> l in self.delegatesDic.allValues) {
        [l resetTimestamp];
    }
}

- (NSMutableDictionary<NSNumber *,id<BMWVideoProcessDelegate>> *)delegatesDic
{
    if (_delegatesDic == nil) {
        _delegatesDic = [[NSMutableDictionary alloc] init];
    }
    return _delegatesDic;
}

- (NSRecursiveLock *)delegatesLock
{
    if (_delegatesLock == nil) {
        _delegatesLock = [[NSRecursiveLock alloc] init];
    }
    return _delegatesLock;
}

// can override
- (NSString*)tag
{
    return @"";
}

// can override
- (void)pull
{
}

// can override
- (BOOL)retry
{
    return NO;
}

// can override
- (CVPixelBufferRef)render:(BMWVideoAlgorithmSourceProfile*)profile
{
    // 3:4->1:1
    static const GLfloat coordinates[] = {
        0.0f, 0.125f,
        1.0f, 0.125f,
        0.0f, 0.875f,
        1.0f, 0.875f,
    };
    self.littleImageDrawer.isMirror = profile.isMirror;
    self.littleImageDrawer.deviceOrientation = profile.orientation;
    if(self.ratio1x1) {
        [self.littleImageDrawer draw:profile.textureId coordinates:coordinates];
    } else {
        [self.littleImageDrawer draw:profile.textureId];
    }
    CVPixelBufferRef pixelBuffer = self.littleImageDrawer.framebuffer.renderTarget;
    return pixelBuffer;
}

@end
