#import "BMWFaceAttributeAlgorithm.h"
#import "BMWDeviceUtils.h"
#import "GPCamDefine.h"
#import "BMWBufferUtils.h"
#import <AVFoundation/AVFoundation.h>
#import "BMWVideoAlgorithmResult.h"

@implementation BMWFaceAttributeAlgorithm
@synthesize tag = _tag;

- (NSString*)tag
{
    return @"face_attribute";
}

- (void)start
{
}

- (void)stop
{
}

- (id<BMWVideoAlgorithmResultInterface>)process:(void (^)(BMWAlgorithmProcessProfile * profile))builder
{
    BMWFaceAttributeAlgorithmResult *result = [[BMWFaceAttributeAlgorithmResult alloc] init];
    return result;
}

@end
