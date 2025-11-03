#import "BMWSliceData.h"
#import "GPCamConfigurator.h"
#import "BMWWatermarkItem.h"

BMWRect* BMWRectMakeForList(NSArray<NSNumber*>* rectList)
{
    BMWRect *instace = [[BMWRect alloc] init];
    if(rectList.count != 4) return nil;
    instace.left = rectList[0].floatValue;
    instace.top = rectList[1].floatValue;
    instace.right = rectList[2].floatValue;
    instace.bottom = rectList[3].floatValue;
    return instace;
}

NSArray<NSNumber*>* BMWMakeListFromRect(CGRect rect)
{
    NSMutableArray<NSNumber*>* array = [[NSMutableArray alloc] init];
    [array addObject:@(rect.origin.x)];
    [array addObject:@(rect.origin.y)];
    [array addObject:@(rect.origin.x + rect.size.width)];
    [array addObject:@(rect.origin.y + rect.size.height)];
    return array;
}

BMWRect* BMWRectMake(float left, float top, float right, float bottom)
{
    BMWRect *instace = [[BMWRect alloc] init];
    instace.left = left;
    instace.top = top;
    instace.right = right;
    instace.bottom = bottom;
    return instace;
}

BMWRect* BMWMakeNormRectFromCGRect(CGRect rect, CGSize size)
{
    BMWRect *instace = [[BMWRect alloc] init];
    instace.left = rect.origin.x / size.width;
    instace.top = rect.origin.y / size.height;
    instace.right = (rect.origin.x + rect.size.width) / size.width;
    instace.bottom = (rect.origin.y + rect.size.height) / size.height;
    return instace;
}

BMWRect* BMWMakeRectFromCGRect(CGRect rect)
{
    BMWRect *instace = [[BMWRect alloc] init];
    instace.left = CLAMP(rect.origin.x, 0.0, 1.0);
    instace.top = CLAMP(rect.origin.y, 0.0, 1.0);
    instace.right = CLAMP((rect.origin.x + rect.size.width), 0.0, 1.0);
    instace.bottom =  CLAMP((rect.origin.y + rect.size.height), 0.0, 1.0);
    return instace;
}

BMWRect* BMWMakeRectFromCGPoint(CGPoint ceter, CGSize size)
{
    CGFloat left = ceter.x - size.width / 2.0f;
    CGFloat top = ceter.y - size.height / 2.0f;
    CGFloat right = ceter.x + size.width / 2.0f;
    CGFloat bottom = ceter.y + size.height / 2.0f;
    return BMWRectMake(left, top, right, bottom);
}

BMWRect* BMWClamp(BMWRect* rect, float min, float max)
{
    return BMWRectMake(CLAMP(rect.left, min, max),
                      CLAMP(rect.top, min, max),
                      CLAMP(rect.right, min, max),
                      CLAMP(rect.bottom, min, max));
}

BMWRect* BMWRectFull(void)
{
    BMWRect *rect = BMWRectMake(0, 0, 1, 1);
    return rect;
}

CGFloat BMWIOU(CGRect one, CGRect two)
{
    CGRect intersectionRect = CGRectIntersection(one, two);
    CGRect unionRect = CGRectUnion(one, two);
    CGFloat iou = (intersectionRect.size.width * intersectionRect.size.height) / (unionRect.size.width * unionRect.size.height);
    return iou;
}

BOOL BMWOverlap(CGRect one, CGRect two)
{
    // 5%的精度
    CGRect intersection = CGRectIntersection(one, two);
    if(ABS(one.origin.x - intersection.origin.x) < 0.05 &&
       ABS(one.origin.y - intersection.origin.y) < 0.05 &&
       ABS(one.size.width - intersection.size.width) < 0.05 &&
       ABS(one.size.height - intersection.size.height) < 0.05) {
        return YES;
    }
    if(ABS(two.origin.x - intersection.origin.x) < 0.05 &&
       ABS(two.origin.y - intersection.origin.y) < 0.05 &&
       ABS(two.size.width - intersection.size.width) < 0.05 &&
       ABS(two.size.height - intersection.size.height) < 0.05) {
        return YES;
    }
    return NO;
}

