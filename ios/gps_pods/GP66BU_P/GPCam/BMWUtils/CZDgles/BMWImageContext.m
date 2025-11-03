#import "BMWImageContext.h"
#import <UIKit/UIKit.h>
#import <OpenGLES/ES2/gl.h>

void runInRenderingQueue(BOOL sync, void (^block)(void))
{
    if (sync) {
        runSynchronouslyRenderingQueue(block);
    } else {
        runAsynchronouslyOnRenderingQueue(block);
    }
}

void runOnContextQueue(BOOL sync, BMWImageContext *context, void (^block)(void))
{
    if (sync) {
        runSynchronouslyOnContextQueue(context, block);
    } else {
        runAsynchronouslyOnContextQueue(context, block);
    }
}

void runOnMainQueue(BOOL sync, void (^block)(void))
{
    if(block == nil) return;
    if (sync) {
        runSynchronouslyOnMainQueue(block);
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

void runSynchronouslyOnMainQueue(void (^block)(void))
{
    if(block == nil) return;
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
}

void runSynchronouslyRenderingQueue(void (^block)(void))
{
    dispatch_queue_t videoProcessingQueue = [BMWImageContext sharedContextQueue];
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([[BMWImageContext sharedImageProcessingContext] contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_sync(videoProcessingQueue, block);
        }
}

void runAsynchronouslyOnRenderingQueue(void (^block)(void))
{
    dispatch_queue_t videoProcessingQueue = [BMWImageContext sharedContextQueue];

#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([[BMWImageContext sharedImageProcessingContext] contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_async(videoProcessingQueue, block);
        }
}

void runSynchronouslyOnContextQueue(BMWImageContext *context, void (^block)(void))
{
    if (!context) return;
    dispatch_queue_t videoProcessingQueue = [context contextQueue];
#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([context contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_sync(videoProcessingQueue, block);
        }
}

void runAsynchronouslyOnContextQueue(BMWImageContext *context, void (^block)(void))
{
    if (!context) return;
    dispatch_queue_t videoProcessingQueue = [context contextQueue];

#if !OS_OBJECT_USE_OBJC
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (dispatch_get_current_queue() == videoProcessingQueue)
#pragma clang diagnostic pop
#else
        if (dispatch_get_specific([context contextKey]))
#endif
        {
            block();
        }else
        {
            dispatch_async(videoProcessingQueue, block);
        }
}

dispatch_queue_attr_t XHmageDefaultQueueAttribute(qos_class_t qosClass)
{
#if TARGET_OS_IPHONE
    if ([[[UIDevice currentDevice] systemVersion] compare:@"9.0" options:NSNumericSearch] != NSOrderedAscending)
    {
        return dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qosClass, 0);
    }
#endif
    return nil;
}

@interface BMWImageContext()
{
    EAGLSharegroup *_sharegroup;
    void *_openGLESContextQueueKey;
}
@end

@implementation BMWImageContext

@synthesize coreVideoTextureCache = _coreVideoTextureCache;

- (void *)contextKey
{
    return _openGLESContextQueueKey;
}

- (void)dealloc
{
    [self flush];
}

- (void)flush
{
    if (_coreVideoTextureCache) {
                CVOpenGLESTextureCacheFlush(_coreVideoTextureCache, 0);
        CFRelease(_coreVideoTextureCache);
        _coreVideoTextureCache = NULL;
    }
}

- (instancetype)initWithQosClass:(qos_class_t)qosClass
{
    return [self initWithQosClass:qosClass name:@"com.xhey.openGLESContextQueue"];
}

- (instancetype)initWithQosClass:(qos_class_t)qosClass name:(NSString *)name
{
    if (!(self = [super init])) {
        return nil;
    }
    _openGLESContextQueueKey = &_openGLESContextQueueKey;
    _sharegroup = nil;
    _contextQueue = dispatch_queue_create(name.UTF8String, XHmageDefaultQueueAttribute(qosClass));
    dispatch_queue_set_specific(_contextQueue, _openGLESContextQueueKey, (__bridge void *)self, NULL);
    return self;
}

- (id)init
{
    return [self initWithQosClass:QOS_CLASS_DEFAULT];
}

- (EAGLContext *)context
{
    if (_context == nil) {
        _context = [self createContext];
    }
    return _context;
}

- (EAGLContext *)createContext;
{
    EAGLContext *context = nil;
    if (_sharegroup) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3 sharegroup:_sharegroup];
    } else {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES3];
    }
        return context;
}

- (CVOpenGLESTextureCacheRef)coreVideoTextureCache
{
    if (_coreVideoTextureCache == NULL) {
        CVReturn err = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, [self context], NULL, &_coreVideoTextureCache);

        if (err) {
            NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", err);
        }
    }
    return _coreVideoTextureCache;
}

+ (BMWImageContext *)sharedImageProcessingContext;
{
    static dispatch_once_t pred;
    static BMWImageContext *sharedImageProcessingContext = nil;

    dispatch_once(&pred, ^{
        sharedImageProcessingContext = [[[self class] alloc] init];
    });
    return sharedImageProcessingContext;
}

+ (void)useImageProcessingContext
{
    [[BMWImageContext sharedImageProcessingContext] useAsCurrentContext];
}

+ (dispatch_queue_t)sharedContextQueue;
{
    return [[self sharedImageProcessingContext] contextQueue];
}

- (void)useAsCurrentContext;
{
    EAGLContext *imageProcessingContext = [self context];
    if ([EAGLContext currentContext] != imageProcessingContext) {
        [EAGLContext setCurrentContext:imageProcessingContext];
    }
}

+ (void)close
{
    runSynchronouslyRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        glFinish();
        [EAGLContext setCurrentContext:nil];
    });
    }

@end
