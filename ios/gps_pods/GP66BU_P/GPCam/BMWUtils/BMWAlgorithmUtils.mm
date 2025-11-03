#import "BMWAlgorithmUtils.h"
#import <AVFoundation/AVFoundation.h>

#if CVAlgorithmgEnable
  #include <ncnn/ncnn/net.h>
#endif

// —— OpenCV 可用性与 YES/NO 宏防护 ——
// 如果你在 podspec 里定义了 OpenCVFlag=1，这里再做一次健壮探测
#if defined(OpenCVFlag) && __has_include(<opencv2/opencv.hpp>)
  #define XH_OPENCV_AVAILABLE 1
#else
  #define XH_OPENCV_AVAILABLE 0
#endif

#if XH_OPENCV_AVAILABLE
  // 避免与 UIKit 的 YES/NO 宏冲突
  #pragma push_macro("YES")
  #pragma push_macro("NO")
  #ifdef YES
  #undef YES
  #endif
  #ifdef NO
  #undef NO
  #endif

  #include <opencv2/core.hpp>
  #include <opencv2/opencv.hpp>
  #import "ImageProcessUtils.h"
  #import "BMWBufferUtils.h"
  #import "UIImage+GPCam.h"
  #import "BMWGLUtils.h"
  #import "BMWBaseDrawer.h"
  #import "BMWFramebuffer.h"

  // 仅在 OpenCV 可用时声明（否则会因为 cv::Mat 报错）
  static void CGImageToMat(const CGImageRef image, cv::Mat& m, bool alphaExist);

  // 恢复 YES/NO 宏
  #pragma pop_macro("NO")
  #pragma pop_macro("YES")
#endif

#include <stdlib.h>
#import "ssim.h"

@implementation BMWDecibelFilter

+ (int)decibelFromPcm:(const int16_t *)pcmdata size:(size_t)size
{
    return getDecibelViaMean(pcmdata, size);
}

+ (int)decibelFromPcm2:(const int16_t *)pcmdata size:(size_t)size
{
    return getDecibelViaRMS(pcmdata, size);
}

static int getDecibelViaMean(const int16_t *pcmdata, size_t size)
{
    int db = 0;
    float sum = 0;
    for(int i = 0; i < size; i++) {
        int16_t value = pcmdata[i];
        sum += abs(value);
    }
    sum = sum / size;
    db = (int)(20.0 * log10(sum) + 0.5);
    return db;
}

static const float kMaxSquaredLevel = 32768 * 32768;
static const float kMinLevel = 30;
static int getDecibelViaRMS(const int16_t *pcmdata, size_t size)
{
    int db = 0;
    float sumSquare = 0;
    for(int i = 0; i < size; i++) {
        int16_t value = pcmdata[i];
        sumSquare += value * value;
    }
    float rms = sumSquare / (size * kMaxSquaredLevel);
    rms = - 10 * log10(rms);
    if (rms < kMinLevel) {
        rms = kMinLevel;
    }
    db = (int)(rms + 0.5);
    return db;
}

@end

typedef struct __attribute__((objc_boxable)) {
    double prevData;
    double p, q, r, kGain;
} Kalman;

@interface BMWKalmanFilter ()

@property (strong, nullable) NSValue *kalman;

@end

@implementation BMWKalmanFilter
#if CVAlgorithmgEnable
static void to_argb(const ncnn::Mat& m, u_int8_t* argb)
{
    const float* ptr0 = m.channel(0);
    const float* ptr1 = m.channel(1);
    const float* ptr2 = m.channel(2);
#define SATURATE_CAST_UCHAR(X) (u_int8_t)::std::min(::std::max((int)(X), 0), 255);
    int size = m.w * m.h;
    int remain = size;
    for (; remain>0; remain--)
    {
        argb[3]=255;
        argb[0] = SATURATE_CAST_UCHAR(*ptr0);//r
        argb[1] = SATURATE_CAST_UCHAR(*ptr1);//g
        argb[2] = SATURATE_CAST_UCHAR(*ptr2);//b

        argb += 4;
        ptr0++;
        ptr1++;
        ptr2++;
    }
#undef SATURATE_CAST_UCHAR
}
#endif

void KalmanInit(Kalman *k)
{
    k->kGain = 0;
    k->p = 5;    //p初值可以随便取，但是不能为0（0的话最优滤波器了）
    k->q = 0.001;    //q参数调滤波后的曲线平滑程度，q越小越平滑
    k->r = 0.5;    //r参数调整滤波后的曲线与实测曲线的相近程度，越小越接近
    k->prevData = 0;
    return;
}

double KalmanFilter(Kalman *k, double data)
{
    k->p = k->p + k->q;
    k->kGain = k->p / (k->p + k->r);
    data = k->prevData + k->kGain * (data - k->prevData);
    k->p = (1 - k->kGain * k->p);
    k->prevData = data;
    return data;
}

