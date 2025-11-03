//
//  CameraVC+Gesture.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/3.
//  相机手势

import Foundation
import UIKit
import GPCam

extension CameraVC: CameraGestureControllerDelegate {
    
    /// 用长按手势做对焦
    func CameraGestureLongPress(_ point: CGPoint, gesture: UILongPressGestureRecognizer) {
        
        guard let gestureView = gesture.view else {
            return
        }
        
        switch gesture.state {
        case .began: do {
            lastLPStartLocation = point
            return
        }
        case .ended: do {
            if (lastLPStartLocation?.equalTo(point) ?? false) == false {
                return
            }
        }
        default: return
        }
        
        tryRestartCamera()
        //点击拍照时处理时，去掉对焦动作
//        if takepho.isUserInteractionEnabled == false{return}
        
        let convertPoint = gestureView.convert(point, to: glView)
        let containsInRect = glView.frame.contains(point)
        // 不在相机预览预期直接返回
        if !containsInRect {
            return
        }
        
        var capturePoint: CGPoint
        if camera?.cameraEntry.devicePosition == .back {
            capturePoint = CGPoint(x: convertPoint.y / glView.height ,y: 1 - convertPoint.x / glView.width)
        } else {
            capturePoint = CGPoint(x: convertPoint.y / glView.height ,y: convertPoint.x/glView.width)
        }
                
        camera?.setEffectIntensity(BMWEffectTypeItem.brightnessEffect(), intensity: 0.0)
        // V2.0.20: 应旭刚要求，修改聚焦方法，跟国内方案同步
        camera?.cameraEntry.focusAndExpose(at: capturePoint)
        
        let new_p = gestureView.convert(point, to: UIScreen.main.coordinateSpace)
        focusWithPoint(new_p)
    }

    func configureGestureView() {
        gestureController = GPCameraGesture(contentView: gestureView)
        gestureController?.delegate = self
    }

    // MARK: - 双击屏幕切换摄像头
    func CameraGestureSwichCamera(_ sender: GPCameraGesture) {
//        switchCam()
    }

    
    func CameraGesturePanStart(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer) {
        
        if focusView.isHidden == false {
            focusView.panGestureAction(gesture)
            return
        }
       // 不需要处理滤镜
    }
    
    func CameraGesturePanValueChange(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer) {
        
        if focusView.isHidden == false {
            focusView.panGestureAction(gesture)
            return
        }
    }
    
    func CameraGesturePanEnd(_ direction: GPXGesture.Direction, offset: CGFloat, gesture: UIPanGestureRecognizer) {
        
    }
    
    func CameraGestureNewChangingFilter(_ progress: CGFloat) {
        
//        // 产品需求 , 切换对焦亮度的时候不允许切换滤镜(阿慧)
//        if self.cameraState == .recording && self.captureMode == .video && videoPauseBtn.isHidden == false || focusView.isHidden == false {
//            return
//        }
//      
//        // v.2.9.165
//        beautyFliterVC?.directionFilter(direction: progress > 0 ? .last:.next, switchWay: "slide")
        
        /* 2.9.225版本修改这个埋点:切换滤镜
        let filterID = beautyFliterVC?.currentFilterId() ?? -10000
        
        if captureMode == .photo{
            Report.filter_switch("photoCameraPage",id:filterID)
        }else{
            Report.filter_switch("videoCameraPage",id:filterID)
        }*/
    }
    
    func CameraGestureZoom(_ scale: CGFloat, sender: GPCameraGesture) {
        
        camera?.cameraEntry.zoom(withScale: scale)
//        showWideAngleSliderView(comeFrom: .twoFingerScale)
    }
    
    func CameraGestureZoomBegin(_ scale: CGFloat, sender: GPCameraGesture){
        camera?.cameraEntry.zoomBegin(scale)
    }
    func CameraGestureZoomEnd(_ scale: CGFloat, sender: GPCameraGesture){
        camera?.cameraEntry.zoomEnd(scale)
    }
    
    
}

