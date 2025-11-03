#import "BMWJpegPacker.h"
#import "BMWMUserCommentModel.h"
#import "BMWWatermarkItem.h"
#include "jpeg_packer.h"
#import "BMWRemoveWatermarkManager.h"
#import "BMWCodeDetectManager.h"
#import "BMWCodeHelper.h"
#import "GPCamConfigurator.h"
#import "BMWAnitCodeManger.h"

@interface BMWJpegPacker ()
@property (nonatomic) NSString* workPath;
@property (nonatomic) JpegPackPosition position;
@property (nonatomic) BMWAnitCodeManger *anitCodeManger;
@end

@implementation BMWJpegPacker

+ (BMWJpegPacker*)sharedInstance
{
    static BMWJpegPacker* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[BMWJpegPacker alloc] init];
        }
    });
    return instance;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.position = AppendEnd;
    }
    return self;
}

- (void)configPackPostion:(JpegPackPosition)position
{
    self.position = position;
}

- (void)pack:(BMWSliceDataModel*)request completeBlock:(void (^)(BMWSliceDataModel* _Nullable reslut))completeBlock
{
    [self pack:request ignoreClarityOpt:NO completeBlock:completeBlock];
}

- (void)pack:(BMWSliceDataModel* _Nullable )request ignoreClarityOpt:(BOOL)ignoreClarityOpt completeBlock:(void (^)(BMWSliceDataModel* _Nullable reslut))completeBlock
{
    double begin = CACurrentMediaTime();
    request.position = self.position;
        BMWSliceDataModel *reslut = [[BMWSliceDataModel alloc] init];
    if (request.jpegData.length == 0 || request.sliceDataList.count == 0) {
        reslut.error = [[NSError alloc] initWithDomain:@"request.jpegData.length == 0 || request.sliceDataList.count == 0" code:-1 userInfo:nil];
        SafeBlock(completeBlock, reslut);
        return;
    }

    NSString *inputImagePath = [self.workPath stringByAppendingPathComponent:@"inputImage.jpg"];
    [request.jpegData writeToFile:inputImagePath atomically:YES];

    std::shared_ptr<JpegPackerImp> encoder(new JpegPackerImp(""));

    std::vector<SliceDataInfo> sliceDataInfos;
    for(BMWSliceData *slice in request.sliceDataList) {
        if(ignoreClarityOpt && (slice.type == JpegDataClarityOptOrg || slice.type == JpegDataClarityOptOrgSlice)) {
            continue;
        }
        std::vector<char> data_vec((char*)slice.data.bytes, (char*)slice.data.bytes + slice.data.length);
        float rect[] = {slice.rect.left, slice.rect.top, slice.rect.right, slice.rect.bottom};
        std::vector<float> rect_vec;
        rect_vec.assign(rect, rect + 4);
        SliceDataInfo info = {slice.type, slice.id, data_vec, rect_vec};
        sliceDataInfos.push_back(info);
    }

    bool ignorePackedRawData = false;
    for(BMWSliceData *slice in request.sliceDataList) {
        if(slice.type == JpegDataClarityOptOrg || slice.type == JpegDataClarityOptOrgSlice || slice.rect.isNormOne){
            ignorePackedRawData = true;
            break;
        }
    }
    vector<char> packedRawData;
    int ret = encoder->jpegEncode((IMAGE_ENCODE_POS)request.position, request.version, inputImagePath.UTF8String, sliceDataInfos, packedRawData);
    if (ret < 0) {
        reslut.error = [[NSError alloc] initWithDomain:[NSString stringWithFormat:@"jpeg pack encode internal error:%d", ret] code:-2 userInfo:nil];
        SafeBlock(completeBlock, reslut);
    }
    if(packedRawData.size() > 0 && ignorePackedRawData == false) {
        request.packedRawData = [NSData dataWithBytes:(char*)packedRawData.data() length:packedRawData.size()];
    }
    // release
    encoder.reset();
    if (!reslut.error) {
        reslut.jpegData = [NSData dataWithContentsOfFile:inputImagePath];
    }
    reslut.position = request.position;
    reslut.sliceDataList = request.sliceDataList;
    if ([NSFileManager.defaultManager fileExistsAtPath:inputImagePath]) {
        [NSFileManager.defaultManager removeItemAtPath:inputImagePath error:nil];
    }
    double end = CACurrentMediaTime();
    reslut.timeCost += (end - begin) * 1000;
        SafeBlock(completeBlock, reslut);
}

