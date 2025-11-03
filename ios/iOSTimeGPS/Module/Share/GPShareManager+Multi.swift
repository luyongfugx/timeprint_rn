//
//  GPShareManager+Multi.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/3.
//

import Foundation

extension GPShareManager {
    
    // MARK: 多图多视频分享
    
    static func shareMultiMedias(_ medias: MediaResult, type: XHPhotoShowShareType) {
        //上报多资源分享
        GPFirebaseManager.muti_share();
        
        let mediaItems = medias.items
        guard let firstItem = mediaItems.first else { return }
        
        let activityItems: [Any] = mediaItems.map { item in
            switch item {
            case .video(let url, _):
                return url
            case .image(let image, _):
                return image
            }
        }
        
        switch type {
            // 多资源分享
        case .whatsApp:
            customSystemShare(activityItems: activityItems, type: GPActivityType_Whatsapp)
            return
        case .waBusiness:
            customSystemShare(activityItems: activityItems, type: GPActivityType_WaBussiness)
            return
        case .zalo:
            customSystemShare(activityItems: activityItems, type: GPActivityType_Zalo)
            return
        case .kakaoTalk:
            customSystemShare(activityItems: activityItems, type: GPActivityType_KakaoTalk)
            return
        case .telegram:
            customSystemShare(activityItems: activityItems, type: GPActivityType_Telegram)
            return
        case .viber:
            customSystemShare(activityItems: activityItems, type: GPActivityType_Viber)
            return
            // 单资源分享
        default:
            switch firstItem {
            case .video(let url, let asset):
                GPShareManager.shareCustomType(activityItems: activityItems, shareType: type, isPhoto: false)
            case .image(let img, _):
                GPShareManager.shareCustomType(activityItems: activityItems, shareType: type, isPhoto: true)
            }
        }
    }
    
}
