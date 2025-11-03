#import "BMWWmMergeDrawer2.h"

static NSString* const kFragmentString = SHADER_STRING
(
 precision highp float;
 precision highp int;
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform vec2 uwmSize;
 uniform float uWidth;
 uniform float uHeight;
 
 void main()
 {
    int width = int(uWidth / uwmSize.x);
    int height = int(uHeight / uwmSize.y);
    float xfpos = textureCoordinate.x / float(width);
    float yfpos = textureCoordinate.y / float(height);
    
    float color = 0.0; vec2 uv;
    for(int col = 0; col < width; col++) {
        for(int row = 0; row < height; row++) {
            uv = vec2(xfpos + float(col)/float(width), yfpos + float(row)/float(height));
            color += texture2D(inputImageTexture, uv).r;
        }
    }
    color = color / float(width*height);
    float bit = 0.0;
    if(color > 0.5) {
        bit = 1.0;
    }
   gl_FragColor = vec4(bit, bit, bit, 1.0);
 }
);

@interface BMWWmMergeDrawer2 ()
{
    GLuint _wmSizeSlot;
    GLuint _widthSlot;
    GLuint _heightSlot;
}
@property (nonatomic) CGSize wmSize;
@property (nonatomic) int width;
@property (nonatomic) int height;
@end

@implementation BMWWmMergeDrawer2

- (void)destory
{
}

- (instancetype)init:(CGSize)size wmSize:(CGSize)wmSize
{
    if (self = [super init]) {
        self.width = (int)size.width;
        self.height = (int)size.height;
        self.wmSize = wmSize;
    }
    return self;
}

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:nil fragmentShader:kFragmentString];
    _wmSizeSlot = [super getUniformLocation:@"uwmSize"];
    _widthSlot = [super getUniformLocation:@"uWidth"];
    _heightSlot = [super getUniformLocation:@"uHeight"];
}

- (void)prepare
{
    [super prepare];
    glUniform2f(_wmSizeSlot, _wmSize.width, _wmSize.height);
    glUniform1f(_widthSlot, _width);
    glUniform1f(_heightSlot, _height);
}

@end
