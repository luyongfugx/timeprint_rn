#import "BMWYUV2RGBDrawer.h"

static NSString* const kFragmentString = SHADER_STRING
(
 precision highp float;
 precision highp int;
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D sUTexture;
 
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
    vec3 rgb = texture2D(inputImageTexture, textureCoordinate).rgb;
    
    float y = 0.298355*rgb.r + 0.587478*rgb.g + 0.114167*rgb.b;
    float u = decodeColor(texture2D(sUTexture, textureCoordinate));
    float v = 0.501175*rgb.r - 0.419627*rgb.g - 0.081548*rgb.b + 0.5;
    
    vec3 yuv = vec3(y, (u - 0.5), (v - 0.5));
    float r = yuv.x * 1.0 + yuv.y * 0.0 + yuv.z * 1.40199995;
    float g = yuv.x * 1.0 + yuv.y * -0.344136298 + yuv.z * -0.714136302;
    float b = yuv.x * 1.0 + yuv.y * 1.77199996 + yuv.z * 0.0;
    
    r = clamp(r, 0.0, 1.0);
    g = clamp(g, 0.0, 1.0);
    b = clamp(b, 0.0, 1.0);
    gl_FragColor = vec4(r,g,b, 1.0);
 }
);

@interface BMWYUV2RGBDrawer()
{
    GLuint _uTextureSlot;
}
@property (nonatomic) int uTexId;

@end

@implementation BMWYUV2RGBDrawer

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:nil fragmentShader:kFragmentString];
    _uTextureSlot = [super getUniformLocation:@"sUTexture"];
}

- (void)prepare
{
    [super prepare];
    glActiveTexture(GL_TEXTURE1);
    glUniform1i(_uTextureSlot, 1);
    glBindTexture(GL_TEXTURE_2D, _uTexId);
}

- (void)renderTextureId:(GLuint)texId uTexId:(int)uTexId vertices:(const GLfloat *)vertices
{
    _uTexId = uTexId;
    [super drawWithTexId:texId vertices:vertices rotation:kXHImageNoRotation];
}

@end


