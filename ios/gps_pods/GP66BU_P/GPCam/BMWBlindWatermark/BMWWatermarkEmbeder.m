#import "BMWWatermarkEmbeder.h"
#import "BMWRGB2YUVDrawer.h"
#import "BMWDwtDrawer.h"
#import "BMWDctWmExtractDrawer.h"
#import "BMWDctWmEmbedDrawer.h"
#import "BMWIDwtDrawer.h"
#import "BMWYUV2RGBDrawer.h"
#import "BMWFramebuffer.h"
#import "BMWGLUtils.h"
#import "BMWWatermarkDrawer.h"
#import "BMWBlindWatermarkModel.h"
#import "BMWBlindWatermarkUtils.h"

@interface BMWWatermarkEmbeder ()

@property (nonatomic, strong) BMWImageContext *context;
// crop slice image to embed watermark
@property (nonatomic, strong) BMWBaseDrawer *cropDrawer;
@property (nonatomic, strong) BMWFramebuffer *cropFBO;
// rgb2yuv
@property (nonatomic, strong) BMWRGB2YUVDrawer *rgb2yuvDrawer;
@property (nonatomic, strong) BMWFramebuffer *rgb2yuvFBO;
// dwt row
@property (nonatomic, strong) BMWDwtDrawer *dwtDrawer;
@property (nonatomic, strong) BMWFramebuffer *dwtFBO;
// dwt col
@property (nonatomic, strong) BMWDwtDrawer *dwt2Drawer;
@property (nonatomic, strong) BMWFramebuffer *dwt2FBO;
// pass draw
@property (nonatomic, strong) BMWBaseDrawer *passDrawer;
@property (nonatomic, strong) BMWFramebuffer *passFBO;
// dct->wm->idct embed wm
@property (nonatomic, strong) BMWDctWmEmbedDrawer *embedDrawer;
// idwt col
@property (nonatomic, strong) BMWIDwtDrawer *idwtDrawer;
@property (nonatomic, strong) BMWFramebuffer *idwtFBO;
// idwt row
@property (nonatomic, strong) BMWIDwtDrawer *idwt2Drawer;
@property (nonatomic, strong) BMWFramebuffer *idwt2FBO;
// yuv2rgb
@property (nonatomic, strong) BMWYUV2RGBDrawer *yuv2rgbDrawer;
@property (nonatomic, strong) BMWFramebuffer *yuv2rgbFBO;
// blend slice
@property (nonatomic, strong) BMWBaseDrawer *blendDrawer;

// blend slice
@property (nonatomic, assign) GLuint wmTexId;

@property (nonatomic, strong) BMWBlindWatermarkModel* wmModel;

@end

@implementation BMWWatermarkEmbeder

- (void)destory
{
    // release resouce
    glDeleteTextures(1, (const GLuint *)&_wmTexId);

    [self.yuv2rgbDrawer destory];
    [self.yuv2rgbFBO destroy];

    [self.cropDrawer destory];
    [self.cropFBO destroy];

    [self.rgb2yuvDrawer destory];
    [self.rgb2yuvFBO destroy];

    [self.dwtDrawer destory];
    [self.dwtFBO destroy];

    [self.dwt2Drawer destory];
    [self.dwt2FBO destroy];

    [self.passDrawer destory];
    [self.passFBO destroy];

    [self.embedDrawer destory];

    [self.idwtDrawer destory];
    [self.idwtFBO destroy];

    [self.idwt2Drawer destory];
    [self.idwt2FBO destroy];

    [self.blendDrawer destory];
}

- (instancetype)init:(BMWImageContext*)context;
{
    if (self = [super init]) {
        _context = context;
    }
    return self;
}

- (void)updateWmModel:(BMWBlindWatermarkModel*)wmModel
{
    _wmModel = wmModel;
    if(wmModel){
        [self setup];
    };
}

- (void)setup
{
    CGSize size = self.wmModel.watermarkSliceSize;
    UIImage *wm = self.wmModel.watermarkImage;
    [BMWGLUtils getRawData:wm forceRedraw:YES block:^(GLubyte * _Nonnull imageData, int width, int height, GLenum format) {
        _wmTexId = [BMWGLUtils createTextureWithData:imageData width:width height:height];
    }];

    // crop slice image to embed watermark
    self.cropDrawer = [[BMWBaseDrawer alloc] init];
    self.cropFBO = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.context];

    // rgb2yuv
    self.rgb2yuvDrawer = [[BMWRGB2YUVDrawer alloc] init];
    self.rgb2yuvFBO = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.context];

    // dwt row
    self.dwtDrawer = [[BMWDwtDrawer alloc] init:size direction:0];
    self.dwtFBO = [[BMWFramebuffer alloc] initWithSize2:size imageContext:self.context];

    // dwt col
    self.dwt2Drawer = [[BMWDwtDrawer alloc] init:size direction:1];
    self.dwt2FBO = [[BMWFramebuffer alloc] initWithSize2:size imageContext:self.context];

    // pass draw
    self.passDrawer = [[BMWBaseDrawer alloc] init];
    self.passFBO = [[BMWFramebuffer alloc] initWithSize2:size imageContext:self.context];

    // dct->wm->idct embed wm
    self.embedDrawer = [[BMWDctWmEmbedDrawer alloc] init:size];

    // idwt col
    self.idwtDrawer = [[BMWIDwtDrawer alloc] init:size direction:1];
    self.idwtFBO = [[BMWFramebuffer alloc] initWithSize2:size imageContext:self.context];

    // idwt row
    self.idwt2Drawer = [[BMWIDwtDrawer alloc] init:size direction:0];
    self.idwt2FBO = [[BMWFramebuffer alloc] initWithSize2:size imageContext:self.context];

    // yuv2rgb
    self.yuv2rgbDrawer = [[BMWYUV2RGBDrawer alloc] init];
    self.yuv2rgbFBO = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.context];

    // blend slice
    self.blendDrawer = [[BMWBaseDrawer alloc] init];
}