- (void)unpack:(void (^)(BMWSliceDataModel *request))builder completeBlock:(void (^)(BMWSliceDataModel* _Nullable reslut))completeBlock
{
    double begin = CACurrentMediaTime();
    BMWSliceDataModel *request = [[BMWSliceDataModel alloc] init];
    request.position = self.position;
    SafeBlock(builder, request);
        BMWSliceDataModel *reslut = [[BMWSliceDataModel alloc] init];
    request.jpegData = request.jpegData;
    if (request.jpegData.length == 0) {
        reslut.error = [[NSError alloc] initWithDomain:@"request.jpegData.length == 0" code:-10 userInfo:nil];
        SafeBlock(completeBlock, reslut);
                return;
    }

    NSString *inputImagePath = [self.workPath stringByAppendingPathComponent:@"inputImage.jpg"];
    [request.jpegData writeToFile:inputImagePath atomically:YES];

    std::shared_ptr<JpegPackerImp> decoder(new JpegPackerImp(""));

    NSMutableArray<BMWSliceData*>* sliceDataList = [[NSMutableArray alloc] init];
    long version = 0;
    vector<SliceDataInfo> slices;
    int ret = decoder->jpegDecode((IMAGE_ENCODE_POS)request.position, version, inputImagePath.UTF8String, slices);

    // 图种有效性检查
    do {
        if (ret < 0) {
            reslut.error = [[NSError alloc] initWithDomain:[NSString stringWithFormat:@"jpeg pack decode internal error:%d", ret] code:-11 userInfo:nil];
            break;
        }
        for (auto slice : slices) {
            if (slice.rect.size() != 4) {
                continue;
            }
            NSData *data = [NSData dataWithBytes:(char*)slice.data.data() length:slice.data.size()];
            BMWRect *rect = BMWRectMake(slice.rect[0], slice.rect[1], slice.rect[2], slice.rect[3]);
            BMWSliceData *sliceData = [BMWSliceData buildWithId:slice.id type:slice.type data:data rect:rect];
            [sliceDataList addObject:sliceData];
        }
        if (sliceDataList.count == 0 || sliceDataList.count != slices.size()) {
            reslut.error = [[NSError alloc] initWithDomain:[NSString stringWithFormat:@"slices data invalid:%d,%d", sliceDataList.count, slices.size()] code:-12 userInfo:nil];
            break;
        }
    } while (NO);
    reslut.sliceDataList = sliceDataList;
    reslut.position = request.position;
    reslut.version = version;
    // release
    decoder.reset();
        if ([NSFileManager.defaultManager fileExistsAtPath:inputImagePath]) {
        [NSFileManager.defaultManager removeItemAtPath:inputImagePath error:nil];
    }
    double end = CACurrentMediaTime();
    reslut.timeCost += (end - begin) * 1000;
    SafeBlock(completeBlock, reslut);
}

- (void)packVideo:(BMWSliceDataModel* _Nullable )request completeBlock:(void (^)(BMWSliceDataModel* _Nullable reslut))completeBlock {
    double begin = CACurrentMediaTime();
        std::vector<SliceDataInfo> sliceDataInfos;
    for(BMWSliceData *slice in request.sliceDataList) {
        if(slice.type == JpegDataClarityOptOrg || slice.type == JpegDataClarityOptOrgSlice) {
            continue;
        }
        std::vector<char> data_vec((char*)slice.data.bytes, (char*)slice.data.bytes + slice.data.length);
        float rect[] = {slice.rect.left, slice.rect.top, slice.rect.right, slice.rect.bottom};
        std::vector<float> rect_vec;
        rect_vec.assign(rect, rect + 4);
        SliceDataInfo info = {slice.type, slice.id, data_vec, rect_vec, slice.filePath.UTF8String};
        sliceDataInfos.push_back(info);
    }

    std::unique_ptr<JpegPackerImp> encoder = std::make_unique<JpegPackerImp>("");
    int ret = encoder->videoEncode(request.version, request.filePath.UTF8String, sliceDataInfos);
    BMWSliceDataModel *result = [[BMWSliceDataModel alloc] init];
    if (ret < 0) {
        result.error = [[NSError alloc] initWithDomain:[NSString stringWithFormat:@"jpeg pack video encode internal error:%d", ret] code:-2 userInfo:nil];
        SafeBlock(completeBlock, result);
        return;
    }
    result.position = request.position;
    result.version = request.version;
    result.filePath = request.filePath;
    result.sliceDataList = request.sliceDataList;
    double end = CACurrentMediaTime();
    result.timeCost += (end - begin) * 1000;
        SafeBlock(completeBlock, result);
}

