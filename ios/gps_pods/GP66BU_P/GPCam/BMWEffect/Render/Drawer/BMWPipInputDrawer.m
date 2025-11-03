#import "BMWPipInputDrawer.h"
#import "BMWGLUtils.h"

static NSString* const kFragmentString = SHADER_STRING
(
 precision highp float;
 varying vec2 textureCoordinate;
 uniform sampler2D inputImageTexture;
 uniform sampler2D inputImageTexture2;
 uniform sampler2D maskTexture;
 uniform mat3 colorConversionMatrix;
 uniform int linearP3;
 uniform int useMask;
 const mat3 linearP3ToLinearSRGBMatrix = mat3(
     1.2249,     -0.2249,    0.0,
     -0.042056,  1.0421,     0.0,
     -0.019638,  -0.078637,  1.0983);
 const vec4 bgColor = vec4(0.0);

 uniform int enableBorder;
 uniform vec4 borderColor;
 uniform float borderWidth;
 uniform float radius;
 uniform vec2 resolution;
// ref：https://www.shadertoy.com/view/fsdyzB
 float roundedBoxSDF(vec2 centerPosition, vec2 size, vec4 radius)
 {
    radius.xy = (centerPosition.x > 0.0) ? radius.xy : radius.zw;
    radius.x  = (centerPosition.y > 0.0) ? radius.x  : radius.y;
    vec2 q = abs(centerPosition)-size+radius.x;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - radius.x;
 }

 vec4 border(vec4 fragColor, vec2 fragCoord)
 {
    vec2 rectSize = resolution.xy;     // The pixel-space scale of the rectangle.
    vec2 rectCenter = (resolution.xy / 2.0); // The pixel-space rectangle center location

    vec4  colorRect = fragColor; // The color of rectangle
    vec4  colorBorder = borderColor; // The color of (internal) border
    vec4  colorShadow = vec4(0.0); // The color of shadow
    vec4  colorBg = vec4(0.0); // The color of background

    // Corner
    float edgeSoftness = 2.0; // How soft the edges should be (in pixels). Higher values could be used to simulate a drop shadow.
    vec4 cornerRadiuses = vec4(radius, radius, radius, radius); // The radiuses of the corners(in pixels): [topRight, bottomRight, topLeft, bottomLeft]

    // Border
    float borderThickness = borderWidth; // The border size (in pixels)
    float borderSoftness = 2.0; // How soft the (internal) border should be (in pixels)

    // Shadow
    float shadowSoftness = 0.0;            // The (half) shadow radius (in pixels)
    vec2  shadowOffset = vec2(0.0, 0.0); // The pixel-space shadow offset from rectangle center

    vec2 halfSize = (rectSize / 2.0); // Rectangle extents (half of the size)
    vec4 radius = cornerRadiuses; // Animated corners radiuses
    float distance = roundedBoxSDF(fragCoord.xy - rectCenter, halfSize, radius);
    float smoothedAlpha = 1.0-smoothstep(0.0, edgeSoftness, distance);
    float borderAlpha = 1.0-smoothstep(borderThickness - borderSoftness, borderThickness, abs(distance));
    float shadowDistance = roundedBoxSDF(fragCoord.xy - rectCenter + shadowOffset, halfSize, radius);
    float shadowAlpha = 1.0-smoothstep(-shadowSoftness, shadowSoftness, shadowDistance);

    // Apply colors layer-by-layer: background <- shadow <- rect <- border.
    // Blend background with shadow
    vec4 res_shadow_color = mix(colorBg, vec4(colorShadow.rgb, shadowAlpha), shadowAlpha);

    // Blend (background+shadow) with rect
    vec4 res_shadow_with_rect_color = mix(res_shadow_color, colorRect, min(colorRect.a, smoothedAlpha));

    // Blend (background+shadow+rect) with border
    vec4 res_shadow_with_rect_with_border = mix(res_shadow_with_rect_color, colorBorder, min(colorBorder.a, min(borderAlpha, smoothedAlpha)) );
     return res_shadow_with_rect_with_border;
 }

 void main()
 {
    vec3 yuv;
    vec3 rgb;
    yuv.x = texture2D(inputImageTexture, textureCoordinate).r;
    yuv.yz = texture2D(inputImageTexture2, textureCoordinate).ra - vec2(0.5, 0.5);
    rgb = colorConversionMatrix * yuv;
    if(linearP3 > 0) {
        rgb = rgb * linearP3ToLinearSRGBMatrix;
    }
    float alpha = 1.0;
    if(useMask > 0) {
        alpha = texture2D(maskTexture, textureCoordinate).r;
    }
    vec4 outColor = vec4(rgb, 1.0);
    outColor = bgColor * (1.0 - alpha) + outColor * (alpha);
    if(enableBorder > 0) {
        vec2 pos = textureCoordinate * resolution;
        outColor = border(outColor, pos);
    }
    gl_FragColor = outColor;
 }
);

@interface BMWPipInputDrawer()
{
    GLuint _inputImageTexture2Slot;
    GLuint _maskTextureSlot;
    GLuint _useMaskSlot;
    GLuint _linearP3Slot;
    GLuint _colorConversionMatrixSlot;
    GLfloat _colorConversionMatrix[9];
    GLuint _enableBorderSlot;
    GLuint _borderColorSlot;
    GLuint _borderWidthSlot;
    GLuint _radiusSlot;
    GLuint _resolutionSlot;

}
@property (nonatomic) BOOL useYUV;
@property (nonatomic) BMWImageContext *imageContext;
@property (nonatomic) GLint inputImageTextureId;
@property (nonatomic) GLint inputImageTexture2Id;
@property (nonatomic) BOOL linearP3;
@property (nonatomic) BOOL enableMask;
@property (nonatomic) GLint maskTextureId;

