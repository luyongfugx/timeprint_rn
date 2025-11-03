#import <Foundation/Foundation.h>
#import "BMWSliceData.h"

NS_ASSUME_NONNULL_BEGIN

@interface BMWJpegPacker : NSObject

+ (BMWJpegPacker*)sharedInstance;

- (void)configPackPostion:(JpegPackPosition)position;

// 构建图种
- (void)pack:(BMWSliceDataModel* _Nullable )request completeBlock:(void (^)(BMWSliceDataModel* _Nullable reslut))completeBlock;
- (void)pack:(BMWSliceDataModel* _Nullable )request ignoreClarityOpt:(BOOL)ignore completeBlock:(void (^)(BMWSliceDataModel* _Nullable reslut))completeBlock;

// 提取图种
- (void)unpack:(void (^)(BMWSliceDataModel *request))maker completeBlock:(void (^)(BMWSliceDataModel* _Nullable reslut))completeBlock;

- (void)packVideo:(BMWSliceDataModel* _Nullable )request completeBlock:(void (^)(BMWSliceDataModel* _Nullable reslut))completeBlock;
- (void)unpackVideo:(void (^)(BMWSliceDataModel *request))maker dstDir:(NSString *)dstDir completeBlock:(void (^)(BMWSliceDataModel* _Nullable reslut))completeBlock;
// 从带有图种视频的文件中把有水印视频抽出来，上面unpackVideo是把无水印视频抽出来
- (BOOL)extractWatermarkedVideoFrom:(NSString*)videoFilePath dstFilePath:(NSString*)dstFilePath error:(NSError**)error;

- (void)copyPack:(NSURL*)srcUrl destJpegData:(NSData*)destJpegData completeBlock:(void (^)(BMWSliceDataModel* _Nullable reslut))completeBlock;

// 3.0.155云图种，用图种文件+压缩后的原图，构建一个可以去水印的图，tips：需要把压缩后的原图的拷贝到沙河
- (NSInteger)buildWithPackedRawData:(NSString*)packedRawDataPath destJpegPath:(NSString*)destJpegPath;

/// 3.0.155云图种, 检测是否能去水印在block中返回类型
/// - Parameters:
///   - srcUrl:
///   - completeBlock:参数 int code, NSString *extraCode
///   code=0表示，不支持去水印
///   code=1表示，可以本地图种去水印
///   code=2表示，可以去通过消除笔去水印(判断逻辑为右下角有「今日水印」)，extraCode为nil
///   code=3表示，可以采用云图种去水印，extraCode为防伪码，但具体能不能去取决于业务测是否拉去到了图种和us
///   优先级：本地图种去水印 >云图种去水印>消除笔去水印。注意，云图种业务测需要结合OSS情况，如果不能去水印降级到消除笔去水印
- (void)checkPackedWithPath:(NSURL*)srcUrl completeBlock:(void (^)(int code, NSString * _Nullable extraCode))completeBlock;

/// 3.0.195，检测是否包含图种，可以作为近似判断今拍。同步方法，耗时大概1ms
/// - Parameters:
///   - srcUrl:
///   - Returns:YES表示有图种，NO表示没有图种
- (BOOL)checkPackedWithPath:(NSURL*)srcUrl;

/*
 @{@"officalWatermark" : BMWRect,图片坐标系(归一化到0-1),
    @"watermark" : BMWRect,图片坐标系(归一化到0-1)}*/
- (NSDictionary<NSString*, BMWRect*>*)sliceRect:(NSString*)userCommentStr;

/*
 0 表示可以去除右下角官方水印
 非0 表示不能去除，数值表示原因
 */
- (NSUInteger)canRemoveOfficalWatermark:(NSString*)userCommentStr;

- (void)checkClarityOpt:(NSURL*)srcUrl userCommentStr:(NSString*)userCommentStr completeBlock:(void (^)(BOOL reslut))completeBlock;


/*
 0 表示可以提取出照片
 非0 标识可以提取出照片
 */
- (void)checkParseImage:(NSURL*)srcUrl userCommentStr:(NSString*)userCommentStr completeBlock:(void (^)(BOOL result))completeBlock;


@end

NS_ASSUME_NONNULL_END
