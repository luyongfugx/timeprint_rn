#import <Foundation/Foundation.h>
@class BMWWatermarkItem;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, JpegPackPosition) {
    JpegAppN = 0,
    AppendEnd = 1,
    Auto = 0xFF
};

typedef NS_ENUM(NSInteger, JpegPackType) {
    JpegDataOrgSlice = 0xFF,
    JpegDataClarityOptOrg = 0xFE,
    JpegDataClarityOptOrgSlice = 0xFD
};

typedef NS_ENUM(NSInteger, JpegPackId) {
    JpegPackIdClarityOptImage = 0xFFFF
};

typedef NS_ENUM(NSInteger, BMWClarityOptStatus) {
    BMWClarityOptStatusCanNotOpt       = 0, // 不可做清晰度优化
    BMWClarityOptStatusCanOpt          = 1, // 可做清晰度优化
    BMWClarityOptStatusCanUnkown       = 2, // 是否可以做清晰度优化未知，需要做离线检测
};

typedef NS_ENUM(NSInteger, BMWClarityDetectMode) {
    BMWClarityDetectModeClose       = 0, // 清晰度优化关闭
    BMWClarityDetectModeOnline      = 1, // 清晰度优化在线检测
    BMWClarityDetectModeOffline     = 2, // 清晰度优化离线检测
};

@interface BMWRect : NSObject
@property (nonatomic) NSUInteger tag;
@property (nonatomic) float left;
@property (nonatomic) float top;
@property (nonatomic) float right;
@property (nonatomic) float bottom;
- (CGRect)CGrect;
- (CGFloat)erea;
- (CGPoint)center;
- (float)width;
- (float)height;
- (BMWRect*)scale:(float)ratio;
- (BOOL)isFullScreen;
- (BOOL)isNormOne;
- (BOOL)isOutside;
- (BMWRect*)convert2ParentRect:(BMWRect*)parentRect;
- (BMWRect*)norm;
- (BMWRect*)orientation:(int)o;
@end

@interface BMWCorners : NSObject
@property (nonatomic) NSUInteger tag;
@property (nonatomic) CGPoint point0; // 左上
@property (nonatomic) CGPoint point1; // 右上
@property (nonatomic) CGPoint point2; // 右下
@property (nonatomic) CGPoint point3; // 左下
- (BMWCorners*)norm:(CGSize)size;
- (BMWCorners*)adjustWithOrient:(BMWDeviceOrientation)orient mirrorX:(BOOL)mirrorX;
- (BMWCorners*)mirrorX;
- (BMWCorners*)mirrorY;
- (BMWRect*)xhrect;
@end


FOUNDATION_EXPORT BMWRect* BMWRectFull(void);
FOUNDATION_EXPORT BMWRect* BMWRectMake(float left, float top, float right,float bottom);
FOUNDATION_EXPORT BMWRect* BMWRectMakeForList(NSArray<NSNumber*>* rectList);
FOUNDATION_EXPORT BMWRect* BMWMakeNormRectFromCGRect(CGRect rect, CGSize size);
FOUNDATION_EXPORT BMWRect* BMWMakeRectFromCGRect(CGRect rect);
FOUNDATION_EXPORT BMWRect* BMWMakeRectFromCGPoint(CGPoint center, CGSize size);
FOUNDATION_EXPORT BMWRect* BMWIntersection(BMWRect* one, BMWRect* two);
FOUNDATION_EXPORT CGFloat BMWRectDistance(BMWRect* one, BMWRect* two);
FOUNDATION_EXPORT BMWRect* BMWClamp(BMWRect* rect, float min, float max);
FOUNDATION_EXPORT NSArray<NSNumber*>* BMWMakeListFromRect(CGRect rect);
FOUNDATION_EXPORT CGFloat BMWIOU(CGRect one, CGRect two);
FOUNDATION_EXPORT BOOL BMWOverlap(CGRect one, CGRect two);
FOUNDATION_EXPORT BMWCorners* BMWMakeCornersForList(NSArray<NSNumber*>* list/*左上,右上,右下,左下*/);
FOUNDATION_EXPORT NSArray<NSNumber*>* /*左上,右上,右下,左下*/BMWMakeListFromCorners(BMWCorners* corners);

@interface BMWSliceData : NSObject

@property (nonatomic) long id;

@property (nonatomic) JpegPackType type;

@property (nonatomic) NSData* data;

@property (nonatomic) BMWRect *rect;

@property (nonatomic) NSString *filePath;

+ (BMWSliceData*)buildWithId:(long)id type:(long)type data:(NSData*)data rect:(BMWRect*)rect;

@property (nonatomic, copy) dispatch_block_t releaseBlock;

@end

@interface BMWSliceDataModel : NSObject

@property (nonatomic, nullable) NSError *error;

@property (nonatomic) double timeCost;

@property (nonatomic) long version;

@property (nonatomic) long position;

@property (nonatomic, nullable) NSData* jpegData;

@property (nonatomic, copy) NSString *filePath;

// 3.0.155云图种，新增图种裸数据属性
@property (nonatomic, nullable) NSData* packedRawData;

@property (nonatomic) NSInteger sliceType;

@property (nonatomic) BMWClarityOptStatus clarityOpt;
// preview image的模糊度
@property (nonatomic) CGFloat previewClarity;
// captured image的模糊度
@property (nonatomic) CGFloat capturedClarity;

@property (nonatomic, nullable) NSArray<BMWSliceData*>* sliceDataList;
@property (nonatomic, nullable) NSArray<BMWSliceData*>* sliceDataList2;
@property (nonatomic, nullable) NSArray<BMWSliceData*>* sliceDataList3;

// append操作，将other放到self后面，不做去重处理
- (void)append:(BMWSliceDataModel*)other;

// merge操作，以self为base，将other合并到self，如果有重复slice以other为主
- (void)merge:(BMWSliceDataModel*)other;

- (BMWRect*__nullable)watermarkRectAfterClarityOpt;

+ (BMWSliceDataModel*)buildForVideo:(NSArray<BMWWatermarkItem*>*)watermarks watermarkVideoUrl:(NSURL*)watermarkVideoUrl noWatermarkVideoUrl:(NSURL*)noWatermarkVideoUrl;

@end

NS_ASSUME_NONNULL_END
