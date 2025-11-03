#import "BMWNightModeDrawer.h"
#import "BMWGLUtils.h"

static NSString* const kFragmentString = SHADER_STRING
(
 varying highp vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D maskTexture;
 uniform highp mat3 colorConversionMatrix;
 uniform highp int useYUV;

 highp vec4 yuv2rgb()
 {
    highp vec3 yuv;
    yuv.x = texture2D(inputImageTexture, textureCoordinate).r;
    yuv.yz = texture2D(inputImageTexture2, textureCoordinate).ra - vec2(0.5, 0.5);
    return vec4(colorConversionMatrix * yuv, 1.0);
 }

 void main()
 {
    highp vec4 textureColor;
    if(useYUV > 0) {
        textureColor = yuv2rgb();
    } else {
        textureColor = texture2D(inputImageTexture, textureCoordinate);
    }

    highp vec2 offset = vec2(0.333333, 0.333333);

    highp vec2 uv1 = textureCoordinate * offset;
    highp vec2 uv2 = uv1 + offset * vec2(1.0, 0.0);
    highp vec2 uv3 = uv1 + offset * vec2(2.0, 0.0);

    highp vec2 uv4 = uv1 + offset * vec2(0.0, 1.0);
    highp vec2 uv5 = uv1 + offset * vec2(1.0, 1.0);
    highp vec2 uv6 = uv1 + offset * vec2(2.0, 1.0);

    highp vec2 uv7 = uv1 + offset * vec2(0.0, 2.0);
    highp vec2 uv8 = uv1 + offset * vec2(1.0, 2.0);
    highp vec2 uv9 = uv1 + offset * vec2(2.0, 2.0);

    highp vec3 alpha = vec3(2.0, 2.0, 2.0);
    highp vec3 beta = vec3(1.0, 1.0, 1.0);
    highp vec3 r1 = texture2D(maskTexture,uv1).rgb * alpha - beta;
    highp vec3 r2 = texture2D(maskTexture,uv2).rgb * alpha - beta;
    highp vec3 r3 = texture2D(maskTexture,uv3).rgb * alpha - beta;
    highp vec3 r4 = texture2D(maskTexture,uv4).rgb * alpha - beta;
    highp vec3 r5 = texture2D(maskTexture,uv5).rgb * alpha - beta;
    highp vec3 r6 = texture2D(maskTexture,uv6).rgb * alpha - beta;
    highp vec3 r7 = texture2D(maskTexture,uv7).rgb * alpha - beta;
    highp vec3 r8 = texture2D(maskTexture,uv8).rgb * alpha - beta;

    highp vec3 x = textureColor.rgb;
    x = x + r1 * (pow(x,alpha) - x);
    x = x + r2 * (pow(x,alpha) - x);
    x = x + r3 * (pow(x,alpha) - x);
    x = x + r4 * (pow(x,alpha) - x);
    x = x + r5 * (pow(x,alpha) - x);
    x = x + r6 * (pow(x,alpha) - x);
    gl_FragColor = vec4(x, 1.0);
 }
);

extern GLfloat* ITU_601_MATRIX;
extern GLfloat* ITU_709_MATRIX;

@interface BMWNightModeDrawer()
{
    GLuint _inputImageTexture2Slot;
    GLuint _colorConversionMatrixSlot;
    GLuint _maskTextureSlot;
    GLuint _useYUVSlot;
    GLfloat _colorConversionMatrix[9];
}
@property (nonatomic) BOOL useYUV;
@property (nonatomic) BMWImageContext *imageContext;
@property (nonatomic) GLint inputImageTextureId;
@property (nonatomic) GLint inputImageTexture2Id;
@property (nonatomic) GLint maskTexId;
@end

@implementation BMWNightModeDrawer

- (void)destory
{
    [super destory];
    if (_inputImageTextureId > 0) {
        glDeleteTextures(1, &_inputImageTextureId);
    }
    if (_inputImageTexture2Id > 0) {
        glDeleteTextures(1, &_inputImageTexture2Id);
    }
}

- (instancetype)initWithContext:(BMWImageContext *)imageContext useYUV:(BOOL)useYUV;
{
    self.useYUV = useYUV;
    if (self = [super init]) {
        self.imageContext = imageContext;
    }
    return self;
}

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    [super setupProgram:nil fragmentShader:kFragmentString];
    _inputImageTexture2Slot = [super getUniformLocation:@"inputImageTexture2"];
    _maskTextureSlot = [super getUniformLocation:@"maskTexture"];
    _colorConversionMatrixSlot = [super getUniformLocation:@"colorConversionMatrix"];
    _useYUVSlot = [super getUniformLocation:@"useYUV"];
}

- (void)prepare
{
    [super prepare];

    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _inputImageTexture2Id);
    glUniform1i(_inputImageTexture2Slot, 1);

    glActiveTexture(GL_TEXTURE2);
    glBindTexture(GL_TEXTURE_2D, _maskTexId);
    glUniform1i(_maskTextureSlot, 2);

    glUniform1i(_useYUVSlot, _useYUV);

    glUniformMatrix3fv(_colorConversionMatrixSlot, 1, GL_FALSE, _colorConversionMatrix);
}

- (void)clearup
{
    [super clearup];
}

- (void)setColorConversionMatrix:(CFStringRef)matrix
{
    memcpy(_colorConversionMatrix, [BMWBaseDrawer ColorConversionMatrix:matrix], sizeof(GLfloat) * 9);
}

- (void)setInputPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
     if (self.useYUV) {
        [self setupYUVTexture:pixelBuffer];
    } else {
       _inputImageTextureId = [BMWGLUtils createTextureWithBuffer:pixelBuffer context:self.imageContext];
    }
}

- (void)setupYUVTexture:(CVPixelBufferRef)pixelBuffer
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    CFTypeRef colorAttachments = CVBufferGetAttachment(pixelBuffer, kCVImageBufferYCbCrMatrixKey, NULL);

    [self setColorConversionMatrix:colorAttachments];

    CVOpenGLESTextureRef inputImageTextureRef = NULL;
    CVOpenGLESTextureRef inputImageTexture2Ref = NULL;
    CVReturn ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.imageContext.coreVideoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_LUMINANCE, width, height, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &inputImageTextureRef);
    if (ret != noErr) {
                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return;
    }

    ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.imageContext.coreVideoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_LUMINANCE_ALPHA, width / 2, height / 2, GL_LUMINANCE_ALPHA, GL_UNSIGNED_BYTE, 1, &inputImageTexture2Ref);
    if (ret != noErr) {
                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return;
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    _inputImageTextureId = CVOpenGLESTextureGetName(inputImageTextureRef);
    glBindTexture(GL_TEXTURE_2D, _inputImageTextureId);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);

    _inputImageTexture2Id = CVOpenGLESTextureGetName(inputImageTexture2Ref);
    glBindTexture(GL_TEXTURE_2D, _inputImageTexture2Id);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);

    if (inputImageTextureRef) {
        CFRelease(inputImageTextureRef);
    }
    if (inputImageTexture2Ref) {
        CFRelease(inputImageTexture2Ref);
    }
}

- (void)setMaskTexId:(GLint)maskTexId;
{
    _maskTexId = maskTexId;
}

- (void)draw
{
    [super drawWithTexId:_inputImageTextureId];
}

@end
