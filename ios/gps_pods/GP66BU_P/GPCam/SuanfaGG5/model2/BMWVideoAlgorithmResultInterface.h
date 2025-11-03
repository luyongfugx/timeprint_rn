#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol BMWVideoAlgorithmResultInterface <NSObject>

@required

+ (NSString*)buildReportModel:(NSArray*)originInfo correctInfo:(NSArray*)correctInfo;

- (BOOL)isValid;

/* 定义Algorithm输入源，目前包含如下
 * CameraSource
 * ImageSource
 * SimpleVideoEditor    
 * ImageSourceForOCR
 */
@property(strong) NSString* source;

@property(assign) CGFloat sourceRatio;

@property(assign) CGFloat timecost;

@property(assign) CFTimeInterval refreshInterval;

@end

NS_ASSUME_NONNULL_END
