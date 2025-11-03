#import "BMWVideoAlgorithmResult.h"
#import "BMWVideoAlgorithmReportModel.h"
#import "BMWSliceData.h"
#import "GPCamUtils.h"

/////////////////车牌识别//////////////
@implementation BMWVlprMetaData

- (id)copyWithZone:(nullable NSZone *)zone
{
    BMWVlprMetaData *copied = [[BMWVlprMetaData allocWithZone:zone] init];
    copied.orientation = self.orientation;
    copied.score = self.score;
    copied.rect = self.rect;
    copied.rectForImage = self.rectForImage;
    copied.type = self.type.copy;
    copied.formatCharacter = self.formatCharacter.copy;
    return copied;
}

@end

@implementation BMWVlprAlgorithmResult

@synthesize source = _source;
@synthesize sourceRatio = _sourceRatio;
@synthesize timecost = _timecost;
@synthesize refreshInterval = _refreshInterval;

- (BOOL)isValid
{
    return self.data != nil;
}

+ (NSString*)buildReportModel:(NSArray<BMWRectMetaData*>*)originInfo correctInfo:(NSArray<BMWRectMetaData*>*)correctInfo
{
    BMWVlprAlgorithmModel *model = BMWVlprAlgorithmModel.new;
    model.modelId = BMWAlgorithmModelIdVlpr;
    if (originInfo.count > 0) {
        BMWVlprMetaData* metaData = originInfo.firstObject;
        BMWVlprMetaModel *metaModel = BMWVlprMetaModel.new;
        metaModel.score = metaData.score;
        metaModel.angle = 0;
        metaModel.type = metaData.type;
        metaModel.formatCharacter = metaData.formatCharacter;
        metaModel.rect = [BMWBox build:metaData.rectForImage];
        model.originInfo = metaModel;
    }
    if (correctInfo.count > 0) {
        BMWVlprMetaData* metaData = correctInfo.firstObject;
        BMWVlprMetaModel *metaModel = BMWVlprMetaModel.new;
        metaModel.score = metaData.score;
        metaModel.angle = 0;
        metaModel.type = metaData.type;
        metaModel.formatCharacter = metaData.formatCharacter;
        metaModel.rect = [BMWBox build:metaData.rectForImage];
        model.correctInfo = metaModel;
    }
    
    if (model.originInfo == nil && model.correctInfo == nil) {
        return nil;
    }
    NSString* modelJsonStr = model2JosnString(model);
    return modelJsonStr;
}

@end


/////////////////目标检测//////////////
@implementation BMWRectMetaData

- (instancetype)init {
    if (self = [super init]) {
        self.isAuto = YES;
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    BMWRectMetaData *copied = [[[self class] allocWithZone:zone] init];
    copied.orientation = self.orientation;
    copied.score = self.score;
    copied.label = self.label;
    copied.labelName = self.labelName;
    copied.rect = self.rect;
    copied.rectForImage = self.rectForImage;
    copied.imageCoordinateSystem = self.imageCoordinateSystem;
    return copied;
}

- (CGRect)rect
{
    if (self.imageCoordinateSystem) {
        return _rectForImage;
    }
    return _rect;
}

+ (BMWRectMetaData*)buildForUI:(CGRect)rect;
{
    BMWRectMetaData* data = BMWRectMetaData.new;
    data.imageCoordinateSystem = NO;
    data.rect = rect;
    return data;
}


+ (BMWRectMetaData*)buildForImage:(CGRect)rect;
{
    BMWRectMetaData* data = BMWRectMetaData.new;
    data.imageCoordinateSystem = YES;
    data.rectForImage = rect;
    return data;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{score:%@, labelName:%@, rect:%@}",
            @(self.score), self.labelName, @(self.rect)];
}

@end

@implementation BMWFaceDectectAlgorithmResult

@synthesize source = _source;
@synthesize sourceRatio = _sourceRatio;
@synthesize timecost = _timecost;
@synthesize refreshInterval = _refreshInterval;

