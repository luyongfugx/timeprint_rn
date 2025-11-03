#import "BMWImageProcessRequest.h"
#import "BMWImageRender.h"
#import "BMWImageContext.h"
#import "BMWBufferUtils.h"
#import "BMWGLUtils.h"
#import "BMWWatermarkItem.h"

@implementation BMWOrginalRenderModel
@end

@implementation BMWProcessRenderModel
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.effectType = BMWEffectTypeUnknown;
        self.enableImageFeature = YES;
    }
    return self;
}
@end

@implementation BMWOrginalMetaData
- (instancetype)init
{
    self = [super init];
    if (self) {
        self.previewCapturedSimilarity = -1;
        self.previewClarity = -1;
        self.capturedClarity = -1;
    }
    return self;
}
- (NSString *)description
{
    return [NSString stringWithFormat:@"clarityDetectModel: {similarity:%lf, previewClarity:%lf, capturedClarity:%lf}", self.previewCapturedSimilarity, self.previewClarity, self.capturedClarity];
}

@end

@implementation BMWPocessedMetaData
- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"pocessedMetaData: {imageFeature:%@}", self.imageFeature];
}
@end

@interface BMWImageProcessRequest ()
@property (nonatomic) long long requesId;
@end

@implementation BMWImageProcessRequest

- (void)dealloc
{
    }

- (instancetype)init
{
    if(self = [super init]) {
        self.requesId = CACurrentMediaTime() * 1000;
    }
    return self;
}

@end

@implementation BMWImageProcessBuilder : NSObject

+ (BMWImageProcessRequest*)build:(void(^)(BMWImageProcessRequest * maker))block
{
    BMWImageProcessRequest *request = [[BMWImageProcessRequest alloc] init];
    !block ? : block(request);
    return request;
}
@end
