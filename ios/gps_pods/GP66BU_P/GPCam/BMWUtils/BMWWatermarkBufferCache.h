#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "BMWWatermarkItem.h"
#import "BMWWatermarkBuffer.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWWatermarkBufferCache : NSObject

- (void)clear;

- (void)clear:(NSArray<BMWWatermarkItem*>*)items;

- (void)pushWatermark:(BMWWatermarkItem*)item;

- (void)popWatermarkSync:(BMWWatermarkItem*)item buffer:(void(^)(BMWWatermarkBuffer* buffer))block;

- (void)getWatermarkSync:(BMWWatermarkItem*)item buffer:(void(^)(BMWWatermarkBuffer* buffer))block;

@end

NS_ASSUME_NONNULL_END