- (void)unpackVideo:(void (^)(BMWSliceDataModel *request))maker dstDir:(NSString *)dstDir completeBlock:(void (^)(BMWSliceDataModel* _Nullable reslut))completeBlock {
    double begin = CACurrentMediaTime();
    BMWSliceDataModel *request = [[BMWSliceDataModel alloc] init];
    request.position = self.position;
    SafeBlock(maker, request);
        std::unique_ptr<JpegPackerImp> decoder = std::make_unique<JpegPackerImp>("");
    std::vector<SliceDataInfo> slices;
    long version;
    int ret = decoder->videoDecode(version, request.filePath.UTF8String, dstDir.UTF8String, slices);
    BMWSliceDataModel *result = [[BMWSliceDataModel alloc] init];
    if (ret < 0) {
        result.error = [[NSError alloc] initWithDomain:[NSString stringWithFormat:@"jpeg pack video decode internal error:%d", ret] code:-2 userInfo:nil];
        SafeBlock(completeBlock, result);
        return;
    }
    NSMutableArray<BMWSliceData*>* sliceDataList = [[NSMutableArray alloc] init];
    for (auto slice : slices) {
        if (slice.rect.size() != 4) {
            continue;
        }

        NSData *data = [NSData dataWithBytes:(char*)slice.data.data() length:slice.data.size()];
        BMWRect *rect = BMWRectMake(slice.rect[0], slice.rect[1], slice.rect[2], slice.rect[3]);
        BMWSliceData *sliceData = [BMWSliceData buildWithId:slice.id type:slice.type data:data rect:rect];
        sliceData.filePath = [NSString stringWithUTF8String:slice.filePath.c_str()];
        [sliceDataList addObject:sliceData];
    }
    result.sliceDataList = sliceDataList;
    result.position = request.position;
    result.version = version;
    result.filePath = request.filePath;
    double end = CACurrentMediaTime();
    result.timeCost += (end - begin) * 1000;
        SafeBlock(completeBlock, result);
}

- (BOOL)extractWatermarkedVideoFrom:(NSString*)videoFilePath dstFilePath:(NSString*)dstFilePath error:(NSError**)error {
    double begin = CACurrentMediaTime();
    std::unique_ptr<JpegPackerImp> decoder = std::make_unique<JpegPackerImp>("");
    int ret = decoder->extractWatermarkedVideo(videoFilePath.UTF8String, dstFilePath.UTF8String);
    if (ret < 0) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:[NSString stringWithFormat:@"jpeg pack video decode internal error:%d", ret] code:-2 userInfo:nil];
        }
        return NO;
    }
    double end = CACurrentMediaTime();
        return YES;
}

- (void)checkPackedWithImage:(UIImage*)image completeBlock:(void (^)(int code, NSString * _Nullable extraCode))completeBlock
{
    void(^triggerCallback)(int code, NSString *extraCode) = ^(int code, NSString *extraCode) {
        dispatch_async(dispatch_get_main_queue(), ^{
                        SafeBlock(completeBlock, code, extraCode);
        });
    };
    BMWCodeDetectManager *detectManager = BMWCodeDetectManager.sharedInstance;
    [detectManager detectWithRequestBulder:^(BMWCodeRequestModel * _Nonnull requestModel) {
        requestModel.image = image;
        CGFloat ratio = requestModel.image.size.width / requestModel.image.size.height;
        requestModel.type = BMWCodeDetectTypeOCRCode;
        requestModel.cropRect = [BMWCodeHelper.sharedInstance officalWatermarkRect:ratio];
    } completeBlock:^(BMWCodeReslutModel * _Nullable reslutModel, NSError * _Nullable error) {
        BOOL hasAntiCode = NO;
        BOOL hasOfficialLogo = NO;
        for(BMWOCRMetaData* d in reslutModel.data) {
            if([d.rawLabel containsString:@"防伪"]) {
                hasAntiCode = YES;
            }
            if([d.rawLabel containsString:@"今日水印"]) {
                hasOfficialLogo = YES;
            }
        }
        double bg = CACurrentMediaTime();
        [self.anitCodeManger probeAntiCodeWithRequestBulder:^(BMWAnitCodeRequestModel * _Nonnull model) {
            model.image = image;
        } completeBlock:^(BMWAnitCodeReslutModel * _Nullable reslutModel, BMWAnitCodeErrorModel * _Nullable errorModel) {
            double end = CACurrentMediaTime();
                        if(reslutModel != nil && reslutModel.ocrMetaData != nil && reslutModel.ocrMetaData.label.length > 0) {
                triggerCallback(3, reslutModel.ocrMetaData.label);
            } else if(hasOfficialLogo) {
                triggerCallback(2, nil);
            } else {
                triggerCallback(0, nil);
            }
        }];
    }];
}

