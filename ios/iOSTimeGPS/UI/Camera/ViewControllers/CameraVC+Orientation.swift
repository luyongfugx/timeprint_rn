//
//  CameraVC+Orientation.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/26.
//  相机方向旋转

import Foundation
import GPCam

public enum GPOrientation:Int {
    case portraitDirection = 1
    case downDirection = 2
    case leftDirection = 3
    case rightDirection = 4
    case unknownDirection = 5
    
    func isVertical() -> Bool {
        return self == .portraitDirection || self == .downDirection
    }
}

extension CameraVC {
    
    func startMonitorOrientation() {
        //陀螺仪
        GPOrientationManager.shared.startMonitor()
        GPOrientationManager.shared.delegate = self

    }
    
    func stopMonitorOrientation() {
        GPOrientationManager.shared.stopMonitor()
    }
    
}

// watermark ortation
extension CameraVC: GPOrientationMamagerDelegate{
    
    func GPOrientationMamagerOrientationChange(currentOrientation: GPOrientation, oldOrientation: GPOrientation) {
        
        camera?.realtimeDeviceOrientation = BMWDeviceOrientation.init(rawValue: currentOrientation.rawValue)!
        // [lxg ADD] 2.9.210 录制视频过程中，不修改水印方向
        // [lxg ADD] 2.9.275 拍照原子操作中，不修改水印方向
        if isRecording {
            return
        }
        changeWatermarkOriention(currentOrientation: currentOrientation)
        // XHLogDebug("[水印方向调试] - 调用改变水印方向的方法 - 11")
//        countdownLabel?.changeOriention(currentOrientation: currentOrientation);
    }
    
    func changeWatermarkOriention(currentOrientation: GPOrientation){
        orientionWatermarkView(currentWatermarkView, currentOrientation: currentOrientation)
        // 250版本添加，实时更改数钢筋的水印，数字方向
//        changeSteelOritation(currentOrientation: currentOrientation)
        wideAngleListView?.original(original: currentOrientation)
        // 更新倒计时标签的方向
        updateCountdownLabelOrientation(currentOrientation)
    }
    
    // 更新倒计时标签方向
    private func updateCountdownLabelOrientation(_ orientation: GPOrientation) {
        var transform = CGAffineTransform.identity
        
        switch orientation {
        case .portraitDirection:
            transform = .identity
        case .downDirection:
            transform = CGAffineTransform(rotationAngle: .pi)
        case .leftDirection:
            transform = CGAffineTransform(rotationAngle: .pi / 2)
        case .rightDirection:
            transform = CGAffineTransform(rotationAngle: -.pi / 2)
        default:
            break
        }
        
        UIView.animate(withDuration: 0.3) {
            self.countdownLabel.transform = transform
        }
    }
    
    func orientionWatermarkView(_ watermarkView:UIView?, currentOrientation: GPOrientation){
        
        guard let _watermarkView = watermarkView as? BaseWatermark else {
            return
        }
        _watermarkView.transform = CGAffineTransform.identity

        var rotateTransform = CGAffineTransform.identity
        switch currentOrientation{
        case .downDirection:
            if _watermarkView.orientation == currentOrientation{
                return
            }
            _watermarkView.frame = CGRect(x: 0, y: 0, width: watermarkContentView.frame.size.width, height: watermarkContentView.frame.size.height)
            _watermarkView.orientation = currentOrientation
            rotateTransform = CGAffineTransform.identity.rotated(by: CGFloat.pi)
        case .leftDirection:
            _watermarkView.orientation = currentOrientation
            _watermarkView.frame = CGRect(x: 0, y: 0, width: watermarkContentView.frame.size.height, height: watermarkContentView.frame.size.width)
            _watermarkView.center = CGPoint.init(x: watermarkContentView.bounds.width/2, y: watermarkContentView.bounds.height/2)
            rotateTransform = CGAffineTransform.identity.rotated(by: CGFloat.pi/2)
        case .rightDirection:
            _watermarkView.orientation = currentOrientation
            _watermarkView.frame = CGRect(x: 0, y: 0, width: watermarkContentView.frame.size.height, height: watermarkContentView.frame.size.width)
            _watermarkView.center = CGPoint.init(x: watermarkContentView.bounds.width/2, y: watermarkContentView.bounds.height/2)
            rotateTransform = CGAffineTransform.identity.rotated(by: -CGFloat.pi/2)
        case .portraitDirection:
            _watermarkView.frame = CGRect(x: 0, y: 0, width: watermarkContentView.frame.size.width, height: watermarkContentView.frame.size.height)
            _watermarkView.orientation = currentOrientation
            //以防记录的值影响计算  水印选择页面  的位移
            rotateTransform = CGAffineTransform.identity
            
        default:
            break
        }
        _watermarkView.transform = rotateTransform
        _watermarkView.forceRefresh()
        watermarkContentView.forceRefresh()

        orientionProductWatermarkView(currentWatermarkView?.offcialLogoView, currentOrientation: currentOrientation)
    }

