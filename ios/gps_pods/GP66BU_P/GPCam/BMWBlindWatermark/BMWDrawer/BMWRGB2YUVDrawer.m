#import "BMWRGB2YUVDrawer.h"

static NSString* const kFragmentString = SHADER_STRING
(
 precision highp float;
 precision highp int;
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 void main()
 {
    vec3 rgb = texture2D(inputImageTexture, textureCoordinate).rgb;
    float y = 0.298355*rgb.r + 0.587478*rgb.g + 0.114167*rgb.b;
    float u = -0.169040*rgb.r - 0.332849*rgb.g + 0.501888*rgb.b + 0.5;
    float v = 0.501175*rgb.r - 0.419627*rgb.g - 0.081548*rgb.b + 0.5;
    gl_FragColor = vec4(u, 0, 0, 1.0);
 }
);

@interface BMWRGB2YUVDrawer ()
{
}
@end

@implementation BMWRGB2YUVDrawer

- (void)destory
{
}

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:nil fragmentShader:kFragmentString];
}

- (void)renderTextureId:(GLuint)texId vertices:(const GLfloat *)vertices
{
    [super drawWithTexId:texId vertices:vertices rotation:kXHImageNoRotation];
}

@end

