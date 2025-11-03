//
//  CameraVC+Focus.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/28.
//

import Foundation
import GPCam

extension CameraVC {
    
    func createFocusView() {
        focusView = GPFocusView.focusView(progressCallback: { [weak self]  progress in
            self?.changeCamExpouseISO(progress)
        })
        
        view.addSubview(focusView)
        focusView.frame = CGRect.init(x: (view.width - GPFocusView.width) * 0.5, y: (view.height - GPFocusView.height) * 0.5, width: GPFocusView.width, height: GPFocusView.height)
    }
    
    /// 设置亮度
    /// progressOffset: value: 0 ~ 1
    func changeCamExpouseISO(_ progressOffset: CGFloat) {
        
        //范围 -1 ~ 1
        camera?.setEffectIntensity(BMWEffectTypeItem.brightnessEffect(), intensity: Float(progressOffset * 2 - 1))
    }
    
    func focusWithPoint(_ point:CGPoint){
        
        focusView.updateDateFocusCenter(with: point)
        // 对焦的时候消失掉焦距切换视图
                
    }
        
    func firstAutoFocusP() {
        
        var point = CGPoint.zero
        
        switch cameraMode {
        case .photo:
            point = CGPoint(x: 0.5, y: 0.4)
        case .video:
            point = CGPoint(x: 0.5, y: 0.5)
        case .report:
            point = CGPoint(x: 0.5, y: 0.4)
        }
        
        changeCamExpouseISO(0.5)
        focusWithPoint(CGPoint(x: GPApp.screenWidth*point.x, y: GPApp.screenHeight*point.y))
        camera?.cameraEntry.focusAndExpose(at: point)
    }
}
