#import <Foundation/Foundation.h>
#import "BMWMediaBaseModel.h"
#import "BMWVideoAlgorithmResult.h"

NS_ASSUME_NONNULL_BEGIN

/////////////////通用类//////////////
@interface BMWBox : BMWMediaBaseModel
@property(assign) CGFloat left;
@property(assign) CGFloat top;
@property(assign) CGFloat right;
@property(assign) CGFloat bottom;
+ (BMWBox*)build:(CGRect)rect;
@end

@interface BMWDectectMetaModel : BMWMediaBaseModel
@property(assign) CGFloat score;
@property(assign) CGFloat angle;
@property(strong) BMWBox *rect;
@end


/////////////////车牌识别//////////////
@interface BMWVlprMetaModel : BMWDectectMetaModel
@property(strong) NSString *type;
@property(strong) NSString *formatCharacter;
@end

@interface BMWVlprAlgorithmModel : BMWMediaBaseModel
@property(assign) NSInteger modelId;
@property(strong) BMWVlprMetaModel *originInfo;
@property(strong) BMWVlprMetaModel *correctInfo;
@end


/////////////////人脸检测//////////////

@interface BMWFacesMetaModel : BMWMediaBaseModel
@property(strong) NSArray <BMWDectectMetaModel*>*rects;
@end

@interface BMWFaceDectectAlgorithmModel : BMWMediaBaseModel
@property(assign) NSInteger modelId;
@property(strong) BMWFacesMetaModel *originInfo;
@property(strong) BMWFacesMetaModel *correctInfo;

@end

/////////////////钢筋检测//////////////
@interface BMWSteelMetaModel : BMWMediaBaseModel
@property(strong) NSArray <BMWDectectMetaModel*>*rects;
@end

@interface BMWSteelDectectAlgorithmModel : BMWMediaBaseModel
@property(assign) NSInteger modelId;
@property(strong) BMWSteelMetaModel *originInfo;
@property(strong) BMWSteelMetaModel *correctInfo;

@end

NS_ASSUME_NONNULL_END
