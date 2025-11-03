#import "BMWWatermarkExtractor.h"
#import "BMWRGB2YUVDrawer.h"
#import "BMWDwtDrawer.h"
#import "BMWDctWmExtractDrawer.h"
#import "BMWIDwtDrawer.h"
#import "BMWWmMergeDrawer.h"
#import "BMWFramebuffer.h"
#import "BMWGLUtils.h"
#import "BMWBlindWatermarkUtils.h"
#import "BMWWmMergeDrawer2.h"
#import "ssim.h"

#define WM_BLOCK 32

@implementation BMWWatermarkResultModel

- (NSString *)description
{
    return [NSString stringWithFormat:@"bwm: { similarity:%0.4f, %0.4f, %0.4f }", self.allSimilarity, self.topSimilarity, self.bottomSimilarity];
}

@end

@interface BMWWatermarkExtractor ()
@property (nonatomic, strong) BMWImageContext *context;
@end

@implementation BMWWatermarkExtractor

- (instancetype)init
{
    if (self = [super init]) {
        self.context = BMWImageContext.sharedImageProcessingContext;
    }
    return self;
}

- (instancetype)init:(BMWImageContext*)context
{
    if (self = [super init]) {
        self.context = context;
    }
    return self;
}

- (void)extract:(UIImage*)image scaledSize:(CGSize)scaledSize wmLen:(int)wmLen completeBlock:(void (^)(NSString *_Nullable wm, NSError *_Nullable error))block
{
    wmLen = wmLen * 8;
    if (image == nil || wmLen == 0) {
        block(nil, [NSError errorWithDomain:@"wm extract parameter error" code:-1 userInfo:nil]);
        return;
    }
        double begin = CACurrentMediaTime();
    runAsynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];

        GLuint texId = [BMWGLUtils setupTexture:image];
        CGSize size = scaledSize;
        GLfloat vertices[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f,  1.0f,
            1.0f,  1.0f,
        };

        // resize draw
#if 1
                BMWBaseDrawer *resizeDrawer = [[BMWBaseDrawer alloc] init];
        BMWFramebuffer *resizeFBO = [[BMWFramebuffer alloc] initWithSize2:size imageContext:self.context];
        [resizeFBO bind];
        [resizeDrawer drawWithTexId:texId vertices:vertices rotation:kXHImageNoRotation];
        [BMWBlindWatermarkUtils printBuffer:resizeFBO tag:@"resize"];
#endif

        //rgb2yuv
        BMWRGB2YUVDrawer *rgb2yuvDrawer = [[BMWRGB2YUVDrawer alloc] init];
        BMWFramebuffer *rgb2yuvFBO = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.context];
        [rgb2yuvFBO bind];
        [rgb2yuvDrawer renderTextureId:resizeFBO.texture vertices:vertices];
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

        // dct -> wm extract
        CGSize wmSize = CGSizeMake(size.width/8, size.height/8);
        BMWDctWmExtractDrawer *extractDrawer = [[BMWDctWmExtractDrawer alloc] init:CGSizeMake(size.width, size.height)];
        BMWFramebuffer *extractFBO = [[BMWFramebuffer alloc] initWithSize:wmSize imageContext:self.context];
        [extractFBO bind];
        [extractDrawer renderTextureId:dwt2FBO.texture wmBitsCount:wmLen vertices:vertices];
        [BMWBlindWatermarkUtils printBuffer:extractFBO tag:@"extract"];

        // wm bit merge
        BMWWmMergeDrawer *mergeDrawer = [[BMWWmMergeDrawer alloc] init:wmSize wmSize:WM_BLOCK];
        BMWFramebuffer *mergeFBO = [[BMWFramebuffer alloc] initWithSize:CGSizeMake(WM_BLOCK, WM_BLOCK) imageContext:self.context];
        [mergeFBO bind];
        [mergeDrawer renderTextureId:extractFBO.texture wmBitsCount:wmLen vertices:vertices];
        [BMWBlindWatermarkUtils printBuffer:mergeFBO tag:@"merged"];
        glFinish();

        CVPixelBufferRef buffer = mergeFBO.renderTarget;
        CVPixelBufferLockBaseAddress(buffer, 0);
        unsigned char* pixelData = (unsigned char *)CVPixelBufferGetBaseAddress(buffer);
        unsigned char wmData[WM_BLOCK*WM_BLOCK];
        CVPixelBufferUnlockBaseAddress(buffer, 0);
        for(int i = 0; i < WM_BLOCK*WM_BLOCK; i++) {
            wmData[i] = pixelData[i*4+2];
        }

        NSString *wm = [NSString stringWithCString:(const char*)wmData encoding:NSASCIIStringEncoding];

        glDeleteTextures(1, (const GLuint *)&texId);
