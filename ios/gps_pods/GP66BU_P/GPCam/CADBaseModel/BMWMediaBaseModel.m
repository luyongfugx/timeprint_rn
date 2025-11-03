#import <objc/runtime.h>
#import "BMWMediaBaseModel.h"

NSString* model2JosnString(id model)
{
    NSString* modelJsonStr = nil;
    NSDictionary* modelDic = [MTLJSONAdapter JSONDictionaryFromModel:model];
    if([NSJSONSerialization isValidJSONObject:modelDic]) {
        NSError *error;
        NSData *modelJsonData = [NSJSONSerialization dataWithJSONObject:modelDic options:NSJSONWritingPrettyPrinted  error:&error];
        modelJsonStr = [[NSString alloc] initWithData:modelJsonData encoding:NSUTF8StringEncoding];
    }
    // json null替换为""
    modelJsonStr = [modelJsonStr  stringByReplacingOccurrencesOfString:@": null" withString:@": \"\""];
    return modelJsonStr;
}


@implementation BMWMediaBaseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{};
}

+ (NSValueTransformer *)listJSONTransfrmerWithItemClass:(Class)itemClass
{
    return [MTLValueTransformer reversibleTransformerWithForwardBlock:^(NSArray *infos) {
        if (![infos isKindOfClass:[NSArray class]]){
            return @[];
        }
        NSMutableArray *list = [NSMutableArray array];
        for (NSDictionary *dict in infos) {
            id item = [MTLJSONAdapter modelOfClass:itemClass fromJSONDictionary:dict error:nil];
            if (item) {
                [list addObject:item];
            }
        }
        return [NSArray arrayWithArray:list];
    } reverseBlock:^(NSArray *items) {
        NSMutableArray *list = [NSMutableArray array];
        for (id item in items) {
            [list addObject:[MTLJSONAdapter JSONDictionaryFromModel:(MTLModel<MTLJSONSerializing> *)item]];
        }
        return list;
    }];
}


+ (NSDictionary*)getObjectData:(id)obj
{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    unsigned int propsCount;

    objc_property_t *props = class_copyPropertyList([obj class], &propsCount);

    for(int i = 0;i < propsCount; i++) {

        objc_property_t prop = props[i];
        NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];
        id value = [obj valueForKey:propName];
        if(value == nil) {

            value = [NSNull null];
        } else {
            value = [self getObjectInternal:value];
        }
        [dic setObject:value forKey:propName];
    }

    return dic;
}

+ (id)getObjectInternal:(id)obj {

    if([obj isKindOfClass:[NSString class]]
       ||
       [obj isKindOfClass:[NSNumber class]]
       ||
       [obj isKindOfClass:[NSNull class]]) {

        return obj;

    }
    if([obj isKindOfClass:[NSArray class]]) {

        NSArray *objarr = obj;
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:objarr.count];

        for(int i = 0; i < objarr.count; i++) {

            [arr setObject:[self getObjectInternal:[objarr objectAtIndex:i]] atIndexedSubscript:i];
        }
        return arr;
    }
    if([obj isKindOfClass:[NSDictionary class]]) {

        NSDictionary *objdic = obj;
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[objdic count]];

        for(NSString *key in objdic.allKeys) {

            [dic setObject:[self getObjectInternal:[objdic objectForKey:key]] forKey:key];
        }
        return dic;
    }
    return [self getObjectData:obj];

}
@end
