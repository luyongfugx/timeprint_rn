//
//  AppDelegate.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/12.
//

import UIKit
import GPCam
import React
import ReactAppDependencyProvider
import React_RCTAppDelegate

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    //react-native
    var reactNativeFactory: RCTReactNativeFactory?
    var savedNativeVC: UIViewController?
    var reactNativeDelegate: ReactNativeDelegate?
    
    var window: UIWindow?
    var launchWindow: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.backgroundColor = .black
        //rn
        let delegate = ReactNativeDelegate()
        let factory = RCTReactNativeFactory(delegate: delegate)
        delegate.dependencyProvider = RCTAppDependencyProvider()
        reactNativeDelegate = delegate
        reactNativeFactory = factory
        
        LaunchManager.launchTimeCount += 1
//        if LaunchManager.launchTimeCount > 1 {
//            GPLaunchManager.shared.addNewLaunch()
//        }
        
        
        // 初始化日志
        configLog()
        // add param reactNativeFactory: factory
        let cameraVC = CameraVC(reactNativeFactory: factory)
        let nav = UINavigationController(rootViewController: cameraVC)
        nav.isNavigationBarHidden = true
        window?.rootViewController = nav
//        window?.makeKeyAndVisible()
        
        GPFirebaseManager.initFirebase()
        AppConfigManager.shared.initConfig()
                
        // 异步任务
        DispatchQueue.global().async {
            TimeManager.shared.getIsPhoneRestarted()
            TimeManager.shared.getServiceTimeFromDB()
        }
        
        // 1) 注册代理转发（用于接收点击回调、前台展示策略）
        UNUserNotificationCenter.current().sea_registerDelegateForwarder()

        // 2) 启动上报（会：请求 Provisional；判断是否到达升级节点；并计算/调度下一条提醒）
        // 不传则默认跟随设备地区，比如越南 VN；也可手动覆盖："VN"/"ID"/"MY"/"TH"...
        SEANotificationStrategy.shared.onAppLaunch(countryOverride: GPCountryManager.geoCountryCode)
        
        return true
    }
    
    func applicationWillEnterForeground(_: UIApplication) {
        // 后台进入前台时, 辅助验证是否五星好评过
        let startFiveStarTime = GoodReviewsManager.startFiveStarTime
        let currentTime = Int(Date().timeIntervalSince1970)
        // 距离上次弹窗已经超过了15秒
        if startFiveStarTime > 0, (currentTime - startFiveStarTime) > 15 {
            GoodReviewsManager.hasFiveStar = true
        } else {
            // 未超过则重置时间
            GoodReviewsManager.startFiveStarTime = 0
        }
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // 前台：如果上一条通知 1 小时无点击 → 计为忽略，达2次→暂停3天，再降级7天（仅周一/仅第一峰值窗）
        SEANotificationStrategy.shared.onBecameActive()
    }
    
    // 配置日志
    private func configLog() {
        // log打印
        GPLogManager.configDDLog()
        // 注册日志和上报接口到音视频SDK
        GPCamRegistrator.sharedInstance().registryFunc { funcs in
            funcs.logD = { msg in
//                LogDebug(msg)
            }
            funcs.logI = { msg in
//                LogDebug(msg)
            }
            funcs.logE = { msg in
                LogDebug(msg)
            }
            
        }
    }
}

class ReactNativeDelegate: RCTDefaultReactNativeFactoryDelegate {
  override func sourceURL(for bridge: RCTBridge) -> URL? {
    self.bundleURL()
  }

  
  override func bundleURL() -> URL? {
    #if DEBUG
      RCTBundleURLProvider.sharedSettings().jsBundleURL(forBundleRoot: "index")
    #else
      Bundle.main.url(forResource: "main", withExtension: "jsbundle")
    #endif
  }
}
