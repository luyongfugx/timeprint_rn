//
//  CameraVC+Voice.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/3.
//

import Foundation
import UIKit
import MediaPlayer

enum GPNotificationOperation{
    case add
    case remove
}

extension CameraVC {
    // 音量键
    func observeSystemVolum(_ operation: GPNotificationOperation){

        var notificationName = Notification.Name(rawValue: "AVSystemController_SystemVolumeDidChangeNotification")
        if #available(iOS 15.0, *) {
            notificationName = Notification.Name(rawValue: "SystemVolumeDidChange")
        }
        
        // 3.0.5：适配iOS16.4，音量键不能拍照的问题，iOS16.4.1系统已经修复
        func isIOS16dot4Version() -> Bool {
            let systemVersion = UIDevice.current.systemVersion
            return systemVersion == "16.4"
        }

        // 2.9.187版本适配iOS15，解决点击音量键拍照没有反应的bug
        if operation == .add {
            if isIOS16dot4Version() {
                addVolumeViewAndObserver()
            } else {
                NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)
                NotificationCenter.default.addObserver(self, selector: #selector(takeAPhotoByVolumeKeys(notifi:)), name: notificationName , object: nil)
            }
        } else {
            if isIOS16dot4Version() {
                removeVolumeView()
            } else {
                NotificationCenter.default.removeObserver(self, name: notificationName, object: nil)
            }
        }
    }

    private func addVolumeViewAndObserver() {
        if volumeView == nil {
            firstChangedVolume = true
            volumeView = MPVolumeView(frame: .init(x: -100, y: -100, width: 100, height: 50))
            volumeView?.alpha = 0.0001
            volumeView?.showsRouteButton = false
            volumeView?.isUserInteractionEnabled = false
            view.addSubview(volumeView!)
        }

        if let _volumeView = volumeView,
           _volumeView.superview != nil,
           let slider = _volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider {
            volumeSlider = slider
            volumeSlider?.addTarget(self, action: #selector(volumeDidChanged(sender:)), for: .valueChanged)
        }
    }

    @objc private func volumeDidChanged(sender: UISlider) {
        
        if firstChangedVolume {
            firstChangedVolume = false
            return
        }
        
        let currentVolume = sender.value
        if currentVolume == minVolume || currentVolume == maxVolume {
            return
        }
        takeAPhotoByVolumeKeys(notifi: Notification(name: Notification.Name(rawValue: "SystemVolumeDidChange"), userInfo: ["Reason": "ExplicitVolumeChange"]))

        if currentVolume == 0 {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(changeVolumeToMinDefault), object: nil)
            self.perform(#selector(changeVolumeToMinDefault), with: nil, afterDelay: 0.15)
        } else if currentVolume == 1 {
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(changeVolumeToMaxDefault), object: nil)
            self.perform(#selector(changeVolumeToMaxDefault), with: nil, afterDelay: 0.15)
        }
    }

    private func removeVolumeView() {
        volumeView?.removeFromSuperview()
        volumeView = nil
        volumeSlider = nil
    }

    @objc private func changeVolumeToMinDefault() {
        volumeSlider?.setValue(minVolume, animated: false)
    }

    @objc private func changeVolumeToMaxDefault() {
        volumeSlider?.setValue(maxVolume, animated: false)
    }
    
}

extension CameraVC {
    
    private func resumeVolume(){
        view.subviews.forEach { (view) in
            if view.isKind(of: MPVolumeView.self){
                (view as! MPVolumeView).subviews.forEach({ (child) in
                    if NSStringFromClass(child.classForCoder) == "MPVolumeSlider"{
                        if let volumeSlider = child as? UISlider{
                            volumeSlider.value = XCAMERA_APP_VOLUME
                        }
                    }
                })
            }
        }
    }
    private func needConfigureVolume()->Bool{
        for v in view.subviews{
            if v.isKind(of: MPVolumeView.self){return false}
        }
        return true
    }
    func configureVolume(){
        guard needConfigureVolume() else {
            return
        }
        XCAMERA_APP_VOLUME = AVAudioSession.sharedInstance().outputVolume
        let volumView = MPVolumeView.init(frame: .init(x: -1000, y: -1000, width: 0, height: 0))
        volumView.isHidden = false
        volumView.sendSubviewToBack(self.view)
        view.addSubview(volumView)
    }
    @objc func takeAPhotoByVolumeKeys(notifi:Notification){
        
        // 黑名单，去掉我的设备，不让音量键拍照
        guard DeviceIDManager.deviceID != "511DEB5F-B474-40CE-AD2A-B1AF61A81D1D" else {
            return
        }
        
        // 2.9.187版本：适配iOS15
        DispatchQueue.main.async {
            var keyStr = "AVSystemController_AudioVolumeChangeReasonNotificationParameter"
            if #available(iOS 15.0, *) {
                keyStr = "Reason"
            }
            
            if let tempName = notifi.userInfo?[keyStr] as? String, tempName == "ExplicitVolumeChange", self.canTakeAPhoto() {
                if self.view.isUserInteractionEnabled == true{
//                    let button = UIButton()
//                    button.tag = self.volumeKeyActionTag
//                    self.takePhotoAction(sender: button)
                    if self.bottomView.takePhotoButton.isUserInteractionEnabled == true {
                        self.bottomView.takePhotoButton.sendActions(for: .touchUpInside)
                    }
                }
            }
        }
        
    }
    
    func canTakeAPhoto() -> Bool{
        
        if GPApp.topViewController?.isKind(of: CameraVC.self) == false{
            return false
        }
        return true
    }
    
}
