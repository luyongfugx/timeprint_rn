//
//  GPFirebaseManager.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/19.
//


import UIKit
import Foundation
import FirebaseAnalytics
import FirebaseCore

class GPFirebaseManager: NSObject {
    
    // 初始化 FirebaseApp
    class func initFirebase() {
        FirebaseApp.configure()
        LogDebug("设置当前设备唯一ID：\(DeviceIDManager.deviceID)")
        setUserData(DeviceIDManager.deviceID)
    }
    
    class func setUserData(_ userId: String) {
        // 设置用户ID，不区分测试和线上环境
//        Crashlytics.crashlytics().setUserID(userId)
    }
    
    class func logCrashlytics(_ msg: String) {
//        Crashlytics.crashlytics().log(msg)
    }

    class func logEvent(event: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(event, parameters: parameters)
    }

}

// 业务埋点
extension GPFirebaseManager {
    
    // 拍照
    class func take_photo() {
        //获取当前id
        let  maskId:String = WatermarkManager.shared.selectWatermarkID()
        GPFirebaseManager.logEvent(event: "take_photo")
        //增加水印类型上报
        if(!maskId.isEmpty) {
            GPFirebaseManager.logEvent(event: "take_photo_wm_\(maskId)")
        }
       
    }

    // 拍照错误
    class func take_photo_fail(errorMsg: String) {
        GPFirebaseManager.logEvent(event: "take_photo_fail", parameters: ["errorMsg": errorMsg])
    }
    
    // 保存照片错误
    class func save_photo_fail(errorMsg: String) {
        GPFirebaseManager.logEvent(event: "save_photo_fail", parameters: ["errorMsg": errorMsg])
    }
    
    
    // 拍视频
    class func take_video_fail(errorMsg: String) {
        GPFirebaseManager.logEvent(event: "take_video_fail", parameters: ["errorMsg": errorMsg])
    }
    // 拍视频
    class func take_video() {
        GPFirebaseManager.logEvent(event: "take_video")

        //获取当前id,增加上报
        let  maskId:String = WatermarkManager.shared.selectWatermarkID()
        if(!maskId.isEmpty) {
            GPFirebaseManager.logEvent(event: "take_video_wm_\(maskId)")
        }
  
    }
    
    // 保存视频错误
    class func save_video_fail(errorMsg: String) {
        GPFirebaseManager.logEvent(event: "save_video_fail", parameters: ["errorMsg": errorMsg])
    }
    // 创建相册错误
    class func create_album_fail(errorMsg: String) {
        GPFirebaseManager.logEvent(event: "create_album_fail", parameters: ["errorMsg": errorMsg])
    }
    
    // 时间接口成功
    class func time_api_success(_ requestTotalTime: Int) {
        GPFirebaseManager.logEvent(event: "time_api_success", parameters: ["requestTotalTime": requestTotalTime])
    }
    
    // 时间接口失败
    class func time_api_fail(errorMsg: String) {
        GPFirebaseManager.logEvent(event: "time_api_fail", parameters: ["errorMsg": errorMsg])
    }
    
    
    // 反馈接口成功
    class func feedback_api_success(_ requestTotalTime: Int) {
        GPFirebaseManager.logEvent(event: "time_api_success", parameters: ["requestTotalTime": requestTotalTime])
    }
    
    // 反馈接口失败
    class func feedback_api_fail(errorMsg: String) {
        GPFirebaseManager.logEvent(event: "time_api_fail", parameters: ["errorMsg": errorMsg])
    }
    
    
    
    // 时间接口超过2分钟超时
    class func time_api_timeout() {
        GPFirebaseManager.logEvent(event: "time_api_timeout")
    }
    
    // 请求天气成功
    class func weatherSucccess() {
        GPFirebaseManager.logEvent(event: "weather_api_succcess")
    }
    
    // 请求天气失败
    class func weatherFail() {
        GPFirebaseManager.logEvent(event: "weather_api_fail")
    }

    
    // 搜索
    class func photo_search() {
        GPFirebaseManager.logEvent(event: "photo_search")
    }
    
    // 增加logo
    class func add_logo() {
        GPFirebaseManager.logEvent(event: "add_logo")
    }
    
    // remove_logo_bg logo
    class func remove_logo_bg() {
        GPFirebaseManager.logEvent(event: "remove_logo_bg")
    }
    // recover_logo_bg
    class func recover_logo_bg() {
        GPFirebaseManager.logEvent(event: "recover_logo_bg")
    }
    // 单照片分享
    class func single_share() {
        GPFirebaseManager.logEvent(event: "single_share")
    }
    // 多照片分享
    class func muti_share() {
        GPFirebaseManager.logEvent(event: "muti_share")
    }
    
    // 日历相册页
    class func calendar_view() {
        GPFirebaseManager.logEvent(event: "calendar_view")
    }
    
}
