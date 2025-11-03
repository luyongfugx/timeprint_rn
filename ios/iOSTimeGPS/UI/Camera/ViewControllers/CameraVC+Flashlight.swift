//
//  CameraVC+Flashlight.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/28.
//

import Foundation
import GPCam

// 闪光灯模式
enum GPFlashMode: Int {
    /// 关闭
    case off
    
    /// 自动
    case auto
    
    /// 开启
    case on
    
    /// 常亮
    case always
    
    /// 夜景
    case night
    
    func getIconType() -> IconFontType {
        switch self {
        case .off:
            return .btn_flash_close
        case .on:
            return .btn_flash_open
        case .auto:
            return .btn_flash_auto
        case .always:
            return .btn_flashlight
        case .night:
            return .btn_nighmode
        }
    }
}

extension CameraVC {
    
    // 更新闪光灯模式
    func updateFlashLight() {
        var state: GPFlashMode = .off
        if cameraMode == .photo {
            state = flashlightMode
            switch state {
            case .off:
                camera?.cameraEntry.configureDeviceFlash(.off)
                camera?.cameraEntry.configureDeviceTorch(.off)
                camera?.enableNightEnhance(false)
            case .on:
                camera?.cameraEntry.configureDeviceFlash(.on)
                camera?.cameraEntry.configureDeviceTorch(.off)
                camera?.enableNightEnhance(false)
            case .auto:
                camera?.cameraEntry.configureDeviceFlash(.auto)
                camera?.cameraEntry.configureDeviceTorch(.off)
                camera?.enableNightEnhance(false)
            case .always:
                camera?.cameraEntry.configureDeviceFlash(.off)
                camera?.cameraEntry.configureDeviceTorch(.on)
                camera?.enableNightEnhance(false)
            case .night:
                camera?.cameraEntry.configureDeviceFlash(.off)
                camera?.cameraEntry.configureDeviceTorch(.off)
                camera?.enableNightEnhance(true)
            }
        } else {
            // 拍视频
            if isCameraBack {
                // V2.9.105: 闪光灯模式： 后置+拍视频,moidfy by waynelu flash off
                state = flashlightMode
                switch state {
                    case .off:
                  
                        camera?.cameraEntry.configureDeviceFlash(.off)
                        camera?.cameraEntry.configureDeviceTorch(.off)
                        camera?.enableNightEnhance(false)
                    case .always,.on,.auto,.night:
                        camera?.cameraEntry.configureDeviceFlash(.off)
                        camera?.cameraEntry.configureDeviceTorch(.on)
                        camera?.enableNightEnhance(false)
                   
                }

  
            } else {
                // 前置摄像头
                camera?.cameraEntry.configureDeviceFlash(.off)
                camera?.cameraEntry.configureDeviceTorch(.off)
                camera?.enableNightEnhance(false)
            }
        }
        topView.flashButton.setTitle(state.getIconType().rawValue, for: .normal)
    }
    
    // 切换前后置摄像头
    func swiftCameraBack() {
        var cameraM:BMWCameraMode = .photoBack
        if isCameraBack {
            if cameraMode == .video {
                cameraM = .videoFront
            } else {
                cameraM = .photoFront
            }
        } else {
            if cameraMode == .video {
                cameraM = .videoBack
            } else {
                cameraM = .photoBack
            }
        }
        camera?.changeFilter(cameraM)
        camera?.switch()
    }
}