- (void)checkPackedWithPath:(NSURL*)srcUrl completeBlock:(void (^)(int code, NSString * _Nullable extraCode))completeBlock
{
    __block int ret = 0;
    if (srcUrl.path.length == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
            SafeBlock(completeBlock, 0, nil);
        });
        return;
    }

    FILE* pFile = fopen(srcUrl.path.UTF8String, "rb");
    if (pFile == 0) {
                dispatch_async(dispatch_get_main_queue(), ^{
            SafeBlock(completeBlock, 0, nil);
        });
        return;
    }

    std::shared_ptr<JpegPackerImp> packer(new JpegPackerImp(""));
    vector<string> filePaths = {srcUrl.path.UTF8String};
    vector<int> positions = {IMAGE_ENCODE_APPEND_END};
    vector<int> status = packer->getCanjpegDecode(filePaths, positions);
    if (status.size() > 0 && status[0] > 0 ){
        dispatch_async(dispatch_get_main_queue(), ^{
            SafeBlock(completeBlock, 1, nil);
        });
    } else {
        if(GPCamConfigurator.sharedInstance.enableEraseWatermark) {
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:srcUrl]];
            [self checkPackedWithImage:image completeBlock:completeBlock];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                SafeBlock(completeBlock, 0, nil);
            });
        }
    }
}

- (BOOL)checkPackedWithPath:(NSURL*)srcUrl
{
    __block int ret = 0;
    if (srcUrl.path.length == 0) {
                return NO;
    }

    std::shared_ptr<JpegPackerImp> packer(new JpegPackerImp(""));
    vector<string> filePaths = {srcUrl.path.UTF8String};
    vector<int> positions = {IMAGE_ENCODE_APPEND_END};
    vector<int> status = packer->getCanjpegDecode(filePaths, positions);
    if (status.size() > 0 && status[0] > 0 ){
        return YES;
    }
    return NO;
}

- (void)copyPack:(NSURL*)srcUrl destJpegData:(NSData*)destJpegData completeBlock:(void (^)(BMWSliceDataModel* _Nullable reslut))completeBlock
{
    [self unpack:^(BMWSliceDataModel * _Nonnull request) {
        request.jpegData = [NSData dataWithContentsOfURL:srcUrl];
        //request.jpegData = [NSData dataWithContentsOfFile:srcPath];
    } completeBlock:^(BMWSliceDataModel * _Nullable reslut) {
        if(reslut.error) {
            SafeBlock(completeBlock, reslut);
            return;
        }
        reslut.jpegData = destJpegData;
        [self pack:reslut completeBlock:^(BMWSliceDataModel * _Nullable reslut2) {
            reslut2.timeCost += reslut.timeCost;
            SafeBlock(completeBlock, reslut2);
        }];
    }];
}

- (NSInteger)buildWithPackedRawData:(NSString*)packedRawDataPath destJpegPath:(NSString*)destJpegPath
{
    std::shared_ptr<JpegPackerImp> coder(new JpegPackerImp(""));
    int ret = coder->jpegMerge(IMAGE_ENCODE_APPEND_END, packedRawDataPath.UTF8String, destJpegPath.UTF8String);
        coder.reset();
    return ret;
}

