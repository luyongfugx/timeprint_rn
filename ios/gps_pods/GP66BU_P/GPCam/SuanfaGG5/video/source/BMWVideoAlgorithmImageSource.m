#import "BMWVideoAlgorithmImageSource.h"
#import "BMWDeviceUtils.h"
#import "BMWImageContext.h"
#import "BMWGLUtils.h"
#import "BMWLittleImageDrawer.h"

static int MAX_RETRY_COUNT = 6;
@interface BMWVideoAlgorithmImageSource ()

@property (nonatomic) GLuint textId;
@property (nonatomic) NSUInteger retryCount;

@end

@implementation BMWVideoAlgorithmImageSource

- (void)dealloc
{
    runSynchronouslyRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        [super clear];
        glDeleteTextures(1, &_textId);
    });
}

- (instancetype)initWithImage:(UIImage*)image size:(CGSize)size
{
    self = [super init];
    if (!self) {
        return nil;
    }
    runSynchronouslyRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        [super setup:BMWImageContext.sharedImageProcessingContext size:size];
        self.textId = [BMWGLUtils setupTexture:image];
    });
    return self;
}

- (instancetype)initWithImage:(UIImage*)image
{
    CGFloat ratio = image.size.width / image.size.height;
    CGFloat low = [BMWDeviceUtils isLowerThaniPhone7] ? 480 : 720;
    CGSize size;
    if (ratio > 1.0) {
        size = CGSizeMake((int)(low*ratio), low);
    } else {
        size = CGSizeMake(low, (int)(low/ratio));
    }
    return [self initWithImage:image size:size];
}

// override
- (NSString*)tag
{
    return @"ImageSource";
}

// override
- (void)pull
{
    runAsynchronouslyOnRenderingQueue(^{
        self.retryCount = 0;
        [BMWImageContext useImageProcessingContext];
        [super triggerAllDelegates:self.textId orientation:BMWDeviceOrientationPortait];
    });
}

// override
- (CVPixelBufferRef)render:(BMWVideoAlgorithmSourceProfile*)profile;
{
    const GLfloat* co = [self retryCoordinates:self.retryCount];
    self.retryCount++;
    self.littleImageDrawer.isMirror = profile.isMirror;
    self.littleImageDrawer.deviceOrientation = profile.orientation;
    [self.littleImageDrawer draw:profile.textureId coordinates:co];
    CVPixelBufferRef pixelBuffer = self.littleImageDrawer.framebuffer.renderTarget;
    return pixelBuffer;
}

// override
- (BOOL)retry
{
        if (self.retryCount > MAX_RETRY_COUNT) {
        self.retryCount = 0;
        return NO;
    }
    runAsynchronouslyOnRenderingQueue(^{
        [BMWImageContext useImageProcessingContext];
        [super triggerAllDelegates:self.textId orientation:BMWDeviceOrientationPortait force:YES timestamp:-1];
    });
    return YES;
}

- (const GLfloat*)retryCoordinates:(NSUInteger)index
{
    static const GLfloat coordinates[7][8] = {
        { //0 FULL
            0.0f, 0.0f,
            1.0f, 0.0f,
            0.0f, 1.0f,
            1.0f, 1.0f,
        },
        { //1 CENTER
            0.2f, 0.2f,
            0.8f, 0.2f,
            0.2f, 0.8f,
            0.8f, 0.8f,
        },
        { //2 LEFT-BOTTOM
            0.0f, 0.35f,
            0.65f, 0.35f,
            0.0f, 1.0f,
            0.65f, 1.0f,
        },
        { //3 RIGHT-BOTTOM
            0.35f, 0.35f,
            1.0f, 0.35f,
            0.35f, 1.0f,
            1.0f, 1.0f,
        },
        { //4 RIGHT-TOP
            0.0f, 0.0f,
            0.65f, 0.0f,
            0.0f, 0.65f,
            0.65f, 0.65f,
        },
        { //5 RIGHT-BOTTOM
            0.35f, 0.0f,
            1.0f, 0.0f,
            0.35f, 0.65f,
            1.0f, 0.65f,
        },
        { //6 SMALL
            0.0f, 0.0f,
            1.6f, 0.0f,
            0.0f, 1.6f,
            1.6f, 1.6f,
        },
    };

   return coordinates[index];
}

@end
