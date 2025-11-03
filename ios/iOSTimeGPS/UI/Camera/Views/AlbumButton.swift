//
//  AlbumButton.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/19.
//

import Foundation
import UIKit
class AlbumButton: GPButton {
    
    var iconLabel: UILabel = {
        let label = UILabel.iconLabel(fontSize: CameraBottomView.albumWidth, labelWidth: CameraBottomView.albumWidth, iconType: IconFontType.btn_album)
        label.textAlignment = .center
        label.textColor = .white
        label.centerX = CameraBottomView.albumWidth/2.0
        label.centerY = CameraBottomView.albumWidth/2.0
        return label
    }()
    
    override func buildUI() {
        backgroundColor = .clear
        layerCornerRadius = 4
        addSubview(iconLabel)
    }
    
    func updateImage(img: UIImage?) {
        guard let img = img else { return }
        iconLabel.isHidden = true
        setImage(img, for: .normal)
        imageView?.contentMode = .scaleAspectFill
        
        // 放大动画
        addAnimation()
    }
    
    private func addAnimation() {
        
        let fadeOut1 = CABasicAnimation(keyPath: "transform.scale")
        fadeOut1.duration = 0.2
        fadeOut1.beginTime = 0 // 0.3+1.0
        fadeOut1.fromValue = 1.5
        fadeOut1.toValue = 1.0
        
        let animateGroup = CAAnimationGroup()
        animateGroup.duration = 0.2 // 0.3+1+0.3
        animateGroup.animations = [fadeOut1]
        animateGroup.fillMode = CAMediaTimingFillMode.forwards
        animateGroup.isRemovedOnCompletion = false
        self.imageView?.layer.add(animateGroup, forKey: "hint")
    }
    
}
