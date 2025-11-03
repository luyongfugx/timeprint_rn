#import <Foundation/Foundation.h>
#import "BMWCodeDataModel.h"
@class BMWWatermarkResultModel;
@class BMWOCRMetaData;
NS_ASSUME_NONNULL_BEGIN

__attribute__((visibility("hidden"))) @interface BMWAnitCodeErrorModel : NSObject
// 若为true，标示可以中断后续流程
@property (nonatomic) BOOL shouldAbort;
@property (nonatomic) NSError *_Nullable bwmError;
@property (nonatomic) NSError *_Nullable codeError;
@end

__attribute__((visibility("hidden")))  @interface BMWAnitCodeRequestModel : NSObject
@property (nonatomic) UIImage* image;
// 期望后续流程不做或是做不到兜底可设置为true
@property (nonatomic) BOOL abortWhenError;
@property (nonatomic) CGFloat similarityThreshold;
@property (nonatomic, copy) BOOL (^timestampExtraCheck)(NSUInteger timestampFormat, long long timestamp);
@property (nonatomic, copy) BOOL (^locationExtraCheck)(float longitude, float latitude);
@end

__attribute__((visibility("hidden"))) @interface BMWAnitCodeReslutModel : NSObject
@property (nonatomic) BMWWatermarkResultModel *wmResultModel;
@property (nonatomic) BMWOCRMetaData *ocrMetaData;
@property (nonatomic) BMWCodeDataModel *codeDataModel;
@end

/*
 [self.anitCodeManger probeAntiCodeWithRequestBulder:^(BMWAnitCodeRequestModel * _Nonnull model) {
     model.image = self.imageView.image;
     model.similarityThreshold = 0.2;
     model.timestampExtraCheck = ^BOOL(NSUInteger timestampFormat, long long timestamp) {
         double now = [[NSDate date] timeIntervalSince1970];
         return timestamp < (long long)now;
     };
 } completeBlock:^(BMWAnitCodeReslutModel * _Nullable codeReslutModel, BMWAnitCodeErrorModel * _Nullable errorModel) {
     if (!errorModel) {
         NSLog(@"防伪码检测整个流程成功");
     } else if(errorModel.shouldAbort) {
        NSLog(@"终止后续流程");
     }  else  {
        NSLog(@"进行后续兜底操作");
     }
 }]
 */
// TODO 压测概率0.002的概率出现检测失败
/*
     if (!errorModel) {
        // 防伪码检测整个流程成功
     } else if(errorModel.shouldAbort) {
        // 终止后续流程
     }  else  {
        // 进行后续兜底操作
     }
 */
__attribute__((visibility("hidden"))) @interface BMWAnitCodeManger : NSObject
- (void)probeAntiCodeWithRequestBulder:(void (^)(BMWAnitCodeRequestModel *model))builder completeBlock:(void (^)(BMWAnitCodeReslutModel* _Nullable reslutModel, BMWAnitCodeErrorModel *_Nullable errorModel))completeBlock;

+ (NSString*)internalErrorMessage:(BMWAnitCodeErrorModel *_Nullable)errorModel reslutModel:(BMWAnitCodeReslutModel* _Nullable)reslutModel;

+ (CGRect)expandRectFromAnitCodeRect:(CGRect)codeRect;

@end

NS_ASSUME_NONNULL_END
