//
//  CameraVC+.swift
//  iOSTimeGPS
//
//

import AVFoundation

extension CameraVC {
    
    func checkCameraPermission() {
        guard !GPCheetManager.isCheetMode else { return }
        let permission = AVCaptureDevice.authorizationStatus(for: .video)
        
        if permission == .denied || permission == .restricted {
            createPermissionUI()
            if let cameraAccessView = self.cameraAccessView {
                view.bringSubviewToFront(cameraAccessView)
                cameraAccessView.isHidden = false
            }
        } else {
            self.cameraAccessView?.isHidden = true
        }
    }
    func checkRecordPermission() {
        AVAudioSession.sharedInstance().requestRecordPermission { (granted) in
            if granted {
                print("checkRecordPermission \(granted)");
                self.cameraAccessView?.isHidden = true
      
            } else {
                print("createPermissionUI checkRecordPermission \(granted)");
                self.createPermissionUI()
                if let cameraAccessView = self.cameraAccessView {
                    self.view.bringSubviewToFront(cameraAccessView)
                    self.cameraAccessView?.isHidden = false
                }
            }
        }
    }
    
    private func createPermissionUI() {
        if cameraAccessView == nil {
            let _cameraAccessView = CameracAccessView(frame: .zero)
            cameraAccessView = _cameraAccessView
            view.addSubview(_cameraAccessView)
            _cameraAccessView.snp.makeConstraints { make in
                make.center.equalTo(glView.snp.center)
                make.width.equalToSuperview()
            }
        }
    }
    
    func checkLocationPermission() {
        
        if CLLocationManager.locationServicesEnabled() == false {
            self.openSystemLocationServiceSetting()
        } else if CLLocationManager.authorizationStatus() == .denied {
            self.openSystemLocationSetting()
        }
        
    }
    
    
    private func openSystemLocationServiceSetting() {
        let cancelAction = ZLCustomAlertAction(title: "k_cancle".localized(), style: .default, handler: nil)
        let gotoSettingsAction = ZLCustomAlertAction(title: "i_setting".localized(), style: .tint) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        showAlertController(title: "k_turn_on_location_service_title".localized(), message: "k_turn_on_location_service_msg".localized(), shouldMessageLeft: true, style: .alert, actions: [cancelAction, gotoSettingsAction], sender: self)
    }
    
    private func openSystemLocationSetting() {
        let cancelAction = ZLCustomAlertAction(title: "k_cancle".localized(), style: .default, handler: nil)
        let gotoSettingsAction = ZLCustomAlertAction(title: "i_setting".localized(), style: .tint) { _ in
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        showAlertController(title: "i_cant_get_location".localized(), message: "i_please_access_location_info".localized(), shouldMessageLeft: false, style: .alert, actions: [cancelAction, gotoSettingsAction], sender: self)
    }
}
