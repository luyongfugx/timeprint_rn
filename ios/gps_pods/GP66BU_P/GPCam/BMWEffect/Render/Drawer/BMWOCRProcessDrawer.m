#import "BMWOCRProcessDrawer.h"

static NSString* const kFragmentString = SHADER_STRING
(
    precision highp float;
    varying highp vec2 textureCoordinate;
    uniform sampler2D inputImageTexture;
    uniform float contrationIntensity;
    uniform float brightnessIntensity;
    const vec3 luminanceWeighting = vec3(0.2125, 0.7154, 0.0721);

    vec3 adjustBrightness(vec3 color, float value)
    {
        return clamp(color + value, 0.0, 1.0);
    }

    vec3 adjustcontration(vec3 color, float value)
    {
        float luminance = dot(color, luminanceWeighting);
        vec3 greyScaleColor = vec3(luminance);
        return mix(greyScaleColor, color, value);
     }

    void main()
    {
        vec4 color = texture2D(inputImageTexture, textureCoordinate);
        vec3 c1 = adjustcontration(color.rgb, contrationIntensity);
        vec3 c2 = adjustBrightness(c1, brightnessIntensity);
        gl_FragColor = vec4(c2.rgb, 1.0);
    }
 );


@interface BMWOCRProcessDrawer()
{
    GLuint _contrationIntensitySlot;
    GLuint _brightnessIntensitySlot;
}
@property (nonatomic) float contrationIntensity;
@property (nonatomic) float brightnessIntensity;

@end

@implementation BMWOCRProcessDrawer

+ (void)load
{
    [[NSUserDefaults standardUserDefaults] setFloat:0.0f forKey:@"ocr_contration_key"];
    [[NSUserDefaults standardUserDefaults] setFloat:-0.62f forKey:@"ocr_brightness_key"];
}

- (instancetype)init
{
    if (self = [super init]) {
        _contrationIntensity = [[NSUserDefaults standardUserDefaults] floatForKey:@"ocr_contration_key"];
        _brightnessIntensity = [[NSUserDefaults standardUserDefaults] floatForKey:@"ocr_brightness_key"];
    }
    return self;
}

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:nil fragmentShader:kFragmentString];
    _brightnessIntensitySlot = [super getUniformLocation:@"brightnessIntensity"];
    _contrationIntensitySlot = [super getUniformLocation:@"contrationIntensity"];
}

- (void)prepare
{
    [super prepare];
    glUniform1f(_contrationIntensitySlot, _contrationIntensity);
    glUniform1f(_brightnessIntensitySlot, _brightnessIntensity);
}

- (void)setContrationIntensity:(float)intensity
{
    _contrationIntensity = intensity;
}

- (void)setBrightnessIntensity:(float)intensity
{
    _brightnessIntensity = intensity;
}

@end