- (double)kalmanFilter:(double)value
{
    Kalman kalman;
    if (self.kalman) {
        [self.kalman getValue:&kalman];
    } else {
        KalmanInit(&kalman);
    }
    double result = KalmanFilter(&kalman, value);
    self.kalman = @(kalman);
        return result;

}

- (void)reset
{
    self.kalman = nil;
}

@end

@interface BMWLinearSmoothFilter ()

@property (assign) double lastValue;

@end

@implementation BMWLinearSmoothFilter

- (instancetype)init
{
    if (self = [super init]) {
        self.factor = 0.2;
    }
    return self;
}

- (double)smoothFilter:(double)value
{
    double result = value;
    if (self.lastValue == 0) {
        self.lastValue = value;
    } else {
        result = self.factor * value + (1 - self.factor) * self.lastValue;
        self.lastValue = result;
    }
    return result;
}

- (void)reset
{
    self.lastValue = 0.0;
}

static void BMWAlgorithmUtils_dataProviderReleaseCallback(void * __nullable info, const void * data, size_t size)
{
    if(data != NULL) {
        free((void*)data);
    }
}

#if CVAlgorithmgEnable
UIImage* mat2Image(const ncnn::Mat& m)
{
    u_int8_t *newBitmap = new u_int8_t[m.h*m.w*4];
    to_argb(m, newBitmap);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, newBitmap, m.h*4*m.w, BMWAlgorithmUtils_dataProviderReleaseCallback);
    CGImageRef cgImage2 = CGImageCreate(m.w, m.h, 8, 8 * 4, m.w*4, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault, provider, NULL, NO, kCGRenderingIntentDefault);
    UIImage *image = [UIImage imageWithCGImage:cgImage2];
    CGDataProviderRelease(provider);
    CGImageRelease(cgImage2);
    CGColorSpaceRelease(colorSpace);
    return image;
}

UIImage* cvMat2Image(cv::Mat& cvMat)
{
    //获取矩阵数据
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    //判断矩阵使用的颜色空间
    CGColorSpaceRef colorSpace;
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    //创建数据privder
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    //获取bitmpa位数
    size_t bitsPerPixel = cvMat.elemSize()*8;
    //获取通道数
    size_t channels = cvMat.channels();
    //获取通道位深
    size_t bitsPerComponent = bitsPerPixel/channels;

    //创建位图信息  根据通道位深及通道数判断使用的位图信息
    CGBitmapInfo bitmapInfo;
    if(bitsPerComponent == 8) {
        if(channels == 3) {
            bitmapInfo = kCGImageAlphaNone | kCGImageByteOrderDefault;
        } else if(channels == 4){
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrderDefault;
        } else {
                        abort();
        }
    }else if(bitsPerComponent == 16) {
        if(channels == 3){
            bitmapInfo = kCGImageAlphaNone | kCGImageByteOrder16Little;
        }else if(channels == 4){
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrder16Little;
        }else{
                        abort();
        }
    }else{
                abort();
    }

    //根据矩阵及相关信息创建CGImageRef结构体
    CGImageRef imageRef = CGImageCreate(cvMat.cols, //矩阵宽度
                                        cvMat.rows, //矩阵列数
                                        bitsPerComponent,        //通道位深
                                        8 * cvMat.elemSize(),  //每个像素位深
                                        cvMat.step[0],  //每行占用字节数
                                        colorSpace,    //使用的颜色空间
                                        bitmapInfo,//通道排序、大小端读取顺序信息
                                        provider, //数据源
                                        NULL,   //解码数组 一般传null
                                        true, //是否抗锯齿
                                        kCGRenderingIntentDefault   //使用默认的渲染方式
                                        );
    // 通过cgImage转化出来UIImage对象
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    //释放imageRef
    CGImageRelease(imageRef);
    //释放provider
    CGDataProviderRelease(provider);
    //释放颜色空间
    CGColorSpaceRelease(colorSpace);
    return finalImage;
}
#endif
@end

@implementation BMWImageProcessUtils
+ (CGFloat)similarityCheck:(unsigned char*)ori
                oriOffsetY:(int)oriOffsetY
                 oriStride:(int) oriStride
                       ext:(unsigned char*)ext
                extOffsetY:(int) extOffsetY
                 extStride:(int)extStride
                     width:(int)width
                    height:(int)height
{
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

#if OpenCVFlag
+ (NSString*)imageEncode:(CVPixelBufferRef)pixelBuffer
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    cv::Mat imageMat(height, width, CV_8UC4, baseAddress, bytesPerRow);
    cv::Mat grayMat;
    cv::cvtColor(imageMat, grayMat, cv::COLOR_BGRA2GRAY);
    uint32_t filter = MEDIAN_FILTER|SOBEL_FILTER|LBP_FILTER;
    std::string code = ImageProcessUtils::filterEncode(grayMat, filter);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    NSString *nsString = [NSString stringWithUTF8String:code.data()];
    return nsString;
}

