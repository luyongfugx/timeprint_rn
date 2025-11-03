#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>
#import "GPCamDefine.h"

@class BMWImageContext;
@class BMWFramebuffer;

@interface BMWGLView : UIView 

@property(nonatomic, readwrite) BMWImageFillModeType fillMode;

+ (const GLfloat *)textureCoordinatesForRotation:(BMWImageRotationMode)rotationMode;

- (instancetype)initWithFrame:(CGRect)frame;

- (instancetype)initWithCoder:(NSCoder *)aDecoder;

// the folowing three api is common config api, should use after init
- (void)setInputImageSize:(CGSize)size;

@property (nonatomic, assign) BMWImageRotationMode inputRotation;

- (void)setInputImageRotation:(BMWImageRotationMode)rotation;

- (void)setRenderBackingColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;

// use after config api
// must call in rendering thread
- (void)commonInit:(BMWImageContext*)context;

// must call in rendering thread
- (void)renderTextureId:(GLuint)textureId;

// must call in rendering thread
- (void)destoryBuffers;

- (void)showBlur:(BOOL)show;
- (void)showBlur:(BOOL)show delay:(CGFloat)delay;

#if CAMERA_STARTUP_OPT_DEBUG
- (void)showDebugTips:(NSString *)tips;
#endif

@property (nonatomic, strong) BMWFramebuffer *displayedFramebuffer;
@property (nonatomic, assign) CGSize size;
@property (nonatomic, assign) CGFloat cornerRadius;

@end
