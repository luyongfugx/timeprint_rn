#import "BMWWmMergeDrawer.h"

static NSString* const kFragmentString = SHADER_STRING
(
 precision highp float;
 precision highp int;
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform float uwmSize;
 uniform float uWidth;
 uniform float uHeight;
 uniform int uWmBitsCount;
 
 void main()
 {
    float xoffset = 1.0 / uWidth;
    float yoffset = 1.0 / uHeight;
    float xfpos = uwmSize * textureCoordinate.x;
    float yfpos = uwmSize * textureCoordinate.y;
    int xpos = int(xfpos);
    int ypos = int(yfpos);
    int pos = ypos*int(uwmSize) + xpos;
    
    float value = 0.0;
    float sum = 0.0;
    int num = 0; int row; int col; int p; float bit;
    vec2 uv;
    if(pos < uWmBitsCount / 8) {
        for(int i = 0; i < 8; i++) {
            num = 0; sum = 0.0;
            while (float(i+pos*8+uWmBitsCount*num) < uWidth*uHeight) {
                p = i+pos*8+uWmBitsCount*num;
                row = p / int(uWidth);
                col = int(mod(float(p), uWidth));
                
                uv = vec2(float(col)/uWidth+xoffset/2.0, float(row)/uHeight+yoffset/2.0);
                
                sum = sum + texture2D(inputImageTexture, uv).r;
                
                num++;
            }
            sum = sum / float(num);
            bit = 0.0;
            if(sum > 0.5) {
                bit = 1.0;
            }
            value = (value*2.0+bit);
        }
    }
   gl_FragColor = vec4(value/255.0, 0.0, 0.0, 1.0);
 }
);

@interface BMWWmMergeDrawer ()
{
    GLuint _wmSizeSlot;
    GLuint _widthSlot;
    GLuint _heightSlot;
    GLuint _wmBitsCountSlot;
}
@property (nonatomic) int wmSize;
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) int wmBitsCount;
@end

@implementation BMWWmMergeDrawer

- (void)destory
{
}

- (instancetype)init:(CGSize)size wmSize:(int)wmSize
{
    if (self = [super init]) {
        self.width = (int)size.width;
        self.height = (int)size.height;
        self.wmSize = (int)wmSize;
    }
    return self;
}

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:nil fragmentShader:kFragmentString];
    _wmSizeSlot = [super getUniformLocation:@"uwmSize"];
    _widthSlot = [super getUniformLocation:@"uWidth"];
    _heightSlot = [super getUniformLocation:@"uHeight"];
    _wmBitsCountSlot = [super getUniformLocation:@"uWmBitsCount"];
}

- (void)prepare
{
    [super prepare];
    glUniform1f(_wmSizeSlot, _wmSize);
    glUniform1f(_widthSlot, _width);
    glUniform1f(_heightSlot, _height);
    glUniform1i(_wmBitsCountSlot, _wmBitsCount);
}

- (void)renderTextureId:(GLuint)texId wmBitsCount:(int)wmBitsCount vertices:(const GLfloat *)vertices
{
    _wmBitsCount = wmBitsCount;
    [super drawWithTexId:texId vertices:vertices rotation:kXHImageNoRotation];
}

@end



