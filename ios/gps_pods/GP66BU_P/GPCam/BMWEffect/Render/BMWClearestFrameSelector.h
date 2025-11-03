#import <Foundation/Foundation.h>
#import "BMWImageContext.h"
#import "GPCamDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWClearestFrameSelector : NSObject

- (instancetype)initWithContext:(BMWImageContext *)imageContext;

- (void)reset;

- (void)onVideoFrameArrived:(GLuint)textureId
                       size:(CGSize)size
                  timestamp:(CMTime)timestamp;

- (UIImage *)getClearestFrameWithMirror:(BOOL)mirror
                            orientation:(BMWDeviceOrientation)orientation
                              timestamp:(CMTime *)timestamp
                             frameIndex:(NSInteger *)frameIndex;

@end

NS_ASSUME_NONNULL_END
