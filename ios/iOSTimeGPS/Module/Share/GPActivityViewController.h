

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    GPActivityType_Whatsapp,
    GPActivityType_WaBussiness,
    GPActivityType_Line,
    GPActivityType_Zalo,
    GPActivityType_KakaoTalk,
    GPActivityType_Telegram,
    GPActivityType_FBMessenger,
    GPActivityType_Viber
} GPActivityType;

@interface GPActivityViewController : UIActivityViewController

- (instancetype)initWithActivityItems:(NSArray *)activityItems applicationActivities:(nullable NSArray<__kindof UIActivity *> *)applicationActivities xhActivityType:(GPActivityType)xhActivityType;

@end

NS_ASSUME_NONNULL_END
