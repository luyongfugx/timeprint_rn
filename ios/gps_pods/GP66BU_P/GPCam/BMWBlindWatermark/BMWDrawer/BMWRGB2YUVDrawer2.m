#import "BMWRGB2YUVDrawer2.h"

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
    y = clamp(y, 0.0, 1.0);
    gl_FragColor = vec4(y, y, y, 1.0);
 }
);

@interface BMWRGB2YUVDrawer2 ()
{
}
@end

@implementation BMWRGB2YUVDrawer2

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

