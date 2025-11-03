#import "BMWVideoAlgorithmOCRSource.h"
#import "BMWImageContext.h"
#import "BMWGLUtils.h"
#import "BMWOCRProcessDrawer.h"
#import "BMWFramebuffer.h"
#import "BMWCodeHelper.h"

@interface BMWVideoAlgorithmOCRSource ()
@property (nonatomic) NSUInteger level;
@property (nonatomic) CGFloat ratio;
@property (nonatomic) GLuint texId;
@property (nonatomic) BMWOCRProcessDrawer *drawer;
@property (nonatomic) BMWFramebuffer *framebuffer;
@property (nonatomic) CGRect rect;

@end

@implementation BMWVideoAlgorithmOCRSource

+ (int)maxRetryCount
{
    return 10 * [self officalWatermarkStyleArray].count;
}

+ (NSArray<NSNumber*>*)officalWatermarkStyleArray
{
    static NSArray<NSNumber*>* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = @[@(0), @(BMWOfficalWatermarkStyleBlueRealTimeFix)];
        }
    });
    return instance;
}

- (void)dealloc
{
    runSynchronouslyRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        [self clear];
    });
}

- (instancetype)initWithImage:(UIImage*)image size:(CGSize)size level:(NSUInteger)level
{
    self = [super init];
    if (!self) {
        return nil;
    }
    runSynchronouslyRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        NSArray<NSNumber*>* styleArray = [self.class officalWatermarkStyleArray];
        //01/23/45/67/89/1011/1213/1415/1617/1819
        self.level = level / styleArray.count;
        NSInteger style = styleArray[level % styleArray.count].integerValue;
        CGSize newSize = CGSizeMake((NSUInteger)size.width, (NSUInteger)size.height);
        self.ratio = newSize.width / newSize.height;
        self.rect = [BMWCodeHelper.sharedInstance codeRect:self.ratio style:style isCode:YES];

        CGFloat brightness = -0.62;
        NSUInteger sizeType = 0;
        if (self.level == 0) {
            sizeType = 0;
            brightness = -0.62;
        }
        else if (self.level == 1) {
            sizeType = 2;
            brightness = -0.62;
        }
        else if (self.level == 2) {
            sizeType = 1;
            brightness = -0.62;
        }
        else if (self.level == 3) {
            sizeType = 0;
            brightness = -0.9;
        }
        else if (self.level == 4) {
            sizeType = 0;
            brightness = -0.8;
        }
        else if (self.level == 5) {
            sizeType = 0;
            brightness = -0.7;
        }
        else if (self.level == 6) {
            sizeType = 0;
            brightness = -0.4;
        } else if (self.level == 7) {
            sizeType = 0;
            brightness = 0.0;
        }
        else if (self.level == 8) {
            sizeType = 0;
            brightness = 0.2;
        }
        else if (self.level == 9) {
            sizeType = 0;
            brightness = 0.3;
        } else if (self.level == 10) {
            sizeType = 0;
            brightness = -0.62;
        }
        [[NSUserDefaults standardUserDefaults] setFloat:brightness forKey:@"ocr_brightness_key"];
        if (sizeType == 1) {
            if (MAX(newSize.width, newSize.height) < 1600) {
                CGFloat high = 1600;
                if (self.ratio > 1.0) {
                    newSize = CGSizeMake(high, (int)(high/self.ratio));
                } else {
                    newSize = CGSizeMake((int)(high*self.ratio), high);
                }
            }
            int w = ((int)(self.rect.size.width * newSize.width)+3)/4*4;
            int h = ((int)(self.rect.size.height * newSize.height)+3)/4*4;
            newSize = CGSizeMake(w, h);
        } else {
            if (sizeType == 2) {
                self.rect = CGRectMake(self.rect.origin.x, self.rect.origin.y, 1.0-self.rect.origin.x, 1.0-self.rect.origin.y);
            }
            CGFloat r = self.rect.size.width / self.rect.size.height;
            int h = 32;
            int w = ((int)(h * r) + 3) / 4 * 4;
            newSize = CGSizeMake(w, h);
        }
        [self setup:BMWImageContext.sharedImageProcessingContext size:newSize];
        self.texId = [BMWGLUtils setupTexture:image];
            });
    return self;
}

// override
- (void)clear
{
    if (self.drawer) {
        [self.drawer destory];
        self.drawer = nil;
    }
    if (self.framebuffer) {
        [self.framebuffer destroy];
        self.framebuffer = nil;
    }
    if (self.texId > 0) {
        glDeleteTextures(1, &_texId);
        _texId = 0;
    }
}

// override
- (void)setup:(BMWImageContext*)context size:(CGSize)size
{
    self.drawer = [[BMWOCRProcessDrawer alloc] init];
    self.framebuffer = [[BMWFramebuffer alloc] initWithSize:size imageContext:BMWImageContext.sharedImageProcessingContext];
}

// override
- (NSString*)tag
{
    return @"ImageSourceForOCR";
}

// override
- (void)pull
{
    runAsynchronouslyOnRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        [super triggerAllDelegates:self.texId orientation:BMWDeviceOrientationPortait];
    });
}

// override
- (CVPixelBufferRef)render:(BMWVideoAlgorithmSourceProfile*)profile;
{
    [self.framebuffer bind];
    [self.drawer resetMatrix];

    static GLfloat vertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    GLfloat l = _rect.origin.x;
    GLfloat t = _rect.origin.y;
    GLfloat r = (l + _rect.size.width);
    GLfloat b = (t + _rect.size.height);
    const GLfloat coordinates[8] = {
        l, t,
        r, t,
        l, b,
        r, b,
    };
    [self.drawer drawWithTexId:profile.textureId vertices:vertices coordinates:coordinates];
    glFinish();
    CVPixelBufferRef pixelBuffer = self.framebuffer.renderTarget;
    return pixelBuffer;
}

@end
