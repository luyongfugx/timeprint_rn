#import <AVFoundation/AVFoundation.h>
#import "BMWRenderInterface.h"
#import "BMWImageContext.h"
#import "BMWFramebuffer.h"

@class BMWWatermarkItem;
@class BMWWatermarkInfoV2;

NS_ASSUME_NONNULL_BEGIN

@interface BMWWatermarkRender : NSObject <BMWRenderInterface>

@property (nonatomic, readonly) CVPixelBufferRef renderTarget;

@property (nonatomic) BOOL hiddenProductWatermark;

@property (nonatomic, assign) BOOL isMirror;

- (instancetype)init;

- (instancetype)initWithContext:(BMWImageContext *)imageContext;

- (void)setProductWatermark:(BMWWatermarkItem *)productWatermark;

- (void)prepareWatermark:(BMWWatermarkItem *)watermark;

- (void)setWatermark:(BMWWatermarkItem *)watermark;

- (void)updateWatermarkV2s:(NSArray<BMWWatermarkInfoV2* >*)infos;

- (void)setInputTexture:(GLuint)textureId;

- (void)process:(double)frameTime;

- (void)processForTrancode:(double)frameTime;

@end

NS_ASSUME_NONNULL_END
