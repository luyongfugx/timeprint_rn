//
//  EditThemeView+Size.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/4.
//

import Foundation
import UIKit

extension EditThemeView {
    
    func buildSizeView() {
        
        self.addSubview(sizeSliderView)
        self.sizeSliderView.snp.makeConstraints { make in
            make.top.equalTo(224+60+20)
            make.height.equalTo(88)
            make.width.equalToSuperview()
            make.right.equalTo(0)
        }
        
        let defaultValue = (self.watermarkModel?.templateScale ?? 1) - 0.5
        
        self.sizeSliderView.slider.setValue(Float(defaultValue), animated: false)
        self.sizeSliderView.slider.addTarget(self, action: #selector(sizeValueSliderChanged(_:)), for: .valueChanged)
        self.sizeSliderView.slider.addTarget(self, action: #selector(sizeValueSliderTouch(_:)), for: .touchUpInside)
        
    }
    
    @objc func sizeValueSliderChanged(_ sender: UISlider) {
        let slideValue = round(self.sizeSliderView.slider.value * 10) / 10 // 保留小数点后一位
        let value = 0.5 + CGFloat(slideValue)
        self.watermarkModel?.templateScale = value
        self.delegate?.updateWatermarkScale(scale: value)
    }
    
    @objc func sizeValueSliderTouch(_ sender: UISlider) {
        var newValue = round(self.sizeSliderView.slider.value * 10) / 10 // 保留小数点后一位
        let value = 0.5 + CGFloat(newValue)
        self.watermarkModel?.templateScale = value
        self.delegate?.updateWatermarkScale(scale: value)
    }
    
}
