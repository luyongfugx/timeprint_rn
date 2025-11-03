//
//  CameraConfig.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/29.
//  相机参数

import Foundation
import GPCam

class CameraConfig {
    
    // 拍照分辨率
    @GPPersistance(key: "com.gpscamera.key.photoQuolity", defaultValue: 0)
    static var photoQuolityInt: Int
    static var photoQuolityType: BMWImageResolutionQuality {
        set {
            CameraConfig.photoQuolityInt = newValue.rawValue
        }
        get {
            return BMWImageResolutionQuality(rawValue: CameraConfig.photoQuolityInt) ?? .current
        }
    }
    
    // 开启原图拍照
    @GPPersistance(key: "com.gpscamera.key.originPhotoSwich", defaultValue: false)
    static var openOriginPhoto: Bool
    
    @GPPersistance(key: "com.gpscamera.key.takephotoTime2", defaultValue: 0)
    static var takephotoTime2: Int

    // 显示相册红点
    @GPPersistance(key: "com.gpscamera.key.showWatermarBtnRed", defaultValue: false)
    static var showWatermarBtnRed: Bool
    
    
    // 是否显示官方水印
    @GPPersistance(key: "com.gpscamera.key.canShowOfficialWatermark", defaultValue: true)
    static var canShowOfficialWatermark: Bool
}
