#import "BMWDctWmExtractDrawer.h"

static NSString* const kVertexString = SHADER_STRING
(
 attribute vec4 position;
 attribute vec4 inputTextureCoordinate;
 varying vec2 textureCoordinate;
 void main() {
     gl_Position = position;
     textureCoordinate = inputTextureCoordinate.xy * 0.125;
 }
);

static NSString* const kFragmentString = SHADER_STRING
(
 precision highp float;
 precision highp int;
 #define BLOCK 4
 #define SCALE 64.0
 #define USE_SVD 0
 #define ITER_NUM 30
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform float uWidth;
 uniform float uHeight;
 uniform int uWmBitsCount;
 const float THRESHOLD = 1e-8;
 
 const mat4 A = mat4(0.5000,   0.5000,   0.5000,   0.5000,
                      0.6533,   0.2706,  -0.2706,  -0.6533,
                      0.5000,  -0.5000,  -0.5000,   0.5000,
                      0.2706,  -0.6533,   0.6533,  -0.2706);

 const mat4 AT = mat4(0.5000,   0.6533,   0.5000,   0.2706,
                      0.5000,   0.2706,  -0.5000,  -0.6533,
                      0.5000,  -0.2706,  -0.5000,   0.6533,
                      0.5000,  -0.6533,   0.5000,  -0.2706);

 struct EVD {
    highp mat4 M;
    highp mat4 V;
 };
 
 struct SVD {
    highp mat4 U;
    highp mat4 S;
    highp mat4 V;
    highp float R;
 };
 
 highp mat4 transpose(highp mat4 inMatrix) {
    highp vec4 i0 = inMatrix[0];
    highp vec4 i1 = inMatrix[1];
    highp vec4 i2 = inMatrix[2];
    highp vec4 i3 = inMatrix[3];
    mat4 outMatrix = mat4(
        vec4(i0.x, i1.x, i2.x, i3.x),
        vec4(i0.y, i1.y, i2.y, i3.y),
        vec4(i0.z, i1.z, i2.z, i3.z),
        vec4(i0.w, i1.w, i2.w, i3.w)
        );
     return outMatrix;
  }

  float dotx(vec4 v1, vec4 v2) {
    return (v1.x * v2.x + v1.y * v2.y + v1.z * v2.z + v1.w * v2.w);
}
 
  float signx(float number)
 {
    if (number < 0.0) {
         return -1.0;
    } else {
         return 1.0;
     }
 }
 
 EVD jacobi(mat4 matrix) {
    mat4 V = mat4(1.0);
    int pass;
    vec4 Ci; vec4 Cj;
    float ele; float ele1; float ele2; float tao; float tan; float cos; float sin;
    for(int w = 0; w < ITER_NUM; w++) {
        pass = 1;
        for(int i = 0; i < 4; i++) {
            for(int j = i + 1; j < 4; j++) {
                Ci = matrix[i];
                Cj = matrix[j];
                ele = dotx(Ci, Cj);
                if(abs(ele) > THRESHOLD) {
                    pass = 0;
                    ele1 = dotx(Ci, Ci);
                    ele2 = dotx(Cj, Cj);
                    
                    if(ele1 < ele2) {
                        for(int row = 0; row < 4; ++row) {
                            matrix[i][row] = Cj[row];
                            matrix[j][row] = Ci[row];
                        }
                        for(int row = 0; row < 4; ++row) {
                            float tmp = V[i][row];
                            V[i][row] = V[j][row];
                            V[j][row] = tmp;
                        }
                    }
                    tao = (ele1 - ele2) / (2.0 * ele);
                    tan = signx(tao) / (abs(tao) + sqrt(1.0 + pow(tao, 2.0)));
                    cos = 1.0 / sqrt(1.0 + pow(tan, 2.0));
                    sin = cos * tan;
                   
                    for(int row = 0; row < 4; ++row) {
                         float var1 = matrix[i][row] * cos + matrix[j][row] * sin;
                         float var2 = matrix[j][row] * cos - matrix[i][row] * sin;
                        matrix[i][row] = var1;
                        matrix[j][row] = var2;
                    }
                    for(int col = 0; col < 4; ++col){
                         float var1 = V[i][col] * cos + V[j][col] * sin;
                         float var2 = V[j][col] * cos - V[i][col] * sin;
                        V[i][col] = var1;
                        V[j][col] = var2;
                    }
                }
            }
        }
        if(pass > 0) break;
    }
    return EVD(matrix, V);
 }

 SVD doSVD(mat4 A) {
    EVD d = jacobi(A);
    mat4 M = d.M;
    mat4 V = d.V;
    vec4 E = vec4(0.0);
    mat4 U = mat4(0.0);
    mat4 S = mat4(0.0);
    
    int none_zero = 0;        //记录非0奇异值的个数
    for (int i = 0; i < 4; ++i) {
     float norm = sqrt(dotx(M[i], M[i]));
      if(norm > THRESHOLD){
          none_zero++;
      }
      E[i] = norm;
    }
    /**
     * U矩阵的后(rows-none_zero)列以及V的后(columns-none_zero)列就不计算了，采用默认值0。
     * 对于奇异值分解A=U*Sigma*V^T，我们只需要U的前r列，V^T的前r行（即V的前r列），就可以恢复A了。r是A的秩
     */
     for(int row = 0; row < 4; ++row){
         S[row][row] = E[row];
         for(int col=0; col < none_zero; ++col) {
             if(E[col] > 0.0) {
                 U[col][row] = M[col][row] / E[col];
             }
         }
     }
    return SVD(U, S, V, float(none_zero));
 }
 
// const vec4 bitEnc = vec4(1.0,255.0,65025.0,16581375.0);
// const vec4 bitDec = 1.0/bitEnc;
// vec4 encodeColor (float v) {
//     vec4 enc = bitEnc * v;
//     enc = fract(enc);
//     enc -= enc.yzww * vec2(1.0/255.0, 0.0).xxxy;
//     return enc;
// }
// float decodeColor (vec4 v) {
//     return dot(v, bitDec);
// }
 
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
    float xfpos = uWidth * textureCoordinate.x * 4.0;
    float yfpos = uHeight * textureCoordinate.y * 4.0;
    float xoffset = 1.0 / uWidth;
    float yoffset = 1.0 / uHeight;

    int xipos = int(xfpos / float(BLOCK)) * BLOCK;
    int xindex = int(xfpos - float(xipos));
    float x = float(xipos) / uWidth;
    int ppx = xipos / BLOCK;

    int yipos = int(yfpos / float(BLOCK)) * BLOCK;
    int yindex = int(yfpos - float(yipos));
    float y = float(yipos) / uHeight;
    int ppy = yipos / BLOCK;
    
    x = clamp(x + xoffset/2.0, 0.0, 1.0);
    y = clamp(y + yoffset/2.0, 0.0, 1.0);
    
    mat4 f;
    vec2 uv0; vec2 uv1; vec2 uv2; vec2 uv3;
    float yy;
    for(int i = 0; i < BLOCK; i++) {
        yy = y + float(i) * yoffset;
        uv0 = vec2(x, yy);
        uv1 = vec2(x+xoffset, yy);
        uv2 = vec2(x+xoffset*2.0, yy);
        uv3 = vec2(x+xoffset*3.0, yy);
        f[i][0] = decodeColor(texture2D(inputImageTexture, uv0)) * 255.0;
        f[i][1] = decodeColor(texture2D(inputImageTexture, uv1)) * 255.0;
        f[i][2] = decodeColor(texture2D(inputImageTexture, uv2)) * 255.0;
        f[i][3] = decodeColor(texture2D(inputImageTexture, uv3)) * 255.0;
    }
    
    mat4 dct = AT * f * A;
    int score = 0;
#if USE_SVD
    SVD svd = doSVD(dct);
    if(float(int(mod(svd.S[0][0], SCALE))) > SCALE * 0.5) {
       score = 1;
    }
#else
//    score = int ((dct[0][0] % scale) > scale * 0.5)
   if(float(int(mod(dct[0][0], SCALE))) > SCALE * 0.5) {
      score = 1;
   }
#endif
   gl_FragColor = vec4(float(score), float(score), float(score), 1.0);
 }
);

@interface BMWDctWmExtractDrawer ()
{
    GLuint _widthSlot;
    GLuint _heightSlot;
    GLuint _wmBitsCountSlot;
}
@property (nonatomic) int width;
@property (nonatomic) int height;
@property (nonatomic) int wmBitsCount;
@end

@implementation BMWDctWmExtractDrawer

- (void)destory
{
}

- (instancetype)init:(CGSize)size
{
    if (self = [super init]) {
        self.width = (int)size.width;
        self.height = (int)size.height;
    }
    return self;
}

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:kVertexString fragmentShader:kFragmentString];
    _wmBitsCountSlot = [super getUniformLocation:@"uWmBitsCount"];
    _widthSlot = [super getUniformLocation:@"uWidth"];
    _heightSlot = [super getUniformLocation:@"uHeight"];
}

- (void)prepare
{
    [super prepare];
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



