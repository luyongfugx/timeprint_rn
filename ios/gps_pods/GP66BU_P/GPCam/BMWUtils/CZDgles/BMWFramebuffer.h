#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class BMWImageContext;

@interface BMWFramebuffer : NSObject

@property (readonly) BOOL isValid;
@property (readonly) GLuint texture;
@property (readonly) CGSize bufferSize;
@property (nonatomic) NSString* tag;
@property (readonly) BMWImageContext* imageContext;

- (instancetype)initWithSize:(CGSize)framebufferSize imageContext:(BMWImageContext*)imageContext;

- (instancetype)initWithSize2:(CGSize)framebufferSize imageContext:(BMWImageContext*)imageContext;

- (void)destroy;

- (UIImage*)imageFromFramebufferContent;

- (CVPixelBufferRef)renderTarget;

- (void)bind;

@end

NS_ASSUME_NONNULL_END
