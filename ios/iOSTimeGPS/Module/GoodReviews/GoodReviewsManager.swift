//
//  GoodReviewsManager.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/12/11.
//  五星好评机制

import Foundation
import StoreKit

class GoodReviewsManager {
    
    static let shared = GoodReviewsManager()
    
    // 是否已经五星好评
    @GPPersistance(key: "com.gpscamera.key.goodreview.hasFiveStar", defaultValue: false)
    static var hasFiveStar: Bool
    
    // 是否展示过轻五星好评
    @GPPersistance(key: "com.gpscamera.key.goodreview.hasShowWeakFiveStar", defaultValue: false)
    static var hasShowWeakFiveStar: Bool
    
    // 开始五星好评时间，必须停留在app以外超过15秒才算去好评了
    @GPPersistance(key: "com.gpscamera.key.goodreview.startFiveStarTime", defaultValue: 0)
    static var startFiveStarTime: Int
    
    static let timeArr: [Int] =  [33, 133, 233, 533, 733, 1000, 1200, 1800, 3000, 4000, 6000]
    // 五星好评检测
    func fiveStartCheck() {

        // 中国模式直接取消
        if GPCheetManager.isCheetMode {
            return
        }
                
        if AppConfigManager.shared.config.close_new_five_star == "1" {
            // 如果关闭了，新好评机制，那么使用老的好评机制
            if GoodReviewsManager.timeArr.contains(CameraConfig.takephotoTime2) {
                DispatchQueue.main.async {
                    GoodReviewsManager.shared.gotoScoreInApp()
                }
            }
            return
        }
        
        // 拍照第33、133、233次时，若已经填写过评论，那么最后弹出评星即可（尽可能多，不要遗漏）
        if GoodReviewsManager.timeArr.contains(CameraConfig.takephotoTime2) {
            DispatchQueue.main.async {
                GoodReviewsManager.shared.gotoScoreInApp()
            }
            return
        }
        
        // 新老用户，拍照4次以后，弹出好评引导弹窗，有两个选项，“五星好评”或“我要吐槽”，点击五星好评，弹下面的窗口，点击“我要吐槽”，跳转到反馈页面。
        if CameraConfig.takephotoTime2 == 4 {
            GoodReviewsManager.shared.showWeakFiveStar()
        }
        
    }
    
    // 展示轻度好评提醒
    private func showWeakFiveStar() {
        guard let topViewController = GPApp.topViewController, let topView = topViewController.view else { return }
        GoodReviewsManager.hasShowWeakFiveStar = true
        let guideVC = GoodReviewAlert()
        guideVC.delegate = self
        topViewController.addChild(guideVC)
        topView.addSubview(guideVC.view)
    }
    
//    // 展示重度好评提醒
//    func forceFiveStart() {
//        UIAlertController.showAlert(title: "k_system_alert".localized(), message: "k_force_five_start_des".localized(), buttonTitles: ["k_five_star".localized(), "k_finish_takephoto".localized()], viewController: GPApp.topViewController, styles: [.default, .destructive]) { index, controller in
//            
//            if index == 0 {
//                // 点击 好评
//                GoodReviewsManager.shared.gotoWriteReview()
//            } else if index == 1 {
//                GoodReviewsManager.finishTakePhoto = true
//            }
//        }
//    }
    
    // 跳转App Store 写评论
    private func gotoWriteReview() {
        // 开始五星好评时间，必须停留在app以外超过15秒才算去好评了
        GoodReviewsManager.startFiveStarTime = Int(Date().timeIntervalSince1970)
        let appId = "id6480020509" // 替换为你的应用ID
        let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appId)?action=write-review")!
        UIApplication.shared.open(url)
    }
    
    // 在app内直接评分
    private func gotoScoreInApp() {
        SKStoreReviewController.requestReview()
    }
}

extension GoodReviewsManager: GPImageTextAlertDelegate {
    func didClickComplain() {
        FeedbackVC.gotoFeedback()
    }
    
    func didClickDone() {
        gotoWriteReview()
    }
}
