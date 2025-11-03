//
//  CameraVC+Radio.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/26.
//  相机画幅

import Foundation
import UIKit

enum PhotoRatioType : Int{
    case ratio3x4
    case ratio9x16
    case ratio1x1
    case ratioFull
    
    func getIconType() -> IconFontType {
        switch self {
        case .ratio3x4:
            return .btn_ratio_3X4
        case .ratio1x1:
            return .btn_ratio_1X1
        case .ratio9x16:
            return .btn_ratio_9X16
        case .ratioFull:
            return .btn_ratio_full
        }
    }
}

extension CameraVC {
    
    func updateBGColor() {
        
        var bottomBGViewBgColor: UIColor = .white
        // 是否半透明
        var isTrans = false
        if cameraMode == .video || photoRatio == .ratio9x16 || photoRatio == .ratioFull {
            isTrans = true
            bottomBGViewBgColor = UIColor.black.withAlphaComponent(0.3)
        } else {
            isTrans = false
            bottomBGViewBgColor = UIColor.black.withAlphaComponent(0.3)
        }
        
        bottomView.backgroundColor = bottomBGViewBgColor
        topView.backgroundColor = bottomBGViewBgColor
    }
    
    func updateWatermarkContentViewFrame() {
        let radioState: PhotoRatioType = cameraMode == .video ? .ratio9x16 : photoRatio
        let wmFrame = getWatermarkViewFrame(radioState: radioState)
        watermarkContentView.frame = wmFrame
        currentWatermarkView?.frame = .init(x: 0, y: 0, width: wmFrame.width, height: wmFrame.height)
        glView.frame = wmFrame
        currentWatermarkView?.resetFrame()
        
        let bottomCameraFrame = wmFrame.origin.y + wmFrame.size.height
        var startY = bottomCameraFrame - 44 - 8
        let bottomStartY = GPApp.screenHeight - bottomHeight
        if bottomCameraFrame > bottomStartY {
            startY = bottomStartY - 44 - 8
        }
        watermarkBtn.frame = .init(x: GPApp.screenWidth - 44 - 8, y: startY, width: 44, height: 44)
        quickEditBtn.frame = .init(x: GPApp.screenWidth - 44 - 8, y: watermarkBtn.top - 44, width: 44, height: 44)
    }
    
    func getWatermarkViewFrame(radioState: PhotoRatioType) -> CGRect {
        var cameraH = CGFloat(0)
        let cameraW = UIScreen.main.bounds.width
        var topH = topView.height
        
        let centerVisbleHeight = GPApp.screenHeight - topView.height - bottomHeight
        
        switch radioState{
        case .ratio1x1:
            cameraH = GPApp.screenWidth
            topH = topView.height + (centerVisbleHeight - cameraH)/2.0
        case .ratio9x16:
            cameraH = 16/9.0*GPApp.screenWidth
            
            if GPApp.isIPhoneX {
                topH = topView.height
            } else {
                topH = 0
            }
        case .ratio3x4:
            cameraH = 4/3.0*GPApp.screenWidth
            if GPApp.isIPhoneX {
                topH = topView.height + (centerVisbleHeight - cameraH)/2.0
            } else {
                topH = 0
            }
        case .ratioFull:
            topH = 0
            cameraH = GPApp.screenHeight
        }
        return CGRect.init(x: 0, y: topH, width: cameraW , height: cameraH)
    }
}
