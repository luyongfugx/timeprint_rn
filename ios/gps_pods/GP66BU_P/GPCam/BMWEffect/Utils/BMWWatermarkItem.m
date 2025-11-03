#import "BMWWatermarkItem.h"
#import "BMWDeviceUtils.h"
#import "BMWSliceData.h"
#import "UIView+GPCam.h"
#import "BMWWatermarkDrawer.h"
#define DEBUG_LOCATION_RECT 0

@interface BMWWatermarkItem ()
@property (nonatomic, assign) long long id;
@property (nonatomic, assign) BOOL forceHighResolution;
@end

@implementation BMWWatermarkItem

- (instancetype)init
{
    if (self = [super init]) {
        self.type = BMWWatermarkTypeNormal;
        self.scale = 4.0;//UIScreen.mainScreen.scale;
        self.x = self.y = 0;
        self.w = self.h = 1;
        self.deviceOrientation = BMWDeviceOrientationPortait;
        self.id = (long long)self;
    }
    return self;
}

- (id)copyWithZone:(nullable NSZone *)zone
{
    BMWWatermarkItem *data = [[BMWWatermarkItem allocWithZone:zone] init];
    data.id = self.id;
    data.scale = self.scale;
    data.highResolution = self.highResolution;
    data.x = self.x;
    data.y = self.y;
    data.w = self.w;
    data.h = self.h;
    data.water = [self.water copy];
    data.type = self.type;
    data.hidden = self.hidden;
    data.refreshTime = self.refreshTime;
    data.deviceOrientation = self.deviceOrientation;
    data.renderingSync = self.renderingSync;
    data.beginCapture = [self.beginCapture copy];
    data.realWatermarkRectList = self.realWatermarkRectList;
    data.realWatermarkRectList2 = self.realWatermarkRectList2;
    return data;
}

- (void)setWater:(UIView *)water
{
    _water = water;
    _waterLayer = water.layer;
    _tag = water.tag;
    _water.xhm_invisible = NO;
    [self parseValidWatermark];
    [self parseInvisible:water];
}

- (void)parseInvisible:(UIView*)view
{
    if (view.xhm_invisible == YES) {
        self.forceHighResolution = YES;
        view.layer.xhm_invisible = view.xhm_invisible;
    }
    for (UIView *subView in view.subviews) {
        [self parseInvisible:subView];
    }
}
/* 3.0.220 业务端计算
- (void)parseWatermarkItemFromView:(UIView*)view itemView:(UIView**)itemView tag:(NSUInteger)tag
{
    if (view.tag == tag) {
        BMWMLog(@"BMWWatermarkItem parseWatermarkItem hit:%d", view.tag);
        *itemView = view;
        return;
    }
    for (UIView *subView in view.subviews) {
        if(!subView.hidden) {
            [self parseWatermarkItemFromView:subView itemView:itemView tag:tag];
        }
    }
}

- (void)paraseAddressRect:(UIView*)water transform:(CGAffineTransform)transform
{
    BMWRect *parentRect = BMWRectMake(self.x, self.y, self.x + self.w, self.y + self.h);
    // 主要处理water为非全尺寸问题
    if(parentRect.erea < 0.999) {
        water = water.superview;
        transform = water.transform;
    }
    // 计算水印整体大小
    CGSize waterSize = CGSizeApplyAffineTransform(water.frame.size, transform);
    waterSize = CGSizeMake(abs(waterSize.width), abs(waterSize.height));
    do {
        // 解析地址条目rect
        UIView *locationView = nil;
        [self parseWatermarkItemFromView:water itemView:&locationView tag:BMWWatermarkTagAddressLabel];
        if(!locationView) break;
        CGRect frame = [locationView.superview convertRect:locationView.frame toView:water];
        self.locationRect = BMWMakeNormRectFromCGRect(frame, waterSize);

        // 解析时间条目rect
        UIView *timeView = nil;
        [self parseWatermarkItemFromView:water itemView:&timeView tag:BMWWatermarkTagTimeLabel];
        if(!timeView) break;
        frame = [timeView.superview convertRect:timeView.frame toView:water];
        self.timeRect = BMWMakeNormRectFromCGRect(frame, waterSize);
    } while (NO);
    
#if DEBUG_LOCATION_RECT
        CGRect locationFrame = CGRectMake(self.locationRect.CGrect.origin.x*waterSize.width,
                                     self.locationRect.CGrect.origin.y*waterSize.height,
                                     self.locationRect.CGrect.size.width*waterSize.width,
                                     self.locationRect.CGrect.size.height*waterSize.height);
        UIView *locationView2 = [[UIView alloc] initWithFrame:locationFrame];
        locationView2.layer.borderColor = UIColor.redColor.CGColor;
        locationView2.layer.borderWidth = 1.0f;
        [water addSubview:locationView2];
        
        CGRect timeFrame = CGRectMake(self.timeRect.CGrect.origin.x*waterSize.width,
                                     self.timeRect.CGrect.origin.y*waterSize.height,
                                     self.timeRect.CGrect.size.width*waterSize.width,
                                     self.timeRect.CGrect.size.height*waterSize.height);
        UIView *timeView2 = [[UIView alloc] initWithFrame:timeFrame];
        timeView2.layer.borderColor = UIColor.greenColor.CGColor;
        timeView2.layer.borderWidth = 1.0f;
        [water addSubview:timeView2];
#endif
    BMWMLog(@"BMWWatermarkItem locationRect:%@, timeRect:%@", self.locationRect, self.timeRect);
}
*/
- (BMWWatermarkItem*)calculateScaleByQuality:(BMWImageResolutionQuality)quality
{
    BOOL sp = [BMWDeviceUtils isLowerThaniPhone6] || [BMWDeviceUtils isiPhone7Family];
    BOOL high = quality > BMWImageResolutionQualityMedium || quality == BMWImageResolutionQualityCurrent;
    if (self.forceHighResolution || (high && !sp)) {
        self.scale = 4.0;
        self.highResolution = YES;
    }
    BMWMLog(@"BMWWatermarkItem scale:%lf", self.scale);
    return self;
}

