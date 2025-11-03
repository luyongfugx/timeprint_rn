#import "BMWWatermarkBufferCache.h"
#import <QuartzCore/QuartzCore.h>
#import "BMWGLUtils.h"

@interface BMWWatermarkBufferCache ()
{
    void *_operationQueueKey;
}
@property (nonatomic) dispatch_queue_t operationQueue;
@property (nonatomic, assign) BOOL currentBufferIndex;
@property (nonatomic, strong) NSMutableDictionary<NSNumber*, BMWWatermarkBuffer*>* layerDic;

@end

@implementation BMWWatermarkBufferCache

- (void)dealloc
{
    [self clear];
}

- (void)clear
{
    [self runSyncOnOperationQueue:^{
        [self.layerDic removeAllObjects];
    }];
}

- (void)clear:(NSArray<BMWWatermarkItem*>*)items
{
    [self runSyncOnOperationQueue:^{
        for (BMWWatermarkItem* item in items) {
            NSNumber *key = @(item.id);
            [self.layerDic removeObjectForKey:key];
        }
    }];
}

- (id)init
{
    self = [super init];
    if (self) {
        self.layerDic = [NSMutableDictionary new];
        _operationQueueKey = &_operationQueueKey;
        self.operationQueue = dispatch_queue_create("com.CAD.watermark.cache", 0);
        dispatch_queue_set_specific(self.operationQueue, _operationQueueKey, (__bridge void *_Nullable)(self), NULL);
    }
    return  self;
}

- (void)pushWatermark:(BMWWatermarkItem*)item
{
    if(item.highResolution) {
        [self runAsyncOnOperationQueue:^{
            [BMWGLUtils createBufferWithWatermark:item block:^(UIImage * _Nonnull image) {
                NSNumber *key = @(item.id);
                BMWWatermarkBuffer *b = [BMWWatermarkBuffer watermarkImage:image];
                b.autoReset = !item.cacheBuffer;
                self.layerDic[key] = b;
                            }];
        }];
    } else {
        [self runAsyncOnOperationQueue:^{
            [BMWGLUtils createBufferWithLayer:item.waterLayer scale:item.scale block:^(GLubyte * _Nonnull buffer, CGSize size) {
                NSNumber *key = @(item.id);
                BMWWatermarkBuffer *b = [BMWWatermarkBuffer watermarkBuffer:buffer size:size];
                b.autoReset = !item.cacheBuffer;
                self.layerDic[key] = b;
                            }];
        }];
    }
}

- (void)popWatermarkSync:(BMWWatermarkItem*)item buffer:(void(^)(BMWWatermarkBuffer* buffer))block;
{
    [self runSyncOnOperationQueue:^{
        NSNumber *key = @(item.id);
                BMWWatermarkBuffer *buffer = self.layerDic[key];
        !block ? : block(buffer);
        [self.layerDic removeObjectForKey:key];
    }];
}

- (void)getWatermarkSync:(BMWWatermarkItem*)item buffer:(void(^)(BMWWatermarkBuffer* buffer))block
{
    [self runSyncOnOperationQueue:^{
        NSNumber *key = @(item.id);
        BMWWatermarkBuffer *buffer = self.layerDic[key];
        !block ? : block(buffer);
    }];
}

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

@end
