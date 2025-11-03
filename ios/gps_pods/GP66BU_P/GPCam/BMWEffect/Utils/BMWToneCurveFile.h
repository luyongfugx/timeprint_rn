#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMWToneCurveFile : NSObject

@property (nonatomic, readonly) NSArray *rgbCompositeCurvePoints;
@property (nonatomic, readonly) NSArray *redCurvePoints;
@property (nonatomic, readonly) NSArray *greenCurvePoints;
@property (nonatomic, readonly) NSArray *blueCurvePoints;

- (id)initWithXHToneCurveFileData:(NSData*)data;

unsigned short int16WithBytes(Byte* bytes);

@end

NS_ASSUME_NONNULL_END
