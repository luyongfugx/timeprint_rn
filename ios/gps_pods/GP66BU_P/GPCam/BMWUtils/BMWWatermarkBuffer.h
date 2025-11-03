#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BMWWatermarkBuffer : NSObject

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, assign) GLuint *buf;

@property (nonatomic, assign) CGSize size;

@property (nonatomic, assign) BOOL autoReset;
 
+ (BMWWatermarkBuffer*)watermarkBuffer:(GLbyte*)buffer size:(CGSize)size;

+ (BMWWatermarkBuffer*)watermarkImage:(UIImage*)image;

- (GLuint)genTexture;

- (GLuint)updateTexture:(GLuint)texId;

- (void)reset;

@end

NS_ASSUME_NONNULL_END
