#import <Foundation/Foundation.h>
#import "BMWVideoAlgorithmResultInterface.h"
#import "GPCamDefine.h"
#import "BMWMediaBaseModel.h"
#import "BMWSliceData.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, BMWAlgorithmModeId) {
    BMWAlgorithmModelIdVlpr = 1,
    BMWAlgorithmModelIdFaceDectect = 2,
    BMWAlgorithmModelIdOCR = 3,
    BMWAlgorithmModelIdSteelDetect = 4
};

/////////////////车牌识别//////////////
@interface BMWVlprMetaData : NSObject<NSCopying>

// 设备方向
@property(assign) BMWDeviceOrientation orientation;

@property(assign) CGFloat score;

// 车牌rectUI坐标系(归一化到0-1)
@property(assign) CGRect rect;

// 车牌rectUI图片系(归一化到0-1)
@property(assign) CGRect rectForImage;

// white
// yellow
// blue
// black
// green
// unkown
@property(strong) NSString *type;

// 格式化的字符串;例如:京A·F0236
@property(strong) NSString *formatCharacter;

@property(strong) UIImage *plateImage;

@end

@interface BMWVlprAlgorithmResult : NSObject<BMWVideoAlgorithmResultInterface>

// 0 识别失败;
// 1 识别中, data里rect有效;
// 2 识别成功, data里数据均有效
@property(assign) NSInteger status;

@property(strong) NSArray <BMWVlprMetaData*>*data;

@end

/////////////////目标检测 MetaData//////////////
typedef NS_ENUM(NSUInteger, BMWLabelClassify) {
    BMWLabelClassifyPerson = 0,
    BMWLabelClassifySteel = 1
};

@interface BMWRectMetaData : NSObject<NSCopying>

// 设备方向
@property(assign) BMWDeviceOrientation orientation;

// 目标id
@property(assign) NSUInteger id;

// 检测得分
@property(assign) CGFloat score;

// 目标分类索引
@property(assign) int label;

// 目标分类名称
@property(strong) NSString* labelName;

@property(assign) BOOL isAuto;

// 检测目标rect, UI坐标系(归一化到0-1)
@property(assign) CGRect rect;

// 检测目标rect, 图片坐标系(归一化到0-1)
@property(assign) CGRect rectForImage;

@property(assign) BOOL imageCoordinateSystem;

+ (BMWRectMetaData*)buildForUI:(CGRect)rect;

+ (BMWRectMetaData*)buildForImage:(CGRect)rect;

@end

/////////////////人脸检测//////////////
@interface BMWFaceDectectAlgorithmResult : NSObject<BMWVideoAlgorithmResultInterface>
// 0 识别失败;
// 2 识别成功, data里数据均有效
@property(assign) NSInteger status;

// 人脸检测的平均rect(归一化UI坐标系)
@property(assign) CGRect meanRect;

// 人脸检测的数据集合
@property(strong) NSArray <BMWRectMetaData*>*data;

@end

@interface BMWFaceAttributeData : NSObject
@property(nonatomic) double timestampMS;
@property(nonatomic) BMWDeviceOrientation orientation;
@property(nonatomic) NSUInteger id;
@property(nonatomic) CGFloat clarity;
@property(nonatomic) CGFloat score;
@property(nonatomic) CGFloat visibility;
@property(nonatomic) CGFloat yaw;
@property(nonatomic) CGFloat pitch;
@property(nonatomic) CGFloat roll;
@property(nonatomic) BMWRect* faceRect;
@property(nonatomic) BMWRect* headRect;
@property(nonatomic) UIImage* headImage;
@property(nonatomic) UIImage* oriImage;
@end

@interface BMWFaceAttributeAlgorithmResult : NSObject<BMWVideoAlgorithmResultInterface>
//  0  有合适的人脸数据
// -1 没有人脸
// -2 多张人脸
// -3 单张人脸倾斜角度过大
// -4 单张人脸有遮挡
// -5 人脸区域过小
@property(assign) NSInteger status;
@property(strong) NSMutableArray<BMWFaceAttributeData*>* data;
@end

/////////////////钢筋检测//////////////
@interface BMWSteelDectectAlgorithmResult : NSObject<BMWVideoAlgorithmResultInterface>
// 0 识别失败;
// 2 识别成功, data里数据均有效
@property(assign) NSInteger status;

// 钢筋检测的平均rect(归一化UI坐标系)
@property(assign) CGRect meanRect;

// 钢筋检测的数据集合
@property(strong) NSArray <BMWRectMetaData*>*data;

@end

/////////////////OCR//////////////
@interface BMWOCRMetaData : NSObject<NSCopying>
// 设备方向
@property(assign) BMWDeviceOrientation orientation;

