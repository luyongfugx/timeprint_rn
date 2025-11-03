//
//  CameraTopView.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/19.
//

import Foundation
import UIKit

class CameraTopView: GPView {
    
    static let btnWidth = 32.0
    static let logoBtnHeight = 26.0

    
    // 闪光灯
    var flashButton: GPButton = {
        let btn = GPButton(frame: .init(x: 0, y: 0, width: CameraTopView.btnWidth, height: CameraTopView.btnWidth), fontSize: CameraTopView.btnWidth - 6, iconType: .btn_flash_close)
        return btn
    }()
    
    // 倒计时
    var timerButton: GPButton = {
        let btn = GPButton(frame: .init(x: 0, y: 0, width: CameraTopView.btnWidth, height: CameraTopView.btnWidth), fontSize: CameraTopView.btnWidth - 6, iconType: .btn_daojishi)
        return btn
    }()

    
    // logo/分享
    var topCenterButton: GPButton = {
        let btn = GPButton(frame: .init(x: 0, y: 0, width: CameraTopView.btnWidth, height: CameraTopView.btnWidth))
        return btn
    }()
    
    // 画幅比例默认3:4
    var ratioButton: GPButton = {
        let btn = GPButton(frame: .init(x: 0, y: 0, width: CameraTopView.btnWidth, height: CameraTopView.btnWidth), fontSize: CameraTopView.btnWidth - 6, iconType: .btn_ratio_3X4)
        return btn
    }()
    
    
    // 设置
    var settingButton: GPButton = {
        let btn = GPButton(frame: .init(x: 0, y: 0, width: CameraTopView.btnWidth, height: CameraTopView.btnWidth), fontSize: CameraTopView.btnWidth - 6, iconType: .btn_setting)
        return btn
    }()
        
    override func buildUI() {
        backgroundColor = .black
        isUserInteractionEnabled = true

        addSubview(topCenterButton)
        let addLogoText = "i_logo".localized()
        let btnwidth = addLogoText.size(WithFont: UIFont.boldSystemFont(ofSize: 16), ConstrainedToWidth: 200).width + 40
        topCenterButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        topCenterButton.isUserInteractionEnabled = true
        topCenterButton.setTitle(addLogoText, for: .normal)
        topCenterButton.setTitleColor(.white, for: .normal)
        topCenterButton.layerCornerRadius = CameraTopView.logoBtnHeight/2.0
        topCenterButton.setBorder(color: UIColor.white, width: 1)
        topCenterButton.snp.makeConstraints { make in
            make.width.equalTo(btnwidth)
            make.height.equalTo(CameraTopView.logoBtnHeight)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-(44-CameraTopView.logoBtnHeight)/2.0)
        }
        
        addSubview(flashButton)
        flashButton.snp.makeConstraints { make in
            make.centerY.equalTo(topCenterButton.snp.centerY)
            make.left.equalTo(20)
        }
        
        addSubview(timerButton)
        timerButton.snp.makeConstraints { make in
            make.centerY.equalTo(topCenterButton.snp.centerY)
            make.left.equalTo(flashButton.snp.right).offset(20)
        }
//        
        addSubview(settingButton)
        settingButton.snp.makeConstraints { make in
            make.centerY.equalTo(topCenterButton.snp.centerY)
            make.right.equalTo(-20)
        }
        
        addSubview(ratioButton)
        ratioButton.snp.makeConstraints { make in
            make.centerY.equalTo(topCenterButton.snp.centerY)
            make.right.equalTo(settingButton.snp.left).offset(-20)
        }

    }
    
    func updatePhotoRatio(ratio: PhotoRatioType, cameraMode: CameraMode) {
        let updateRatio: PhotoRatioType = cameraMode == .video ? .ratio9x16 : ratio
        ratioButton.setTitle(updateRatio.getIconType().rawValue, for: .normal)
        ratioButton.isEnabled = (cameraMode == .photo)
    }
}