- (instancetype)init {
    if (self = [super init]) {
        self.data = NSArray.new;
    }
    return self;
}

- (CGRect)meanRect
{
    if (self.data.firstObject.orientation == BMWDeviceOrientationLeft ||
        self.data.firstObject.orientation == BMWDeviceOrientationRight) {
        return CGRectMake(_meanRect.origin.y,
                          _meanRect.origin.x,
                          _meanRect.size.height,
                          _meanRect.size.width);
    }
    return _meanRect;
}

- (BOOL)isValid
{
    return YES;
}

- (NSString *)description
{
    NSString *faceInfo = @"";
    for (NSInteger i = 0; i < self.data.count; i++) {
        BMWRectMetaData *metaData = self.data[i];
        NSString *face = [NSString stringWithFormat:@"\n[%@] score:%@ rect:[%@]",@(i),@(metaData.score), @(metaData.rect)];
        faceInfo = [faceInfo stringByAppendingString:face];
    }
    return [NSString stringWithFormat:@"status:%@ meanReact:%@ - data:%@",
            @(self.status), @(self.meanRect), faceInfo];
}

+ (NSString*)buildReportModel:(NSArray<BMWRectMetaData*>*)originInfo correctInfo:(NSArray<BMWRectMetaData*>*)correctInfo
{
    BMWFaceDectectAlgorithmModel *model = BMWFaceDectectAlgorithmModel.new;
    model.modelId = BMWAlgorithmModelIdFaceDectect;
    if (originInfo.count > 0) {
        BMWFacesMetaModel *facesModel = BMWFacesMetaModel.new;
        NSMutableArray<BMWDectectMetaModel*> *arr = NSMutableArray.new;
        facesModel.rects = arr;
        model.originInfo = facesModel;
        for (BMWRectMetaData* metaData in originInfo) {
            BMWDectectMetaModel *metaModel = BMWDectectMetaModel.new;
            [arr addObject:metaModel];
            metaModel.score = metaData.score;
            metaModel.angle = 0;
            metaModel.rect = [BMWBox build:metaData.rectForImage];
        }
    }
    if (correctInfo.count > 0) {
        BMWFacesMetaModel *facesModel = BMWFacesMetaModel.new;
        NSMutableArray<BMWDectectMetaModel*> *arr = NSMutableArray.new;
        facesModel.rects = arr;
        model.correctInfo = facesModel;
        for (BMWRectMetaData* metaData in correctInfo) {
            BMWDectectMetaModel *metaModel = BMWDectectMetaModel.new;
            [arr addObject:metaModel];
            metaModel.score = metaData.score;
            metaModel.angle = 0;
            metaModel.rect = [BMWBox build:metaData.rectForImage];
        }
    }
    if (model.originInfo == nil || model.correctInfo == nil) {
        return nil;
    }
    NSString* modelJsonStr = model2JosnString(model);
    return modelJsonStr;
}

@end


@implementation BMWFaceAttributeData
- (NSString *)description
{
    return [NSString stringWithFormat:@"orientation:%d, visibility:%lf, yaw:%lf, pitch:%lf, roll:%lf, face erea:%lf, clarity:%lf",
            self.orientation, self.visibility, self.yaw, self.pitch, self.roll, self.faceRect.erea, self.clarity];
}
@end


@implementation BMWFaceAttributeAlgorithmResult

- (instancetype)init {
    if (self = [super init]) {
        self.status = -1;
        self.data = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"status:%d, data:{%@}", self.status, self.data];
}

@end

@implementation BMWSteelDectectAlgorithmResult

@synthesize source = _source;
@synthesize sourceRatio = _sourceRatio;
@synthesize timecost = _timecost;
@synthesize refreshInterval = _refreshInterval;
- (instancetype)init {
    if (self = [super init]) {
        self.data = NSArray.new;
    }
    return self;
}