@property (nonatomic) int enableBorder;
@property (nonatomic) UIColor *borderColor;
@property (nonatomic) float borderWidth;
@property (nonatomic) float radius;
@property (nonatomic) CGSize resolution;
@end

@implementation BMWPipInputDrawer

- (void)destory
{
    [super destory];
    if (_inputImageTextureId > 0) {
        glDeleteTextures(1, &_inputImageTextureId);
    }
    if (_inputImageTexture2Id > 0) {
        glDeleteTextures(1, &_inputImageTexture2Id);
    }
    if (_maskTextureId > 0) {
        glDeleteTextures(1, &_maskTextureId);
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
    [super setupProgram:nil fragmentShader:self.useYUV ? kFragmentString : nil];
    _inputImageTexture2Slot = [super getUniformLocation:@"inputImageTexture2"];
    _colorConversionMatrixSlot = [super getUniformLocation:@"colorConversionMatrix"];
    _linearP3Slot = [super getUniformLocation:@"linearP3"];
    _maskTextureSlot = [super getUniformLocation:@"maskTexture"];
    _useMaskSlot = [super getUniformLocation:@"useMask"];

    _enableBorderSlot = [super getUniformLocation:@"enableBorder"];
    _borderColorSlot = [super getUniformLocation:@"borderColor"];
    _borderWidthSlot = [super getUniformLocation:@"borderWidth"];
    _radiusSlot = [super getUniformLocation:@"radius"];
    _resolutionSlot = [super getUniformLocation:@"resolution"];
}

- (void)prepare
{
    [super prepare];
    glEnable(GL_BLEND);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, _inputImageTexture2Id);
    glUniform1i(_inputImageTexture2Slot, 1);

    if(_enableMask) {
        glActiveTexture(GL_TEXTURE2);
        glBindTexture(GL_TEXTURE_2D, _maskTextureId);
        glUniform1i(_maskTextureSlot, 2);
    }
    glUniform1i(_useMaskSlot, _enableMask);
    glUniformMatrix3fv(_colorConversionMatrixSlot, 1, GL_FALSE, _colorConversionMatrix);
    glUniform1i(_linearP3Slot, _linearP3);

    glUniform1i(_enableBorderSlot, self.enableBorder);
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [self.borderColor getRed:&red green:&green blue:&blue alpha:&alpha];
    glUniform4f(_borderColorSlot, red, green, blue, alpha);
    glUniform1f(_borderWidthSlot, self.borderWidth);
    glUniform1f(_radiusSlot, self.radius);
    glUniform2f(_resolutionSlot, self.resolution.width,  self.resolution.height);
}

- (void)clearup
{
    [super clearup];
    glDisable(GL_BLEND);
}

- (void)setColorConversionMatrix:(CFStringRef)matrix
{
    memcpy(_colorConversionMatrix, [BMWBaseDrawer ColorConversionMatrix:matrix], sizeof(GLfloat) * 9);
}

- (void)setMaskPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
    _enableMask = pixelBuffer != NULL;
    if(pixelBuffer == NULL) return;

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    OSType pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer);
    CVOpenGLESTextureRef maskTextureRef = NULL;
    CVReturn ret = noErr;
    if (pixelFormat == kCVPixelFormatType_OneComponent8) {
        ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.imageContext.coreVideoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_LUMINANCE, width, height, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0, &maskTextureRef);
    } else if (pixelFormat == kCVPixelFormatType_OneComponent32Float) {
        ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.imageContext.coreVideoTextureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_LUMINANCE, width, height, GL_LUMINANCE, GL_FLOAT, 0, &maskTextureRef);
    } else {
        ret = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, self.imageContext.coreVideoTextureCache, pixelBuffer, NULL,GL_TEXTURE_2D, GL_RGBA, (GLsizei)width, (GLsizei)height, GL_BGRA, GL_UNSIGNED_BYTE, 0, &maskTextureRef);
    }
    if (ret != noErr) {
                CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
        return;
    }
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    _maskTextureId = CVOpenGLESTextureGetName(maskTextureRef);
    glBindTexture(GL_TEXTURE_2D, _maskTextureId);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glBindTexture(GL_TEXTURE_2D, 0);

    if (maskTextureRef) {
        CFRelease(maskTextureRef);
    }
    if (pixelBuffer) {
        CFRelease(pixelBuffer);
    }
}

- (void)setInputPixelBuffer:(CVPixelBufferRef)pixelBuffer
{
     if (self.useYUV) {
        [self setupYUVTexture:pixelBuffer];
    } else {
       _inputImageTextureId = [BMWGLUtils createTextureWithBuffer:pixelBuffer context:self.imageContext];
    }
    CFTypeRef colorPrimaries = CVBufferGetAttachment(pixelBuffer, kCVImageBufferColorPrimariesKey, NULL);
    if (colorPrimaries != NULL) {
        self.linearP3 = CFStringCompare(colorPrimaries, kCVImageBufferColorPrimaries_P3_D65, 0) == kCFCompareEqualTo;
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

- (void)draw
{
    [super drawWithTexId:_inputImageTextureId];
}

- (void)setBorder:(CGSize)resolution radius:(int)radius borderWidth:(float)borderWidth borderColor:(UIColor*)borderColor
{
    self.enableBorder = YES;
    self.resolution = resolution;
    self.radius = radius;
    self.borderWidth = borderWidth;
    self.borderColor = borderColor;
}

@end
