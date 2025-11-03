#import "BMWIDwtDrawer.h"

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
  
 void main() {
     float color1; float color2; vec4 color[2];
     vec2 uv1; vec2 uv2;
     float xfpos = uWidth * textureCoordinate.x;
     float yfpos = uHeight * textureCoordinate.y;
     float xoffset = 1.0 / uWidth;
     float yoffset = 1.0 / uHeight;
    
     int xipos = int(xfpos / 2.0) * 2;
     int xindex = int(xfpos - float(xipos));
     float x = float(xipos) / uWidth;
    
     int yipos = int(yfpos / 2.0) * 2;
     int yindex = int(yfpos - float(yipos));
     float y = float(yipos) / uHeight;
    
     int index = 0;
     float scale = 1.0;
     if(uDirection == 0) { //row
         index = xindex;
         scale = 1.0;
         uv1 = vec2(x/2.0+xoffset/2.0, textureCoordinate.y);
         uv2 = vec2(uv1.x+0.5, uv1.y);
     } else { // col
         index = yindex;
         scale = 2.0;
         uv1 = vec2(textureCoordinate.x, y/2.0+yoffset/2.0);
         uv2 = vec2(uv1.x, uv1.y+0.5);
     }
     color1 = decodeColor(texture2D(inputImageTexture, uv1)) * 255.0;
     color2 = decodeColor(texture2D(inputImageTexture, uv2)) * 255.0;
     color[0] = encodeColor((color1 + color2)/scale/255.0);
     color[1] = encodeColor((color1 - color2)/scale/255.0);
     gl_FragColor = color[index];
//    gl_FragColor = vec4((y/2.0+yoffset/2.0), 0.0, 0.0, 1.0);
//    gl_FragColor = vec4(textureCoordinate.y, 0.0, 0.0, 1.0);
//    gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
 }
);

@interface BMWIDwtDrawer ()
{
    GLuint _directionSlot;
    GLuint _widthSlot;
    GLuint _heightSlot;
}
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) int direction;
@end

@implementation BMWIDwtDrawer

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

