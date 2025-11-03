#import "BMWEffectTypeItem.h"

@implementation BMWEffectTypeItem

- (instancetype)init
{
    if (self = [super init]) {
        self.catigory = @"beauty";
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    BMWEffectTypeItem *data = [[BMWEffectTypeItem alloc] init];
    data.id = self.id;
    data.catigory = [self.catigory copy];
    data.type = self.type;
    data.name = [self.name copy];
    data.path = [self.path copy];
    data.key = [self.key copy];
    return data;
}

- (NSString*)identifer;
{
    return [NSString stringWithFormat:@"%@-%@-%@-%@-%@", self.catigory, @(self.type), self.name, self.path, self.key];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"%@-%@-%@-%@-%@", self.catigory, @(self.type), self.name, self.path, self.key];
}

+ (BMWEffectTypeItem*)lutEffectItem
{
    BMWEffectTypeItem *item = BMWEffectTypeItem.new;
    item.catigory = @"lut";
    item.name = @"滤镜";
    return item;
}

+ (BMWEffectTypeItem*)brightnessEffectItem
{
    BMWEffectTypeItem *item = BMWEffectTypeItem.new;
    item.catigory = @"brightness";
    item.name = @"亮度";
    return item;
}

@end
