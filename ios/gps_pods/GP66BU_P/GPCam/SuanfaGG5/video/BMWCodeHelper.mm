#import "BMWCodeHelper.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import "code_generator.h"
#import "BMWSliceData.h"
#import "BMWALifeCycleHelper.h"

@interface BMWCodeHelper()
{
    std::shared_ptr<CodeGenerator> _codeGenerator;
}

@property (nonatomic) CLLocation *location;
@property (nonatomic) NSMutableArray<NSString*>* usedCodes;
@property (nonatomic) NSUInteger digitCount;
@property (nonatomic) NSUInteger baseCount;

@end

@implementation BMWCodeHelper

+ (BMWCodeHelper*)sharedInstance
{
    static BMWCodeHelper* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!instance) {
            instance = [[BMWCodeHelper alloc] init];
        }
    });
    return instance;
}

- (id)init
{
    if(self = [super init]) {
        _baseCount = 24;
        _digitCount = 14;
        _codeGenerator.reset(new CodeGenerator(_baseCount, _digitCount));
        _usedCodes = [[NSMutableArray alloc] init];
    }
    return self;
}

- (BMWWatermarkItem *)codeWaterMark:(CGSize)imageSize model:(BMWCodeDataModel*)model
{
    if(model == nil || CGSizeEqualToSize(imageSize, CGSizeZero)) return nil;
    CGFloat ratio = imageSize.width / imageSize.height;
    if (model.code.length == 0) {
        [self genCode:model];
    }
    NSString *code = model.code;
    BMWWatermarkItem *item = nil;
    if (code.length > 0) {
//        item = [[BMWWatermarkItem alloc] init];
//        BMWCodeView *view = [[BMWCodeView alloc] initWithCode:code];
//        CGRect rect = [self codeRect:ratio style:model.officalWatermarkStyle isCode:NO];
//        item.water = view;
//        item.x = rect.origin.x;
//        item.y = rect.origin.y;
//        item.w = rect.size.width;
//        item.h = rect.size.height;
//        item.scale = ceilf(imageSize.width * item.w / view.bounds.size.width);
//        item.highResolution = YES;
//        
//        NSMutableArray<BMWRect*>* realWatermarkRectList2 = [[NSMutableArray alloc] init];
//        BMWRect *xhRect = BMWMakeRectFromCGRect(CGRectMake(item.x, item.y, item.w, item.h));
//        xhRect.tag = BMWWatermarkTagAntiCode;
//        [realWatermarkRectList2 addObject:xhRect];
//        item.realWatermarkRectList2 = realWatermarkRectList2;
    }
    return item;
}