- (BOOL)isValid
{
    return YES;
}

- (CGRect)meanRect
{
    if (self.data.firstObject.orientation == BMWDeviceOrientationLeft ||
        self.data.firstObject.orientation == BMWDeviceOrientationRight) {
        return CGRectMake(_meanRect.origin.y,
                          _meanRect.origin.x,
                          _meanRect.size.height,
                          _meanRect.size.width);
    }
    return _meanRect;
}

- (NSString *)description
{
    NSString *info = @"";
#if 0
    for (NSInteger i = 0; i < self.data.count; i++) {
        BMWRectMetaData *metaData = self.data[i];
        NSString *str = [NSString stringWithFormat:@"[%@] score:%@ rect:[%@]\n",@(i),@(metaData.score), @(metaData.rect)];
        info = [info stringByAppendingString:str];
    }
#else
    info = [NSString stringWithFormat:@"%@",@(self.data.count)];
#endif
    return [NSString stringWithFormat:@"status:%@ meanReact:%@ - data:%@",
            @(self.status), @(self.meanRect), info];
}

+ (NSString*)buildReportModel:(NSArray<BMWRectMetaData*>*)originInfo correctInfo:(NSArray<BMWRectMetaData*>*)correctInfo
{
    BMWSteelDectectAlgorithmModel *model = BMWSteelDectectAlgorithmModel.new;
    model.modelId = BMWAlgorithmModelIdSteelDetect;
    if (originInfo.count > 0) {
        BMWSteelMetaModel *steelsModel = BMWSteelMetaModel.new;
        NSMutableArray<BMWDectectMetaModel*> *arr = NSMutableArray.new;
        steelsModel.rects = arr;
        model.originInfo = steelsModel;
        for (BMWRectMetaData* metaData in originInfo) {
            BMWDectectMetaModel *metaModel = BMWDectectMetaModel.new;
            [arr addObject:metaModel];
            metaModel.score = metaData.score;
            metaModel.angle = 0;
            metaModel.rect = [BMWBox build:metaData.rectForImage];
        }
    }
    if (correctInfo.count > 0) {
        BMWSteelMetaModel *steelsModel = BMWSteelMetaModel.new;
        NSMutableArray<BMWDectectMetaModel*> *arr = NSMutableArray.new;
        steelsModel.rects = arr;
        model.correctInfo = steelsModel;
        for (BMWRectMetaData* metaData in correctInfo) {
            BMWDectectMetaModel *metaModel = BMWDectectMetaModel.new;
            [arr addObject:metaModel];
            metaModel.score = metaData.score;
            metaModel.angle = 0;
            metaModel.rect = [BMWBox build:metaData.rectForImage];
        }
    }
    if (model.originInfo == nil || model.correctInfo == nil) {
        return nil;
    }
    NSString* modelJsonStr = model2JosnString(model);
    return modelJsonStr;
}
@end


@implementation BMWOCRMetaData

- (id)copyWithZone:(nullable NSZone *)zone
{
    BMWOCRMetaData *copied = [[[self class] allocWithZone:zone] init];
    copied.orientation = self.orientation;
    copied.score = self.score;
    copied.rect = self.rect;
    copied.corners = self.corners;
    copied.label = [self.label copy];
    copied.rawLabel = [self.rawLabel copy];
    copied.containIllegalWord = self.containIllegalWord;
    copied.image = [self.image copy];
    return copied;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"ocrCodeMetaData: { score:%0.4f, codeLabel:%@, codeRect:{%0.4f, %0.4f, %0.4f, %0.4f}, containIllegalWord:%@, rawLabel:%@ }", self.score, self.label, self.rect.origin.x, self.rect.origin.y, self.rect.size.width, self.rect.size.height, @(self.containIllegalWord), self.rawLabel];
}

@end

@implementation BMWOCRAlgorithmResult

@synthesize source = _source;
@synthesize sourceRatio = _sourceRatio;
@synthesize timecost = _timecost;
@synthesize refreshInterval = _refreshInterval;

