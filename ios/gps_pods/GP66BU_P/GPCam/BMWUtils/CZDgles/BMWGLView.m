#import "BMWGLView.h"
#import "BMWGlShaderHelper.h"
#import "BMWImageContext.h"
#import "UIView+GPCam.h"

#define STRINGIZE(x) #x
#define STRINGIZE2(x) STRINGIZE(x)
#define SHADER_STRING(text) @ STRINGIZE2(text)

NSString* const kVertexString = SHADER_STRING
(
    attribute vec4 position;
    attribute vec4 inputTextureCoordinate;
    varying vec2 textureCoordinate;
    void main()
    {
        gl_Position = position;
        textureCoordinate = inputTextureCoordinate.xy;
    }
 );

NSString* const kFragmentString = SHADER_STRING
(
    precision highp float;
    varying highp vec2 textureCoordinate;
    uniform sampler2D inputImageTexture;
    void main()
    {
        gl_FragColor = texture2D(inputImageTexture, textureCoordinate);
    }
 );

// 使用匿名 category 来声明私有成员
@interface BMWGLView()
{
    int _backingWidth;
    int _backingHeight;

    GLfloat _imageVertices[8];
    GLuint _colorRenderBuffer;
    GLuint _frameBuffer;
    GLuint _programHandle;
    GLuint _positionSlot;
    GLuint _inputTextureCoordinateSlot;
    GLuint _inputImageTexture;
}

@property (nonatomic, strong) CAEAGLLayer* eaglLayer;
@property (nonatomic, strong) BMWImageContext* imageContext;
@property (nonatomic, assign) CGSize inputImageSize;
@property (nonatomic, assign) CGRect viewRect;
@property (nonatomic, assign) CGFloat red;
@property (nonatomic, assign) CGFloat green;
@property (nonatomic, assign) CGFloat blue;
@property (nonatomic, assign) CGFloat alpha;
@property (nonatomic, assign) BOOL isShowingBlur;
@property (nonatomic, strong) UIVisualEffectView *effectview;
@property (nonatomic, assign) double timestamp;
@property (nonatomic, assign) NSInteger frameCount;
@property (nonatomic) UILabel* tipsLabel;

@end

@implementation BMWGLView

+ (Class)layerClass
{
    return [CAEAGLLayer class];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.effectview.frame = self.bounds;
        self.timestamp = 0;
        self.frameCount = 0;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.effectview.frame = self.bounds;
        self.timestamp = 0;
        self.frameCount = 0;
    }
    return self;
}

#if CAMERA_STARTUP_OPT_DEBUG
- (void)showDebugTips:(NSString *)tips
{
    if(!self.tipsLabel) {
        self.tipsLabel = [[UILabel alloc] init];
        self.tipsLabel.textColor = [UIColor yellowColor];
        self.tipsLabel.textAlignment = NSTextAlignmentLeft;
        self.tipsLabel.frame = CGRectMake(0, 0, BMWScreenWidth, 180);
        self.tipsLabel.numberOfLines = 0;
    }
    [self.tipsLabel removeFromSuperview];
    [self addSubview:self.tipsLabel];
    self.tipsLabel.text = tips;
}
#endif

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.size = self.bounds.size;
    self.cornerRadius = self.layer.cornerRadius;
}

- (void)dealloc
{
    BMWMLogM(@"BMWGLView dealloc...");
    runSynchronouslyOnContextQueue(self.imageContext, ^{
        [self.imageContext useAsCurrentContext];
        if (_programHandle > 0) {
            glDeleteShader(_programHandle);
            _programHandle = 0;
        }
    });
}

- (void)showBlur:(BOOL)show
{
    [self showBlur:show delay:0];
}

- (void)showBlur:(BOOL)show delay:(CGFloat)delay
{
    if(self.effectview.frame.size.width == 0) {
        return;
    }
    self.effectview.frame = self.bounds;
    self.viewRect = self.bounds;
    float time = show ? 0.0 : 0.4;
    [UIView animateWithDuration:time animations:^{
        self.effectview.alpha = show;
    }];
#if 0
    if(!show) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.isShowingBlur = show;
        });
    } else {
        self.isShowingBlur = show;
    }
#endif
}

- (UIVisualEffectView *)effectview
{
    if(!_effectview) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _effectview = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        [self addSubview:_effectview];
        _effectview.alpha = 0;
    }
    return _effectview;
}

- (void)setFillMode:(BMWImageFillModeType)newValue;
{
    _fillMode = newValue;
}

- (void)setInputImageSize:(CGSize)size
{
    _inputImageSize = size;
}

- (void)setInputImageRotation:(BMWImageRotationMode)rotation;
{
    _inputRotation = rotation;
}

- (void)setRenderBackingColorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
    self.red = red;
    self.green = green;
    self.blue = blue;
    self.alpha = alpha;
}

- (void)recalculateViewGeometry
{
    if (_frameBuffer <= 0) {
        return;
    }

    CGFloat heightScaling, widthScaling;
    CGRect insetRect = AVMakeRectWithAspectRatioInsideRect(_inputImageSize, self.viewRect);
    CGSize currentViewSize = self.viewRect.size;
    switch(_fillMode)
    {
        case kXHImageFillModeStretch:
        {
            widthScaling = 1.0;
            heightScaling = 1.0;
        }
            break;
        case kXHImageFillModePreserveAspectRatio:
        {
            widthScaling = insetRect.size.width / currentViewSize.width;
            heightScaling = insetRect.size.height / currentViewSize.height;
        }
            break;
        case kXHImageFillModePreserveAspectRatioAndFill:
        {
            widthScaling = currentViewSize.height / insetRect.size.height;
            heightScaling = currentViewSize.width / insetRect.size.width;
        }
            break;
    }

    _imageVertices[0] = -widthScaling;
    _imageVertices[1] = -heightScaling;
    _imageVertices[2] = widthScaling;
    _imageVertices[3] = -heightScaling;
    _imageVertices[4] = -widthScaling;
    _imageVertices[5] = heightScaling;
    _imageVertices[6] = widthScaling;
    _imageVertices[7] = heightScaling;
}

