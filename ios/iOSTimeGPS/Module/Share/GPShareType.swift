//
//  GPShareType.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/2.
//

import Foundation
import MessageUI


// rawValue 作为cachekey, 影响photoshow.bottomView的UI
enum XHPhotoShowShareType: String, GPCodable {
    case whatsApp, waBusiness, telegram, email, iMessage, system, fbMessenger, line, zalo, kakaoTalk, viber, zip
    
    var info: (title: String, imageName: String) {
        switch self {
        case .zip:
            return ("ZIP", "icon_zip")
        case .whatsApp:
            return ("WhatsApp", "icon_share_whatsapp")
        case .waBusiness:
            return ("WA Business", "icon_share_wabusiness")
        case .telegram:
            return ("Telegram", "icon_share_telegram")
        case .email:
            return ("i_email".localized(), "icon_share_email")
        case .iMessage:
            return ("iMessage".localized(), "icon_share_message")
        case .fbMessenger:
            return ("Messenger", "icon_share_messenger")
        case .line:
            return ("Line", "social_line_fill")
        case .zalo:
            return ("Zalo", "social_zalo_fill")
        case .kakaoTalk:
            return ("KakaoTalk", "social_kakao_fill")
        case .system:
            return ("i_share_more".localized(), "icon_share_more")
        case .viber:
            return ("Viver", "viber_icon")
        }
    }
    
    var reportShareWay: String {
        switch self {
        case .waBusiness:
            return "wa business"
        case .kakaoTalk:
            return "kakao"
        default:
            return rawValue
        }
    }
    
    var needAttachedText: Bool {
        switch self {
        default:
            return false
        }
    }

    func getUrlScheme() -> String {
        switch self {
        case .whatsApp:
            return "whatsapp-consumer://"
        case .waBusiness:
            return "whatsapp-smb://"
        case .telegram:
            return "tg://"
        case .email:
            return "mailto:"
        case .fbMessenger:
            return "fb-messenger://"
        case .kakaoTalk:
            return "kakaotalk://"
        case .line:
            return "line://"
        case .zalo:
            return "zalo://"
        case .system, .iMessage, .zip:
            return ""
        case .viber:
            return "viber://"
        }
    }
    
    func supportInfo() -> (isSupport: Bool, notSupportToast: String) {
        let appNotInstall = "i_not_installed_toast".localized()
        switch self {
        case .iMessage:
            let isSupport = MFMessageComposeViewController.canSendText()
            return (isSupport, appNotInstall)
        case .email:
            return (MFMailComposeViewController.canSendMail(), appNotInstall)
        case .system:
            return (true, "")
        default:
            let scheme = getUrlScheme()
            if let url = URL(string: scheme) {
                return (UIApplication.shared.canOpenURL(url), appNotInstall)
            } else {
                return (false, appNotInstall)
            }
        }
    }
    
    var canMultiShare: Bool {
        switch self {
        case .whatsApp, .waBusiness, .zalo, .kakaoTalk, .telegram:
            return true
        default:
            return false
        }
    }
}