+ (NSString*)buildReportModel:(NSArray*)originInfo correctInfo:(NSArray*)correctInfo
{
    return nil;
}

- (BOOL)isValid
{
    return self.data != nil;
}

- (NSString*)ocrTexts
{
    NSString *info = @"";
    for (BMWOCRMetaData* data in self.data) {
        if(data.rawLabel.length > 0) {
            NSString* elm = [NSString stringWithFormat:@"%@ ", data.rawLabel];
            info = [info stringByAppendingString:elm];
        }
    }
    info = [info stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return info;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"status:%@ - data:[%@]",
            @(self.status), self.data];
}

@end

@implementation BMWCodeAlgorithmResult
@synthesize source = _source;
@synthesize sourceRatio = _sourceRatio;
@synthesize timecost = _timecost;
@synthesize refreshInterval = _refreshInterval;

+ (NSString*)buildReportModel:(NSArray*)originInfo correctInfo:(NSArray*)correctInfo
{
    return nil;
}

- (BOOL)isValid
{
    return self.data != nil;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"status:%@ - data:[%@]",
            @(self.status), self.data];
}

@end

@interface BMWImageClsAlgorithmResult ()
@end

@implementation BMWImageClsAlgorithmResult
@synthesize source = _source;
@synthesize sourceRatio = _sourceRatio;
@synthesize timecost = _timecost;
@synthesize refreshInterval = _refreshInterval;

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

- (NSArray<BMWRectMetaData*>*)filterWithLabels:(NSArray <NSString*>*)labelArray
{
    NSMutableArray<BMWRectMetaData*>* temp = [[NSMutableArray alloc] init];
    for (BMWRectMetaData* data in self.data) {
        for (NSString* label in labelArray) {
            if([data.labelName isEqualToString:label]) {
                [temp addObject:data];
            }
        }
    }
    return temp;
}

- (BMWRectMetaData*)findBestWithLabels:(NSArray <NSString*>*)labelArray
{
    NSMutableArray<BMWRectMetaData*>* temp = [[NSMutableArray alloc] init];
    for (BMWRectMetaData* data in self.data) {
        for (NSString* label in labelArray) {
            if([data.labelName isEqualToString:label]) {
                [temp addObject:data];
            }
        }
    }
    // 依据面积做降序排序
    temp = [temp sortedArrayUsingComparator:^NSComparisonResult(BMWRectMetaData *  _Nonnull obj1, BMWOCRMetaData *  _Nonnull obj2) {
        CGFloat r1 = BMWMakeRectFromCGRect(obj1.rect).erea;
        CGFloat r2 = BMWMakeRectFromCGRect(obj2.rect).erea;
        return r1 < r2 ? NSOrderedDescending : NSOrderedAscending;
    }];
    return temp.firstObject;
}

- (BOOL)isUnknown
{
    return [self.labelNames isEqualToString:@"unknown"];
}

- (NSString*)labelNames
{
    if (self.data.count == 0) return @"unknown";
    NSMutableDictionary<NSString*, NSNumber*> *labelDic = [[NSMutableDictionary alloc] init];
    for (NSInteger i = 0; i < self.data.count; i++) {
        BMWRectMetaData *metaData = self.data[i];
        NSNumber *value = labelDic[metaData.labelName];
        NSUInteger count = value.integerValue+1;
        labelDic[metaData.labelName] = @(count);
    }
    __block NSString *info = @"";
    __block NSUInteger index = 0;
    [labelDic enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSNumber * _Nonnull obj, BOOL * _Nonnull stop) {
        NSString* sep = (index == labelDic.count - 1) ? @"" : @",";
        NSString* count = obj.integerValue == 1 ? @"" : [NSString stringWithFormat:@"#%@", obj];
        NSString* elm = [NSString stringWithFormat:@"%@%@%@", key, count, sep];
        info = [info stringByAppendingString:elm];
        index++;
    }];
    return info;
}