- (void)checkClarityOpt:(NSURL*)srcUrl userCommentStr:(NSString*)userCommentStr completeBlock:(void (^)(BOOL reslut))completeBlock
{
    BMWMUserCommentModel *model = nil;
    do {
        if (userCommentStr.length == 0) {
            break;
        }
        NSError *error = nil;
        NSData *jsonData = [userCommentStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        if(error) {
                        break;
        }

        model = [MTLJSONAdapter modelOfClass:[BMWMUserCommentModel class] fromJSONDictionary:jsonDic error:&error];

        if(error || model == nil) {
                        break;
        }
    } while (0);

    if(model.sliceImage.clarityOpt <= BMWClarityOptStatusCanOpt) {
        BOOL reslut = model.sliceImage.clarityOpt == BMWClarityOptStatusCanOpt;
        SafeBlock(completeBlock, reslut);
    } else if(model.sliceImage.clarityOpt == BMWClarityOptStatusCanUnkown && srcUrl) {
        BMWRemoveWatermarkManager *manager = [[BMWRemoveWatermarkManager alloc] init];
        [manager detectClarityOffline:srcUrl completeBlock:^(BMWClarityOptStatus status) {
            BOOL reslut = status == BMWClarityOptStatusCanOpt;
            SafeBlock(completeBlock, reslut);
        }];
    } else {
        SafeBlock(completeBlock, NO);
    }
}

- (void)checkParseImage:(NSURL*)srcUrl userCommentStr:(NSString*)userCommentStr completeBlock:(void (^)(BOOL result))completeBlock
{

}

- (NSDictionary<NSString*,BMWRect*>*)sliceRect:(NSString*)userCommentStr
{
    NSDictionary<NSString*, BMWRect*>* rectDic = nil;
    do {
        if (userCommentStr.length == 0) {
            break;
        }
        NSError *error = nil;
        NSData *jsonData = [userCommentStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        if(error) {
                        break;
        }

        BMWMUserCommentModel *model = [MTLJSONAdapter modelOfClass:[BMWMUserCommentModel class] fromJSONDictionary:jsonDic error:&error];

        if(error || model == nil) {
                        break;
        }
        if(model.hasSliceImageForUI) {
            rectDic = [self parseRectForUI2:model];
        } else {
            rectDic = [self parseRectForUI:model];
        }
    } while (0);
        return rectDic;
}

- (NSDictionary<NSString*, BMWRect*>*)parseRectForUI:(BMWMUserCommentModel*) model
{
    NSMutableDictionary<NSString*, BMWRect*>* rectDic = [[NSMutableDictionary alloc] init];
    do {
        if(!model.isValid) {
            break;
        }
        BMWRect *parantRect = BMWRectMakeForList(model.sliceImage.list3.firstObject.sliceRect);
        int count = model.sliceImage.list.count;
        if(model.hasOfficialWatermark && model.watermarkOverlap != 1) {
            BMWMUserCommentSliceList *sliceRect = model.sliceImage.list[count-1];
            BMWRect *rect = BMWRectMake(sliceRect.sliceRect[0].floatValue,
                                      sliceRect.sliceRect[1].floatValue,
                                      sliceRect.sliceRect[2].floatValue,
                                      sliceRect.sliceRect[3].floatValue);
            BMWRect *newRect = [rect convert2ParentRect:parantRect];
            newRect.left += newRect.width*0.1f;
            newRect.top += newRect.height*0.1f;
            rectDic[@"officalWatermark"] = newRect;
        }

        if(model.hasWatermark) {
            int idx = count-2;
            if(model.watermarkOverlap == 1 || !model.hasOfficialWatermark) {
                idx = count-1;
            }
            if(idx >= 0)  {
                BMWMUserCommentSliceList *sliceRect = model.sliceImage.list[idx];
                BMWRect *rect = BMWRectMake(sliceRect.sliceRect[0].floatValue,
                                          sliceRect.sliceRect[1].floatValue,
                                          sliceRect.sliceRect[2].floatValue,
                                          sliceRect.sliceRect[3].floatValue);
                BMWRect *newRect = [rect convert2ParentRect:parantRect];

                if(model.hasWatermarkShadow && !newRect.isFullScreen) {
                    newRect = BMWClamp([newRect scale:0.6f], 0.0, 1.0);
                }
                rectDic[@"watermark"] = newRect;
            }
        }
    } while (0);
    return rectDic;
}

- (NSInteger)canRemoveOfficalWatermark:(NSString*)userCommentStr
{
    NSInteger ret = 0;
    double begin = CACurrentMediaTime();
    do {
        if (userCommentStr.length == 0) {
            ret = -1;
            break;
        }
        NSError *error = nil;
        NSData *jsonData = [userCommentStr dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
        if(error) {
                        ret = -2;
            break;
        }

        BMWMUserCommentModel *model = [MTLJSONAdapter modelOfClass:[BMWMUserCommentModel class] fromJSONDictionary:jsonDic error:&error];

        if(error || model == nil) {
                        ret = -3;
            break;
        }

        // 有list3,比如无遮挡水印等等
        if(model.sliceImage.list3.firstObject.sliceRect != nil && !BMWRectMakeForList(model.sliceImage.list3.firstObject.sliceRect).isNormOne) {
            ret = -4;
            break;
        }

        // 官方水印和水印完全重叠，比如全屏水印
        BMWRect *officalRect = [self findRectbyTag:BMWWatermarkTagOfficialWatermark model:model isList2:NO];
        if(officalRect == nil) {
            ret = -5;
            break;
        }

        // 官方水印和水印部分重叠
        BOOL intersection = NO;
        for(BMWMUserCommentSliceList *sliceRect in model.sliceImage.list) {
            int tag = sliceRect.sliceImageId.integerValue;
            // 忽略offical watermark
            if(tag == officalRect.tag) continue;
            // 忽略清晰度优化的tag
            if(tag == JpegPackIdClarityOptImage) continue;
            // watermark使用list2里的rect来计算，提高覆盖，但可能去官方水印会有瑕疵
            BMWRect *rect =[self findRectbyTag:tag model:model isList2:YES];
            if(BMWIntersection(officalRect, rect)) {
                intersection = YES;
                break;
            }
        }
        ret = intersection ? -6 : 0;
    } while (0);
        return ret;
}

- (NSDictionary<NSString*, BMWRect*>*)parseRectForUI2:(BMWMUserCommentModel*) model
{
    NSMutableDictionary<NSString*, BMWRect*>* rectDic = [[NSMutableDictionary alloc] init];
    do {
        BMWRect *rect = [self findRectbyTag:BMWWatermarkTagAnimationView model:model isList2:YES];
        if(rect) {
            rectDic[@"watermark"] = rect;
        }
    } while(0);

    do {
        BMWRect *rect = [self findRectbyTag:BMWWatermarkTagOfficialWatermark model:model isList2:YES];
        BMWRect *rect2 = [self findRectbyTag:BMWWatermarkTagAntiCode model:model isList2:YES];
        if(rect && rect2) {
            rect = BMWRectMake(MIN(rect.left, rect2.left),
                       MIN(rect.top, rect2.top),
                       MAX(rect.right, rect2.right),
                       MAX(rect.bottom, rect2.bottom));

        } else if(rect2) {
            rect = rect2;
        }
        if(rect) {
            rectDic[@"officalWatermark"] = BMWClamp([rect scale:1.2], 0.0, 1.0);
        }
    } while(0);

    return rectDic;
}

- (BMWRect*)findRectbyTag:(NSUInteger)tag model:(BMWMUserCommentModel*) model isList2:(BOOL)isList2
{
    BMWRect *parantRect = BMWRectMakeForList(model.sliceImage.list3.firstObject.sliceRect);
    NSArray<BMWMUserCommentSliceList*>* list = isList2 ? model.sliceImage.list2 : model.sliceImage.list;
    for(BMWMUserCommentSliceList *sliceRect in list) {
        BMWRect *rect = BMWRectMake(sliceRect.sliceRect[0].floatValue,
                                  sliceRect.sliceRect[1].floatValue,
                                  sliceRect.sliceRect[2].floatValue,
                                  sliceRect.sliceRect[3].floatValue);
        rect.tag = sliceRect.sliceImageId.integerValue;
        if(rect.tag == tag) {
            BMWRect *newRect = [rect convert2ParentRect:parantRect];
            newRect.tag = rect.tag;
            return newRect;
        }
    }
    return nil;
}

- (NSString*)workPath
{
    if (!_workPath) {
        _workPath = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"SliceImage"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:_workPath]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:_workPath
                                      withIntermediateDirectories:YES
                                                       attributes:nil
                                                            error:nil];
        }

    }
    return _workPath;
}

- (BMWAnitCodeManger *)anitCodeManger
{
    if(!_anitCodeManger) {
        _anitCodeManger = [[BMWAnitCodeManger alloc] init];
    }
    return _anitCodeManger;
}
@end
