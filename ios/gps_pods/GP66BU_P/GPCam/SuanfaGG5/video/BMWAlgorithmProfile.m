#import "BMWAlgorithmProfile.h"
#import "BMWSliceData.h"

@implementation BMWAlgorithmProcessProfile
- (instancetype)init
{
    if (self = [super init]) {
        self.orient = BMWDeviceOrientationPortait;
        self.rectOfInterest = BMWRectFull();
        self.enableSmooth = NO;
    }
    return self;
}
@end

@implementation BMWAlgorithmConfigModel

- (instancetype)init
{
    if (self = [super init]) {
        self.size = 640;
        self.probThreshold = 0.5f;
        self.nmsThreshold = 0.3f;
    }
    return self;
}

+ (NSString*)buildJsonFromModel:(BMWAlgorithmConfigModel*)model
{
    NSString* modelJsonStr = model2JosnString(model);
    return modelJsonStr;
}

+ (BMWAlgorithmConfigModel*)buildModel:(NSArray<NSString*>*)labels
{
    BMWAlgorithmConfigModel* model = [[BMWAlgorithmConfigModel alloc] init];
    model.labels = labels;
    return model;
}

+ (BMWAlgorithmConfigModel*)buildModelFromJsonPath:(NSString*)jsonPath
{
    BMWAlgorithmConfigModel* model = nil;
    do {
        NSData* jsonData = [[NSData alloc] initWithContentsOfFile:jsonPath];
        if (jsonData.length == 0) {
            break;
        }
        NSError *error = nil;
        NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        if(error) {
                        break;
        }

        model = [MTLJSONAdapter modelOfClass:[BMWAlgorithmConfigModel class] fromJSONDictionary:jsonDic error:&error];

        if(error || model == nil) {
                        break;
        }
    } while (0);
    return model;
}
@end