- (NSString*)evaLabel
{
    NSString *info = @"d|unknown";
    if (self.data.count == 0) return info;
    
    // 处理分类数据
    if(self.isClassification && self.data.count > 0) {
        info = @"c";
        // c|head|shelf
        for (NSInteger i = 0; i < self.data.count; i++) {
            BMWRectMetaData *metaData = self.data[i];
            if(metaData.labelName.length > 0) {
                info = [info stringByAppendingFormat:@"|%@,%d",metaData.labelName, (int)(metaData.score*100)];
            }
        }
    }
    // 处理检测数据
    else if(self.data.count > 0) {
        info = @"d";
        // d|face,0.01,0.093,0.073,0.185|car,0.062,0.185,0.177,0.463
        for (NSInteger i = 0; i < self.data.count; i++) {
            BMWRectMetaData *metaData = self.data[i];
            if(metaData.labelName.length > 0) {
                CGFloat left = metaData.rect.origin.x;
                CGFloat top = metaData.rect.origin.y;
                CGFloat right = metaData.rect.origin.x + metaData.rect.size.width;
                CGFloat bottom = metaData.rect.origin.y + metaData.rect.size.height;
                info = [info stringByAppendingFormat:@"|%@,%d,%.3f,%.3f,%.3f,%.3f",metaData.labelName, (int)(metaData.score*100), left, top, right, bottom];
            }
        }
    }
    return info;
}

- (NSString *)description
{
    NSString *info = @"";
    for (NSInteger i = 0; i < self.data.count; i++) {
        BMWRectMetaData *metaData = self.data[i];
        NSString *one = [NSString stringWithFormat:@"%@, ", metaData];
        info = [info stringByAppendingString:one];
    }
    return [NSString stringWithFormat:@"status:%@ - data:[%@]",
            @(self.status), info];
}

@end

/////////////////门头结果//////////////
@implementation BMWShopSignOCRData
@end

@implementation BMWShopSignMetaData

