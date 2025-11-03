#import <Foundation/Foundation.h>
#import "BMWWatermarkItem.h"
#import "BMWCodeDataModel.h"

NS_ASSUME_NONNULL_BEGIN

static const float SCREEN_WIDTH = 360;
static const float PADDING = (1);
static const float CODE_FONT = (6);
static const float CODE_RIGHT_MARGIN = (1);
static const float CODE_RIGHT_MARGIN_ID_10011 = (25);
static const float CODE_WIDTH = (51 + 2*PADDING);
static const float CODE_LEFT_MARGIN = (0);
static const float CODE_TITLE_WIDTH = (11);
static const float ALL_CODE_WIDTH = (CODE_TITLE_WIDTH + CODE_LEFT_MARGIN + CODE_WIDTH);
static const float CODE_HEIGHT = (6 + PADDING);
static const float CODE_BOTTOM_MARGIN = (2);

__attribute__((visibility("hidden"))) @interface BMWCodeHelper : NSObject

@property (nonatomic, readonly) NSDictionary* allRectMapping;
@property (nonatomic, readonly) NSDictionary* codeRectMapping;
@property (nonatomic, readonly) NSUInteger digitCount;

+ (BMWCodeHelper*)sharedInstance;

- (BOOL)check:(BMWCodeDataModel*)model;

- (void)genCode:(BMWCodeDataModel*)model;

- (void)deCode:(BMWCodeDataModel*)model;

- (CGRect)codeRect:(CGFloat)ratio isCode:(BOOL)isCode;

- (CGRect)codeRect:(CGFloat)ratio/*w:h**/ style:(NSUInteger)style isCode:(BOOL)isCode;

- (CGRect)officalWatermarkRect:(CGFloat)ratio;

- (CGRect)antiCodeDisplayRect:(CGFloat)ratio;

- (BMWWatermarkItem *)codeWaterMark:(CGSize)imageSize model:(BMWCodeDataModel*)model;

// for TEST
- (NSString*)genCodeInternal;

- (NSString*)randomCode;

- (NSArray<NSString*>*)usedCode;

@end

NS_ASSUME_NONNULL_END
