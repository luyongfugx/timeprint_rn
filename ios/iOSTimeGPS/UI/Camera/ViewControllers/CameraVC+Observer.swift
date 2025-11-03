//
//  CameraVC+Observer.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/21.
//

import Foundation

extension CameraVC {
    
    func addObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(enterBackground),
                                               name: UIApplication.didEnterBackgroundNotification,
                                               object: nil)
        camera?.addObserver(self, forKeyPath: "currZoomFactor", options: .new, context: nil)
    }
    
    @objc func willEnterForeground() {
        currentWatermarkView?.removeDotLineAnimation()
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        self.tryRestartCamera()
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.2) {
            self.firstAutoFocusP()
        }

        // 优先检测定位+地址
        GPSGeoManager.shared.startMonitor()
    }
        
    func firstAddWatermark() {
        currentWatermarkView = BaseWatermark.generateWatermarkView(watermarkModel: WatermarkManager.shared.getSelectWatermarkModel(), frame: .init(x: 0, y: GPApp.statusBarAndNavigationBarHeight, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - GPApp.statusBarAndNavigationBarHeight))
        watermarkContentView.addSubview(currentWatermarkView!)
        currentWatermarkView?.delegate = self
        currentWatermarkView?.updateUI()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            // delay
            self.currentWatermarkView?.addDotLineAnimation()
        }

    }
    
    @objc func enterBackground(){
        if isRecording {
            LogDebug("切到后台，停止录像 ")
            gotoTakePhoto()
        }
        closeCamera()
        currentWatermarkView?.removeDotLineAnimation()
    }
    
    // 重启摄像头,true 需要重启，false 不需要
    @discardableResult
    func tryRestartCamera() -> Bool {
        /// 在当前页面 ，且没有运行 重启摄像头
        guard camera?.cameraEntry.isRunning() == false, isCurrentVC else {
            return false
        }
        camera?.startCapture(complete: { error, totalTimecost, cameraTimecost in
            LogDebug("startCapture result: \(String(describing: error))")
        })
        return true
    }
    
    // 关闭摄像头
    func closeCamera() {
        //停止捕获
        camera?.stopCapture()
    }
    
}