#if 1
        [resizeDrawer destory];
        [resizeFBO destroy];
#endif

        [rgb2yuvDrawer destory];
        [rgb2yuvFBO destroy];

        [dwtDrawer destory];
        [dwtFBO destroy];

        [dwt2Drawer destory];
        [dwt2FBO destroy];

        [extractDrawer destory];
        [extractFBO destroy];

        [mergeDrawer destory];
        [mergeFBO destroy];
        dispatch_async(dispatch_get_main_queue(), ^{
            !block ? : block(wm, nil);
        });
        double end = CACurrentMediaTime();
            });
}

- (void)extract:(UIImage*)image completeBlock:(void (^)(BMWWatermarkResultModel* model, NSError *_Nullable error))block
{
    BMWBlindWatermarkModel *model = BMWBlindWatermarkModel.defaultModel;
    int wmLen = model.watermarkImage.size.width * model.watermarkImage.size.height;
    CGSize size = model.watermarkSliceSize;
    CGRect rect = [model watermarkRectByRatio:image.size.width / image.size.height];
    double begin = CACurrentMediaTime();
    runAsynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];

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
        GLfloat vertices[] = {
            -1.0f, -1.0f,
            1.0f, -1.0f,
            -1.0f,  1.0f,
            1.0f,  1.0f,
        };

        GLuint texId = [BMWGLUtils setupTexture:image];

        // crop draw
        BMWBaseDrawer *cropDrawer = [[BMWBaseDrawer alloc] init];
        BMWFramebuffer *cropFBO = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.context];
        [cropFBO bind];
        [cropDrawer drawWithTexId:texId vertices:vertices coordinates:coordinates];
        [BMWBlindWatermarkUtils printBuffer:cropFBO tag:@"crop"];

        //rgb2yuv
        BMWRGB2YUVDrawer *rgb2yuvDrawer = [[BMWRGB2YUVDrawer alloc] init];
        BMWFramebuffer *rgb2yuvFBO = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.context];
        [rgb2yuvFBO bind];
        [rgb2yuvDrawer renderTextureId:cropFBO.texture vertices:vertices];
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

        // dct -> wm extract
        CGSize wmSize = CGSizeMake(size.width/8, size.height/8);
        BMWDctWmExtractDrawer *extractDrawer = [[BMWDctWmExtractDrawer alloc] init:CGSizeMake(size.width, size.height)];
        BMWFramebuffer *extractFBO = [[BMWFramebuffer alloc] initWithSize:wmSize imageContext:self.context];
        [extractFBO bind];
        [extractDrawer renderTextureId:dwt2FBO.texture wmBitsCount:wmLen vertices:vertices];
        [BMWBlindWatermarkUtils printBuffer:extractFBO tag:@"extract"];

        // merge
        BMWWmMergeDrawer2 *mergeDrawer = [[BMWWmMergeDrawer2 alloc] init:wmSize wmSize:model.watermarkImage.size];
        BMWFramebuffer *mergeFBO = [[BMWFramebuffer alloc] initWithSize2:model.watermarkImage.size imageContext:self.context];
        [mergeFBO bind];
        [mergeDrawer drawWithTexId:extractFBO.texture];
        [BMWBlindWatermarkUtils printBuffer:mergeFBO tag:@"merge"];

        glFinish();
        UIImage* wmImage = mergeFBO.imageFromFramebufferContent;
        UIImage* oriWmImage = model.watermarkImage;
#if 0
        oriWmImage = [self reMapImage:model.watermarkImage];
        wmImage = [self reMapImage:wmImage];
