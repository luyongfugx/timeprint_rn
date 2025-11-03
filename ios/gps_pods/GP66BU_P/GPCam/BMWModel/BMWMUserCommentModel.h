#import <Foundation/Foundation.h>
#import "BMWMediaBaseModel.h"
#import "BMWSliceData.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BMWTakePhotoType) {
    // 上部分和下部分可以同时存在，type=上部分|下部分。比如无遮挡和拜访可视化的type=0x103
    // 通用&&下部分，范围0x0-0xFF
    BMWTakePhotoTypeNormal    = 0, // 普通拍照
    BMWTakePhotoTypeTakeCollagePhoto     = 1, // 边拍边拍
    BMWTakePhotoTypeCollagePhoto    = 2, // 拼图(保留)
    BMWTakePhotoTypeUnmask     = 3, // 无遮挡
    BMWTakePhotoTypePhotoRoute = 4, // 拍照路线条目拍照
    BMWTakePhotoTypeI18nBusinessCard = 5, // 海外版本个人名片
    // 上部分，范围0x100-0xFF00
    BMWTakePhotoTypeVisiteModeVisualization = 0x100 // 拜访结果可视化
};

/// data model
@interface BMWMUserCommentBaseInfoUa : BMWMediaBaseModel
@property(nonatomic, strong) NSString* os;
@end
@interface BMWMUserCommentBaseInfo : BMWMediaBaseModel
@property(nonatomic, strong) BMWMUserCommentBaseInfoUa* ua;
@end
@interface BMWMUserCommentWatermarkContent : BMWMediaBaseModel
@property(nonatomic, assign) NSUInteger id;
@end
@interface BMWMUserCommentWatermarkContentExtension : BMWMediaBaseModel
@property(nonatomic, strong) NSString* officialWatermarkType;
@end
@interface BMWMUserCommentData : BMWMediaBaseModel
@property(nonatomic, strong) NSString* watermarkBaseID;
@property(nonatomic, strong) BMWMUserCommentBaseInfo* baseInfo;
@property(nonatomic, strong) NSArray<BMWMUserCommentWatermarkContent*>* watermarkContent;
@property(nonatomic, strong) BMWMUserCommentWatermarkContentExtension *watermarkContentExtension;
@end

@interface BMWMUserCommentSliceList : BMWMediaBaseModel
@property(nonatomic, strong) NSString* sliceImageId;
@property(nonatomic, strong) NSArray<NSNumber*>* sliceRect;
@end

//"sliceImage": {
//    "capturedClarity": -1,
//    "clarityOpt": 0,
//    "list": [
//    ],
//    "list2": [
//    ],
//    "list3": [
//    ],
//    "postion": 0,
//    "previewClarity": -1,
//    "state": 0,
//    "type": 0
//}
@interface BMWMUserCommentSliceData : BMWMediaBaseModel
@property(nonatomic, assign) BMWTakePhotoType type;
@property(nonatomic, assign) NSUInteger postion;
@property(nonatomic, assign) NSUInteger state;
@property(nonatomic, assign) BMWClarityOptStatus clarityOpt;
@property(nonatomic, assign) CGFloat capturedClarity;
@property(nonatomic, assign) CGFloat previewClarity;
@property(nonatomic, strong) NSArray<BMWMUserCommentSliceList*> *list;
@property(nonatomic, strong) NSArray<BMWMUserCommentSliceList*> *list2;
@property(nonatomic, strong) NSArray<BMWMUserCommentSliceList*> *list3;
@end


/// us model
@interface BMWMUserCommentModel : BMWMediaBaseModel
@property(nonatomic, strong) BMWMUserCommentData* data;
@property(nonatomic, strong) BMWMUserCommentSliceData* sliceImage;
@property(nonatomic, assign) BOOL hasSliceImageForUI;
@property(nonatomic, assign) BOOL isValid;
@property(nonatomic, assign) BOOL hasWatermarkShadow;
@property(nonatomic, assign) BOOL hasWatermark;
@property(nonatomic, assign) BOOL hasOfficialWatermark;
@property(nonatomic, assign) BOOL hasMapCode;
@property(nonatomic, assign) BOOL isIOS;
@property(nonatomic, assign) NSInteger watermarkOverlap;
@property(nonatomic, strong) NSArray<BMWSliceData*>* sliceDataList;
@property(nonatomic, strong) NSArray<BMWSliceData*>* sliceDataList2;
@property(nonatomic, strong) NSArray<BMWSliceData*>* sliceDataList3;
@end

NS_ASSUME_NONNULL_END