@property(assign) CGFloat angleScore;
@property(assign) CGFloat score;
@property(assign) CGRect rect;

// 四个点坐标
@property(strong) BMWCorners *corners;

@property(strong) NSString *label;

// 映射前的字符串
@property(strong) NSString *rawLabel;

// 映射前的字符串是否包含无效的字符
@property(assign) BOOL containIllegalWord;

@property(strong) UIImage *image;

@end

@interface BMWOCRAlgorithmResult : NSObject<BMWVideoAlgorithmResultInterface>
// 是否为门头识别场景
@property(assign) BOOL isShopSign;
// 0 识别失败;
// 2 识别成功, data里数据均有效
@property(assign) NSInteger status;

@property(strong, nullable) BMWOCRMetaData* dataOfInterest;

@property(strong) NSArray <BMWOCRMetaData*>*data;

- (NSString*)ocrTexts;

@end

@interface BMWCodeAlgorithmResult : NSObject<BMWVideoAlgorithmResultInterface>
// 0 识别失败;
// 2 识别成功
@property(assign) NSInteger status;

// 是被调整过
@property(assign) BOOL isAdjusted;

// 感兴趣的点
@property(assign) CGPoint pointOfInterest;
// 感兴趣的数据
@property(strong, nullable) BMWOCRMetaData*  dataOfInterest;
// 所有数据
@property(strong, nullable) NSArray <BMWOCRMetaData*>*data;
@end

@interface BMWImageClsAlgorithmResult : NSObject<BMWVideoAlgorithmResultInterface>
// 0 识别失败;
// 2 识别成功, data里数据均有效
@property(assign) NSInteger status;

@property(assign) BOOL isClassification;
@property(assign) BOOL isMirror;
@property(assign) BOOL isShelf;
@property(assign) BOOL isHead;
@property(assign) BOOL isTextScene;
@property(assign) BOOL isUnknown;

@property(strong) NSArray <BMWRectMetaData*>*data;

// format "shelf;hat#3"
- (NSString*)labelNames;
// c|head|shelf
// d|face,0.01,0.093,0.073,0.185|car,0.062,0.185,0.177,0.463
- (NSString*)evaLabel;

// 给定一个标签集合，查找所有符合要求的集合
// 比如:labelArray给["face", "other_clothes", "reflective_clothes"]，返回人脸集合
- (NSArray<BMWRectMetaData*>*)filterWithLabels:(NSArray <NSString*>*)labelArray;

// 给定一个标签集合，查找最合适的特征
// labelArray给["head-head", "display-shelf", "display-box", "display-loose", "refrigerator", "freezer", "table", "electronic_scale"]，返回最合适的特征
- (BMWRectMetaData* _Nullable)findBestWithLabels:(NSArray <NSString*>*)labelArray;

@end

/////////////////门头结果//////////////
@interface BMWShopSignOCRData : BMWMediaBaseModel
@property(nonatomic) CGFloat prob;
@property(nonatomic) NSString* text;
@property(nonatomic) NSArray <NSNumber*>*rect;
// 四个点坐标
@property(nonatomic) NSArray <NSNumber*>*corners;
@end

@interface BMWShopSignMetaData : BMWMediaBaseModel

@property(nonatomic) CGFloat prob;
@property(nonatomic) NSArray <NSNumber*>*headRect;
@property(nonatomic) NSMutableArray <BMWShopSignOCRData*>*ocrList;

@end

@interface BMWShopSignRecognitionResult : BMWMediaBaseModel
@property(strong) NSMutableArray <BMWShopSignMetaData*>*headList;

+ (nullable BMWShopSignRecognitionResult*)build:(NSMutableArray<BMWRectMetaData*>*)detList ocrList:(NSMutableArray<BMWOCRMetaData*>*)ocrList;

+ (nullable BMWShopSignRecognitionResult*)build:(BMWOCRAlgorithmResult*)ocr;

+ (nullable BMWShopSignRecognitionResult*)buildMaxShopSign:(BMWShopSignRecognitionResult*)one;

- (nullable NSString*)toJsonStr;

- (nullable NSString*)shopSignsForDebug;
@end


/////////////////图片质量//////////////
@interface BMWImageQualityAlgorithmResult : NSObject<BMWVideoAlgorithmResultInterface>
// 0 识别失败;
// 2 识别成功, data里数据均有效
@property(assign) NSInteger status;

@property(strong) NSArray <BMWRectMetaData*>*imageQualityData;
@property(strong) NSArray <BMWRectMetaData*>*recaptureData;

@end

NS_ASSUME_NONNULL_END