+ (float)laplacian:(CVPixelBufferRef)pixelBuffer
{
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer);
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    cv::Mat imageMat(height, width, CV_8UC4, baseAddress, bytesPerRow);
    cv::Mat grayMat,laplacian;
    cv::cvtColor(imageMat, grayMat, cv::COLOR_BGRA2GRAY);
    cv::Laplacian(grayMat, laplacian, CV_64F);
    cv::Scalar mean, stddev;
    cv::meanStdDev(laplacian, mean, stddev);
    float variance = stddev.val[0];
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    return variance;
}

#if 0
+ (NSString*)imageEncodeWithImage:(UIImage*)image size:(CGSize)size;
{
    double bg = CACurrentMediaTime();
    UIImage *resizedImage = [image xhm_resizeImage:size];
#if 0
    CVPixelBufferRef pixelBuffer = [BMWBufferUtils imageBufferFromUIImage:resizedImage];
    NSString *feature = [BMWImageProcessUtils imageEncode:pixelBuffer];
    CFRelease(pixelBuffer);
//    BMWMLog(@"imageEncodeWithImage timecost:%0.2f, feature:%@",1000*(CACurrentMediaTime()-bg), feature);
    return feature;
#else
    __block NSString *feature = @"";
    runSynchronouslyRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        __block GLuint scrId = 0;
        [BMWGLUtils getRawData:image forceRedraw:YES block:^(GLubyte * _Nonnull imageData, int width, int height, GLenum format) {
            scrId = [BMWGLUtils createTextureWithData:imageData width:width height:height];
        }];
        // draw input
        BMWBaseDrawer *inputDrawer  = [[BMWBaseDrawer alloc] init];
        BMWFramebuffer *inputFBO = [[BMWFramebuffer alloc] initWithSize:size imageContext:BMWImageContext.sharedImageProcessingContext];
        [inputFBO bind];
        [inputDrawer drawWithTexId:scrId];
        glFinish();
        feature = [BMWImageProcessUtils imageEncode:inputFBO.renderTarget];
        glDeleteTextures(1, (const GLuint *)&scrId);
        [inputFBO destroy];
        [inputDrawer destory];
    });
        return feature;
#endif
}

#else
+ (NSString*)imageEncodeWithImage:(UIImage*)image size:(CGSize)size
{
    double bg = CACurrentMediaTime();
    int w = size.width;
    int h = size.height;
    cv::Mat mat;
    cv::Mat imageMat;
    CGImageToMat(image.CGImage, mat, true);
    cv::resize(mat, imageMat, cv::Size(w, h), 0, 0, cv::INTER_LINEAR);
    cv::Mat grayMat;
    cv::cvtColor(imageMat, grayMat, cv::COLOR_BGRA2GRAY);
    uint32_t filter = MEDIAN_FILTER|SOBEL_FILTER|LBP_FILTER;
    std::string code = ImageProcessUtils::filterEncode(grayMat, filter);
    NSString *feature = [NSString stringWithUTF8String:code.data()];
        return feature;
}
#endif

static void CGImageToMat(const CGImageRef image, cv::Mat& m, bool alphaExist)
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image);
    CGFloat cols = CGImageGetWidth(image), rows = CGImageGetHeight(image);
    CGContextRef contextRef;
    CGBitmapInfo bitmapInfo = kCGImageAlphaPremultipliedLast;
    if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelMonochrome)
    {
        m.create(rows, cols, CV_8UC1); // 8 bits per component, 1 channel
        bitmapInfo = kCGImageAlphaNone;
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNone;
        else
            m = cv::Scalar(0);
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    else if (CGColorSpaceGetModel(colorSpace) == kCGColorSpaceModelIndexed)
    {
        // CGBitmapContextCreate() does not support indexed color spaces.
        colorSpace = CGColorSpaceCreateDeviceRGB();
        m.create(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNoneSkipLast |
                                kCGBitmapByteOrderDefault;
        else
            m = cv::Scalar(0);
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
        CGColorSpaceRelease(colorSpace);
    }
    else
    {
        m.create(rows, cols, CV_8UC4); // 8 bits per component, 4 channels
        if (!alphaExist)
            bitmapInfo = kCGImageAlphaNoneSkipLast |
                                kCGBitmapByteOrderDefault;
        else
            m = cv::Scalar(0);
        contextRef = CGBitmapContextCreate(m.data, m.cols, m.rows, 8,
                                           m.step[0], colorSpace,
                                           bitmapInfo);
    }
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows),
                       image);
    CGContextRelease(contextRef);
}

#else

+ (NSString*)imageEncode:(CVPixelBufferRef)pixelBuffer
{
    return @"";
}

+ (float)laplacian:(CVPixelBufferRef)pixelBuffer
{
    return 0.0f;
}

+ (NSString*)imageEncodeWithImage:(UIImage*)image
{
    return @"";
}

#endif
@end