    func orientionProductWatermarkView(_ view: UIView?, currentOrientation: GPOrientation) {
        
        if let view = view as? BaseWatermark {
            
            switch currentOrientation{
            case .downDirection: do {
                if view.orientation == currentOrientation{
                    return
                }
                view.transform = CGAffineTransform.identity
                view.frame = CGRect(x: 0, y: 0, width: watermarkContentView.frame.size.width, height: watermarkContentView.frame.size.height)
                watermarkContentView.layoutIfNeeded()
                view.orientation = currentOrientation
                //以防记录的值影响计算  水印选择页面  的位移
//                view.setAnimationViewCachePosition(orientation: currentOrientation,moveValue:0)
                view.transform = CGAffineTransform.identity.rotated(by: CGFloat.pi)
            }
            case .leftDirection: do {
                
                if view.orientation == currentOrientation{
                    return
                }
                view.transform = CGAffineTransform.identity
                view.orientation = currentOrientation
                view.frame = CGRect(x: 0, y: 0, width: watermarkContentView.frame.size.height, height: watermarkContentView.frame.size.width)
                view.center = CGPoint.init(x: watermarkContentView.bounds.width/2, y: watermarkContentView.bounds.height/2)
                view.transform = CGAffineTransform.identity.rotated(by: CGFloat.pi/2)
            }
                
            case .rightDirection: do {
                
                if view.orientation == currentOrientation{
                    return
                }
                view.transform = CGAffineTransform.identity
                view.orientation = currentOrientation
                view.frame = CGRect(x: 0, y: 0, width: watermarkContentView.frame.size.height, height: watermarkContentView.frame.size.width)
                view.center = CGPoint.init(x: watermarkContentView.bounds.width/2, y: watermarkContentView.bounds.height/2)
                view.transform = CGAffineTransform.identity.rotated(by: -CGFloat.pi/2)
                watermarkContentView.layoutIfNeeded()
//                view.setAnimationViewCachePosition(orientation: currentOrientation,moveValue:0)
            }
            
            case .portraitDirection: do {
                
                view.transform = CGAffineTransform.identity
                view.frame = CGRect(x: 0, y: 0, width: watermarkContentView.frame.size.width, height: watermarkContentView.frame.size.height)
                watermarkContentView.layoutIfNeeded()
                view.orientation = currentOrientation
                //以防记录的值影响计算  水印选择页面  的位移
//                view.setAnimationViewCachePosition(orientation: currentOrientation,moveValue:0)
                view.transform = CGAffineTransform.identity
            }
            default:
                break
            }
            
            view.layoutIfNeeded()
        }
    }
        
    func watermarkChangeByFrameSize(){
        
        if let watermarkView = currentWatermarkView{
            let oriention = GPOrientationManager.shared.getOrientation()
            watermarkView.frameSizeChange(orientation: oriention)
        }
    }
}