- (void)embeded:(GLuint)texId texSize:(CGSize)texSize sliceEmbedCallback:(void (^)(CGRect sliceRect))sliceEmbedCallback
{
    // prepare parameter
    UIImage *wm = self.wmModel.watermarkImage;
    CGSize size = self.wmModel.watermarkSliceSize;
    CGRect rect = [self.wmModel watermarkRectByRatio:texSize.width/texSize.height];
    int len = wm.size.width * wm.size.height;

        GLfloat l = rect.origin.x;
    GLfloat t = rect.origin.y;
    GLfloat r = l + rect.size.width;
    GLfloat b = t + rect.size.height;
    const GLfloat coordinates[8] = {
        l, t,
        r, t,
        l, b,
        r, b,
    };
    static GLfloat vertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };

    // begin embed watermark
    // crop slice image to embed watermark
    [self.cropFBO bind];
    [self.cropDrawer drawWithTexId:texId vertices:vertices coordinates:coordinates];
    [BMWBlindWatermarkUtils printBuffer:self.cropFBO tag:@"crop"];
    texId = self.cropFBO.texture;

    // rgb2yuv
    [self.rgb2yuvFBO bind];
    [self.rgb2yuvDrawer renderTextureId:texId vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:self.rgb2yuvFBO tag:@"rgb2yuv"];

    // dwt row
    [self.dwtFBO bind];
    [self.dwtDrawer renderTextureId:self.rgb2yuvFBO.texture vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:self.dwtFBO tag:@"dwt"];

    // dwt col
    [self.dwt2FBO bind];
    [self.dwt2Drawer renderTextureId:self.dwtFBO.texture vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:self.dwt2FBO tag:@"dwt2"];

    // pass draw
    [self.passFBO bind];
    [self.passDrawer drawWithTexId:self.dwt2FBO.texture vertices:vertices rotation:kXHImageNoRotation];
    [BMWBlindWatermarkUtils printBuffer:self.passFBO tag:@"pass"];

    // dct->wm->idct embed wm
    BMWFramebuffer *embedFBO = self.passFBO;
    [embedFBO bind];
    glViewport(0, 0, size.width / 2, size.height / 2);
    [self.embedDrawer renderTextureId:self.dwt2FBO.texture wmTexId:_wmTexId wmBitsCount:len vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:embedFBO tag:@"embed"];

    // idwt col
    [self.idwtFBO bind];
    [self.idwtDrawer renderTextureId:embedFBO.texture vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:self.idwtFBO tag:@"idwt"];

    // idwt row
    [self.idwt2FBO bind];
    [self.idwt2Drawer renderTextureId:self.idwtFBO.texture vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:self.idwt2FBO tag:@"idwt2"];

    // yuv2rgb
    [self.yuv2rgbFBO bind];
    [self.yuv2rgbDrawer renderTextureId:texId uTexId:self.idwt2FBO.texture vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:self.yuv2rgbFBO tag:@"yuv2rgb"];

    // blend slice
#if 0
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
#endif
    SafeBlock(sliceEmbedCallback, rect);
    [self.blendDrawer drawWithTexId:self.yuv2rgbFBO.texture vertices:vertices rotation:kXHImageNoRotation];
    [BMWBlindWatermarkUtils printBuffer:self.passFBO tag:@"blind"];
}

- (void)embeded:(UIImage*)image embedCallback:(void (^)(UIImage *processedImage))embedCallback
{
    runAsynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        int _outputWidth = image.size.width;
        int _outputHeight = image.size.height;
        BMWBaseDrawer *inputDrawer = [[BMWBaseDrawer alloc] init];
        BMWFramebuffer *inputFBO = [[BMWFramebuffer alloc] initWithSize:image.size imageContext:self.context];
        GLuint srcTexId = [BMWGLUtils setupTexture:image];
        [inputFBO bind];
        [inputDrawer drawWithTexId:srcTexId];
        [self embeded:inputFBO.texture texSize:image.size sliceEmbedCallback:^(CGRect sliceRect) {
            [inputFBO bind];
            int x = sliceRect.origin.x * _outputWidth + 0.5;
            int y = sliceRect.origin.y * _outputHeight + 0.5;
            int width = sliceRect.size.width * _outputWidth + 0.5;
            int height = sliceRect.size.height * _outputHeight + 0.5;
            glViewport(x, y, width, height);
        }];
        glFinish();
        UIImage *processedImage = [inputFBO imageFromFramebufferContent];
        SafeBlock(embedCallback, processedImage);

        // release resouce
        [inputDrawer destory];
        [inputFBO destroy];
        glDeleteTextures(1, (const GLuint *)&srcTexId);
    });
}

