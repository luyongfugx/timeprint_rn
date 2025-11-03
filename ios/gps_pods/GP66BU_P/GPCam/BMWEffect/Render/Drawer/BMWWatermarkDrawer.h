#import <Foundation/Foundation.h>
#import "BMWBaseDrawer.h"

NS_ASSUME_NONNULL_BEGIN

@class BMWFramebuffer;
@class BMWImageContext;
@interface BMWWatermarkInfo : NSObject
@property(nonatomic) NSString* tag;
@property(nonatomic) GLint texId;
@property(nonatomic) CGRect rect;
@property(nonatomic) BMWImageRotationMode rotationMode;

+ (BMWWatermarkInfo*)buildInfo:(NSString*)tag texId:(GLint)texId rect:(CGRect)rect deviceOrientation:(BMWDeviceOrientation)orientation;
@end

// 3.0.225 上有用来处理人脸名片需求，有一个XHGLView，需要在这里传入，支持图片和视频动态渲染水印内容
@interface BMWWatermarkInfoV2 : NSObject

@property (nonatomic, strong) BMWFramebuffer *framebuffer;
@property(nonatomic) CGRect rect;
@property(nonatomic) BMWImageRotationMode rotationMode;

@end

@interface BMWWatermarkDrawer : BMWBaseDrawer

- (instancetype)initWithContext:(BMWImageContext *)context;

- (void)updateWatermark:(BMWWatermarkInfo*)info;
- (void)updateWatermarkV2s:(NSArray<BMWWatermarkInfoV2* >*)infos;
- (NSArray<BMWWatermarkInfo*>*)findWatermrkWithTag:(NSString*)tag;
- (void)draw;

@end

NS_ASSUME_NONNULL_END


