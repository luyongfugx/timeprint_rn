#import "BMWLaplacianDrawer.h"

static NSString* const kFragmentString = SHADER_STRING
(
 precision highp float;
 uniform sampler2D inputImageTexture;
 uniform vec2 textureSize;
 varying vec2 textureCoordinate;

 void main() {
    vec2 offset = vec2(1.0, 1.0) / textureSize;
    float edge = 0.0;
    edge += texture2D(inputImageTexture, textureCoordinate + offset * vec2(-1, -1)).r * -1.0;
    edge += texture2D(inputImageTexture, textureCoordinate + offset * vec2(0, -1)).r * -1.0;
    edge += texture2D(inputImageTexture, textureCoordinate + offset * vec2(1, -1)).r * -1.0;
    edge += texture2D(inputImageTexture, textureCoordinate + offset * vec2(-1, 0)).r * -1.0;
    edge += texture2D(inputImageTexture, textureCoordinate + offset * vec2(0, 0)).r * 8.0;
    edge += texture2D(inputImageTexture, textureCoordinate + offset * vec2(1, 0)).r * -1.0;
    edge += texture2D(inputImageTexture, textureCoordinate + offset * vec2(-1, 1)).r * -1.0;
    edge += texture2D(inputImageTexture, textureCoordinate + offset * vec2(0, 1)).r * -1.0;
    edge += texture2D(inputImageTexture, textureCoordinate + offset * vec2(1, 1)).r * -1.0;
    edge = abs(edge);
    edge = clamp(edge, 0.0, 1.0);
    gl_FragColor = vec4(edge, edge, edge, 1.0);
 }
);


@interface BMWLaplacianDrawer()
{
    GLuint _textureSizeSlot;
}

@end

@implementation BMWLaplacianDrawer

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:nil fragmentShader:kFragmentString];
    _textureSizeSlot = [super getUniformLocation:@"textureSize"];
}

- (void)prepare
{
    [super prepare];
    glUniform2f(_textureSizeSlot, _inputSize.width, _inputSize.height);
}

@end