- (BMWWatermarkItem*)calculateScaleBySize:(CGSize)size
{
    BOOL sp = [BMWDeviceUtils isLowerThaniPhone6] || [BMWDeviceUtils isiPhone7Family];
    BOOL high = MAX(size.width, size.height) >= BMWImageResolutionHigh;
    if (high && !sp) {
        self.scale = 6.0;
        self.highResolution = YES;
    }
    BMWMLog(@"BMWWatermarkItem scale:%lf", self.scale);
    return self;
}

- (void)parseValidWatermark
{
#if DEBUG_LOCATION_RECT
    @onExit {
        self.realWatermarkRectList = [NSArray arrayWithObjects:self.locationRect, self.timeRect, nil];
        self.realWatermarkRectList2 = [NSArray arrayWithObjects:self.locationRect, self.timeRect, nil];
    };
#endif
    // parse valid watermark
    UIView *water = _water;
    CGAffineTransform transform = water.transform;
    // 拍照确认和编辑case下不添加标注和文字case需要特殊处理一下，取出有效的view
    Class contentViewClass = NSClassFromString(@"_TtC14XCameraMixture13XHContentView");
    // 加字
    Class stickerClass = NSClassFromString(@"_TtC14XCameraMixture20XHQStickerActionView");
    // 标注
    Class stickerNewClass = NSClassFromString(@"_TtC14XCameraMixture23XHQStickerActionViewNew");
    BOOL hasFullWatermark = NO;
    NSMutableArray<BMWRect*>* realWatermarkRectList = [[NSMutableArray alloc] init];
    NSMutableArray<BMWRect*>* realWatermarkRectList2 = [[NSMutableArray alloc] init];
    
    // case0.1 直接通过x,y,w,h计算rect
    if(water.tag == BMWWatermarkTagVisitInfoDisplayOutside &&
       water.hidden != YES && water.alpha != 0) {
        BMWRect *rect = BMWMakeRectFromCGRect(CGRectMake(self.x, self.y, self.w, self.h));
        rect.tag = water.tag;
        [realWatermarkRectList addObject:rect];
        [realWatermarkRectList2 addObject:rect];
        self.realWatermarkRectList = realWatermarkRectList;
        self.realWatermarkRectList2 = realWatermarkRectList2;
        // 3.0.220 业务端计算
//        [self paraseAddressRect:water transform:transform];
        BMWMLog(@"BMWWatermarkItem parse case0.1 rect:%@", rect);
        return;
    }
    
    if([water isMemberOfClass:contentViewClass] ||
       ([water isKindOfClass:contentViewClass] && self.type == BMWWatermarkTypeProduct)) {
        int validCount = 0;
        BOOL doubelShotMode = NO;
        for (UIView *subView in water.subviews) {
            if ([subView isKindOfClass:stickerClass] || [subView isKindOfClass:stickerNewClass]) {
                validCount = 0;
                break;
            }
            
            if (!(CGRectEqualToRect(subView.frame, CGRectZero) ||
                subView.hidden == YES || subView.alpha == 0)) {
                validCount++;
                if(/*TODO 双摄模式下的去水印单独处理*/subView.tag == BMWWatermarkTagDoubleShotSmallImageTag) {
                    doubelShotMode = YES;
                    BMWRect *rect = BMWMakeNormRectFromCGRect(subView.frame, water.frame.size);
                    rect.tag = subView.tag;
                    [realWatermarkRectList addObject:rect];
                    [realWatermarkRectList2 addObject:rect];
                }
            }
        }
        if (validCount == 1 || doubelShotMode) {
            water = water.subviews.lastObject;
            transform = CGAffineTransformInvert(water.transform);
        }
    }

    CGSize waterSize = CGSizeApplyAffineTransform(water.frame.size, transform);
    waterSize = CGSizeMake(abs(waterSize.width), abs(waterSize.height));
    // 3.0.220 业务端计算
//    [self paraseAddressRect:water transform:transform];
    // case0
    // 全屏情况: id35(现场拍照)、id46(防盗水印)、id55(开防盗声明条目)、 画笔情况、新的CopyRight条目
    Class id35 = NSClassFromString(@"_TtC14XCameraMixture13ID35Watermark");
    Class id46 = NSClassFromString(@"_TtC14XCameraMixture13ID46Watermark");
    Class id55 = NSClassFromString(@"_TtC14XCameraMixture13ID55Watermark");
    if (hasFullWatermark || [water isKindOfClass:id35] || [water isKindOfClass:id46] ||
        ([water isKindOfClass:id55] && water.subviews.firstObject.hidden == NO)) {
        CGRect newFrame = water.frame;
        if (!CGRectEqualToRect(newFrame, CGRectZero)) {
            //全屏幕情况下直接修改 BMWMakeNormRectFromCGRect(newFrame, waterSize) -> BMWRectFull()
            BMWRect *rect = BMWRectFull();
            rect.tag = water.tag;
            [realWatermarkRectList addObject:rect];
            [realWatermarkRectList2 addObject:rect];
            BMWMLog(@"BMWWatermarkItem parse case0, tag:%d, rect:%@", water.tag, rect);
        }
        self.realWatermarkRectList = realWatermarkRectList;
        self.realWatermarkRectList2 = realWatermarkRectList2;
        return;
    }
    
    // case1
    // 如果self.water有tag表明watermark为小区域水印或是官方水印
    if (water.tag == BMWWatermarkTagAnimationView ||
        water.tag == BMWWatermarkTagOfficialWatermark) {
        CGRect newFrame = water.frame;
        CGRect newFrame2 = water.frame;
        // 获取官方水印通过water.subviews.firstObject获取shawdow
        if (water.tag == BMWWatermarkTagOfficialWatermark) {
            newFrame = water.subviews.firstObject.frame;
            newFrame2 = water.subviews.lastObject.frame;
        }
        // 小图模式的需要water.superview来计算watermark的位置
        else {
            waterSize = CGSizeApplyAffineTransform(water.superview.frame.size, water.superview.transform);
            waterSize = CGSizeMake(abs(waterSize.width), abs(waterSize.height));
        }
        if (!CGRectEqualToRect(newFrame, CGRectZero)) {
            BMWRect *rect = BMWMakeNormRectFromCGRect(newFrame, waterSize);
            rect.tag = water.tag;
            [realWatermarkRectList addObject:rect];
            BMWRect *rect2 = BMWMakeNormRectFromCGRect(newFrame2, waterSize);
            rect2.tag = water.tag;
            [realWatermarkRectList2 addObject:rect2];
            BMWMLog(@"BMWWatermarkItem parse case1, rect:%@, rect2:%@", rect, rect2);
        }
        self.realWatermarkRectList = realWatermarkRectList;
        self.realWatermarkRectList2 = realWatermarkRectList2;
        return;
    }
    // case2
    // self.water.tag=0 表明watermark为全屏,根据tag遍历出有效的subview
    Class id10 = NSClassFromString(@"_TtC14XCameraMixture13ID10Watermark");
    Class id21 = NSClassFromString(@"_TtC14XCameraMixture13ID21Watermark");
    Class id34 = NSClassFromString(@"_TtC14XCameraMixture13ID34Watermark");
    for (UIView *subView in water.subviews) {
        BOOL isConfirm = [subView isKindOfClass:[water class]];
        BOOL hasSticker = [subView isKindOfClass:stickerClass] || [subView isKindOfClass:stickerNewClass];
        if (!hasSticker && !isConfirm &&
            (CGRectEqualToRect(subView.frame, CGRectZero) ||
            subView.hidden == YES ||
            subView.alpha == 0 ||
            subView.tag == 0)) {
            continue;
        }
        BMWRect *rect = nil;
        BMWRect *rect2 = nil;
        // id10/id34/id21有shadow，通过subView.subviews.firstObject来获取shawdow
        BOOL parseShawdow = subView.tag == BMWWatermarkTagAnimationView && ([water isKindOfClass:id10] || [water isKindOfClass:id21] || [water isKindOfClass:id34]);
        UIView *newSubView = subView;
        if (([water isKindOfClass:id21] || [water isKindOfClass:id34]) && parseShawdow) {
            newSubView = subView.subviews.firstObject;
        }
        UIView *shawdow = newSubView.subviews.firstObject;
        parseShawdow = parseShawdow && [shawdow isKindOfClass:[UIImageView class]] && shawdow.hidden == NO && shawdow.alpha > 0;
        if (parseShawdow) {
            CGFloat left = MAXFLOAT;
            CGFloat top = MAXFLOAT;
            CGFloat right = -MAXFLOAT;
            CGFloat bottom = -MAXFLOAT;
            for (UIView *subsubView in newSubView.subviews) {
                left = MIN(subsubView.frame.origin.x, left);
                top = MIN(subsubView.frame.origin.y, top);
                right = MAX(subsubView.frame.origin.x+subsubView.frame.size.width, right);
                bottom = MAX(subsubView.frame.origin.y+subsubView.frame.size.height, bottom);
            }
            CGRect newFrame = CGRectMake(left, top, right-left, bottom-top);
            if (!CGRectEqualToRect(newFrame, CGRectZero)) {
                newFrame = CGRectMake(newFrame.origin.x + subView.frame.origin.x,
                                      newFrame.origin.y + subView.frame.origin.y,
                                      newFrame.size.width,
                                      newFrame.size.height);
                rect = BMWMakeNormRectFromCGRect(newFrame, waterSize);
            }
        } else {
            rect = BMWMakeNormRectFromCGRect(subView.frame, waterSize);
            if (subView.tag == BMWWatermarkTagOutQRCode || subView.tag == BMWWatermarkTagOutMap) {
                // 二维码和地图条目外扩一点，防止去水印不干净问题
                rect = [rect scale:1.02];
            }
        }
        if (rect) {
            rect.tag = subView.tag;
            [realWatermarkRectList addObject:rect];
        }
        rect2 = BMWMakeNormRectFromCGRect(subView.frame, waterSize);
        if (rect2) {
            rect2.tag = subView.tag;
            [realWatermarkRectList2 addObject:rect2];
        }
        BMWMLog(@"BMWWatermarkItem parse case2, rect:%@, parseShawdow:%d, rect2:%@", rect, parseShawdow, rect2);
    }
    self.realWatermarkRectList = realWatermarkRectList;
    self.realWatermarkRectList2 = realWatermarkRectList2;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"{id:%lu, water:%@, x/y/h/w:%lf/%lf/%lf/%lf, refreshTime:%lf}", self.id, self.water, self.x, self.y, self.w, self.h, self.refreshTime];
}