#endif
        // check similarity
        BMWWatermarkResultModel *resultMode = [self checkSimilarity:oriWmImage extractWmImage:wmImage];
        dispatch_async(dispatch_get_main_queue(), ^{
            resultMode.watermarkImage = wmImage;
            !block ? : block(resultMode, nil);
        });
        glDeleteTextures(1, (const GLuint *)&texId);

        [cropDrawer destory];
        [cropFBO destroy];

        [rgb2yuvDrawer destory];
        [rgb2yuvFBO destroy];

        [dwtDrawer destory];
        [dwtFBO destroy];

        [dwt2Drawer destory];
        [dwt2FBO destroy];

        [extractDrawer destory];
        [extractFBO destroy];

        [mergeDrawer destory];
        [mergeFBO destroy];

        double end = CACurrentMediaTime();
            });
}

- (UIImage*)reMapImage:(UIImage*)oriImage
{
    static int indexArray[16*16] = {194, 211, 244, 146, 47, 144, 94, 65, 70, 17, 20, 147, 38, 101, 205, 140, 119, 164, 92, 161, 181, 214, 129, 247, 122, 95, 6, 242, 193, 165, 234, 196, 231, 133, 138, 77, 102, 74, 207, 227, 111, 176, 168, 157, 171, 206, 105, 90, 66, 217, 117, 155, 63, 235, 229, 156, 245, 216, 236, 83, 39, 166, 53, 121, 172, 67, 127, 45, 208, 100, 135, 120, 26, 226, 131, 198, 13, 187, 222, 7, 241, 186, 78, 203, 33, 22, 59, 219, 15, 184, 145, 107, 12, 115, 191, 44, 76, 143, 80, 213, 162, 56, 2, 252, 132, 1, 237, 29, 142, 84, 52, 82, 221, 189, 224, 128, 202, 54, 200, 51, 125, 23, 137, 228, 0, 253, 153, 209, 48, 35, 41, 75, 30, 108, 201, 88, 195, 246, 139, 68, 149, 96, 72, 159, 50, 134, 173, 124, 103, 24, 112, 188, 9, 8, 113, 81, 21, 110, 250, 160, 58, 106, 130, 19, 212, 11, 178, 49, 46, 37, 114, 31, 150, 91, 199, 169, 71, 223, 28, 204, 141, 62, 225, 25, 32, 177, 5, 18, 55, 240, 89, 152, 34, 43, 192, 238, 4, 175, 40, 255, 185, 126, 197, 118, 123, 174, 170, 148, 64, 220, 14, 158, 254, 183, 230, 136, 248, 27, 243, 57, 251, 167, 99, 182, 97, 87, 218, 36, 116, 109, 154, 151, 73, 16, 190, 210, 180, 215, 79, 163, 179, 85, 249, 10, 60, 239, 233, 86, 93, 104, 232, 3, 61, 98, 69, 42};

    int width = oriImage.size.width;
    int height = oriImage.size.height;
    CGImageRef imageSource = oriImage.CGImage;
    CFDataRef oriDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(imageSource));
    unsigned char *oriBuffer = NULL;
    if(oriDataProvider != NULL) {
        oriBuffer = (unsigned char *)CFDataGetBytePtr(oriDataProvider);
    }
    unsigned char *newBuffer = (unsigned char *)malloc(width * height * 4);
    for (int v = 0; v < height; v++) {
        for (int u = 0; u < width; u++) {
            int index = v*width + u;
            int newIndex = indexArray[index];
            index = index * 4;
            newIndex = newIndex * 4;
            *((int*)(newBuffer+index)) = *((int*)(oriBuffer+newIndex));
        }
    }
    CFRelease(oriDataProvider);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, newBuffer, width*height*4, NULL);
    CGImageRef cgImage2 = CGImageCreate(width, height, 8, 8 * 4, width*4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault, provider, NULL, NO, kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:cgImage2];
    CGDataProviderRelease(provider);
    CGImageRelease(cgImage2);
    CGColorSpaceRelease(colorSpace);
    return image;
}

