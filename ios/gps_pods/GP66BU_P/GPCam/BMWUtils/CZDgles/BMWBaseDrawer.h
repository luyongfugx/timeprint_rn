#import <Foundation/Foundation.h>
#import "BMWGLView.h"
#import "BMWGlShaderHelper.h"
#import "BMWImageContext.h"
#import "GPCamDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWBaseDrawer : NSObject

// the folowing need ovrride
- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader;

- (int)getUniformLocation:(NSString*)name;

// life clyle, should call supper
- (void)destory;

- (instancetype)init;

// do before and after rending, should call supper
- (void)prepare;

- (void)clearup;

// call the folowing befoe render
- (void)resetMatrix;
- (void)rotateZ:(float)radians;
- (void)scaleX:(float)scaleX scaleY:(float)scaleY;
- (void)transX:(float)tx transY:(float)ty;

- (void)setInputTexId:(GLint)texId;

- (void)setRotation:(BMWImageRotationMode)rotation;

// render api
- (void)draw;

- (void)drawWithTexId:(GLint)textureId;

- (void)drawWithTexId:(GLint)textureId coordinates:(const GLfloat *)coordinates;

- (void)drawWithTexId:(GLuint)textureId
             vertices:(const GLfloat *)vertices
             rotation:(BMWImageRotationMode)rotation;

- (void)drawWithTexId:(GLuint)textureId
             vertices:(const GLfloat *)vertices
          coordinates:(const GLfloat *)coordinates;

+ (const GLfloat *)ColorConversionMatrix:(CFStringRef)matrix;

@end

NS_ASSUME_NONNULL_END
