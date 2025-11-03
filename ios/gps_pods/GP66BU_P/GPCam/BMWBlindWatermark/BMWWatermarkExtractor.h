#import <Foundation/Foundation.h>
#import "BMWBaseDrawer.h"
#import "BMWBlindWatermarkModel.h"

NS_ASSUME_NONNULL_BEGIN

__attribute__((visibility("hidden"))) @interface BMWWatermarkResultModel : NSObject

@property (nonatomic, assign) BMWBlindWatermarkType type;
@property (nonatomic, assign) CGFloat allSimilarity;
@property (nonatomic, assign) CGFloat topSimilarity;
@property (nonatomic, assign) CGFloat bottomSimilarity;
@property (nonatomic, strong) UIImage* watermarkImage;
@end

__attribute__((visibility("hidden"))) @interface BMWWatermarkExtractor : NSObject

- (instancetype)init;

- (instancetype)init:(BMWImageContext*)context;

- (void)extract:(UIImage*)image scaledSize:(CGSize)scaledSize wmLen:(int)wmLen completeBlock:(void (^)(NSString *_Nullable wm, NSError *_Nullable error))block;

- (void)extract:(UIImage*)image completeBlock:(void (^)(BMWWatermarkResultModel* model, NSError *_Nullable error))block;

@end

NS_ASSUME_NONNULL_END