- (NSString*)genCodeInternal
{
    double timestampS = [[NSDate date] timeIntervalSince1970];
    NSString *timestampStr = [[NSUserDefaults standardUserDefaults] stringForKey:@"timestamp_key"];
    if (timestampStr.length > 0) {
        NSDateFormatter *dateFormater = [[NSDateFormatter alloc] init];
        [dateFormater setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
        dateFormater.timeZone = [[NSTimeZone alloc] initWithName:@"Asia/Shanghai"];
        dateFormater.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        timestampS = [[dateFormater dateFromString:timestampStr] timeIntervalSince1970];
        [[NSUserDefaults standardUserDefaults] setValue:@"" forKey:@"timestamp_key"];
    }
    double x = self.location.coordinate.longitude;
    double y = self.location.coordinate.latitude;
    string code_ = _codeGenerator->genCode((int64_t)timestampS, x, y, -1, true);
    NSString *code = [NSString stringWithCString:code_.c_str() encoding:NSASCIIStringEncoding];
    [self.usedCodes addObject:code];
    return code;
}

- (BOOL)check:(BMWCodeDataModel*)model
{
    bool support = NO;
    if (_codeGenerator == nullptr) {
        NSAssert(NO, @"genCode CodeGenerator == NULL");
    }
    support = _codeGenerator->check(model.version, model.timeStamp, model.longitude, model.latitude);
    return support;
}

- (void)genCode:(BMWCodeDataModel*)model
{
    NSString *code = nil;
    if (_codeGenerator == nullptr) {
        NSAssert(NO, @"genCode CodeGenerator == NULL");
    }
    // 优先使用雪花ID
    if(model.snowFlakeId.length > 0) {
        string code_ = _codeGenerator->genCode(model.snowFlakeId.UTF8String, false);
        model.code = [NSString stringWithCString:code_.c_str() encoding:NSASCIIStringEncoding];
        return;
    }
    // 再使用其他编码方式
    if (![self check:model]) {
        model.code = nil;
        return;
    }
    if(model.version == BMWAntiCodeVersionTimeAndLocationType || model.version == BMWAntiCodeVersionTimeAndLocationType2) {
        uint64_t timestamp = (uint64_t)model.timeStamp;
        uint64_t timestampFormat = model.timestampFormat;
        uint64_t locationType = (uint64_t)model.locationType;
        string code_ = _codeGenerator->genCode(model.version, timestamp, timestampFormat, locationType, model.bwmId, false);
        code = [NSString stringWithCString:code_.c_str() encoding:NSASCIIStringEncoding];
    } else if (model.version == BMWAntiCodeVersionTimeAndXY || model.version == BMWAntiCodeVersionTimeAndXY2) {
        uint64_t timestampS = (uint64_t)model.timeStamp;
        double x = model.longitude;
        double y = model.latitude;
        string code_ = _codeGenerator->genCode(model.version, timestampS, x, y, model.bwmId, false);
        code = [NSString stringWithCString:code_.c_str() encoding:NSASCIIStringEncoding];
        [self.usedCodes addObject:code];
    }else {
        NSAssert(NO, @"genCode invalid Version");
    }
    model.code  = code;
}

- (void)deCode:(BMWCodeDataModel*)model
{
    if (model.code.length == 0 || model.code.length != self.digitCount) {
        model.valid = NO;
        return;
    }
    string code_(model.code.UTF8String);
    CodeData codeData = _codeGenerator->parseCode(code_, false);
    model.valid = codeData.valid;
    model.version = (BMWAntiCodeVersion)codeData.version;
    model.timestampFormat = (NSUInteger)codeData.timestampFormat;
    model.timeStamp = codeData.timestamp;
    model.longitude = codeData.longitude;
    model.latitude = codeData.latitude;
    model.locationType = codeData.locationType;
    model.bwmId = (int)codeData.reserved;
    // 修改location type方便业务用location type做统一判断
    if(model.version == BMWAntiCodeVersionTimeAndXY || model.version == BMWAntiCodeVersionTimeAndXY2) {
        model.locationType = 4;
    }
}

- (CGRect)codeRect:(CGFloat)ratio isCode:(BOOL)isCode
{
    return [self codeRect:ratio style:0 isCode:isCode];
}

- (CGRect)officalWatermarkRect:(CGFloat)ratio
{
    CGRect codeRect = [self codeRect:ratio isCode:NO];
    CGFloat size = codeRect.size.width;
    CGFloat x = codeRect.origin.x;
    CGFloat y = codeRect.origin.y - size;
    return CGRectMake(x, y, size, size + codeRect.size.height);
}


- (CGRect)antiCodeDisplayRect:(CGFloat)ratio
{
    CGRect codeRect = [self codeRect:ratio isCode:NO];
    CGFloat size = codeRect.size.width / 2.0f;
    CGFloat x = codeRect.origin.x;
    CGFloat y = codeRect.origin.y - size;
    return CGRectMake(x, y, codeRect.size.width, size + codeRect.size.height);
}

- (float)rectRatioByRatio:(float)ratio/*w:h**/
{
    float r = ratio;
    if (abs(ratio - 3 / 4.0) < 1e-2) {
        r =  3 / 4.0;
    } else if (abs(ratio - 9 / 16.0) < 1e-2) {
        r = 9 / 16.0;
    } else if (abs(ratio - 1.0) < 1e-2) {
        r = 1.0;
    } else if (abs(ratio - 4.0 / 3.0) < 1e-2) {
        r = 4.0 / 3.0;
    } else if (abs(ratio - 16 / 9.0) < 1e-2) {
        r = 16 / 9.0;
    }
   return r;
}

- (CGRect)codeRect:(CGFloat)ratio/*w:h**/ style:(NSUInteger)style isCode:(BOOL)isCode
{
    ratio = [self rectRatioByRatio:ratio];
    
    CGFloat width = SCREEN_WIDTH;
    CGFloat height = width / ratio;
    if (ratio > 1.0) {
        height = SCREEN_WIDTH;
        width = height * ratio;
    }
    CGFloat R = CODE_RIGHT_MARGIN;
    if(style == 10011) {
        R =  BMWALifeCycleHelper.sharedInstance.screenSize.width <= 375 ?
        (CODE_RIGHT_MARGIN_ID_10011 + 1) : (CODE_RIGHT_MARGIN_ID_10011);
    }
    CGFloat W = isCode ? CODE_WIDTH : ALL_CODE_WIDTH;
    CGFloat offset = (R + W);
    CGFloat x = (width - offset) / width;
    CGFloat y = (height - CODE_HEIGHT - CODE_BOTTOM_MARGIN) / height;
    CGFloat w = W / width;
    CGFloat h = CODE_HEIGHT / height;
    CGFloat topOffset = isCode ? 0.1 : 0;
    CGFloat bottomOffset = isCode ? 0.1 : 0;
    CGFloat leftOffset = isCode ? 0.01 : 0;
    CGFloat rightOffset = isCode ? 0.01 : 0;
    CGRect rect = CGRectMake(x+w*leftOffset,
                             y+h*topOffset,
                             w-w*(leftOffset+rightOffset),
                             h-h*(topOffset+bottomOffset));
    return rect;
}

#pragma mark - TEST

- (NSString*)randomCode
{
    NSString *code = [NSString stringWithFormat:@"%@", [self _randomCode]];
    [self.usedCodes addObject:code];
    return code;
}

- (NSArray<NSString*>*)usedCode
{
    return self.usedCodes;
}

- (NSString*)_randomCode
{
    //    A B C D E F G
    //    H K L M N P R
    //    S T U W X Y Z
    //    1 2 3 4 6 7 9
    static NSArray<NSString*> *supportedLabls = @[
        @"A", @"B", @"C", @"D", @"E",
        @"H", @"K", @"L", @"M", @"N", @"P", @"R",
        @"T", @"U", @"W", @"X", @"Y",
        @"1", @"2", @"3", @"4", @"6", @"7", @"9"];
    NSUInteger len = supportedLabls.count;
    NSMutableString *text = [[NSMutableString alloc] init];
    for (int i = 0; i < self.digitCount; i++) {
        int index = arc4random() % len;
        [text appendString:supportedLabls[index]];
    }
    return text;
}

+ (void)load
{
    Class c1;
    IMP origIMP;
    Method origMethod;
    Method swizzledMethod;
    
// -[XCamera.BMWLocationManager locationManager:didUpdateLocations:]
    c1 = objc_getClass("XCamera.BMWLocationManager");
    origMethod = class_getInstanceMethod(c1, NSSelectorFromString(@"locationManager:didUpdateLocations:"));
    class_addMethod(c1, NSSelectorFromString(@"hook_locationManager:didUpdateLocations:"),method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    swizzledMethod = class_getInstanceMethod([self class], NSSelectorFromString(@"hook_locationManager:didUpdateLocations:"));
    origIMP = method_getImplementation(origMethod);
    method_exchangeImplementations(origMethod, swizzledMethod);
}

- (void)hook_locationManager:(CLLocationManager *)manager
     didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    BMWCodeHelper.sharedInstance.location = locations.firstObject;
    [self hook_locationManager:manager didUpdateLocations:locations];
}

@end
