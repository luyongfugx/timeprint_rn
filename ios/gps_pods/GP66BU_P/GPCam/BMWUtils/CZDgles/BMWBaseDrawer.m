#import "BMWBaseDrawer.h"

static NSString* const kVertexString = SHADER_STRING
(
    precision highp float;
    attribute vec4 position;
    attribute vec4 inputTextureCoordinate;
    uniform mat4 mvpMatrix;
    varying vec2 textureCoordinate;

    void main()
    {
        gl_Position = mvpMatrix * position;
        textureCoordinate = inputTextureCoordinate.xy;
    }
 );

static NSString* const kFragmentString = SHADER_STRING
(
    precision highp float;
    varying highp vec2 textureCoordinate;
    uniform sampler2D inputImageTexture;

    void main()
    {
        gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
    }
 );

@interface BMWBaseDrawer ()
{
    int _backingWidth;
    int _backingHeight;

    GLuint _programHandle;
    GLuint _positionSlot;
    GLuint _inputTextureCoordinateSlot;
    GLuint _inputImageTextureSlot;
    GLuint _mvpMatrixSlot;
}
@property(nonatomic) GLint inputTextId;
@property(nonatomic) CATransform3D mvpMatrix;
@property(nonatomic) BMWImageRotationMode rotation;

@end

@implementation BMWBaseDrawer

- (void)destory
{
    if (_programHandle > 0) {
        glDeleteShader(_programHandle);
        _programHandle = 0;
    }
}

- (instancetype)init
{
    if (!(self = [super init])) {
        return nil;
    }
    self.rotation = kXHImageNoRotation;
    [self resetMatrix];
    [self setupProgram:kVertexString fragmentShader:kFragmentString];
    return self;
}

- (void)setupProgram:(nullable NSString*)vertexShader fragmentShader:(nullable NSString*)fragmentShader
{
    if(vertexShader == nil) vertexShader = kVertexString;
    if(fragmentShader == nil) fragmentShader = kFragmentString;
    _programHandle = [BMWGlShaderHelper loadProgramString:vertexShader withFragmentShaderString:fragmentShader];
    if (_programHandle == 0) {
                return;
    }
    _positionSlot = glGetAttribLocation(_programHandle, "position");
    _inputTextureCoordinateSlot = glGetAttribLocation(_programHandle, "inputTextureCoordinate");
    _inputImageTextureSlot = [self getUniformLocation:@"inputImageTexture"];
    _mvpMatrixSlot = [self getUniformLocation:@"mvpMatrix"];
}

- (void)prepare
{
#if 0
    GLfloat matrix[] = {
        (GLfloat)_mvpMatrix.m11, (GLfloat)_mvpMatrix.m21, 0.0, (GLfloat)_mvpMatrix.m41,
        (GLfloat)_mvpMatrix.m12, (GLfloat)_mvpMatrix.m22, 0.0, (GLfloat)_mvpMatrix.m42,
        0.0,                  0.0,                  1.0, 0.0,
        0.0,                  0.0,                  0.0, 1.0,
    };
#else
    GLfloat matrix[] = {
        (GLfloat)_mvpMatrix.m11, (GLfloat)_mvpMatrix.m12, (GLfloat)_mvpMatrix.m13, (GLfloat)_mvpMatrix.m14,
        (GLfloat)_mvpMatrix.m21, (GLfloat)_mvpMatrix.m22, (GLfloat)_mvpMatrix.m23, (GLfloat)_mvpMatrix.m24,
        (GLfloat)_mvpMatrix.m31, (GLfloat)_mvpMatrix.m32, (GLfloat)_mvpMatrix.m33, (GLfloat)_mvpMatrix.m34,
        (GLfloat)_mvpMatrix.m41, (GLfloat)_mvpMatrix.m42, (GLfloat)_mvpMatrix.m43, (GLfloat)_mvpMatrix.m44
    };
    glUniformMatrix4fv(_mvpMatrixSlot, 1, GL_FALSE, matrix);
#endif
}

- (void)draw
{
    [self drawWithTexId:_inputTextId];
}

- (void)drawWithTexId:(GLint)textureId
{
    static GLfloat vertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    const GLfloat *coordinates = [self.class textureCoordinatesForRotation:kXHImageNoRotation];
    [self drawWithTexId:textureId vertices:vertices coordinates:coordinates];
}

- (void)drawWithTexId:(GLint)textureId coordinates:(const GLfloat *)coordinates
{
    static GLfloat vertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    [self drawWithTexId:textureId vertices:vertices coordinates:coordinates];
}

- (void)drawWithTexId:(GLuint)textureId
             vertices:(const GLfloat *)vertices
             rotation:(BMWImageRotationMode)rotation
{
    _inputTextId = textureId;
    const GLfloat *coordinates = [self.class textureCoordinatesForRotation:rotation];
    [self drawWithTexId:textureId vertices:vertices coordinates:coordinates];
}

