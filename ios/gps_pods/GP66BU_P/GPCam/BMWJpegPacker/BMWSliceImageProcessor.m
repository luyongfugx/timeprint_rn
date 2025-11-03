#import "BMWSliceImageProcessor.h"
#import "BMWFramebuffer.h"
#import "BMWBaseDrawer.h"
#import "BMWGLUtils.h"
#import "UIView+GPCam.h"
#import "BMWWatermarkItem.h"
#import "UIImage+GPCam.h"
static float MinSliceSize = 1080.0f;

@implementation BMWSliceImageRequest
- (instancetype)init
{
    if (self = [super init]) {
        self.jpegPackerType = JpegDataOrgSlice;
    }
    return self;
}
@end

@implementation BMWSliceImageReslut

- (instancetype)init
{
    if (self = [super init]) {
        self.sliceDataModel = [[BMWSliceDataModel alloc] init];
    }
    return self;
}

@end

@interface BMWSliceImageProcessor ()
@property (nonatomic, strong) BMWImageContext *context;
@property (nonatomic, strong) BMWFramebuffer *outputFBO;
@end

static GLfloat vertices[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f,  1.0f,
    1.0f,  1.0f,
};
@implementation BMWSliceImageProcessor

- (void)dealloc
{
    [self destroy];
}

- (void)destroy
{
    runSynchronouslyOnContextQueue(self.context, ^{
        [self.context useAsCurrentContext];
        if (self.outputFBO) {
            [self.outputFBO destroy];
            self.outputFBO = nil;
        }
    });
}

- (instancetype)initWithContext:(BMWImageContext *)imageContext;
{
    if (self = [super init]) {
        _context = imageContext;
    }
    return self;
}

- (void)processSlice:(void (^)(BMWSliceImageRequest *request))builder completeBlock:(void (^)(BMWSliceImageReslut* _Nullable reslut))completeBlock
{
    double begin = CACurrentMediaTime();
    BMWSliceImageRequest *request = [[BMWSliceImageRequest alloc] init];
    SafeBlock(builder, request);
    BMWSliceImageReslut *reslut = [[BMWSliceImageReslut alloc] init];

    if (request.rectList.count == 0) {
        reslut.sliceDataModel.error = [[NSError alloc] initWithDomain:@"request.rectList.count==0" code:-1 userInfo:nil];
        SafeBlock(completeBlock, reslut);
        return;
    }
    CGFloat ratio = MinSliceSize/ MIN(request.texSize.width, request.texSize.height);
    request.outputSize = CGSizeMake(request.texSize.width*ratio, request.texSize.height*ratio);

    NSMutableArray<BMWSliceData*>* sliceDataList = [[NSMutableArray alloc] init];

    GLuint scrId = request.scrId;
    BMWBaseDrawer* inputDrawer = [[BMWBaseDrawer alloc] init];
    for (int idx = 0; idx < request.rectList.count; idx++) {
        BMWRect *newRect = request.rectList[idx];
        float TEX_COORD[] = {
                newRect.left, newRect.top,
                newRect.right, newRect.top,
                newRect.left, newRect.bottom,
                newRect.right, newRect.bottom
        };

        CGSize size = CGSizeMake(request.outputSize.width * newRect.width, request.outputSize.height * newRect.height);
        BMWFramebuffer *inputFBO = [[BMWFramebuffer alloc] initWithSize:size imageContext:self.context];
        [inputFBO bind];
        [inputDrawer drawWithTexId:scrId vertices:vertices coordinates:TEX_COORD];
        glFinish();
        UIImage* sliceImage = inputFBO.imageFromFramebufferContent;
//        NSData* sliceImageData = [sliceImage xhm_jpegData:0.45];
        NSData* sliceImageData = UIImageJPEGRepresentation(sliceImage, 0.45);
        [inputFBO destroy];
        BMWSliceData *sliceData = [BMWSliceData buildWithId:newRect.tag type:request.jpegPackerType data:sliceImageData rect:newRect];
        [sliceDataList addObject:sliceData];
    }

    if (sliceDataList.count != request.rectList.count) {
        reslut.sliceDataModel.error = [[NSError alloc] initWithDomain:@"slices data invalid" code:-2 userInfo:nil];
    }

    [inputDrawer destory];
    reslut.sliceDataModel.sliceDataList = sliceDataList;
    double end = CACurrentMediaTime();
    reslut.sliceDataModel.timeCost = (end - begin) * 1000;
        SafeBlock(completeBlock, reslut);
}

- (void)processClarityOptImage:(UIImage*)clarityOptImage completeBlock:(void (^)(BMWSliceImageReslut* _Nullable reslut))completeBlock
{
    BMWSliceImageReslut *reslut = [[BMWSliceImageReslut alloc] init];
    if (clarityOptImage == nil) {
        reslut.sliceDataModel.error = [[NSError alloc] initWithDomain:@"clarityOptImage==nil" code:-1 userInfo:nil];
        SafeBlock(completeBlock, reslut);
        return;
    }
    double begin = CACurrentMediaTime();
    NSMutableArray<BMWSliceData*>* sliceDataList = [[NSMutableArray alloc] init];
    NSData* previewImageData = UIImageJPEGRepresentation(clarityOptImage, 0.45);
    BMWSliceData *sliceData = [BMWSliceData buildWithId:JpegPackIdClarityOptImage type:JpegDataClarityOptOrg data:previewImageData rect:BMWRectFull()];
    [sliceDataList addObject:sliceData];
    reslut.sliceDataModel.sliceDataList = sliceDataList;
    double end = CACurrentMediaTime();
    reslut.sliceDataModel.timeCost = (end - begin) * 1000;
        SafeBlock(completeBlock, reslut);
}

@end
