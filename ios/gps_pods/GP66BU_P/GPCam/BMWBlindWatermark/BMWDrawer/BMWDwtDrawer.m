#import "BMWDwtDrawer.h"
#import "BMWGlShaderHelper.h"
#import "BMWImageContext.h"
#import "GPCamDefine.h"
#import "BMWGLView.h"

static NSString* const kFragmentString = SHADER_STRING
(
 precision highp float;
 precision highp int;
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform int uDirection;
 uniform float uWidth;
 uniform float uHeight;

 vec4 encodeColor(float c)
 {
    float r; float g; float b; float a;
    if(c > 0.0) {
        a = 1.0;
    } else {
        c = -c;
        a = 0.0;
    }
    //rgb
    b = clamp(c-2.0, 0.0, 1.0);
    g = clamp(c-1.0, 0.0, 1.0);
    r = c-g-b;
    return vec4(r, g, b, a);
 }

 float decodeColor(vec4 c)
 {
    float v = c.r + c.g + c.b;
    if(c.a < 1.0) {
        v = -v;
    }
    return v;
 }
 
 void main()
 {
     float offset; float pos; float delta;
     vec2 uv0; vec2 uv1;
     float color; float color0; float color1;
     float scale = 1.0;
     if(uDirection == 0) { //row
          scale = 2.0;
          offset = 1.0 / uWidth;
          pos = textureCoordinate.x;
          if(pos < 0.5) {
              delta = 0.0;
          } else {
              delta = 0.5;
          }
          uv0 = vec2((textureCoordinate.x-delta)*2.0-offset/2.0, textureCoordinate.y);
          uv1 = vec2((textureCoordinate.x-delta)*2.0+offset/2.0, textureCoordinate.y);
     } else { // col
          scale = 1.0;
          offset = 1.0 / uHeight;
          pos = textureCoordinate.y;
          if(pos < 0.5) {
              delta = 0.0;
          } else {
              delta = 0.5;
          }
          uv0 = vec2(textureCoordinate.x, (textureCoordinate.y-delta)*2.0-offset/2.0);
          uv1 = vec2(textureCoordinate.x, (textureCoordinate.y-delta)*2.0+offset/2.0);
     }
     color0 = decodeColor(texture2D(inputImageTexture, uv0)) * 255.0;
     color1 = decodeColor(texture2D(inputImageTexture, uv1)) * 255.0;
     if(pos < 0.5) {
         color = (color0 + color1) / scale;
     } else {
         color = (color0 - color1) / scale;
     }
    gl_FragColor = encodeColor(color / 255.0);
 }
);

@interface BMWDwtDrawer ()
{
    GLuint _directionSlot;
    GLuint _widthSlot;
    GLuint _heightSlot;
}
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) int direction;
@end

@implementation BMWDwtDrawer

- (void)destory
{
}

- (instancetype)init:(CGSize)size direction:(int)direction
{
    if (self = [super init]) {
        self.width = (int)size.width;
        self.height = (int)size.height;
        self.direction = direction;
    }
    return self;
}

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:nil fragmentShader:kFragmentString];
    _widthSlot = [super getUniformLocation:@"uWidth"];
    _heightSlot = [super getUniformLocation:@"uHeight"];
    _directionSlot = [super getUniformLocation:@"uDirection"];
}

- (void)prepare
{
    [super prepare];
    glUniform1f(_widthSlot, _width);
    glUniform1f(_heightSlot, _height);
    glUniform1i(_directionSlot, _direction);
}

- (void)renderTextureId:(GLuint)texId vertices:(const GLfloat *)vertices
{
    [super drawWithTexId:texId vertices:vertices rotation:kXHImageNoRotation];
}

@end