FOUNDATION_EXPORT BMWCorners* BMWMakeCornersForList(NSArray<NSNumber*>* list)
{
    if(list.count != 8) return nil;
    BMWCorners *corners = [[BMWCorners alloc] init];
    corners.point0 = CGPointMake(list[0].floatValue, list[1].floatValue);
    corners.point1 = CGPointMake(list[2].floatValue, list[3].floatValue);
    corners.point2 = CGPointMake(list[4].floatValue, list[5].floatValue);
    corners.point3 = CGPointMake(list[6].floatValue, list[7].floatValue);
    return corners;
}

FOUNDATION_EXPORT NSArray<NSNumber*>* BMWMakeListFromCorners(BMWCorners* corners)
{
    if(corners == nil) return [[NSArray alloc] init];
    NSArray<NSNumber*>* array = @[
        @(corners.point0.x), @(corners.point0.y),
        @(corners.point1.x), @(corners.point1.y),
        @(corners.point2.x), @(corners.point2.y),
        @(corners.point3.x), @(corners.point3.y)
    ];
    return array;
}

@implementation BMWRect

- (float)width
{
    return self.right - self.left;
}

- (float)height
{
    return self.bottom - self.top;
}

- (CGRect)CGrect
{
    return CGRectMake(self.left, self.top, self.right - self.left, self.bottom - self.top);
}

- (CGFloat)erea
{
    return self.width * self.height;
}

- (CGPoint)center
{
    return CGPointMake(self.left + self.width / 2.0, self.top + self.height / 2.0);
}

BMWRect* BMWIntersection(BMWRect* one, BMWRect* two)
{
    if (!CGRectIntersectsRect(one.CGrect, two.CGrect)) {
        return nil;
    }
    CGRect rect = CGRectIntersection(one.CGrect, two.CGrect);
    return BMWMakeRectFromCGRect(rect);
}

CGFloat BMWRectDistance(BMWRect* one, BMWRect* two)
{
    return (one.center.x - two.center.x) * (one.center.x - two.center.x) +
    (one.center.y - two.center.y) * (one.center.y - two.center.y);
}

- (BMWRect*)convert2ParentRect:(BMWRect*)parentRect
{
    if(parentRect == nil) return self;
    CGRect parentCGRect = parentRect.CGrect;
    CGRect selfCGRect = self.CGrect;
    CGFloat x = self.CGrect.origin.x * parentCGRect.size.width + parentCGRect.origin.x;
    CGFloat y = self.CGrect.origin.y * parentCGRect.size.height + parentCGRect.origin.y;
    CGFloat w = self.CGrect.size.width * parentCGRect.size.width;
    CGFloat h = self.CGrect.size.height * parentCGRect.size.height;
    CGRect newCGrect = CGRectMake(x, y, w, h);
    return BMWMakeRectFromCGRect(newCGrect);
}

- (BMWRect*)scale:(float)ratio
{
    float delta = self.width * (ratio-1)/2.0;
    self.left -= (self.left == 0 ? 0: delta);
    self.right += delta;
    delta = self.height * (ratio-1)/2.0;
    self.top -= delta;
    self.bottom += (self.bottom == 1 ? 0 : delta);
    return self;
}

// TODO 看起来有问题，找时间
- (BOOL)isFullScreen
{
    return self.left < 0.001 && self.top < 0.001 && self.top < 0.999 && self.top < 0.999;
}

- (BOOL)isNormOne
{
    return self.left < 0.001 && self.top < 0.001 && self.right > 0.999 && self.bottom > 0.999;
}

- (BOOL)isOutside
{
    float ratio = 0.0125;
    return self.left < ratio || self.top < ratio || self.right > (1.0-ratio) || self.bottom > (1.0-ratio);
}

