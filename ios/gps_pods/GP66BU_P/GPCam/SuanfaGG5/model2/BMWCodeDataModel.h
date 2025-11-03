#import <Foundation/Foundation.h>
#import "GPCamDefine.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BMWAntiCodeVersion) {
    // [3.0.125]雪花ID编码方式
    BMWAntiCodeVersionSnowFlakeId = 0,
    // [3.0.125]新的时间和地点编码方式
    BMWAntiCodeVersionTimeAndXY2 = 4,
    // [3.0.125]新时间和地点类型编码方式
    BMWAntiCodeVersionTimeAndLocationType2 = 5,
    // 时间和地点编码方式
    BMWAntiCodeVersionTimeAndXY = 6,
    // 时间和地点类型编码方式
    BMWAntiCodeVersionTimeAndLocationType = 7,
};

@interface BMWCodeDataModel : NSObject
// 是否有效
@property (nonatomic) BOOL valid;
// 雪花ID
@property (nonatomic) NSString* __nullable snowFlakeId;

@property (nonatomic) BMWAntiCodeVersion version;

// 0 表示时间戳为秒；1表示时间戳为毫秒
@property (nonatomic) NSUInteger timestampFormat;

// 时间戳;如果version为XHAntiCodeVersionTimeAndXY 时间表示范围为[2022-01-01 00:00:00, 2026-04-03 10:42:08]
@property (nonatomic) long long timeStamp;

// 仅仅支持中国经纬度编码，经度[73.0, 138.535], 维度 [3.0, 68.535]
@property (nonatomic) float longitude;
@property (nonatomic) float latitude;

// 0～3 参考业务定义
// 4 正常经纬度
// N 地点枚举 ~2^20-1
@property (nonatomic) NSUInteger locationType;

@property (nonatomic) int bwmId;
// 2.9.45：蓝色真实时间官方水印
@property (nonatomic) BMWOfficalWatermarkStyle officalWatermarkStyle;
// 本地编码的防伪码+雪花ID编码的防伪码；通过version来区分
@property (nonatomic) NSString* __nullable code;

@property (nonatomic) NSInteger digitCount;

// 构造编码“时间和地点类型”，比如地点没有获取到的类型
+ (BMWCodeDataModel* __nullable)buildWithTimestampMS:(NSUInteger)timestamp locationType:(NSUInteger)locationType;

// 构造编码”时间和地点经纬度“模型
+ (BMWCodeDataModel* __nullable)buildWithTimestampS:(NSUInteger)timestamp longitude:(float)longitude latitude:(float)latitude;

// [3.0.125新] version== 0走3.0.125前编码，version==1走3.0.125后的编码
+ (BMWCodeDataModel* __nullable)buildWithVersion:(NSUInteger)version timestampMS:(NSUInteger)timestamp locationType:(NSUInteger)locationType longitude:(float)longitude latitude:(float)latitude id:(NSString*)snowFlakeId;

// 构造解码模型
+ (BMWCodeDataModel* __nullable)buildWithCode:(NSString*)code;

@end

NS_ASSUME_NONNULL_END
