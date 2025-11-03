#import "BMWFliterDrawer.h"

static NSString* const kFragmentString = SHADER_STRING
(
 precision highp float;
 const float PI = 3.1415926535;
 const vec3 luminanceWeighting = vec3(0.288086, 0.711914, 0.0);
 
 uniform sampler2D inputImageTexture;
 uniform sampler2D lutTexture;
 uniform sampler2D lumMaskCurveTexture; // LumMaskCurve
 uniform sampler2D toneCurveTexture; // ToneCurve
 varying vec2 textureCoordinate;
 
 uniform float lutIntensity;
 uniform float brightnessIntensity;
 uniform float toneCurveIntensity;
 uniform float lumMaskCurveIntensity;
 
 highp vec4 doBrightness(vec4 color, float intensity)
 {
    float bright = intensity * 200.0 / 255.0;
    float r = color.r  + sin(PI * color.r) * bright;
    float g = color.g  + sin(PI * color.g) * bright;
    float b = color.b  + sin(PI * color.b) * bright;
    return vec4(r, g, b, color.a);
 }
 
 highp vec4 doLut(vec4 textureColor, sampler2D lutTexture, float intensity)
 {
     textureColor = clamp(textureColor, 0.0, 1.0);
     highp float blueColor = textureColor.b * 63.0;

     highp vec2 quad1;
     quad1.y = floor(floor(blueColor) / 8.0);
     quad1.x = floor(blueColor) - (quad1.y * 8.0);

     highp vec2 quad2;
     quad2.y = floor(ceil(blueColor) / 8.0);
     quad2.x = ceil(blueColor) - (quad2.y * 8.0);

     highp vec2 texPos1;
     texPos1.x = (quad1.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos1.y = (quad1.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

     highp vec2 texPos2;
     texPos2.x = (quad2.x * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.r);
     texPos2.y = (quad2.y * 0.125) + 0.5/512.0 + ((0.125 - 1.0/512.0) * textureColor.g);

     highp vec4 c1 = texture2D(lutTexture, texPos1);
     highp vec4 c2 = texture2D(lutTexture, texPos2);
     highp vec4 newColor = mix(c1, c2, fract(blueColor));
     return mix(textureColor, vec4(newColor.rgb, textureColor.w), intensity);
 }
 
 highp vec4 doLummask(highp vec4 textureColor, sampler2D curveTexture, float intensity)
 {
      highp float luminance = dot(textureColor.rgb, luminanceWeighting);
      highp vec3 greyScaleColor = vec3(luminance);

      luminance = 1.0 - luminance*luminance;

      highp float redCurveValue = texture2D(curveTexture, vec2(textureColor.r, 0.0)).r;
      highp float greenCurveValue = texture2D(curveTexture, vec2(textureColor.g, 0.0)).g;
      highp float blueCurveValue = texture2D(curveTexture, vec2(textureColor.b, 0.0)).b;

      highp vec4 curveColor = vec4(redCurveValue, greenCurveValue, blueCurveValue, textureColor.a);
      highp vec4 color = vec4(mix(greyScaleColor, curveColor.rgb, intensity), 1.0);

      highp vec3 result = mix(textureColor.rgb, color.rgb, luminance);
      return vec4(result, 1.0);
  }
 
 highp vec4 doToneCurve(highp vec4 textureColor, sampler2D curveTexture, float intensity)
 {
      highp float redCurveValue = texture2D(curveTexture, vec2(textureColor.r, 0.0)).r;
      highp float greenCurveValue = texture2D(curveTexture, vec2(textureColor.g, 0.0)).g;
      highp float blueCurveValue = texture2D(curveTexture, vec2(textureColor.b, 0.0)).b;

      highp vec4 color = vec4(redCurveValue, greenCurveValue, blueCurveValue, textureColor.a);

      highp float luminance = dot(textureColor.rgb, luminanceWeighting);
      highp vec3 greyScaleColor = vec3(luminance);

      return vec4(mix(greyScaleColor, color.rgb, intensity), 1.0);
  }
 
  void main()
  {
    highp vec4 textureColor = texture2D(inputImageTexture, textureCoordinate);
    if(brightnessIntensity > 0.0001 || brightnessIntensity < -0.0001) {
        textureColor = doBrightness(textureColor, brightnessIntensity);
    }
    
    if(lumMaskCurveIntensity > 0.0) {
        textureColor = doLummask(textureColor, lumMaskCurveTexture, lumMaskCurveIntensity);
    }
    if(lutIntensity > 0.0) {
        textureColor = doLut(textureColor, lutTexture, lutIntensity);
    }
    if(toneCurveIntensity > 0.0) {
        textureColor = doToneCurve(textureColor, toneCurveTexture, toneCurveIntensity);
    }
    gl_FragColor = textureColor;
  }
);

@interface BMWFliterDrawer()
{
    GLuint _lutTextureSlot;
    GLuint _lumMaskCurveTextureSlot;
    GLuint _toneCurveTextureSlot;
    
    GLuint _lutIntensitySlot;
    GLuint _brightnessIntensitySlot;
    GLuint _toneCurveIntensitySlot;
    GLuint _lumMaskCurveIntensitySlot;
}
@property (nonatomic) GLint inputTexId;
@property (nonatomic) GLint lutTexId;
@property (nonatomic) GLint lumMaskCurveTextureId;
@property (nonatomic) GLint toneCurveTextureId;

@property (nonatomic) float brightnessIntensity;
@property (nonatomic) float lutIntensity;
@property (nonatomic) float toneCurveIntensity;
@property (nonatomic) float lumMaskCurveIntensity;
@end

@implementation BMWFliterDrawer

- (instancetype)init
{
    if (self = [super init]) {
        _brightnessIntensity = 0.0;
        _lutIntensity = 0.0;
        _toneCurveIntensity = 1.0;
        _lumMaskCurveIntensity = 1.0;
    }
    return self;
}

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:nil fragmentShader:kFragmentString];
    
    _lutTextureSlot = [super getUniformLocation:@"lutTexture"];
    _lumMaskCurveTextureSlot = [super getUniformLocation:@"lumMaskCurveTexture"];
    _toneCurveTextureSlot = [super getUniformLocation:@"toneCurveTexture"];
    
    _brightnessIntensitySlot = [super getUniformLocation:@"brightnessIntensity"];
    _lutIntensitySlot = [super getUniformLocation:@"lutIntensity"];
    _toneCurveIntensitySlot = [super getUniformLocation:@"toneCurveIntensity"];
    _lumMaskCurveIntensitySlot = [super getUniformLocation:@"lumMaskCurveIntensity"];
}

