#import "BMWBlindWatermarkModel.h"
#import "BMWCodeHelper.h"

static float BASE_W = 1920.0f;
static float BASE_H = 2560.0f;
@interface BMWBlindWatermarkModel()

@end

@implementation BMWBlindWatermarkModel

- (id)init
{
    if(self = [super init]) {
    }
    return self;
}

+ (BMWBlindWatermarkModel*)sharedInstance
{
    static BMWBlindWatermarkModel* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[BMWBlindWatermarkModel alloc] init];
        }
    });
    return instance;
}

- (CGRect)watermarkRectByRatio:(float)ratio
{
    CGFloat offsetY = 0.02f;
    float scale = 2.0f;
    CGSize wmSize = self.watermarkImage.size;
    CGSize size = CGSizeMake(wmSize.width*8, wmSize.height*8);

    float W = BASE_W;
    float H = BASE_H;
    if (0.0 < ratio && ratio < 0.5*(9/16.0 + 3/4.0)) {
        W = BASE_H * 0.625;
        H = BASE_H;
    } else if (0.5*(9/16.0 + 3/4.0) <= ratio && ratio < 0.5*(3/4.0 + 1)) {
        W = BASE_H * 0.75;
        H = BASE_H;
    } else if (0.5*(3/4.0 + 1) <= ratio && ratio < 0.5*(1 + 4.0/3.0)) {
        W = BASE_H;
        H = BASE_H;
    } else if (0.5*(1 + 4.0/3.0) <= ratio && ratio < 0.5*(4.0/3.0 + 16/9.0)) {
        W = BASE_H;
        H = BASE_H * 0.75;
    } else if (0.5*(4.0/3.0 + 16/9.0) <= ratio) {
        W = BASE_H;
        H = BASE_H * 0.625;
    }
    CGRect rect = CGRectMake((W - size.width*scale) / W,
                            (H - size.height*scale) / H - offsetY,
                            size.width*scale / W,
                            size.height*scale / H);
    return rect;
}

- (void)configModel16x16x2
{
    NSString *bundlePath = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:@"CCameraLib.bundle"];
    NSString *originalFilterPath = [bundlePath stringByAppendingPathComponent:@"ttffd_008.png"];
    UIImage *image = [UIImage imageWithContentsOfFile:originalFilterPath];
    self.watermarkImage = image;
    self.type = BMWBlindWatermarkTypeImage;
    // 两bit 高位为 盲水印id；地位为平台标示，iOS为0,android为1
    self.bwmId = (0 | 0);
    CGFloat offsetY = 0.02f;
    float scale = 2.0f;
    CGSize wmSize = self.watermarkImage.size;
    CGSize size = CGSizeMake(wmSize.width*8, wmSize.height*8);
    CGRect rect = CGRectMake((BASE_W - size.width*scale) / BASE_W,
                            (BASE_H - size.height*scale) / BASE_H - offsetY,
                            size.width*scale / BASE_W,
                            size.height*scale / BASE_H);
    self.watermarkSliceSize = size;
    self.watermarkRect = rect;
}

- (void)configModel24x24
{
    CGSize size = CGSizeMake(24*8, 24*8);
    CGRect rect = CGRectMake((BASE_W - size.width) / BASE_W,
                            (BASE_H - size.height) / BASE_H,
                            size.width / BASE_W,
                            size.height / BASE_H);
    
    NSString *bundlePath = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:@"CCameraLib.bundle"];
    NSString *originalFilterPath = [bundlePath stringByAppendingPathComponent:@"wm24x24.png"];
    UIImage *image = [UIImage imageWithContentsOfFile:originalFilterPath];
    
    self.watermarkSliceSize = size;
    self.watermarkImage = image;
    self.watermarkRect = rect;
    self.type = BMWBlindWatermarkTypeImage;
    self.bwmId = 1;
}

- (void)configModel16x16x4
{
    CGSize size = CGSizeMake(16*2*8, 16*2*8);
    CGRect rect = CGRectMake((BASE_W - size.width) / BASE_W,
                            (BASE_H - size.height) / BASE_H,
                            size.width / BASE_W,
                            size.height / BASE_H);
    NSString *bundlePath = [[[NSBundle bundleForClass:self.class] bundlePath] stringByAppendingPathComponent:@"CCameraLib.bundle"];
    NSString *originalFilterPath = [bundlePath stringByAppendingPathComponent:@"ttffd_008.png"];
    UIImage *image = [UIImage imageWithContentsOfFile:originalFilterPath];
    
    self.watermarkSliceSize = size;
    self.watermarkImage = image;
    self.watermarkRect = rect;
    self.type = BMWBlindWatermarkTypeImage;
    self.bwmId = 2;
}

+ (BMWBlindWatermarkModel*)defaultModel
{
    BMWBlindWatermarkModel* model = BMWBlindWatermarkModel.sharedInstance;
    // 235使用此model
    [model configModel16x16x2];
//     [model configModel24x24];
    // [model configModel24x24x4];
    return model;
}

- (CGRect)watermarkFullRectByRatio:(float)ratio
{
    CGRect rect = [self watermarkRectByRatio:ratio];
    float top = rect.origin.y;
    CGRect rect2 = [BMWCodeHelper.sharedInstance codeRect:ratio isCode:NO];
    float left = rect2.origin.x;
    return CGRectMake(left, top, 1.0 - left, 1.0 - top);
}

@end
