#import "BMWMUserCommentModel.h"

/// data model
@implementation BMWMUserCommentBaseInfoUa
@end
@implementation BMWMUserCommentBaseInfo
+ (NSValueTransformer *)uaJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWMUserCommentBaseInfoUa *info = [MTLJSONAdapter modelOfClass:[BMWMUserCommentBaseInfoUa class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWMUserCommentBaseInfoUa *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}
@end
@implementation BMWMUserCommentWatermarkContent
@end
@implementation BMWMUserCommentWatermarkContentExtension
@end
@implementation BMWMUserCommentData
+ (NSValueTransformer *)baseInfoJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWMUserCommentBaseInfo *info = [MTLJSONAdapter modelOfClass:[BMWMUserCommentBaseInfo class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWMUserCommentBaseInfo *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

+ (NSValueTransformer *)watermarkContentJSONTransformer
{
    return [self listJSONTransfrmerWithItemClass:[BMWMUserCommentWatermarkContent class]];
}

+ (NSValueTransformer *)watermarkContentExtensionJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWMUserCommentWatermarkContentExtension *info = [MTLJSONAdapter modelOfClass:[BMWMUserCommentWatermarkContentExtension class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWMUserCommentWatermarkContentExtension *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}
@end


/// slice image model
@implementation BMWMUserCommentSliceList
@end
@implementation BMWMUserCommentSliceData

+ (NSValueTransformer *)listJSONTransformer
{
    return [self listJSONTransfrmerWithItemClass:[BMWMUserCommentSliceList class]];
}

+ (NSValueTransformer *)list2JSONTransformer
{
    return [self listJSONTransfrmerWithItemClass:[BMWMUserCommentSliceList class]];
}

+ (NSValueTransformer *)list3JSONTransformer
{
    return [self listJSONTransfrmerWithItemClass:[BMWMUserCommentSliceList class]];
}

@end

@implementation BMWMUserCommentModel
+ (NSValueTransformer *)dataJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWMUserCommentData *info = [MTLJSONAdapter modelOfClass:[BMWMUserCommentData class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWMUserCommentData *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

+ (NSValueTransformer *)sliceImageJSONTransformer
{
    return [MTLValueTransformer  reversibleTransformerWithForwardBlock:^id(NSDictionary *infoDict) {
        BMWMUserCommentSliceData *info = [MTLJSONAdapter modelOfClass:[BMWMUserCommentSliceData class] fromJSONDictionary:infoDict error:nil];
        return info;
    } reverseBlock:^id(BMWMUserCommentSliceData *infomodel) {
        if (infomodel == nil) {
            return [NSDictionary dictionary];
        }
        NSDictionary *dict = [MTLJSONAdapter JSONDictionaryFromModel:infomodel];
        return dict;
    }];
}

- (BOOL)hasWatermarkShadow
{
    _hasWatermarkShadow = [self.data.watermarkBaseID isEqualToString:@"10"] ||
    [self.data.watermarkBaseID isEqualToString:@"21"] ||
    [self.data.watermarkBaseID isEqualToString:@"34"];
    return _hasWatermarkShadow;
}

- (BOOL)hasWatermark
{
    _hasWatermark = ![self.data.watermarkBaseID isEqualToString:@"10000"];
    return _hasWatermark;
}

- (BOOL)hasOfficialWatermark
{
    NSString* type = self.data.watermarkContentExtension.officialWatermarkType;
    BOOL ret = [type isEqualToString:@"-1"] || [type isEqualToString:@"99"];
    _hasOfficialWatermark = !ret;
    return _hasOfficialWatermark;
}

- (BOOL)hasMapCode
{
    _hasMapCode = NO;
    for (BMWMUserCommentWatermarkContent *content in self.data.watermarkContent) {
        if(content.id == 210 || content.id == 220 || content.id == 230) {
            _hasMapCode = YES;
            break;
        }
    }
    return _hasMapCode;
}

- (BOOL)isIOS
{
    _isIOS = [self.data.baseInfo.ua.os isEqualToString:@"iOS"];
    return _isIOS;
}

- (BOOL)isValid
{
    _isValid = NO;
    if(self.sliceImage.list.count == 0) {
        return _isValid;
    }
    
    int maxIdx = 0;
    float maxArea = 0;
    for (int i = 0; i < self.sliceImage.list.count; i++) {
        BMWMUserCommentSliceList *slice = self.sliceImage.list[i];
        float area = (slice.sliceRect[2].floatValue - slice.sliceRect[0].floatValue) * (slice.sliceRect[3].floatValue - slice.sliceRect[1].floatValue);
        if (area > maxArea) {
            maxIdx = i;
            maxArea = area;
        }
    }
    BMWMUserCommentSliceList *maxSlice = self.sliceImage.list[maxIdx];
    
    NSUInteger sliceCount = 0;
    if(self.hasOfficialWatermark) {
        float officialWatermarkLeft = self.sliceImage.list.lastObject.sliceRect[0].floatValue;
        float officialWatermarkTop = self.sliceImage.list.lastObject.sliceRect[1].floatValue;
        if(maxSlice.sliceRect[0].floatValue <= officialWatermarkLeft &&
           maxSlice.sliceRect[1].floatValue <= officialWatermarkTop &&
           maxSlice.sliceRect[2].floatValue >= 1.0 &&
           maxSlice.sliceRect[3].floatValue >= 1.0) {
            _watermarkOverlap = 1;
        }
        sliceCount++;
    }
    if(self.hasWatermark) {
        sliceCount++;
    }
    if(self.hasMapCode) {
        if(maxSlice.sliceRect[1].floatValue < 0.01 &&  maxSlice.sliceRect[2].floatValue >= 0.95) {
            _watermarkOverlap = 2;
        }
        sliceCount++;
    }
    if(self.sliceImage.list.count >= sliceCount || _watermarkOverlap > 0) {
        _isValid = YES;
    }
    return _isValid;
}

- (BOOL)hasSliceImageForUI
{
    _hasSliceImageForUI = self.sliceImage.list2.count > 0;
    return _hasSliceImageForUI;
}

- (NSArray<BMWSliceData *> *)sliceDataList
{
    NSAssert(NO, @"sliceDataList no implementation");
    return _sliceDataList;
}

- (NSArray<BMWSliceData *> *)sliceDataList2
{
    if(!_sliceDataList2) {
        NSMutableArray<BMWSliceData *> *temp = [[NSMutableArray alloc] init];
        for (BMWMUserCommentSliceList* s in self.sliceImage.list2) {
            BMWRect *rect = BMWRectMakeForList(s.sliceRect);
            BMWSliceData *data = [BMWSliceData buildWithId:s.sliceImageId.integerValue type:JpegDataOrgSlice data:nil rect:rect];
            [temp addObject:data];
        }
        _sliceDataList2 = temp;
    }
    return _sliceDataList2;
}

- (NSArray<BMWSliceData *> *)sliceDataList3
{
    if(!_sliceDataList3) {
        NSMutableArray<BMWSliceData *> *temp = [[NSMutableArray alloc] init];
        for (BMWMUserCommentSliceList* s in self.sliceImage.list3) {
            BMWRect *rect = BMWRectMakeForList(s.sliceRect);
            BMWSliceData *data = [BMWSliceData buildWithId:s.sliceImageId.integerValue type:JpegDataOrgSlice data:nil rect:rect];
            [temp addObject:data];
        }
        _sliceDataList3 = temp;
    }
    return _sliceDataList3;
}

@end
