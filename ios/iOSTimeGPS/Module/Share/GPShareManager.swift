//
//  GPShareManager.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/26.
//

import Foundation
import UIKit
import MessageUI

class GPShareManager: NSObject {
    
    static let shared = GPShareManager()
    
    @GPPersistance(key: "com.gpscamera.share.photoShowShareTypeCacheKey", defaultValue: "")
    static var photoShowShareTypeCacheKey: String
    
    static func getSupportShareTypes() -> [XHPhotoShowShareType] {
        let types: [XHPhotoShowShareType] = [.whatsApp, .line, .zalo, .telegram, .fbMessenger, .waBusiness, .kakaoTalk, .iMessage, .email, .viber, .system]
        let supportTypes = types.compactMap { $0.supportInfo().isSupport ? $0 : nil }
        return supportTypes
    }
    
    static func getDefaultShareType() -> XHPhotoShowShareType {
        let types: [XHPhotoShowShareType] = [.whatsApp, .line, .zalo, .telegram, .fbMessenger, .waBusiness, .kakaoTalk, .viber]
        let supportTypes = types.compactMap { $0.supportInfo().isSupport ? $0 : nil }
        return supportTypes.first ?? .system
    }
    
    // 系统分享，参数[UIImage, String, VideoUrl]
    static func shareSystem(activityItems: [Any]) {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        GPApp.topViewController?.present(vc, animated: true)
        vc.completionWithItemsHandler = { _, _, _, _ in
        }
    }
    
    static func shareCustomType(activityItems: [Any], shareType: XHPhotoShowShareType, isPhoto: Bool = true) {
        
        //上报单资源分享
        GPFirebaseManager.single_share();
        if shareType == .system {
            
        } else {
            
        }
        switch shareType {
        case .zip:
            break
        case .system:
            shareSystem(activityItems: activityItems)
        case .fbMessenger:
            customSystemShare(activityItems: activityItems, type: GPActivityType_FBMessenger)
        case .kakaoTalk:
            customSystemShare(activityItems: activityItems, type: GPActivityType_KakaoTalk)
        case .line:
            customSystemShare(activityItems: activityItems, type: GPActivityType_Line)
        case .telegram:
            customSystemShare(activityItems: activityItems, type: GPActivityType_Telegram)
        case .viber:
            customSystemShare(activityItems: activityItems, type: GPActivityType_Viber)
        case .waBusiness:
            customSystemShare(activityItems: activityItems, type: GPActivityType_WaBussiness)
        case .whatsApp:
            customSystemShare(activityItems: activityItems, type: GPActivityType_Whatsapp)
        case .zalo:
            customSystemShare(activityItems: activityItems, type: GPActivityType_Zalo)
        case .iMessage:
            if isPhoto, let img = activityItems.first as? UIImage {
                GPShareManager.shared.shareImageToIMessage(img)
            } else if !isPhoto, let url = activityItems.first as? URL {
                GPShareManager.shared.shareVideoToImessage(url)
            }
        case .email:
            if isPhoto, let img = activityItems.first as? UIImage {
                GPShareManager.shared.shareImageViaEmail(image: img)
            } else if !isPhoto, let url = activityItems.first as? URL {
                GPShareManager.shared.shareVideoViaEmail(videoURL: url)
            }
        }
       
    }
    
    func shareImageViaEmail(image: UIImage) {
        // 检查设备是否可以发送邮件
        guard MFMailComposeViewController.canSendMail() else {
            print("此设备无法发送邮件")
            return
        }
        
        // 创建邮件视图控制器
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        
        // 设置邮件主题、收件人和正文
//        mailComposer.setSubject("分享图片")
//        mailComposer.setToRecipients(["example@example.com"]) // 可选的收件人
//        mailComposer.setMessageBody("这是通过邮件分享的图片。", isHTML: false)
        
        // 将 UIImage 转换为 JPEG 数据并添加附件
        if let imageData = image.jpegData(compressionQuality: 1.0) {
            mailComposer.addAttachmentData(imageData, mimeType: "image/jpeg", fileName: "image.jpg")
        }
        
        // 显示邮件视图控制器
        GPApp.topViewController?.present(mailComposer, animated: true, completion: nil)
    }
    
    func shareVideoViaEmail(videoURL: URL) {
        // 检查设备是否可以发送邮件
        guard MFMailComposeViewController.canSendMail() else {
            print("此设备无法发送邮件")
            return
        }
        
        // 创建邮件视图控制器
        let mailComposer = MFMailComposeViewController()
        mailComposer.mailComposeDelegate = self
        
        //            // 设置邮件主题、收件人和正文
        //            mailComposer.setSubject("分享视频")
        //            mailComposer.setToRecipients(["example@example.com"]) // 可选的收件人
        //            mailComposer.setMessageBody("这是通过邮件分享的视频。", isHTML: false)
        
        // 读取视频数据并添加附件
        do {
            let videoData = try Data(contentsOf: videoURL)
            mailComposer.addAttachmentData(videoData, mimeType: "video/mp4", fileName: "video.mp4")
        } catch {
            print("无法读取视频数据: \(error)")
            return
        }
        
        // 显示邮件视图控制器
        GPApp.topViewController?.present(mailComposer, animated: true, completion: nil)
    }
        
    func shareVideoToImessage(_ videoUrl: URL) {
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self
        messageComposeVC.addAttachmentURL(videoUrl, withAlternateFilename: nil)
        if MFMessageComposeViewController.canSendText() {
            GPApp.topViewController?.present(messageComposeVC, animated: true, completion: nil)
        }
    }
    
    func shareImageToIMessage(_ image: UIImage) {
        let messageComposeVC = MFMessageComposeViewController()
        messageComposeVC.messageComposeDelegate = self
        if let imageData = image.pngData() {
            let filePath = "\(NSTemporaryDirectory())/shareImageTemp2.png"
            if FileManager.default.fileExists(atPath: filePath) == true {
                GPFileManager.removeFile(at: filePath)
            }
            let isSuccess = FileManager.default.createFile(atPath: filePath, contents: imageData, attributes: nil)
            if isSuccess {
                messageComposeVC.addAttachmentURL(URL(fileURLWithPath: filePath), withAlternateFilename: "image.png")
            }
        }
        
        if MFMessageComposeViewController.canSendText() {
            GPApp.topViewController?.present(messageComposeVC, animated: true, completion: nil)
        }
    }
    
    // 自定义UIActivityViewController进行分享
    static func customSystemShare(activityItems: [Any], type: GPActivityType) {

        let vc = GPActivityViewController(activityItems: activityItems, applicationActivities: nil, xhActivityType: type)
        GPApp.topViewController?.present(vc, animated: true)
        vc.completionWithItemsHandler = { activityType, _, _, _ in
//            xLog(.error, module: .share(process: .uninitialized), message: "custom分享activityType：\(activityType)")
//            XHShareManager.shareTypeReport(activityType: activityType?.rawValue, shareFrom: "custom")
        }
    }
}

// MARK: - 短信分享代理

extension GPShareManager: MFMessageComposeViewControllerDelegate {
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        controller.dismiss(animated: true)
    }
}

// MARK: - email分享代理

extension GPShareManager: MFMailComposeViewControllerDelegate {
    // 实现邮件发送控制器的代理方法
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        // 关闭邮件视图控制器
        controller.dismiss(animated: true, completion: nil)
    }
}