- (void)drawWithTexId:(GLuint)textureId
             vertices:(const GLfloat *)vertices
          coordinates:(const GLfloat *)coordinates
{
    glUseProgram(_programHandle);
    [self prepare];
    glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE, 0, vertices);
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_inputTextureCoordinateSlot, 2, GL_FLOAT, GL_FALSE, 0, coordinates);
    glEnableVertexAttribArray(_inputTextureCoordinateSlot);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(_inputImageTextureSlot, 0);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    [self clearup];
}

- (void)clearup
{
    glBindTexture(GL_TEXTURE_2D, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

- (int)getUniformLocation:(NSString*)name
{
    return glGetUniformLocation(_programHandle, name.UTF8String);
}

- (void)resetMatrix
{
    self.mvpMatrix = CATransform3DIdentity;
}

- (void)rotateZ:(float)radians
{
    CATransform3D rotate = CATransform3DMakeRotation(radians, 0, 0, 1);
    self.mvpMatrix = CATransform3DConcat(self.mvpMatrix, rotate);
}

- (void)scaleX:(float)scaleX scaleY:(float)scaleY
{
    CATransform3D scale = CATransform3DMakeScale(scaleX, scaleY, 1.0);
    self.mvpMatrix = CATransform3DConcat(self.mvpMatrix, scale);
}

- (void)transX:(float)tx transY:(float)ty
{
    CATransform3D trans = CATransform3DMakeTranslation(tx, ty, 0);
    self.mvpMatrix = CATransform3DConcat(self.mvpMatrix, trans);
}

- (void)setInputTexId:(GLint)texId
{
    _inputTextId = texId;
}

- (void)setRotation:(BMWImageRotationMode)rotation
{
    _rotation = rotation;
}

+ (const GLfloat*)textureCoordinatesForRotation:(BMWImageRotationMode)rotationMode
{
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };

    static const GLfloat rotateLeftTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };

    static const GLfloat rotateRightTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };

    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f,  0.0f,
        1.0f,  0.0f,
    };

    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f,  1.0f,
        0.0f,  1.0f,
    };

    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };

    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };

    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };

    switch(rotationMode)
    {
        case kXHImageNoRotation: return noRotationTextureCoordinates;
        case kXHImageRotateLeft: return rotateLeftTextureCoordinates;
        case kXHImageRotateRight: return rotateRightTextureCoordinates;
        case kXHImageFlipVertical: return verticalFlipTextureCoordinates;
        case kXHImageFlipHorizonal: return horizontalFlipTextureCoordinates;
        case kXHImageRotateRightFlipVertical: return rotateRightVerticalFlipTextureCoordinates;
        case kXHImageRotateRightFlipHorizontal: return rotateRightHorizontalFlipTextureCoordinates;
        case kXHImageRotate180: return rotate180TextureCoordinates;
    }
}

+ (const GLfloat *)ColorConversionMatrix:(CFStringRef)matrix
{

 //ref:https://en.wikipedia.org/wiki/YCbCr
    static GLfloat ITU_R_2020_MATRIX[9] = {
        1.0,       1.0,        1.0,
        0.0,       -0.164553,  1.88140,
        1.4746000, -0.571353,  0.0
    };

 // Get From kvImage_YpCbCrToARGBMatrix_ITU_R_709_2
    static GLfloat ITU_R_709_2_MATRIX[9] = {
        1.0,        1.0,          1.0,
        0.0,        -0.187324271, 1.8556,
        1.57480001, -0.46812427,  0.0
    };

    // Get From kvImage_YpCbCrToARGBMatrix_ITU_R_601_4
    static GLfloat ITU_R_601_4_MATRIX[9] = {
        1.0,        1.0,          1.0,
        0.0,        -0.344136298, 1.77199996,
        1.40199995, -0.714136302, 0.0
    };

    if (matrix == NULL) {
        return ITU_R_601_4_MATRIX;
    }
    else if (CFStringCompare(matrix, kCVImageBufferYCbCrMatrix_ITU_R_601_4, 0) == kCFCompareEqualTo) {
        return ITU_R_601_4_MATRIX;
    }
    else if (CFStringCompare(matrix, kCVImageBufferYCbCrMatrix_ITU_R_709_2, 0) == kCFCompareEqualTo) {
        return ITU_R_709_2_MATRIX;
    }
    else if (CFStringCompare(matrix, kCVImageBufferYCbCrMatrix_ITU_R_2020, 0) == kCFCompareEqualTo) {
        return ITU_R_2020_MATRIX;
    }
    else {
        return ITU_R_601_4_MATRIX;
    }
}

@end
