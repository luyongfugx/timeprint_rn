#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

extern NSString* model2JosnString(id model);

@interface BMWMediaBaseModel : MTLModel<MTLJSONSerializing>

+ (NSValueTransformer *)listJSONTransfrmerWithItemClass:(Class)itemClass;

+ (NSDictionary*)getObjectData:(id)obj;

@end
