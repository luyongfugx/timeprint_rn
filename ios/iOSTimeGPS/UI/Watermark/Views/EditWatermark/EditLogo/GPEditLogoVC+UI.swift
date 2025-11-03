//
//  GPEditLogoVC+UI.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/6.
//

import Foundation
import UIKit

extension GPEditLogoVC {
    
    func buildViews() {
        
        navBar.addSubview(replaceButton)
        replaceButton.snp.makeConstraints { make in
            make.right.equalTo(-10)
            make.centerY.equalToSuperview()
        }
        
        view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
        }
        
        scrollView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.left.top.equalToSuperview()
            make.width.equalTo(GPApp.screenWidth)
            make.height.equalTo(GPApp.screenHeight)
        }
        
        
        
        //17.0以上才能调用remove bg
        if #available(iOS 17.0, *) {
            containerView.addSubview(bgLabel)
            bgLabel.snp.makeConstraints { make in
                make.left.equalTo(20)
               make.top.equalTo(20)
            }
            containerView.addSubview(removeBgView)
            removeBgView.initLogoImageView(logo: logoItem!)
            //设置remove 回调
            removeBgView.removeBg = { [weak self] image in
                let fileName = NSUUID().uuidString + ".png"
                GPDataCacheManager.shared.cachLogo(logoImg: image!, fileName: fileName)
                self?.logoItem?.selectLogoPath = fileName
                self?.handleComplate()
            }
            removeBgView.snp.makeConstraints { make in
                make.left.equalTo(20)
                make.right.equalTo(-20)
                make.top.equalTo(bgLabel.snp.bottom).offset(12)
                make.height.equalTo(60) // Or whatever height you need
            }
            containerView.addSubview(positionLabel)
            positionLabel.snp.makeConstraints { make in
                make.left.equalTo(20)
                make.top.equalTo(removeBgView.snp.bottom).offset(12)
            }
        }
        else {
            containerView.addSubview(positionLabel)
            positionLabel.snp.makeConstraints { make in
                make.left.equalTo(20)
                make.top.equalTo(20)
            }
        }

        
        containerView.addSubview(postionView)
        postionView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(positionLabel.snp.bottom).offset(12)
            make.height.equalTo(38)
        }
        postionView.currentPosition = logoItem?.enumPosition ?? .onWatermark
        postionView.selectHandle = { [weak self] position in
            self?.logoItem?.enumPosition = position
            self?.handleComplate()
        }
        
        containerView.addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(postionView.snp.bottom).offset(30)
        }
        buildSizeView()
        containerView.bringSubviewToFront(sizeLabel)
        
        containerView.addSubview(alphaLabel)
        alphaLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(sizeSliderView.snp.bottom).offset(20)
        }
        buildAlphaView()
        containerView.bringSubviewToFront(alphaLabel)
    }
        
    @objc
    func didClickReplace() {
        self.replaceAction?()
    }

    
}

extension GPEditLogoVC {
    func buildSizeView() {
        containerView.addSubview(sizeSliderView)
        self.sizeSliderView.snp.makeConstraints { make in
            make.top.equalTo(sizeLabel.snp.bottom).offset(-16)
            make.height.equalTo(88)
            make.width.equalToSuperview()
            make.right.equalTo(0)
        }
        
        let defaultValue = logoItem?.scale ?? 0.23
        
        self.sizeSliderView.slider.minimumValue = 0.1
        self.sizeSliderView.slider.maximumValue = 0.7
        self.sizeSliderView.makeDefaultDot(0.23)
        self.sizeSliderView.slider.setValue(Float(defaultValue), animated: false)
        self.sizeSliderView.slider.addTarget(self, action: #selector(sizeValueSliderChanged(_:)), for: .valueChanged)
        self.sizeSliderView.slider.addTarget(self, action: #selector(sizeValueSliderTouch(_:)), for: .touchUpInside)
    }
    
    @objc func sizeValueSliderChanged(_ sender: UISlider) {
        let slideValue = round(self.sizeSliderView.slider.value * 10) / 10 // 保留小数点后一位
        logoItem?.scale = CGFloat(slideValue)
        handleComplate()
    }
    
    @objc func sizeValueSliderTouch(_ sender: UISlider) {
        let slideValue = round(self.sizeSliderView.slider.value * 10) / 10 // 保留小数点后一位
        logoItem?.scale = CGFloat(slideValue)
        handleComplate()
    }
}


extension GPEditLogoVC {
    func buildAlphaView() {
        containerView.addSubview(alphaSliderView)
        self.alphaSliderView.snp.makeConstraints { make in
            make.top.equalTo(alphaLabel.snp.bottom).offset(-40)
            make.height.equalTo(88)
            make.width.equalToSuperview()
            make.right.equalTo(0)
        }
        
        let defaultValue = logoItem?.alpha ?? 1
        
        self.alphaSliderView.leftLable.text = nil
        self.alphaSliderView.rightLable.text = nil
        self.alphaSliderView.slider.minimumValue = 0
        self.alphaSliderView.slider.maximumValue = 1
        self.alphaSliderView.defaultDot.isHidden = true
        self.alphaSliderView.slider.setValue(Float(defaultValue), animated: false)
        self.alphaSliderView.slider.addTarget(self, action: #selector(alphaValueSliderChanged(_:)), for: .valueChanged)
        self.alphaSliderView.slider.addTarget(self, action: #selector(alphaValueSliderTouch(_:)), for: .touchUpInside)
    }
    
    @objc func alphaValueSliderChanged(_ sender: UISlider) {
        let slideValue = round(self.alphaSliderView.slider.value * 10) / 10 // 保留小数点后一位
        logoItem?.alpha = CGFloat(slideValue)
        handleComplate()
    }
    
    @objc func alphaValueSliderTouch(_ sender: UISlider) {
        let slideValue = round(self.alphaSliderView.slider.value * 10) / 10 // 保留小数点后一位
        logoItem?.alpha = CGFloat(slideValue)
        handleComplate()
    }
}
