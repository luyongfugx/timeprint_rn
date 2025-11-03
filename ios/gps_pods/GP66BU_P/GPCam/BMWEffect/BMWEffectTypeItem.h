#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMWEffectTypeItem : NSObject<NSCopying>

@property (nonatomic) long long id;

@property (nonatomic) NSString *catigory;

@property (nonatomic) long long type;

@property (nonatomic) NSString *name;

@property (nonatomic) NSString *path;

@property (nonatomic) NSString *key;

- (NSString*)identifer;
+ (BMWEffectTypeItem*)lutEffectItem;
+ (BMWEffectTypeItem*)brightnessEffectItem;

@end

NS_ASSUME_NONNULL_END