- (BMWRect*)norm
{
    float left = self.left / self.width;
    float top = self.top / self.height;
    float right = self.right / self.width;
    float bottom = self.bottom / self.height;
    return BMWRectMake(left, top, right, bottom);
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"rect: {tag:%d, left:%f, top:%f, right:%f, bootom:%f}", self.tag, self.left, self.top, self.right, self.bottom];
}

- (BMWRect*)orientation:(int)o
{
    CGRect rect = self.CGrect;
    CGFloat x = self.left;
    CGFloat y = self.top;
    CGFloat w = self.right - self.left;
    CGFloat h = self.bottom - self.top;
    // Left
    if (o == 1) {
        return BMWMakeRectFromCGRect(CGRectMake(1 - y - h, x, h, w));
    }
    // Right
    else if (o == 2) {
        return BMWMakeRectFromCGRect(CGRectMake(y, 1 - x - w, h, w));
    } //Down
    else if (o == 3) {
        return BMWMakeRectFromCGRect(CGRectMake(1 - x - w, 1 - y - h, w, h));
    }
    return self;
}

@end

@implementation BMWCorners

- (NSString*)description
{
    NSString *str = [NSString stringWithFormat:@"point0:%@, point1:%@, point2:%@, point3:%@", @(self.point0), @(self.point1), @(self.point2), @(self.point3)];
    return str;
}

- (BMWCorners*)norm:(CGSize)size
{
    BMWCorners* newCorners = [[BMWCorners alloc] init];
    newCorners.point0 = CGPointMake(self.point0.x / size.width, self.point0.y / size.height);
    newCorners.point1 = CGPointMake(self.point1.x / size.width, self.point1.y / size.height);
    newCorners.point2 = CGPointMake(self.point2.x / size.width, self.point2.y / size.height);
    newCorners.point3 = CGPointMake(self.point3.x / size.width, self.point3.y / size.height);
    return newCorners;
}

- (BMWRect*)xhrect
{
    float left = MIN(self.point0.x, self.point3.x);
    float top = MIN(self.point0.y, self.point1.y);
    float right = MAX(self.point1.x, self.point2.x);
    float bottom = MAX(self.point2.y, self.point3.y);
    return BMWRectMake(left, top, right, bottom);
}

- (BMWCorners*)adjustWithOrient:(BMWDeviceOrientation)orient mirrorX:(BOOL)mirrorX
{
    BMWCorners* newCorners = [[BMWCorners alloc] init];
    if (orient == BMWDeviceOrientationLeft) {
        newCorners.point0 = CGPointMake(1 - self.point3.y, self.point3.x);
        newCorners.point1 = CGPointMake(1 - self.point0.y, self.point0.x);
        newCorners.point2 = CGPointMake(1 - self.point1.y, self.point1.x);
        newCorners.point3 = CGPointMake(1 - self.point2.y, self.point2.x);
    } else if (orient == BMWDeviceOrientationRight) {
        newCorners.point0 = CGPointMake(self.point1.y, 1 - self.point1.x);
        newCorners.point1 = CGPointMake(self.point2.y, 1 - self.point2.x);
        newCorners.point2 = CGPointMake(self.point3.y, 1 - self.point3.x);
        newCorners.point3 = CGPointMake(self.point0.y, 1 - self.point0.x);
    } else if (orient == BMWDeviceOrientationDown) {
        newCorners.point0 = CGPointMake(1 - self.point2.x, 1 - self.point2.y);
        newCorners.point1 = CGPointMake(1 - self.point3.x, 1 - self.point3.y);
        newCorners.point2 = CGPointMake(1 - self.point0.x, 1 - self.point0.y);
        newCorners.point3 = CGPointMake(1 - self.point1.x, 1 - self.point1.y);
    } else {
        newCorners.point0 = self.point0;
        newCorners.point1 = self.point1;
        newCorners.point2 = self.point2;
        newCorners.point3 = self.point3;
    }
    if (!mirrorX)  return newCorners;
    
    // 处理镜像
    BMWCorners* newCorners2 = [[BMWCorners alloc] init];
    if(orient == BMWDeviceOrientationDown || orient == BMWDeviceOrientationPortait) {
        newCorners2.point0 = CGPointMake(1 - newCorners.point1.x, newCorners.point1.y);
        newCorners2.point1 = CGPointMake(1 - newCorners.point0.x, newCorners.point0.y);
        newCorners2.point2 = CGPointMake(1 - newCorners.point3.x, newCorners.point3.y);
        newCorners2.point3 = CGPointMake(1 - newCorners.point2.x, newCorners.point2.y);
    } else {
        newCorners2.point0 = CGPointMake(newCorners.point3.x, 1 - newCorners.point3.y);
        newCorners2.point1 = CGPointMake(newCorners.point2.x, 1 - newCorners.point2.y);
        newCorners2.point2 = CGPointMake(newCorners.point1.x, 1 - newCorners.point1.y);
        newCorners2.point3 = CGPointMake(newCorners.point0.x, 1 - newCorners.point0.y);
    }
    return newCorners2;
}

