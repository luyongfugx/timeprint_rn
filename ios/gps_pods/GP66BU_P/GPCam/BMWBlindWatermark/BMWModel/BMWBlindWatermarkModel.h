#import <Foundation/Foundation.h>
#import "BMWWatermarkItem.h"
#import "BMWCodeDataModel.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BMWBlindWatermarkType) {
    BMWBlindWatermarkTypeImage = 0,
    BMWBlindWatermarkTypeCharacter= 1
};

__attribute__((visibility("hidden"))) @interface BMWBlindWatermarkModel : NSObject

@property (nonatomic, assign) BMWBlindWatermarkType type;

@property (nonatomic) int bwmId;

@property (nonatomic, assign) CGSize watermarkSliceSize;

@property (nonatomic, assign) CGRect watermarkRect;

@property (nonatomic, strong) UIImage* watermarkImage;

@property (nonatomic, assign) NSString* character;

- (CGRect)watermarkRectByRatio:(float)ratio;
- (CGRect)watermarkFullRectByRatio:(float)ratio;
+ (BMWBlindWatermarkModel*)defaultModel;

@end

NS_ASSUME_NONNULL_END
