#import <Foundation/Foundation.h>
#import "GPCamDefine.h"
#import "BMWWatermarkBuffer.h"

typedef NS_ENUM(NSInteger, BMWWatermarkType) {
    BMWWatermarkTypeProduct    = 0,
    BMWWatermarkTypeNormal     = 1
};

typedef NS_ENUM(NSInteger, BMWWatermarkTag) {
    
    // 防盗等全屏水印
    BMWWatermarkTagFull  = 0x1,
    
    // 除官方水印外的，可以拖动的animationView
    BMWWatermarkTagAnimationView = 0x1 << 1,
    
    // 外面显示的logo
    BMWWatermarkTagOutLogo = 0x1 << 2,
    
    // 加字/标注和数人头AI算法水印等 8/16/32
    BMWWatermarkTagMark = 0x1 << 3,
    
    // 右上角的二维码
    BMWWatermarkTagOutQRCode = 0x1 << 6,
    
    // 右上角的地图
    BMWWatermarkTagOutMap = 0x1 << 7,
    
    // 部分水印的背景渐变
    BMWWaterMarkTagBackgroundShape = 0x1 << 8,
    
    // 右上角的倒计时
    BMWWatermarkTagOutCountdown = 0x1 << 9,
    
    // 右下角的官方水印的animationView
    BMWWatermarkTagOfficialWatermark = 0x1 << 10,
    
    // 右下角的防伪码
    BMWWatermarkTagAntiCode = 0x1 << 11,
    
    // 21号考勤外显
    BMWWatermarkTagOutAttendance = 0x1 << 12,
    
    // 3.0.50: 个人名片
    BMWWatermarkTagOutPersonalCard = 0x1 << 13,
    
    // 3.0.80 双摄小图
    BMWWatermarkTagDoubleShotSmallImageTag = 0x1 << 14,
    
    // 3.0.83 车牌VIP Tips
    BMWWatermarkTagLicensePlateAd = 0x1 << 15,
    
    // 信息外显水印
    BMWWatermarkTagVisitInfoDisplayOutside = 0x1 << 16,
    
    // 门头水印条目
    BMWWatermarkTagDoorHeader = 0x1 << 17,
    
    // 3.0.120 右上角的整改二维码
    BMWWatermarkTagOutRectificQRCode = 0x1 << 18,

    // 水印地址tag
    BMWWatermarkTagAddressLabel = 0x1 << 19,
    
    // 手写签名条目
    BMWWatermarkTagSignatureView = 0x1 << 20,
    
    // 时间label标记
    BMWWatermarkTagTimeLabel = 0x1 << 21,
    
    // 大地图
    BMWWatermarkTagFullMap= 0x1 << 22,
    
    // 画中画
    BMWWatermarkTagPiP= 0x1 << 23,
    
    // 全屏底纹
    BMWWatermarkTagFullCopyRight = 0x1 << 24,
    
    // 电子屏
    BMWWatermarkTagElectronicScreen = 0x1 << 25,
};

typedef NS_ENUM(NSInteger, BMWRefreshWatermarkStatus) {
    BMWRefreshWatermarkStatusDataChanged = 1,
    BMWRefreshWatermarkStatusCaptureView = 2
};

typedef void(^BMWRefreshWatermarkFinishBlock)(void);

NS_ASSUME_NONNULL_BEGIN
@class BMWRect;
@class BMWWatermarkInfoV2;
@interface BMWWatermarkItem : NSObject<NSCopying>
@property (nonatomic, readonly) long long id;
@property (nonatomic, assign) CGFloat scale;
@property (nonatomic, assign) BOOL highResolution;
@property (nonatomic, assign) CGFloat x;
@property (nonatomic, assign) CGFloat y;
@property (nonatomic, assign) CGFloat w;
@property (nonatomic, assign) CGFloat h;
@property (nonatomic, strong) UIView *water;
@property (nonatomic, strong) CALayer *waterLayer;
// 说明需要刷新,refreshTime是刷新间隔，每个机型都要，refreshTime的单位是秒  refreshTime时生效
@property (nonatomic, assign) CGFloat refreshTime;
@property (nonatomic, assign) BMWWatermarkType type;
@property (nonatomic, assign) BMWDeviceOrientation deviceOrientation;
@property (nonatomic, assign) BOOL hidden;
// 表示水印渲染(UIView->texture)放到照片后处理阶段执行，为水印预留更改时间
@property (nonatomic, assign) BOOL renderingSync;

@property (nonatomic, assign) NSUInteger tag;

@property (nonatomic, strong) NSArray<BMWRect*>* realWatermarkRectList;

@property (nonatomic, strong) NSArray<BMWRect*>* realWatermarkRectList2;

@property (nonatomic, strong, nullable) BMWRect* locationRect;
// [3.0.220] 水印时间可能分两部分所以改为数组，如果是两部分则日期在前时间在后
@property (nonatomic, strong, nullable) NSArray<BMWRect*>* timeRects;

@property (nonatomic, assign) BOOL cacheBuffer;
@property (nonatomic, strong) BMWWatermarkBuffer *buffer;

@property (nonatomic, copy) void (^beginCapture)(void);

// 主线程回调上来：根据content去刷新UI->调用finishBlock->刷新UI
@property (nonatomic, copy, nullable) void (^refreshWatermark)(BMWRefreshWatermarkStatus status, _Nullable id content, _Nullable BMWRefreshWatermarkFinishBlock finishBlock);

- (BMWWatermarkItem*)calculateScaleByQuality:(BMWImageResolutionQuality)quality;

- (BMWWatermarkItem*)calculateScaleBySize:(CGSize)size;

+ (NSArray<BMWWatermarkInfoV2 *>*)createWatermarkInfoV2sFromItems:(NSArray<BMWWatermarkItem* >*)watermarks deviceOrientation:(BMWDeviceOrientation)deviceOrientation;

@end

NS_ASSUME_NONNULL_END