- (instancetype)init {
    if (self = [super init]) {
        self.ocrList = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (NSValueTransformer *)ocrListJSONTransformer
{
    return [self listJSONTransfrmerWithItemClass:[BMWShopSignOCRData class]];
}
@end

@implementation BMWShopSignRecognitionResult

- (instancetype)init {
    if (self = [super init]) {
        self.headList = [[NSMutableArray alloc] init];
    }
    return self;
}

+ (NSValueTransformer *)headListJSONTransformer
{
    return [self listJSONTransfrmerWithItemClass:[BMWShopSignMetaData class]];
}

- (NSString*)toJsonStr
{
    NSString* modelJsonStr = model2JosnString(self);
    return modelJsonStr;
}

+ (BMWShopSignRecognitionResult*)build:(NSMutableArray<BMWRectMetaData*>*)detList ocrList:(NSMutableArray<BMWOCRMetaData*>*)ocrList
{
    BOOL valid = NO;
    BMWShopSignRecognitionResult* result = [[BMWShopSignRecognitionResult alloc] init];
    for (BMWRectMetaData* detData in detList) {
        BMWShopSignMetaData* elm = [[BMWShopSignMetaData alloc] init];
        elm.prob = detData.score;
        elm.headRect = BMWMakeListFromRect(detData.rect);
        [result.headList addObject:elm];
        for (BMWOCRMetaData* ocrData in ocrList) {
            if(BMWOverlap(detData.rect, ocrData.rect)) {
                BMWShopSignOCRData* ocrelm = [[BMWShopSignOCRData alloc] init];
                ocrelm.text = ocrData.rawLabel;
                ocrelm.prob = ocrData.score;
                ocrelm.rect = BMWMakeListFromRect(ocrData.rect);
                ocrelm.corners = BMWMakeListFromCorners(ocrData.corners);
                [elm.ocrList addObject:ocrelm];
                valid = YES;
            }
        }
    }
    return valid ? result : nil;
}

+ (nullable BMWShopSignRecognitionResult*)build:(BMWOCRAlgorithmResult*)ocr
{
    BOOL valid = NO;
    BMWShopSignRecognitionResult* result = [[BMWShopSignRecognitionResult alloc] init];
    for (BMWOCRMetaData* ocrData in ocr.data) {
        BMWShopSignMetaData* elm = [[BMWShopSignMetaData alloc] init];
        elm.prob = ocrData.score;
        elm.headRect = BMWMakeListFromRect(ocrData.rect);
        [result.headList addObject:elm];
        
        BMWShopSignOCRData* ocrelm = [[BMWShopSignOCRData alloc] init];
        ocrelm.text = ocrData.rawLabel;
        ocrelm.prob = ocrData.score;
        ocrelm.rect = BMWMakeListFromRect(ocrData.rect);
        [elm.ocrList addObject:ocrelm];
        valid = YES;
    }
    return valid ? result : nil;
}

- (nullable NSString*)shopSignsForDebug
{
    NSString *shopSignStr = @"";
    for (int idx = 0; idx < self.headList.count; idx++) {
        BMWShopSignMetaData* metaData = self.headList[idx];
        NSString *ocrDataStr = @"";
        for (BMWShopSignOCRData* ocrData in metaData.ocrList) {
            ocrDataStr = [ocrDataStr stringByAppendingFormat:@"%@;",ocrData.text];
        }
        shopSignStr = [shopSignStr stringByAppendingFormat:@"{[%d]:%@}",idx+1, ocrDataStr];
    }
    return shopSignStr;
}

+ (nullable BMWShopSignRecognitionResult*)buildMaxShopSign:(BMWShopSignRecognitionResult*)one
{
    BOOL valid = NO;
    BMWShopSignRecognitionResult* result = [[BMWShopSignRecognitionResult alloc] init];
    float max = -MAXFLOAT;
    BMWShopSignOCRData *dataOfInterest = nil;
    for (BMWShopSignMetaData* signMetaData in one.headList) {
        for (BMWShopSignOCRData* shopSignOCR in signMetaData.ocrList) {
            CGFloat erea = BMWRectMakeForList(shopSignOCR.rect).erea;
            if(erea > max) {
                max = erea;
                dataOfInterest = shopSignOCR;
                //提取汉字
                NSString *labelHZ = [GPCamUtils filterWithRegex:@"[^\\u4e00-\\u9fa5]" inputStr:shopSignOCR.text];
                // 汉字>=2,保留数字和汉字
                if (labelHZ.length > 1) {
                    shopSignOCR.text = [GPCamUtils filterWithRegex:@"[^\\u4e00-\\u9fa50-9]" inputStr:shopSignOCR.text];
                }
                valid = YES;
            }
        }
    }
    BMWShopSignMetaData* elm = [[BMWShopSignMetaData alloc] init];
    elm.prob = dataOfInterest.prob;
    elm.headRect = dataOfInterest.rect;
    [result.headList addObject:elm];
    [elm.ocrList addObject:dataOfInterest];
    return valid ? result : nil;
}
@end

/////////////////图片质量//////////////
@interface BMWImageQualityAlgorithmResult ()
@end

@implementation BMWImageQualityAlgorithmResult
@synthesize source = _source;
@synthesize sourceRatio = _sourceRatio;
@synthesize timecost = _timecost;
@synthesize refreshInterval = _refreshInterval;

- (instancetype)init {
    if (self = [super init]) {
    }
    return self;
}

+ (NSString*)buildReportModel:(NSArray*)originInfo correctInfo:(NSArray*)correctInfo
{
    return nil;
}

- (BOOL)isValid
{
    return self.recaptureData.count > 0 && self.imageQualityData.count > 0;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"status:%@ - imageQualityData:[%@]- recaptureData:[%@]",
            @(self.status), self.imageQualityData, self.recaptureData];
}

@end
