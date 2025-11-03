#import "BMWUnsharpMaskDrawer.h"

static NSString* const kVertexString = SHADER_STRING
(
    attribute vec4 position;
    attribute vec4 inputTextureCoordinate;
    uniform mat4 mvpMatrix;
    uniform float texelWidth;
    uniform float texelHeight;
    varying vec2 blurCoordinates[9];
    void main()
    {
        vec2 singleStepOffset = vec2(texelWidth, texelHeight);
        blurCoordinates[0] = inputTextureCoordinate.xy;
        blurCoordinates[1] = inputTextureCoordinate.xy + singleStepOffset * vec2(1.0, 0.0);
        blurCoordinates[2] = inputTextureCoordinate.xy + singleStepOffset * vec2(-1.0, 0.0);
        blurCoordinates[3] = inputTextureCoordinate.xy + singleStepOffset * vec2(0.0, 1.0);
        blurCoordinates[4] = inputTextureCoordinate.xy + singleStepOffset * vec2(0.0, -1.0);
        blurCoordinates[5] = inputTextureCoordinate.xy + singleStepOffset * vec2(1.0, 1.0);
        blurCoordinates[6] = inputTextureCoordinate.xy + singleStepOffset * vec2(1.0, -1.0);
        blurCoordinates[7] = inputTextureCoordinate.xy + singleStepOffset * vec2(-1.0, 1.0);
        blurCoordinates[8] = inputTextureCoordinate.xy + singleStepOffset * vec2(-1.0, -1.0);
        gl_Position = mvpMatrix * position;
    }
 );

static NSString* const kFragmentString = SHADER_STRING
(
 precision highp float;
 const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 varying vec2 blurCoordinates[9];
 uniform float intensity;
 uniform float saturation;
 
  void main()
  {
    vec4 sum = vec4(0.0);
    sum += texture2D(inputImageTexture2, blurCoordinates[0]);
    sum += texture2D(inputImageTexture2, blurCoordinates[1]);
    sum += texture2D(inputImageTexture2, blurCoordinates[2]);
    sum += texture2D(inputImageTexture2, blurCoordinates[3]);
    sum += texture2D(inputImageTexture2, blurCoordinates[4]);
    sum += texture2D(inputImageTexture2, blurCoordinates[5]);
    sum += texture2D(inputImageTexture2, blurCoordinates[6]);
    sum += texture2D(inputImageTexture2, blurCoordinates[7]);
    sum += texture2D(inputImageTexture2, blurCoordinates[8]);
    
    // sharpen
    vec3 blurredImageColor = sum.rgb / 9.0;
    vec4 sharpImageColor = texture2D(inputImageTexture2, blurCoordinates[0]);
    vec3 highPass = sharpImageColor.rgb - blurredImageColor;
    vec4 currentColor = texture2D(inputImageTexture, blurCoordinates[0]);
    vec3 color = currentColor.rgb + highPass * intensity;
    
    // saturation
    float luminance = dot(sharpImageColor.rgb, luminanceWeighting);
    vec3 greyScaleColor = vec3(luminance);
    vec3 saturationColor = mix(greyScaleColor, color, saturation);
    
    gl_FragColor = vec4(saturationColor, 1.0);
  }
);

@interface BMWUnsharpMaskDrawer()
{
    GLuint _inputImageTexture2Slot;
    GLuint _intensitySlot;
    GLuint _saturationSlot;
    GLuint _texelWidthSlot;
    GLuint _texelHeightSlot;
}
@property (nonatomic) GLint inputTexId;
@property (nonatomic) GLint tex2Id;
@property (nonatomic) float intensity;
@property (nonatomic) float saturation;

@property (nonatomic) float texelWidth;
@property (nonatomic) float texelHeight;
@end

@implementation BMWUnsharpMaskDrawer

- (instancetype)init
{
    if (self = [super init]) {
        _intensity = 1.3;
        _saturation = 1.1;
    }
    return self;
}

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:kVertexString fragmentShader:kFragmentString];
    _inputImageTexture2Slot = [super getUniformLocation:@"inputImageTexture2"];
    _intensitySlot = [super getUniformLocation:@"intensity"];
    _saturationSlot = [super getUniformLocation:@"saturation"];
    _texelWidthSlot = [super getUniformLocation:@"texelWidth"];
    _texelHeightSlot = [super getUniformLocation:@"texelHeight"];
}

- (void)prepare
{
    [super prepare];
    glActiveTexture(GL_TEXTURE1);
    glUniform1i(_inputImageTexture2Slot, 1);
    glBindTexture(GL_TEXTURE_2D, _tex2Id);
    
    glUniform1f(_intensitySlot, _intensity);
    glUniform1f(_saturationSlot, _saturation);
    
    glUniform1f(_texelWidthSlot, _texelWidth);
    glUniform1f(_texelHeightSlot, _texelHeight);
}

- (void)setIntensity:(float)intensity saturation:(float)saturation
{
    _intensity = intensity;
    _saturation = saturation;
}

- (void)setInputSize:(CGSize)size
{
    _texelWidth = 1.0f/size.width;
    _texelHeight = 1.0f/size.height;
}

- (void)setInputTexId:(GLint)inputTexId tex2Id:(GLint)tex2Id
{
    _tex2Id = tex2Id;
    _inputTexId = inputTexId;
}

- (void)draw
{
    [super drawWithTexId:_inputTexId];
}

@end
