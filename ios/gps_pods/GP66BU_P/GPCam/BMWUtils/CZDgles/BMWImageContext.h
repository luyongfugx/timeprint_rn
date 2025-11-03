#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <OpenGLES/EAGL.h>

@class BMWImageContext;

NS_ASSUME_NONNULL_BEGIN

#ifdef __cplusplus
extern "C" {
#endif
void runSynchronouslyOnMainQueue(void (^block)(void));
void runSynchronouslyRenderingQueue(void (^block)(void));
void runAsynchronouslyOnRenderingQueue(void (^block)(void));
void runSynchronouslyOnContextQueue(BMWImageContext *context, void (^block)(void));
void runAsynchronouslyOnContextQueue(BMWImageContext *context, void (^block)(void));
void runOnContextQueue(BOOL sync, BMWImageContext *context, void (^block)(void));
void runOnMainQueue(BOOL sync, void (^block)(void));
void runInRenderingQueue(BOOL sync, void (^block)(void));
#ifdef __cplusplus
}
#endif
@interface BMWImageContext : NSObject

- (instancetype)initWithQosClass:(qos_class_t)qosClass;

- (instancetype)initWithQosClass:(qos_class_t)qosClass name:(NSString *)name;

- (instancetype)init;

@property(nonatomic) NSUInteger bufferCount;
@property(nonatomic) EAGLContext *context;

@property(nonatomic, readonly) dispatch_queue_t contextQueue;

@property(readonly) CVOpenGLESTextureCacheRef coreVideoTextureCache;

- (void)useAsCurrentContext;

+ (BMWImageContext *)sharedImageProcessingContext;

+ (void)useImageProcessingContext;

+ (dispatch_queue_t)sharedContextQueue;

- (void *)contextKey;

+ (void)close;

- (void)flush;

@end

NS_ASSUME_NONNULL_END

