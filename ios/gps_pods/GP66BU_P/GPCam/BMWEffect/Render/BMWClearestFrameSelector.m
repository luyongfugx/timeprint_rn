#import "BMWClearestFrameSelector.h"
#import "BMWFramebuffer.h"
#import "BMWBaseDrawer.h"
#import "BMWClarityDetector.h"

static const NSUInteger kMaxFramebufferCount = 3;

@interface BMWClearestFrameSelector ()

@property (nonatomic, strong) NSMutableArray<BMWFramebuffer *> *framebuffers;

@property (nonatomic, strong) NSMutableArray<NSValue *> *frameTimestamps;

@property (nonatomic, assign) CGSize bufferSize;

@property (nonatomic, strong) BMWImageContext *imageContext;

@property (nonatomic, strong) BMWBaseDrawer* drawer;

@property (nonatomic, strong) BMWClarityDetector *clarityDetector;

@end

@implementation BMWClearestFrameSelector

- (instancetype)initWithContext:(BMWImageContext *)imageContext {
        self = [super init];
    if (self) {
        _framebuffers = [NSMutableArray array];
        _frameTimestamps = [NSMutableArray array];
        _bufferSize = CGSizeZero;
        _imageContext = imageContext;
    }

    return self;
}

- (void)reset {
        for (BMWFramebuffer *framebuffer in self.framebuffers) {
        [framebuffer destroy];
    }
    self.framebuffers = [NSMutableArray array];
    self.frameTimestamps = [NSMutableArray array];
}

- (void)dealloc {
        BMWImageContext *context = self.imageContext;
    BMWBaseDrawer *drawer = self.drawer;
    NSMutableArray *framebuffers = self.framebuffers;
    self.framebuffers = nil;
    runAsynchronouslyOnContextQueue(context, ^{
        [context useAsCurrentContext];
        [drawer destory];
        for (BMWFramebuffer *framebuffer in framebuffers) {
            [framebuffer destroy];
        }
        [framebuffers removeAllObjects];
    });
}

- (void)onVideoFrameArrived:(GLuint)textureId size:(CGSize)size timestamp:(CMTime)timestamp {
    if (!CGSizeEqualToSize(_bufferSize, size)) {
        _bufferSize = size;
        [self reset];
    }

    if (!self.drawer) {
        self.drawer = [[BMWBaseDrawer alloc] init];
    }

    [self.frameTimestamps addObject:[NSValue valueWithCMTime:timestamp]];

    BMWFramebuffer *framebuffer = nil;
    if (self.framebuffers.count < kMaxFramebufferCount) {
        framebuffer = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.imageContext];
    } else {
        framebuffer = self.framebuffers.firstObject;
        [self.framebuffers removeObjectAtIndex:0];
        [self.frameTimestamps removeObjectAtIndex:0];
    }

    [framebuffer bind];
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    [self.drawer resetMatrix];
    [self.drawer setInputTexId:textureId];
    [self.drawer draw];

    [self.framebuffers addObject:framebuffer];
}

- (UIImage *)getClearestFrameWithMirror:(BOOL)mirror orientation:(BMWDeviceOrientation)orientation timestamp:(CMTime *)timestamp frameIndex:(NSInteger *)frameIndex {
    if (self.framebuffers.count == 0) {
        return nil;
    }

    double beginTime = CACurrentMediaTime();

    if (!self.clarityDetector) {
        self.clarityDetector = [[BMWClarityDetector alloc] initWithContext:self.imageContext];
    }

    NSInteger clearestIndex = -1;
    CGFloat clearest = -1;
    for (NSInteger i = 0; i < self.framebuffers.count; i++) {
        CGSize size = self.framebuffers[i].bufferSize;
        CGFloat min = MIN(size.width, size.height);
        CGFloat ratio = 640 / min;
        CGSize detectSize = CGSizeMake(size.width * ratio, size.height * ratio);
        CGFloat clearness = [self.clarityDetector detectWithTexId:self.framebuffers[i].texture texSize:detectSize];
        if (clearness > clearest || clearestIndex == -1) {
            clearest = clearness;
            clearestIndex = i;
        }
            }

    BMWFramebuffer *framebuffer = self.framebuffers[clearestIndex];
    if (timestamp) {
        *timestamp = [self.frameTimestamps[clearestIndex] CMTimeValue];
    }
    if (frameIndex) {
        *frameIndex = self.framebuffers.count - 1 - clearestIndex;
    }

    [self.drawer resetMatrix];
    [self.drawer setInputTexId:framebuffer.texture];
    CGSize size = framebuffer.bufferSize;
    if (orientation == BMWDeviceOrientationPortait) {
        [self.drawer rotateZ:0];
    } else if (orientation == BMWDeviceOrientationRight) {
        [self.drawer rotateZ:M_PI_2];
        size = CGSizeMake(size.height, size.width);
    } else if (orientation == BMWDeviceOrientationDown) {
        [self.drawer rotateZ:M_PI];
    } else if (orientation == BMWDeviceOrientationLeft) {
        [self.drawer rotateZ:-M_PI_2];
        size = CGSizeMake(size.height, size.width);
    }

    BMWFramebuffer* previewFBO = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.imageContext];
    previewFBO.tag = @"previewFBO";
    [self.drawer scaleX:mirror ? -1.0f : 1.0f scaleY:1.0f];
    [previewFBO bind];
    [self.drawer draw];
    glFinish();
    UIImage *image = previewFBO.imageFromFramebufferContent;
    [previewFBO destroy];

    double endTime = CACurrentMediaTime();

    return image;
}

@end
