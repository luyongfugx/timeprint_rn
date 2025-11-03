//
//  GPApp.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/19.
//

import Foundation
import DeviceKit
import UIKit
import Photos
import AVFoundation

open class GPApp {
    // 屏幕宽度
    public static let screenWidth = UIScreen.main.bounds.width
    
    // 屏幕高度
    public static let screenHeight = UIScreen.main.bounds.size.height
    
    // 判断设备是不是iPhoneX(包括刘海屏和灵动岛机型,底部安全区域大于0都算)
    public static var isIPhoneX: Bool {
        Device.current.hasSensorHousing
    }
    
    // TabBar距底部区域高度
    public static var tabBarBottomHeight: CGFloat {
        isIPhoneX ? 34.0 : 0
    }
    
    // 状态栏的高度
    public static var statusBarHeight: CGFloat {
        let currentDevice = Device.current

        switch (currentDevice.hasSensorHousing, currentDevice.hasDynamicIsland) {
        case (false, _):
            return 20.0
        case (true, true):
            return 54.0
        case (true, false):
            return 40.0
        }
    }
    
    // 导航栏的高度
    public static var navigationBarHeight: CGFloat {
        44.0
    }
    
    // 状态栏和导航栏的高度
    public static var statusBarAndNavigationBarHeight: CGFloat {
        statusBarHeight + navigationBarHeight
    }
    
    // 版本号
    public static var version: String {
        // 2.x.x
        if let str = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return str
        }
        return ""
    }
    
    // build号
    public static var buildVersion: String {
        // 2019101910
        if let str = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return str
        }
        return ""
    }
    
    // 名称
    public static var displayName: String {
        if let str = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String {
            return str
        }
        return ""
    }
    
    // 唯一标识
    public static var identifier: String {
        if let str = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String {
            return str
        }
        return ""
    }
    
    // 制造商
    public static var manufacturer: String {
        "Apple"
    }
    
    // 操作系统
    public static var systemName: String {
        UIDevice.current.systemName
    }
    
    // 操作系统版本
    public static var osVersion: String {
        UIDevice.current.systemVersion
    }
    
//    enum ForStringChange {
//        static var first: String = "printTime"
//        static var second: String = "gan18a64"
//        static var last: String = "wayneSr18"
//        static func getThisString() -> String {
//            return first + second + last
//        }
//    }
    enum ForStringChange {
        static var first: String = "2wY2" 
        static var second: String = "wyNdErq8"
        static var last: String = "YAGs"
        static func getThisString() -> String {
            return first + second + last
        }
    }


    // MARK: - 查找顶层控制器

    // 获取顶层控制器 根据window
    open class func getTopViewController() -> UIViewController? {
        guard let window = keyWindow(), window.windowLevel == .normal else {
            return UIApplication.shared.windows.first(where: { $0.windowLevel == .normal })?.rootViewController.flatMap { getTopViewController($0) }
        }
        return getTopViewController(window.rootViewController)
    }
    
    // 根据控制器获取 顶层控制器
    open class func getTopViewController(_ viewController: UIViewController?) -> UIViewController? {
        guard let viewController else {
            return nil
        }
        
        if let nav = viewController as? UINavigationController {
            // 控制器是nav
            return getTopViewController(nav.visibleViewController)
        } else if let tabC = viewController as? UITabBarController {
            // tabBar的根控制器
            return getTopViewController(tabC.selectedViewController)
        } else if let presentVC = viewController.presentedViewController {
            // modal出来的控制器
            return getTopViewController(presentVC)
        } else {
            // 返回顶控制器
            return viewController
        }
    }
    
    open class func keyWindow() -> UIWindow? {
        return UIApplication.shared.windows.filter { $0.isKeyWindow }.first
    }
    
    // MARK: - 顶层控制器

    open class var topViewController: UIViewController? {
        getTopViewController()
    }
    
    
    static func getDeviceInfoStr() -> String {
           let performanceInfo = getPerformanceInfo()
           let authInfo = getAuthInfo()
           let infoStr = "App设备信息: 版本号:[\(version)] - Build号:[\(buildVersion)] - APP名称:[\(displayName)] - 唯一标识:[\(identifier)] - 制造商:[\(manufacturer)] - 操作系统:[\(systemName)] - 操作系统版本: [\(osVersion)] - 设备型号:[\(BCDevice.shared.getDeviceModel())] - 屏幕宽度:[\(screenWidth)] - 屏幕高度:[\(screenHeight)] - 状态栏的高度:[\(statusBarHeight)] - 导航栏的高度:[\(navigationBarHeight)] - 设备是不是iPhoneX:[\(isIPhoneX)] - 安全区域距底部高度: [\(tabBarBottomHeight)] - \(performanceInfo) -\(authInfo)"
           return infoStr
       }
    static func getAuthStatus(status:Int) -> String {
        var statusString = "";
        switch status {
        case 3:
            statusString = "authorized";
        case 2:
            statusString = "denied";
        case 1:
            statusString = "restricted";
        case 0:
            statusString = "notDetermined";
   
        case 4:
            statusString = "limited";
            
        default:
            statusString = "unknow";
        }
        return statusString
    }

    static func getAuthInfo() -> String {
        let photoStatus =  PHPhotoLibrary.authorizationStatus()
        let videoStatus =  AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus =    AVCaptureDevice.authorizationStatus(for: .audio)
        let errorText = "photoStatus: \(getAuthStatus(status:photoStatus.rawValue))  videoStatus: \(getAuthStatus(status:videoStatus.rawValue))  audioStatus: \(getAuthStatus(status:audioStatus.rawValue))  "
        return errorText;
    }
       // MARK: - 2.9.340:获取性能信息

    static  func getPerformanceInfo() -> String {
           // 2.9.340
           // 磁盘的总大小MB
           let totalSpace = BCDevice.shared.getTotalDiskSpace()
           // 设备的剩余空间大小MB
           let freeSpace = BCDevice.shared.getDiskFreeSpace()
           // 已使用内存(byte),  total: 总内存(byte)
           let memoryInfo = BCDevice.shared.getMemoryUsage()
           let memoryUsed = memoryInfo.used / 1024 / 1024
           let memoryRemain = (memoryInfo.total - memoryInfo.used) / 1024 / 1024
           
           let str = "磁盘空间总大小:[\(totalSpace)MB] - 剩余磁盘空间:[\(freeSpace)MB] - 已使用内存:[\(memoryUsed)MB] - 剩余内存:[\(memoryRemain)MB]"
           return str
       }
    
//    // 跳转到指定的VC
//    open class func jumpToViewController(_ vcClass: UIViewController.Type, animated: Bool = true) {
//        if let topVC = getTopViewController() {
//            _ = topVC.returnToViewController(vcClass, animated: animated)
//        } else {
//            LogDebug("找不到任何VC，无法完成跳转")
//        }
//    }
    
    // MARK: - 获取唯一字符串

//    open class func getUniqueString() -> String {
//        return NSUUID().uuidString.md5()
//    }
//    
    // 获取UUID
    open class func getUUID() -> String {
        return NSUUID().uuidString
    }
   
    open class func gotoSetting() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension GPApp {
    
    static func openAppSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            print("无法获取设置 URL")
            return
        }
        
        if UIApplication.shared.canOpenURL(settingsUrl) {
            UIApplication.shared.open(settingsUrl, options: [:]) { success in
                if success {
                    print("成功打开设置页面")
                } else {
                    print("无法打开设置页面")
                }
            }
        } else {
            print("设备不支持打开设置页面")
        }
    }
    
}