- (void)prepare
{
    [super prepare];
    glActiveTexture(GL_TEXTURE1);
    glUniform1i(_lutTextureSlot, 1);
    glBindTexture(GL_TEXTURE_2D, _lutTexId);
    
    glActiveTexture(GL_TEXTURE2);
    glUniform1i(_lumMaskCurveTextureSlot, 2);
    glBindTexture(GL_TEXTURE_2D, _lumMaskCurveTextureId);
    
    glActiveTexture(GL_TEXTURE3);
    glUniform1i(_toneCurveTextureSlot, 3);
    glBindTexture(GL_TEXTURE_2D, _toneCurveTextureId);
    
    glUniform1f(_brightnessIntensitySlot, _brightnessIntensity);
    glUniform1f(_lutIntensitySlot, _lutTexId > 0 ? _lutIntensity : 0.0);
    glUniform1f(_toneCurveIntensitySlot, _toneCurveIntensity);
    glUniform1f(_lumMaskCurveIntensitySlot, _lumMaskCurveIntensity);
}

- (void)setInputTexId:(GLint)inputTexId;
{
    _inputTexId = inputTexId;
}

- (void)setLutTexId:(GLint)texId;
{
    _lutTexId = texId;
}

- (void)setLumMaskCurveTexId:(GLint)texId;
{
    _lumMaskCurveTextureId = texId;
}

- (void)setToneCurveTextId:(GLint)texId;
{
    _toneCurveTextureId = texId;
}

- (void)setLutIntensity:(float)intensity
{
    _lutIntensity = intensity;
}

- (void)setBrightnessIntensity:(float)intensity
{
    _brightnessIntensity = intensity;
}

- (void)setToneCurveIntensity:(float)intensity
{
    _toneCurveIntensity = intensity;
}

- (void)setLumMaskCurveIntensity:(float)intensity
{
    _lumMaskCurveIntensity = intensity;
}

- (void)draw
{
    [super drawWithTexId:_inputTexId];
}

@end
