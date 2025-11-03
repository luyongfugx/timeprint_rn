#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMWToneCurveData : NSObject
@property (readonly) int width;
@property (readonly) int height;
@property (readonly) uint8_t *textureData;
- (id)initWithACVData:(NSData *)data;
- (id)initWithName:(NSString*)curveFilename;
- (id)initWithACVURL:(NSURL*)curveFileURL;
- (GLint)getTexId;
@end

NS_ASSUME_NONNULL_END
