#import "BMWVideoAlgorithmReportModel.h"

/////////////////通用类//////////////
@implementation BMWBox

+ (BMWBox*)build:(CGRect)rect
{
    BMWBox *box = BMWBox.new;
    box.left = rect.origin.x;
    box.top = rect.origin.y;
    box.right = rect.origin.x + rect.size.width;
    box.bottom = rect.origin.y + rect.size.height;
    return box;
}
@end

@implementation BMWDectectMetaModel

+ (NSValueTransformer *)rectJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWBox *info = [MTLJSONAdapter modelOfClass:[BMWBox class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWBox *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

@end


/////////////////车牌识别//////////////
@implementation BMWVlprMetaModel

+ (NSValueTransformer *)rectJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWBox *info = [MTLJSONAdapter modelOfClass:[BMWBox class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWBox *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

@end

@implementation BMWVlprAlgorithmModel

+ (NSValueTransformer *)originInfoJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWVlprMetaModel *info = [MTLJSONAdapter modelOfClass:[BMWVlprMetaModel class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWVlprMetaModel *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

+ (NSValueTransformer *)correctInfoJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWVlprMetaModel *info = [MTLJSONAdapter modelOfClass:[BMWVlprMetaModel class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWVlprMetaModel *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

@end


/////////////////人脸检测//////////////
@implementation BMWFacesMetaModel

+ (NSValueTransformer *)rectsJSONTransformer
{
    return [self listJSONTransfrmerWithItemClass:[BMWDectectMetaModel class]];
}

@end

@implementation BMWFaceDectectAlgorithmModel

+ (NSValueTransformer *)originInfoJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWFacesMetaModel *info = [MTLJSONAdapter modelOfClass:[BMWFacesMetaModel class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWFacesMetaModel *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

+ (NSValueTransformer *)correctInfoJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWFacesMetaModel *info = [MTLJSONAdapter modelOfClass:[BMWFacesMetaModel class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWFacesMetaModel *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

@end

@implementation BMWSteelMetaModel

+ (NSValueTransformer *)rectsJSONTransformer
{
    return [self listJSONTransfrmerWithItemClass:[BMWDectectMetaModel class]];
}

@end

@implementation BMWSteelDectectAlgorithmModel

+ (NSValueTransformer *)originInfoJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWSteelMetaModel *info = [MTLJSONAdapter modelOfClass:[BMWSteelMetaModel class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWSteelMetaModel *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

+ (NSValueTransformer *)correctInfoJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWSteelMetaModel *info = [MTLJSONAdapter modelOfClass:[BMWSteelMetaModel class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWSteelMetaModel *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}
@end