// ref
// https://searchcode.com/codesearch/view/26663229/
// http://git.videolan.org/?p=ffmpeg.git;a=blob;f=tests/tiny_psnr.c;hb=HEAD
- (BMWWatermarkResultModel*)checkSimilarity:(UIImage*)oriWmImage extractWmImage:(UIImage*)extractWmImage
{
    CGImageRef oriWmImageSource = oriWmImage.CGImage;
    CFDataRef oriWmImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(oriWmImageSource));
    unsigned char *oriWmBuffer = (unsigned char *)CFDataGetBytePtr(oriWmImageDataProvider);
    CGImageRef extractWmImageSource = extractWmImage.CGImage;
    CFDataRef extractWmImageDataProvider = CGDataProviderCopyData(CGImageGetDataProvider(extractWmImageSource));
    unsigned char *extractWmImageBuffer = (unsigned char *)CFDataGetBytePtr(extractWmImageDataProvider);

    int width = oriWmImage.size.width;
    int height = oriWmImage.size.height;

    int oriStride = (int)CGImageGetBytesPerRow(oriWmImageSource);
    int extStride = (int)CGImageGetBytesPerRow(extractWmImageSource);
    float allSimilarity = similarityCheck("all",
                                          oriWmBuffer, 0 , oriStride,
                                          extractWmImageBuffer, 0 , extStride, width, height);

    float topSimilarity = similarityCheck("top",
                                          oriWmBuffer, 0 , oriStride,
                                          extractWmImageBuffer, 0 , extStride, width, height/2);

    float bottomSimilarity = similarityCheck("bottom",
                                             oriWmBuffer, height/2 , oriStride,
                                             extractWmImageBuffer, height/2 , extStride, width, height/2);

    if (oriWmImageDataProvider) {
        CFRelease(oriWmImageDataProvider);
    }
    if (extractWmImageDataProvider) {
        CFRelease(extractWmImageDataProvider);
    }
    BMWWatermarkResultModel* model = [[BMWWatermarkResultModel alloc] init];
    model.allSimilarity = allSimilarity;
    model.topSimilarity = topSimilarity;
    model.bottomSimilarity = bottomSimilarity;
    return model;
}

float similarityCheck(char* tag,
                      unsigned char* ori, int oriOffsetY, int oriStride,
                      unsigned char* ext, int extOffsetY, int extStride,
                      int width, int height) {

    unsigned char *oriWmBufferOne = (unsigned char *)malloc(width * height);
    unsigned char *extractWmImageBufferOne = (unsigned char *)malloc(width * height);

    for (int v = 0; v < height; v++) {
        for (int u = 0; u < width; u++) {
            int index = (v+oriOffsetY) * oriStride + 4*u;
            int index2 = v * width + u;
            oriWmBufferOne[index2] = ori[index];
        }
    }

    for (int v = 0; v < height; v++) {
        for (int u = 0; u < width; u++) {
            int index = (v+extOffsetY) * extStride + 4*u;
            int index2 = v * width + u;
            extractWmImageBufferOne[index2] = ext[index];
        }
    }
    int *temp = (int *)malloc((2*width+12)*sizeof(*temp));
    float similarity = ssim_plane(oriWmBufferOne, width, extractWmImageBufferOne, width, width, height, temp, NULL);
    if(temp != NULL) {
        free(temp);
    }
    if(oriWmBufferOne != NULL) {
        free(oriWmBufferOne);
    }
    if(extractWmImageBufferOne != NULL) {
        free(extractWmImageBufferOne);
    }
    return similarity;
}

static void BMWWatermarkExtractor_dataProviderReleaseCallback(void * __nullable info, const void * data, size_t size)
{
    if (data != NULL) {
        free((void*)data);
    }
}
- (UIImage*)readImageWithBuffer:(CVPixelBufferRef)pixelBuffer outSize:(CGSize)outSize
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    int width = (int)CVPixelBufferGetWidth(pixelBuffer);
    int height = (int)CVPixelBufferGetHeight(pixelBuffer);
    int stride = (int)CVPixelBufferGetBytesPerRow(pixelBuffer);
    unsigned char *ori = CVPixelBufferGetBaseAddress(pixelBuffer);
    unsigned char *buffer = (unsigned char *)malloc(width * height * 4);
    for (int v = 0; v < height; v++) {
        for (int u = 0; u < width; u++) {
            int index = v*stride + 4*u;
            int index2 = v*width*4 + 4*u;
            *((int*)(buffer+index2)) = *((int*)(ori+index));
        }
    }
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, outSize.width*outSize.height*4, BMWWatermarkExtractor_dataProviderReleaseCallback);
    CGImageRef cgImage2 = CGImageCreate(outSize.width, outSize.height, 8, 8 * 4, outSize.width*4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault, provider, NULL, NO, kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:cgImage2];
    CGDataProviderRelease(provider);
    CGImageRelease(cgImage2);
    CGColorSpaceRelease(colorSpace);
    return image;
}
@end
