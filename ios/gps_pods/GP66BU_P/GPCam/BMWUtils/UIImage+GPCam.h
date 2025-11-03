#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImage (GPCam)

- (NSData*)xhm_jpegData:(CGFloat)quality;

- (UIImage*)xhm_resizeImage:(CGSize)size;

- (CGFloat)xhm_similarityCheck:(UIImage*)otherImage;

- (UIImage *)cropImageWithRect:(CGRect)normRect;

@end

NS_ASSUME_NONNULL_END