- (BMWCorners*)mirrorX
{
    BMWCorners* newCorners = [[BMWCorners alloc] init];
    newCorners.point0 = CGPointMake(1 - self.point0.x,  self.point0.y);
    newCorners.point1 = CGPointMake(1 - self.point1.x,  self.point1.y);
    newCorners.point2 = CGPointMake(1 - self.point2.x,  self.point2.y);
    newCorners.point3 = CGPointMake(1 - self.point3.x,  self.point3.y);
    return newCorners;
}

- (BMWCorners*)mirrorY
{
    BMWCorners* newCorners = [[BMWCorners alloc] init];
    newCorners.point0 = CGPointMake(self.point0.x,  1 - self.point0.y);
    newCorners.point1 = CGPointMake(self.point1.x,  1 - self.point1.y);
    newCorners.point2 = CGPointMake(self.point2.x,  1 - self.point2.y);
    newCorners.point3 = CGPointMake(self.point3.x,  1 - self.point3.y);
    return newCorners;
}

@end

@implementation BMWSliceData

+ (BMWSliceData*)buildWithId:(long)id type:(long)type data:(NSData*)data rect:(BMWRect*)rect
{
    BMWSliceData *instace = [[BMWSliceData alloc] init];
    instace.id = id;
    instace.type = type;
    instace.data = data;
    instace.rect = rect;
    return instace;
}

- (instancetype)init
{
    if (self = [super init]) {
    }
    return self;
}


- (void)dealloc
{
    if (_releaseBlock) {
        _releaseBlock();
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"sliceData: {id:%lu, type:%lu, data:%lu, rect:%@}", self.id, self.type, self.data.length, self.rect];
}

@end

@implementation BMWSliceDataModel
- (instancetype)init
{
    if (self = [super init]) {
        self.version = GPCamConfigurator.sharedInstance.jpegPackerVersion;
        self.clarityOpt = 0;
        self.previewClarity = -1.0;
        self.capturedClarity = -1.0;
    }
    return self;
}

- (void)append:(BMWSliceDataModel*)other
{
    self.timeCost += other.timeCost;
    if(other.error) {
        @try {
            NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
            if(other.error.userInfo) {
                [userInfo addEntriesFromDictionary:other.error.userInfo];
            }
            if(self.error.userInfo) {
                [userInfo addEntriesFromDictionary:self.error.userInfo];
            }
            NSString *domain = [NSString stringWithFormat:@"slice append error, one:%@, ohter:%@", self.error.domain, other.error.domain];
            NSError *newError = [NSError errorWithDomain:domain
                                                    code:self.error.code
                                                userInfo:userInfo];
            self.error = newError;
        } @catch (NSException *exception) {
        }
    }
    NSMutableArray *temp = [NSMutableArray arrayWithArray:self.sliceDataList];
    [temp addObjectsFromArray:other.sliceDataList];
    self.sliceDataList = temp;
    
    temp = [NSMutableArray arrayWithArray:self.sliceDataList2];
    [temp addObjectsFromArray:other.sliceDataList2];
    self.sliceDataList2 = temp;
    
    temp = [NSMutableArray arrayWithArray:self.sliceDataList3];
    [temp addObjectsFromArray:other.sliceDataList3];
    self.sliceDataList3 = temp;
}

