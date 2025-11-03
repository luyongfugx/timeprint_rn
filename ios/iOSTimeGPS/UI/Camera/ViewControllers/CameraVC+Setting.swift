//
//  CameraVC+Setting.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/29.
//

import Foundation
import UIKit
import GPCam

enum SettingType: Int {
    case photoQulity
    case autoSaveOriginPhoto
    case swichLanguage
    case officialWatermark
    case feedback
    case shareTimeprint
    case modifyTime
}

extension CameraVC {
    
    func clickSettingBtn(_ sender: UIButton) {
        // 照片质量，是否开启原图拍照，官方水印，语言切换
        //如果是appstoremode模式，删除缓存，切换语言和修改cover(1,6)
        let officialWMTitle = CameraConfig.canShowOfficialWatermark ? "k_hide_official_watermark": "k_show_official_watermark"
        var titleArray = CameraVC.isAppStoreMode ? ["language","cleanCache","cover1", "cover2","cover3","cover4","cover5","cover6",]:["i_photo_quality".localized(), "i_save_origin_photo".localized(), "i_swith_language".localized(), officialWMTitle.localized(), "k_feed_back".localized(), "k_share_timeprint".localized() ]
        if AppConfigManager.shared.config.close_recommend_tf != "1" {
            titleArray.append("k_modify_time".localized())
        }
        
        let menu = CameraVC.isAppStoreMode ? DropDownMenuView.pullDropDrownMenu(anchorView: sender, titleArray: titleArray, startTrianglePadding: 8):  DropDownMenuView.pullDropDrownMenu(anchorView: sender, titleArray: titleArray, startTrianglePadding: 8)
        menu.selectionAction = { [weak self] index , str in
            //如果是 isAppStoreMode
            if(CameraVC.isAppStoreMode){
                self?.chooseAppStoreAction(str)
            }
            else {
                let setType: SettingType = SettingType.init(rawValue: index) ?? .photoQulity
                self?.chooseSettingType(setType)
            }
     
        }
    }
    func chooseAppStoreAction(_ type: String ){
        if(type == "cleanCache"){
            WatermarkManager.shared.clearLocalWaterModel()
        }
        else if (type == "language"){
            GPApp.gotoSetting()
        }
        else {
            //修改图片，比如"cover1", "cover2","cover3","cover4","cover5","cover6"
            changeAppStoreImage(type)
        }
    }
    func chooseSettingType(_ type: SettingType) {
        switch type {
        case .photoQulity:
            let menu = DropDownMenuView.pullDropDrownMenu(anchorView: self.topView.settingButton, titleArray: ["\("i_standard".localized()), 4MB", "\("i_low".localized()), 100KB", "\("i_normal".localized()), 400KB", "\("i_hight".localized()), 1MB", "\("i_ultra".localized()), 4MB"], startTrianglePadding: 8, selectIndex: CameraConfig.photoQuolityType.rawValue)
            menu.selectionAction = { [weak self] index , str in
                // 设置相机拍照质量
                CameraConfig.photoQuolityType = BMWImageResolutionQuality.init(rawValue: index) ?? .current
                self?.camera?.setImageResolutionQuality(CameraConfig.photoQuolityType)
            }
        case .autoSaveOriginPhoto:
            CameraConfig.openOriginPhoto = !CameraConfig.openOriginPhoto
            if CameraConfig.openOriginPhoto {
                GPToast.text("k_auto_save_two".localized())
            } else {
                GPToast.text("k_auto_save_one".localized())
            }

        case .swichLanguage:
            // 切换语言
            GPApp.gotoSetting()
        case .officialWatermark:
            CameraConfig.canShowOfficialWatermark = !CameraConfig.canShowOfficialWatermark
            let showText = CameraConfig.canShowOfficialWatermark ? "k_has_show_officialWatermark" : "k_has_hide_official_watermark"
            GPToast.text(showText.localized())
            if !CameraConfig.canShowOfficialWatermark {
                // 加上埋点
                GPFirebaseManager.logEvent(event: "close_official_wm")
            }
            break
        case .feedback:
            FeedbackVC.gotoFeedback()
        case .shareTimeprint:
            // 分享App
            let shareText = "k_share_app".localized()
            GPShareManager.shareSystem(activityItems: [shareText])
        case .modifyTime:
            openAppStore()
        }
    }
    
    func openAppStore() {
        let appStoreURL = URL(string: "https://itunes.apple.com/app/id6753891513")!
        UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
    }
    
}
