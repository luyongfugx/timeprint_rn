#import "BMWSharpenDrawer.h"

static NSString* const kVertexString = SHADER_STRING
(
 precision highp float;
    attribute vec4 position;
    attribute vec4 inputTextureCoordinate;
    uniform mat4 mvpMatrix;
    uniform float texelWidth;
    uniform float texelHeight;
    varying vec2 blurCoordinates[5];
    void main()
    {
        vec2 stepOffset = vec2(texelWidth, texelHeight);
        blurCoordinates[0] = inputTextureCoordinate.xy;
        blurCoordinates[1] = inputTextureCoordinate.xy + stepOffset * vec2(1.0, 0.0);
        blurCoordinates[2] = inputTextureCoordinate.xy + stepOffset * vec2(-1.0, 0.0);
        blurCoordinates[3] = inputTextureCoordinate.xy + stepOffset * vec2(0.0, 1.0);
        blurCoordinates[4] = inputTextureCoordinate.xy + stepOffset * vec2(0.0, -1.0);
        gl_Position = mvpMatrix * position;
    }
 );

static NSString* const kFragmentString = SHADER_STRING
(
 precision highp float;
 const float delta = 0.1;
 const vec4 valueRange = vec4(0.2, 0.5, 0.9, 0.9);
 const vec4 blurRange = vec4(1.0, 0.9, 0.5, 0.08);
 const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform float sharpenIntensity;
 uniform float saturationIntensity;
 varying vec2 blurCoordinates[5];
 void main()
 {
    vec4 inputColor = texture2D(inputImageTexture, blurCoordinates[0]);
    vec4 meanColor = texture2D(inputImageTexture2, blurCoordinates[0]);

    float p = clamp((min(inputColor.r, meanColor.r - 0.1) - 0.2) * 4.0, 0.0, 1.0);
    float m = meanColor.a;
    float k = (1.0 - m / (m + delta)) * p * 0.2;
    if(k > 1.0 - valueRange.x) {
        k = k * blurRange.x;
    } else if(k > 1.0 - valueRange.y) {
        k = k * blurRange.y;
    } else if(k > 1.0 - valueRange.z) {
        k = k * blurRange.z;
    } else {
        k = k * blurRange.w;
    }
    vec3 resultColor = mix(inputColor.rgb, meanColor.rgb, k);
    
    float g = 0.0;
    g += texture2D(inputImageTexture, blurCoordinates[1]).g;
    g += texture2D(inputImageTexture, blurCoordinates[2]).g;
    g += texture2D(inputImageTexture, blurCoordinates[3]).g;
    g += texture2D(inputImageTexture, blurCoordinates[4]).g;
    g *= 0.25;
    
    float highPass = inputColor.g - g + 0.5;
    float flag = step(0.5, highPass);
    vec3 highpassColor = resultColor + vec3(2.0 * highPass - 1.0);
    vec3 finalColor = mix(max(vec3(0.0), highpassColor), min(vec3(1.0), highpassColor), flag);
    vec3 sharpImageColor = mix(resultColor.rgb, finalColor.rgb, sharpenIntensity);
    
    float luminance = dot(sharpImageColor.rgb, luminanceWeighting);
    vec3 greyScaleColor = vec3(luminance);
    vec3 color = mix(greyScaleColor, sharpImageColor, saturationIntensity);
    gl_FragColor = vec4(color, 1.0);
  }
);

@interface BMWSharpenDrawer()
{
    GLuint _inputImageTexture2Slot;
    GLuint _sharpenIntensitySlot;
    GLuint _saturationIntensitySlot;
    GLuint _texelWidthSlot;
    GLuint _texelHeightSlot;
}
@property (nonatomic) GLint inputTexId;
@property (nonatomic) GLint tex2Id;
@property (nonatomic) float sharpenIntensity;
@property (nonatomic) float saturationIntensity;

@property (nonatomic) float texelWidth;
@property (nonatomic) float texelHeight;
@end

@implementation BMWSharpenDrawer

- (instancetype)init
{
    if (self = [super init]) {
        _sharpenIntensity = 0.5;
        _saturationIntensity = 1.1;
    }
    return self;
}

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:kVertexString fragmentShader:kFragmentString];
    _inputImageTexture2Slot = [super getUniformLocation:@"inputImageTexture2"];
    _sharpenIntensitySlot = [super getUniformLocation:@"sharpenIntensity"];
    _saturationIntensitySlot = [super getUniformLocation:@"saturationIntensity"];
    _texelWidthSlot = [super getUniformLocation:@"texelWidth"];
    _texelHeightSlot = [super getUniformLocation:@"texelHeight"];
}

- (void)prepare
{
    [super prepare];
    glActiveTexture(GL_TEXTURE1);
    glUniform1i(_inputImageTexture2Slot, 1);
    glBindTexture(GL_TEXTURE_2D, _tex2Id);
    glUniform1f(_sharpenIntensitySlot, _sharpenIntensity);
    glUniform1f(_saturationIntensitySlot, _saturationIntensity);
    glUniform1f(_texelWidthSlot, _texelWidth);
    glUniform1f(_texelHeightSlot, _texelHeight);
}

- (void)setIntensity:(float)sharpen saturation:(float)saturation
{
    _sharpenIntensity = sharpen;
    _saturationIntensity = saturation;
}

- (void)setInputSize:(CGSize)size
{
    _texelWidth = 1.0f / size.width;
    _texelHeight = 1.0f / size.height;
}

- (void)setInputTexId:(GLint)inputTexId tex2Id:(GLint)tex2Id
{
    _inputTexId = inputTexId;
    _tex2Id = tex2Id;
}

- (void)draw
{
    [super drawWithTexId:_inputTexId];
}

@end