- (void)merge:(BMWSliceDataModel*)other
{
    if(other.error) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo addEntriesFromDictionary:other.error.userInfo];
        [userInfo addEntriesFromDictionary:self.error.userInfo];
        NSError *newError = [NSError errorWithDomain:self.error.domain
                                                code:self.error.code
                                            userInfo:userInfo];
    }
    NSMutableDictionary<NSNumber*, BMWSliceData*> *listDic = [[NSMutableDictionary alloc] init];
    for(BMWSliceData* data in self.sliceDataList) {
        listDic[@(data.id)] = data;
    }
    for(BMWSliceData* data in other.sliceDataList) {
        listDic[@(data.id)] = data;
    }
    self.sliceDataList = listDic.allValues;
    
    NSMutableDictionary<NSNumber*, BMWSliceData*> *listDic2 = [[NSMutableDictionary alloc] init];
    for(BMWSliceData* data in self.sliceDataList2) {
        listDic2[@(data.id)] = data;
    }
    for(BMWSliceData* data in other.sliceDataList2) {
        listDic2[@(data.id)] = data;
    }
    self.sliceDataList2 = listDic2.allValues;
    
    NSMutableDictionary<NSNumber*, BMWSliceData*> *listDic3 = [[NSMutableDictionary alloc] init];
    for(BMWSliceData* data in self.sliceDataList3) {
        listDic3[@(data.id)] = data;
    }
    for(BMWSliceData* data in other.sliceDataList3) {
        listDic3[@(data.id)] = data;
    }
    self.sliceDataList3 = listDic3.allValues;
}

- (BMWRect*)watermarkRectAfterClarityOpt
{
    BMWSliceData *sliceData = self.sliceDataList.firstObject;
    return sliceData.rect;
}

+ (BMWSliceDataModel*)buildForVideo:(NSArray<BMWWatermarkItem*>*)watermarks watermarkVideoUrl:(NSURL*)watermarkVideoUrl noWatermarkVideoUrl:(NSURL*)noWatermarkVideoUrl;
{
    BMWSliceDataModel *sliceDataModel = [[BMWSliceDataModel alloc] init];
    sliceDataModel.filePath = watermarkVideoUrl.path;
    sliceDataModel.version = 0;
    BMWSliceData *sliceData = [BMWSliceData buildWithId:0 type:JpegDataOrgSlice data:nil rect:BMWRectFull()];
    sliceData.filePath = noWatermarkVideoUrl.path;
    sliceDataModel.sliceDataList = @[sliceData];
    // 获取视觉上可以看到的水印rect,存到self.sliceDataModel.sliceDataList2
    NSMutableArray<BMWRect*>* tmp = [NSMutableArray array];
    for (BMWWatermarkItem *item in watermarks) {
        [tmp addObjectsFromArray:item.realWatermarkRectList2];
    }
    NSMutableArray<BMWSliceData*>* sliceDataList2 = [[NSMutableArray alloc] init];
    for (BMWRect* newRect in tmp) {
        BMWSliceData *sliceData = [BMWSliceData buildWithId:newRect.tag type:JpegDataOrgSlice data:nil rect:newRect];
        [sliceDataList2 addObject:sliceData];
    }
    sliceDataModel.sliceDataList2 = sliceDataList2;
    
    return sliceDataModel;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"sliceDataModel: {error:%@, timecost:%lfms, sliceType:%d, version:%lu, position:%lu, jpegData:%lu, sliceDataList:%@, sliceDataList2:%@, clarityOpt:%d, previewClarity:%lf, capturedClarity:%lf}", self.error, self.timeCost, self.sliceType, self.version, self.position, self.jpegData.length, self.sliceDataList, self.sliceDataList2, self.clarityOpt, self.previewClarity, self.capturedClarity];
}
@end