+ (NSArray<BMWWatermarkInfoV2 *>*)createWatermarkInfoV2sFromItems:(NSArray<BMWWatermarkItem* >*)watermarks deviceOrientation:(BMWDeviceOrientation)deviceOrientation
{
    NSMutableArray<BMWWatermarkInfoV2 *>* watermarkInfos = [[NSMutableArray alloc] init];
    for (BMWWatermarkItem* watermark in watermarks) {
        UIView *view = [watermark.water xhm_findSubview:^BOOL(UIView * _Nonnull subview) {
            return !subview.hidden && [subview isKindOfClass:[BMWGLView class]];
        }];

        if (!view) {
            continue;
        }
        BMWGLView *glView = view;
        CGRect rect = [glView convertRect:glView.bounds toView:watermark.water];
        CGRect containerRect = watermark.water.bounds;
        if (containerRect.size.width == 0 || containerRect.size.height == 0) {
            continue;
        }

        CGRect watermarkRect = CGRectZero;
        watermarkRect.origin.x = rect.origin.x / containerRect.size.width;
        watermarkRect.origin.y = rect.origin.y / containerRect.size.height;
        watermarkRect.size.width = rect.size.width / containerRect.size.width;
        watermarkRect.size.height = rect.size.height / containerRect.size.height;

        BMWFramebuffer *framebuffer = glView.displayedFramebuffer;
        if (!framebuffer) {
            continue;
        }
        BMWWatermarkInfoV2 *watermarkInfo = [[BMWWatermarkInfoV2 alloc] init];
        watermarkInfo.rect = watermarkRect;
        watermarkInfo.framebuffer = framebuffer;
        if (deviceOrientation == BMWDeviceOrientationUnknown) {
            watermarkInfo.rotationMode = glView.inputRotation;
        } else if (deviceOrientation == BMWDeviceOrientationLeft) {
            watermarkInfo.rotationMode = kXHImageRotateLeft;
        } else if (deviceOrientation == BMWDeviceOrientationRight) {
            watermarkInfo.rotationMode = kXHImageRotateRight;
        } else if (deviceOrientation == BMWDeviceOrientationDown) {
            watermarkInfo.rotationMode = kXHImageRotate180;
        } else {
            watermarkInfo.rotationMode = kXHImageNoRotation;
        }
        [watermarkInfos addObject:watermarkInfo];
    }
    
    return watermarkInfos;
}

@end
