//
//  GPSizeSliderBar.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/4.
//

import Foundation
import UIKit

class GPSizeSliderBar: GPView {
        
    lazy var leftLable: UILabel = {
        let label = UILabel()
        label.text = "k_logo_small".localized()
        label.textColor = .text_black_color
        label.font = UIFont.regular(12)
        return label
    }()
    
    lazy var rightLable: UILabel = {
        let label = UILabel()
        label.text = "k_logo_large".localized()
        label.textColor = .text_black_color
        label.font = UIFont.regular(18)
        return label
    }()
    
    lazy var sliderContentView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.clipsToBounds = false
        return view
    }()
    
    lazy var sliderBottomView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.fromHex("#E8E8F0")
        view.layerCornerRadius = 2
        return view
    }()
    
    lazy var slider: UISlider = {
        let v = UISlider()
        v.minimumValue = 0
        v.maximumValue = 1
        v.value = 0.5
        v.minimumTrackTintColor = UIColor.clear
        v.maximumTrackTintColor = UIColor.clear
        v.setThumbImage(UIImage(named: "scale_icon"), for: .normal)
        v.setThumbImage(UIImage(named: "scale_icon"), for: .highlighted)
        return v
    }()
    
    lazy var defaultDot: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.text_highlight
        v.layer.cornerRadius = 2
        v.layer.masksToBounds = true
        return v
    }()
    
    override func buildUI() {
        backgroundColor = UIColor.white
        
        addSubview(leftLable)
        addSubview(rightLable)
        addSubview(sliderContentView)
        sliderContentView.addSubview(sliderBottomView)
        sliderContentView.addSubview(defaultDot)
        sliderContentView.addSubview(slider)
        
        setupConstraints()
    }
    
    func setupConstraints() {
        leftLable.snp.makeConstraints {
            $0.top.equalTo(22)
            $0.left.equalTo(24)
        }
        
        rightLable.snp.makeConstraints {
            $0.top.equalTo(16)
            $0.right.equalTo(-24)
        }
        
        sliderContentView.snp.makeConstraints {
            $0.height.equalTo(24)
            $0.top.equalTo(46)
            $0.left.equalTo(24)
            $0.right.equalTo(-24)
        }
        
        sliderBottomView.snp.makeConstraints {
            $0.height.equalTo(4)
            $0.centerY.equalToSuperview()
            $0.left.right.equalToSuperview()
        }
        
        slider.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.right.equalToSuperview()
        }
                
        defaultDot.snp.makeConstraints {
            $0.width.height.equalTo(4)
            $0.centerY.equalToSuperview()
            $0.centerX.equalToSuperview()
        }
    }
    
    func makeDefaultDot( _ defaultV: Float) {
        let min = slider.minimumValue
        let max = slider.maximumValue
        
        if defaultV >= min && defaultV <= max {
            let rate = CGFloat((defaultV - min) / (max - min))
            var allwidth = self.width
            if allwidth == 0 {
                allwidth = GPApp.screenWidth - 24*2
            }
            defaultDot.snp.remakeConstraints {
                $0.width.height.equalTo(4)
                $0.centerY.equalToSuperview()
                $0.left.equalTo(allwidth*rate + 10)
            }
        }
    }
}
