//
//  GPWideAngleView.swift
//  XCamera
//

import UIKit

class GPWideAngleView: UIButton {
    
    class var wideAngleFont: UIFont {
        UIFont.robotoCondensedRegular(13)
    }
    
    class var width: CGFloat {
        32 + borderWidth * 2
    }

    class var borderWidth: CGFloat {
        1.3
    }

    class func xhWideAngleView(needBorder: Bool = true) -> GPWideAngleView {
        
        let view = GPWideAngleView()
        view.titleLabel?.font = GPWideAngleView.wideAngleFont
        view.setTitleColor(UIColor.white, for: .normal)
        view.backgroundColor = UIColor.init(hex: "000000", 0.2)
        
        if needBorder {
            view.setBorder(color: UIColor.white, width: GPWideAngleView.borderWidth)
        }
        
        view.updateScale(1.0)
        
        return view
    }
    
    func updateScale(_ scale: CGFloat?) {
        
        guard let _scale = scale else{
            return
        }
        
        setTitle(String.init(format: _scale == 0.5 ? "0.5x".localized() : "\(GPWideAngleTipView.scaleString(_scale))x"), for: .normal)
    }
    
    func updateSelected(selected: Bool) {
        
        self.isSelected = selected
        setBorder(color: selected ? UIColor.white : UIColor.clear, width: GPWideAngleView.borderWidth)
    }
}
