//
//  CameraVC+GuideNewApp.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/2/19.
//
import StoreKit
import Foundation

extension CameraVC {
    
    func checkGoToNewApp() {
        
        if let guideToNewApp = AppConfigManager.shared.config.guideToNewApp, let guideToNewAppID = AppConfigManager.shared.config.guideToNewAppID, guideToNewApp == "1", !guideToNewAppID.isEmpty {
            
            // 替换为实际的 App ID
            let appStoreURLString = "https://apps.apple.com/app/id\(guideToNewAppID)"
            
            if let appStoreURL = URL(string: appStoreURLString) {
                if UIApplication.shared.canOpenURL(appStoreURL) {
                    
                    UIAlertController.showAlert(title: "k_guide_new_app_title".localized(), message: "k_guide_new_app_content".localized(), buttonTitles: ["k_cancle".localized(), "k_download".localized()], viewController: GPApp.topViewController, styles: [.destructive, .default]) { index, controller in

                        if index == 0 {
                            // 取消
                        } else if index == 1 {
                            // 下载
                            // 打开 App Store 链接
                            UIApplication.shared.open(appStoreURL, options: [:], completionHandler: nil)
                        }
                    }
                    
                } else {
                    print("Cannot open App Store URL.")
                }
            }
            
            
        }
        
    }
    
}