- (void)embeded:(GLuint)texId size:(CGSize)size wm:(NSString*)wm
{
    double begin = CACurrentMediaTime();
    const char *cc = [wm cStringUsingEncoding:NSASCIIStringEncoding];
    int len = (int)wm.length;
    GLint *wmBits = malloc(len*8*4);
    for (int i = 0; i < len; i++) {
        char c = cc[i];
        // big endian
        for (int j = 0; j < 8; j++) {
            wmBits[i*8+j] = (0x80>>j) & c ? 1 : 0;
        }
    }
    GLfloat vertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };

        //rgb2yuv
    BMWRGB2YUVDrawer *rgb2yuvDrawer = [[BMWRGB2YUVDrawer alloc] init];
    BMWFramebuffer *rgb2yuvFBO = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.context];
    [rgb2yuvFBO bind];
    [rgb2yuvDrawer renderTextureId:texId vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:rgb2yuvFBO tag:@"rgb2yuv"];

    // dwt row
    BMWDwtDrawer *dwtDrawer = [[BMWDwtDrawer alloc] init:size direction:0];
    BMWFramebuffer *dwtFBO = [[BMWFramebuffer alloc] initWithSize2:size imageContext:self.context];
    [dwtFBO bind];
    [dwtDrawer renderTextureId:rgb2yuvFBO.texture vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:dwtFBO tag:@"dwt"];

    // dwt col
    BMWDwtDrawer *dwt2Drawer = [[BMWDwtDrawer alloc] init:size direction:1];
    BMWFramebuffer *dwt2FBO = [[BMWFramebuffer alloc] initWithSize2:size imageContext:self.context];
    [dwt2FBO bind];
    [dwt2Drawer renderTextureId:dwtFBO.texture vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:dwt2FBO tag:@"dwt2"];

    // pass draw
    BMWBaseDrawer *passDrawer = [[BMWBaseDrawer alloc] init];
    BMWFramebuffer *passFBO = [[BMWFramebuffer alloc] initWithSize2:size imageContext:self.context];
    [passFBO bind];
    [passDrawer drawWithTexId:dwt2FBO.texture vertices:vertices rotation:kXHImageNoRotation];
    [BMWBlindWatermarkUtils printBuffer:passFBO tag:@"pass"];

    // dct->wm->idct embed wm
    BMWDctWmEmbedDrawer *embedDrawer = [[BMWDctWmEmbedDrawer alloc] init:size];
    BMWFramebuffer *embedFBO = passFBO;
    [embedFBO bind];
    glViewport(0, 0, size.width / 2, size.height / 2);
    [embedDrawer renderTextureId:dwt2FBO.texture wmBits:wmBits wmBitsCount:len*8 vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:embedFBO tag:@"embed"];

    // idwt col
    BMWIDwtDrawer *idwtDrawer = [[BMWIDwtDrawer alloc] init:size direction:1];
    BMWFramebuffer *idwtFBO = [[BMWFramebuffer alloc] initWithSize2:size imageContext:self.context];
    [idwtFBO bind];
    [idwtDrawer renderTextureId:embedFBO.texture vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:idwtFBO tag:@"idwt"];

    // idwt row
    BMWIDwtDrawer *idwt2Drawer = [[BMWIDwtDrawer alloc] init:size direction:0];
    BMWFramebuffer *idwt2FBO = [[BMWFramebuffer alloc] initWithSize2:size imageContext:self.context];
    [idwt2FBO bind];
    [idwt2Drawer renderTextureId:idwtFBO.texture vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:idwt2FBO tag:@"idwt2"];

    // yuv2rgb
    self.yuv2rgbDrawer = [[BMWYUV2RGBDrawer alloc] init];
    self.yuv2rgbFBO = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.context];
    [self.yuv2rgbFBO bind];
    [self.yuv2rgbDrawer renderTextureId:texId uTexId:idwt2FBO.texture vertices:vertices];
    [BMWBlindWatermarkUtils printBuffer:idwt2FBO tag:@"yuv2rgb"];

    [rgb2yuvDrawer destory];
    [rgb2yuvFBO destroy];

    [dwtDrawer destory];
    [dwtFBO destroy];

    [dwt2Drawer destory];
    [dwt2FBO destroy];

    [passDrawer destory];
    [passFBO destroy];

    [embedDrawer destory];

    [idwtDrawer destory];
    [idwtFBO destroy];

    [idwt2Drawer destory];
    [idwt2FBO destroy];

    free(wmBits);
    double end = CACurrentMediaTime();
    }

@end
