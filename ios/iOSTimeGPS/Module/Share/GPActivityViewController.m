

#import "GPActivityViewController.h"

@interface GPActivityViewController ()

@property(nonatomic, assign) GPActivityType gpActivityType;

@end

@implementation GPActivityViewController

- (instancetype)initWithActivityItems:(NSArray *)activityItems applicationActivities:(nullable NSArray<__kindof UIActivity *> *)applicationActivities xhActivityType:(GPActivityType)gpActivityType {
    
    self = [super initWithActivityItems:activityItems applicationActivities:applicationActivities];
    
    if (self) {
        self.gpActivityType = gpActivityType;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (NSArray *)includedActivityTypes {
    switch (self.gpActivityType) {
        case GPActivityType_Whatsapp:
            return @[@"net.whatsapp.WhatsApp.ShareExtension"];
        case GPActivityType_WaBussiness:
            return @[@"net.whatsapp.WhatsAppSMB.ShareExtension"];
        case GPActivityType_Zalo:
            return @[@"vn.com.vng.zingalo.shareext"];
        case GPActivityType_Line:
            return @[@"jp.naver.line.Share"];
        case GPActivityType_KakaoTalk:
            return @[@"com.iwilab.KakaoTalk.Share"];
        case GPActivityType_Telegram:
            return @[@"ph.telegra.Telegraph.Share"];
        case GPActivityType_FBMessenger:
            return @[@"com.facebook.Messenger.ShareExtension"];
        case GPActivityType_Viber:
            return @[@"com.viber.app-share-extension"];
        default:
            return @[];
    }
}

/*
 wa business : scheme
 whatsapp
 whatsapp-smb


 whatsapp : scheme
 whatsapp
 whatsapp-consumer
 */

@end
