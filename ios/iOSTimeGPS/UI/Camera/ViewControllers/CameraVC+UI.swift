//
//  CameraVC+UI.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/3.
//

import Foundation
import UIKit
import GPCam

extension CameraVC {
  
    func initViews() {
        view.backgroundColor = .black
        navigationController?.navigationBar.isHidden = true
        
        self.glView = BMWGLView(frame: CGRect(x: 0, y: 0, width: GPApp.screenWidth, height: GPApp.screenHeight))
        self.view.addSubview(self.glView)
        glView.backgroundColor = UIColor.black
                
        //375,667
        self.gestureView = UIView(frame: CGRect(x: 0, y: 0, width: GPApp.screenWidth, height: GPApp.screenHeight))
        self.view.addSubview(self.gestureView)
        configureGestureView()
                
        topView = CameraTopView(frame: .init(x: 0, y: 0, width: GPApp.screenWidth, height: GPApp.statusBarAndNavigationBarHeight))
        self.view.addSubview(self.topView)
        topView.flashButton.addTarget(self, action: #selector(flashBtnAction(sender:)), for: .touchUpInside)
        topView.timerButton.addTarget(self, action: #selector(timeBtnAction(sender:)), for: .touchUpInside)
        topView.ratioButton.addTarget(self, action: #selector(ratioBtnAction(sender:)), for: .touchUpInside)
        topView.settingButton.addTarget(self, action: #selector(settingBtnAction(sender:)), for: .touchUpInside)
        topView.topCenterButton.addTarget(self, action: #selector(centerTopBtnAction(sender:)), for: .touchUpInside)
        
        bottomView = CameraBottomView(frame: .zero)
        bottomView.backgroundColor = .black
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(bottomHeight)
        }
        bottomView.takePhotoButton.addTarget(self, action: #selector(takePhotoAction(sender:)), for: .touchUpInside)
        bottomView.refreshButton.addTarget(self, action: #selector(refreshAction(sender:)), for: .touchUpInside)
        bottomView.albumButton.addTarget(self, action: #selector(albumAction(sender:)), for: .touchUpInside)
//        bottomView.watermarkButton.addTarget(self, action: #selector(watermarkAction), for: .touchUpInside)
        bottomView.tabBarView.chooseHandler = { [weak self] mode in
            guard let self = self else { return }
            
            if mode == .report {
                // 直接进入批量选择页
                let vc = MultiPhotoShowViewController(asset: nil, defaultAssetLocated: true)
                //添加对timeprint 的多图分享处理参数
                vc.isFromTimeprint = false
                self.navigationController?.pushViewController(vc, animated: true)
                return
            }
            
            // 切换模式
            self.cameraMode = mode
            //如果切换到视频后，不是i_flash_close 或者 i_flashlight，则使用 i_flash_close
            if mode == .video {
                if flashlightMode  != .off, flashlightMode != .always {
                    flashlightMode =  .off
                }
            }
        }
                
        watermarkContentView = GPContentView(frame: .init(x: 0, y: GPApp.statusBarAndNavigationBarHeight, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height - GPApp.statusBarAndNavigationBarHeight))
        view.addSubview(watermarkContentView)
        
        firstAddWatermark()
        
        // 添加选择模版按钮
        view.addSubview(watermarkBtn)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            if !CameraConfig.showWatermarBtnRed {
                self?.watermarkBtn.showRedDot(isShow: true, point: CGPointMake(44-10-2, 2))
            }
        }
        view.addSubview(quickEditBtn)

        createFocusView()
        view.addSubview(takePhotoViewBG)
        view.bringSubviewToFront(topView)
        view.bringSubviewToFront(bottomView)
        
        handleChineseMode()
        
        updateDelayTakePhotoUI()
    }
    
    func handleChineseMode() {
        if GPCheetManager.isCheetMode {
            topView.ratioButton.isHidden = true
            topView.topCenterButton.isHidden = true
            topView.isHidden = true
            watermarkBtn.isHidden = true
            quickEditBtn.isHidden = true

        } else {
            topView.ratioButton.isHidden = false
            topView.topCenterButton.isHidden = false
            watermarkBtn.isHidden = false
            quickEditBtn.isHidden = false
            topView.isHidden = false
        }
    }
    
    func buildWideAngle() {
        
        if GPCheetManager.isCheetMode {
            return
        }
        
        let _wideAngleListView = GPWideAngleListView.angleListView { [weak self] scale in
            self?.camera?.cameraEntry.setCurrZoomFactor(scale, animation: false)
        }
        wideAngleListView = _wideAngleListView
        view.addSubview(_wideAngleListView)
        // 是否支持广角
        isSupportWideAngle = camera?.cameraEntry.isSupportWideAngle ?? false
        
        _wideAngleListView.snp.makeConstraints({ make in
            make.width.equalTo(GPWideAngleView.width)
            make.height.equalTo(isSupportWideAngle ? 233 : 180)
            make.right.equalTo(-9)
            make.top.equalTo(GPApp.isIPhoneX ? 181 : 100)
        })
        
        let _wideAngleValueTipView = GPWideAngleTipView.tipView()
        view.addSubview(_wideAngleValueTipView)
        _wideAngleValueTipView.snp.makeConstraints { make in
            make.top.equalTo(155)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(71)
        }
        wideAngleValueTipView = _wideAngleValueTipView
        
        let fontWideScale = camera?.cameraEntry.getMinZoomFactor(.front)
        let backWideScale = camera?.cameraEntry.getMinZoomFactor(.back)
//        widgeSliderView?.update(isSupportWidge: isSupportWideAngle, fontWideScale: fontWideScale, backWideScale: backWideScale, isCameraBackPosition: isCameraBackPosition)
        wideAngleListView?.update(isSupportWidge: isSupportWideAngle, frontWideScale: fontWideScale, backWideScale: backWideScale, isCameraBackPosition: isCameraBackPosition)
    }
    
    func updateDelayTakePhotoUI() {
        if self.delayTakephotoType == .none {
            topView.timerButton.setTitleColor(.white, for: .normal)
        } else {
            topView.timerButton.setTitleColor(.yellow_color, for: .normal)
        }
    }
    
    func setupCountdownUI() {
        // 添加倒计时标签到glView
        glView.addSubview(countdownLabel)
        countdownLabel.snp.makeConstraints { make in
            make.width.height.equalTo(100)
            make.bottom.equalToSuperview().offset(-20)
            make.right.equalToSuperview().offset(-20)
        }
        
        // 添加取消按钮
        view.addSubview(cancelButton)
        let bottomPadding = (bottomHeight - 70)/2.0
        cancelButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 70, height: 70))
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-bottomPadding)
        }
        
        cancelButton.addTarget(self, action: #selector(cancelCountdown), for: .touchUpInside)
    }
    
    func checkLogoOrShare() {
        var addLogoText = "i_logo".localized()
        if currentWatermarkView?.hasLogo() == true {
            addLogoText = "i_share".localized()
        }
        let btnwidth = addLogoText.size(WithFont: UIFont.boldSystemFont(ofSize: 16), ConstrainedToWidth: 200).width + 40
        topView.topCenterButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        topView.topCenterButton.isUserInteractionEnabled = true
        topView.topCenterButton.setTitle(addLogoText, for: .normal)
        topView.topCenterButton.setTitleColor(.white, for: .normal)
        topView.topCenterButton.layerCornerRadius = CameraTopView.logoBtnHeight/2.0
        topView.topCenterButton.setBorder(color: UIColor.white, width: 1)
        topView.topCenterButton.snp.remakeConstraints { make in
            make.width.equalTo(btnwidth)
            make.height.equalTo(CameraTopView.logoBtnHeight)
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-(44-CameraTopView.logoBtnHeight)/2.0)
        }
    }
    
}
