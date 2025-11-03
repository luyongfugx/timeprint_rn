#import <Foundation/Foundation.h>
#import "BMWImageContext.h"
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@class BMWWatermarkItem;

NS_ASSUME_NONNULL_BEGIN

@interface BMWGLUtils : NSObject

+ (GLuint)setupTexture:(UIImage*)image;

+ (GLuint)setupTexture:(UIImage*)image redraw:(BOOL)redraw;

+ (void)getRawData:(UIImage*)image block:(void (^)(GLubyte *imageData, int width, int height, GLenum format))result;

+ (void)getRawData:(UIImage*)image forceRedraw:(BOOL)redraw block:(void (^)(GLubyte *imageData, int width, int height, GLenum format))result;

+ (GLuint)createTextureWithData:(uint8_t*)data width:(int)width height:(int)height;

// The following 5 APIs is for creating buffer/texture from UIView/CALayer
+ (GLuint)createTextureWithLayer:(CALayer *)layer scale:(CGFloat)scale;

+ (void)createBufferWithLayer:(CALayer *)layer scale:(CGFloat)scale block:(void (^)(GLubyte *buffer, CGSize size))block;

+ (void)updateTextureWithLayer:(CALayer *)layer scale:(CGFloat)scale textureId:(GLuint)textureId;

+ (void)createBufferWithWatermark:(BMWWatermarkItem *)watermark block:(void (^)(UIImage*image))block;

+ (GLuint)createTextureWithWatermark:(BMWWatermarkItem *)watermark;

+ (GLint)updateTextureWithImage:(UIImage *)image textureId:(GLuint)textureId;

+ (void)updateTextureWithBuffer:(GLbyte *)buffer bufferSize:(CGSize)bufferSize textureId:(GLuint)textureId;

+ (GLuint)createTextureWithBuffer:(CVPixelBufferRef)pixelBuffer context:(BMWImageContext*)context;

+ (GLuint)genTexture;

+ (CGFloat)maxSupportImageSize;

+ (void)rect2GLCoordinate:(CGRect)rect reslut:(void(^)(GLfloat * v))reslut;

+ (UIImage *)imageFromView:(UIView *)view;

+ (UIImage*)imageFromImageData:(void*)imageData size:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
