#import "BMWCodeDataModel.h"
#import "BMWCodeHelper.h"
#import "BMWBlindWatermarkModel.h"

@implementation BMWCodeDataModel

- (instancetype)init
{
    if (self = [super init]) {
        self.digitCount = BMWCodeHelper.sharedInstance.digitCount;
        self.longitude = -1.f;
        self.latitude = -1.f;
    }
    return self;
}

+ (BMWCodeDataModel*)buildWithTimestampS:(NSUInteger)timestamp longitude:(float)longitude latitude:(float)latitude
{
    BMWCodeDataModel *model = [[BMWCodeDataModel alloc] init];
    model.version = BMWAntiCodeVersionTimeAndXY;
    model.timestampFormat = 0;
    model.timeStamp = timestamp;
    model.longitude = longitude;
    model.latitude = latitude;
    model.bwmId = BMWBlindWatermarkModel.defaultModel.bwmId;
    [BMWCodeHelper.sharedInstance genCode:model];
    return model.code.length > 0 ? model : nil;
}

+ (BMWCodeDataModel*)buildWithTimestampMS:(NSUInteger)timestamp locationType:(NSUInteger)locationType
{
    BMWCodeDataModel *model = [[BMWCodeDataModel alloc] init];
    model.version = BMWAntiCodeVersionTimeAndLocationType;
    model.timestampFormat = 1;
    model.timeStamp = timestamp;
    model.locationType = locationType;
    model.bwmId = BMWBlindWatermarkModel.defaultModel.bwmId;
    [BMWCodeHelper.sharedInstance genCode:model];
    return model.code.length > 0 ? model : nil;
}

// [3.0.125新]根据雪花ID构建模型
+ (BMWCodeDataModel* __nullable)buildWithVersion:(NSUInteger)version timestampMS:(NSUInteger)timestamp locationType:(NSUInteger)locationType longitude:(float)longitude latitude:(float)latitude id:(NSString*)snowFlakeId;
{
    BMWCodeDataModel *model = [[BMWCodeDataModel alloc] init];
    model.version = version == 0 ? BMWAntiCodeVersionTimeAndLocationType : BMWAntiCodeVersionTimeAndLocationType2;
    model.timestampFormat = 1;
    model.timeStamp = timestamp;
    if(locationType == 4) {
        model.version = version == 0 ?  BMWAntiCodeVersionTimeAndXY: BMWAntiCodeVersionTimeAndXY2;
        model.timestampFormat = 0;
        model.timeStamp = timestamp / 1000;
    }
    model.snowFlakeId = snowFlakeId;
    model.locationType = locationType;
    model.longitude = longitude;
    model.latitude = latitude;
    model.bwmId = BMWBlindWatermarkModel.defaultModel.bwmId;
    [BMWCodeHelper.sharedInstance genCode:model];
    return model.code.length > 0 ? model : nil;
}

+ (BMWCodeDataModel* __nullable)buildWithCode:(NSString*)code
{
    BMWCodeDataModel *model = [[BMWCodeDataModel alloc] init];
    model.code = code;
    [BMWCodeHelper.sharedInstance deCode:model];
    return model;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"codeMetaModel: {code:%@, valid:%@, version:%@, timeStamp:%@, longitude:%@, latitude:%@, locationType:%@, bwmId:%@}", self.code, @(self.valid), @(self.version), @(self.timeStamp), @(self.longitude), @(self.latitude), @(self.locationType), @(self.bwmId)];
}

@end