- (void)commonInit:(BMWImageContext*)context
{
    self.imageContext = context;
    self.inputRotation = kXHImageRotateRightFlipHorizontal;
    [self.imageContext useAsCurrentContext];
    [self destoryBuffers];

    [self setupProgram];
    CGFloat max = MAX(self.inputImageSize.width, self.inputImageSize.height);
    CGFloat min = MIN(self.inputImageSize.width, self.inputImageSize.height);
    self.contentScaleFactor = [UIScreen mainScreen].scale;
    if (max > 2000 && min / max >= 0.75) {
        self.contentScaleFactor = 4.0;
    }
    self.viewRect = self.bounds;
    self.eaglLayer = (CAEAGLLayer*)self.layer;

    // CALayer 默认是透明的，必须将它设为不透明才能让其可见
    self.eaglLayer.opaque = YES;

    // 设置描绘属性，在这里设置不维持渲染内容以及颜色格式为 RGBA8
    self.eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];

    if (_frameBuffer == 0) {
        [self createDisplayFramebuffer];
    }
    [self recalculateViewGeometry];
}

- (void)createDisplayFramebuffer
{
    BMWMLogM(@"glview createDisplayFramebuffer...");
    glGenFramebuffers(1, &_frameBuffer);
    // 设置为当前 framebuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);

    glGenRenderbuffers(1, &_colorRenderBuffer);
    // 设置为当前 renderbuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    // 为 color renderbuffer 分配存储空间
    [self.imageContext.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];

    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_backingWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_backingHeight);

    // 将 _colorRenderBuffer 装配到 GL_COLOR_ATTACHMENT0 这个装配点上
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);

    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);

    if (status != GL_FRAMEBUFFER_COMPLETE) {
            }
}

- (void)destoryBuffers
{
    if (_colorRenderBuffer > 0) {
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
    }

    if (_frameBuffer > 0) {
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    }

- (void)activateDisplayFramebuffer
{
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(0, 0, _backingWidth, _backingHeight);
}

- (void)renderTextureId:(GLuint)textureId;
{
    if (self.isShowingBlur) {
                return;
    }

    if (_frameBuffer == 0 || _colorRenderBuffer == 0) {
        [self createDisplayFramebuffer];
    }

    [self activateDisplayFramebuffer];

    [self recalculateViewGeometry];

    glUseProgram(_programHandle);
    glClearColor(self.red, self.green, self.blue, self.alpha);
    glClear(GL_COLOR_BUFFER_BIT);

    glVertexAttribPointer(_positionSlot, 2, GL_FLOAT, GL_FALSE, 0, _imageVertices);
    glEnableVertexAttribArray(_positionSlot);
    glVertexAttribPointer(_inputTextureCoordinateSlot, 2, GL_FLOAT, GL_FALSE, 0, [BMWGLView textureCoordinatesForRotation:_inputRotation]);
    glEnableVertexAttribArray(_inputTextureCoordinateSlot);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, textureId);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glUniform1i(0, _inputImageTexture);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [self.imageContext.context presentRenderbuffer:GL_RENDERBUFFER];

    glBindTexture(GL_TEXTURE_2D, 0);
    glBindRenderbuffer(GL_RENDERBUFFER, 0);
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    self.frameCount++;
    double currentTime = CACurrentMediaTime();
    if (self.timestamp == 0) {
        self.timestamp = currentTime;
    }
    if (currentTime - self.timestamp >= 1.0) {
//        BMWMLogInterval(2, @"glview render fps: %.2lf", (double)self.frameCount / (currentTime - self.timestamp));
        self.timestamp = currentTime;
        self.frameCount = 0;
    }
}

- (void)setupProgram
{
    self.red = 0.0;
    self.green = 0.0;
    self.blue = 0.0;
    self.alpha = 1.0;
    // Create program, attach shaders, compile and link program
    _programHandle = [BMWGlShaderHelper loadProgramString:kVertexString withFragmentShaderString:kFragmentString];
    if (_programHandle == 0) {
                return;
    }
    // Get attribute slot from program
    _positionSlot = glGetAttribLocation(_programHandle, "position");
    _inputTextureCoordinateSlot = glGetAttribLocation(_programHandle, "inputTextureCoordinate");
    _inputImageTexture = glGetUniformLocation(_programHandle, "inputImageTexture");
}

+ (const GLfloat *)textureCoordinatesForRotation:(BMWImageRotationMode)rotationMode;
{
    static const GLfloat noRotationTextureCoordinates[] = {
        0.0f, 1.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 0.0f,
    };

    static const GLfloat rotateRightTextureCoordinates[] = {
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
    };

    static const GLfloat rotateLeftTextureCoordinates[] = {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
    };

    static const GLfloat verticalFlipTextureCoordinates[] = {
        0.0f, 0.0f,
        1.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
    };

    static const GLfloat horizontalFlipTextureCoordinates[] = {
        1.0f, 1.0f,
        0.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
    };

    static const GLfloat rotateRightVerticalFlipTextureCoordinates[] = {
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };

    static const GLfloat rotateRightHorizontalFlipTextureCoordinates[] = {
        0.0f, 1.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };

    static const GLfloat rotate180TextureCoordinates[] = {
        1.0f, 0.0f,
        0.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f,
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

@end
