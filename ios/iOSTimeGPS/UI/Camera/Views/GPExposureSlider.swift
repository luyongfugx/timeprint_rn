//
//  GPExposureSlider.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/28.
//

import Foundation
import UIKit

class GPExposureSlider: UIView {
    
    static let width: CGFloat = 40
    static let height: CGFloat = 128
    
    var progressCallback: ((_ progress: CGFloat)->())?
    
    var imageView: UIImageView?
    private let ballSize: CGFloat = 44
    private var imageMinstCenterY: CGFloat = 0
    private var imageMaxCenterY: CGFloat = 0
    
    
    deinit {
        LogDebug("GPExposureSlider -- deinit")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    
        var queImg = UIImage(named: "gp_exposure2")
        queImg = queImg?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        
        let _imageView = UIImageView.init(image: queImg)
        _imageView.tintColor = UIColor.yellow_color

        _imageView.frame =  CGRect(x: 0, y: 0, width: 29, height: 258)
        imageView = _imageView
        addSubview(_imageView)
        _imageView.center = CGPoint(x: GPExposureSlider.width / 2, y: GPExposureSlider.height / 2)
        
        imageMinstCenterY = ballSize * 0.5
        imageMaxCenterY = height - ballSize * 0.5
        
        backgroundColor = UIColor.clear
        layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func panGestureAction(_ gesture: UIPanGestureRecognizer) {
        
        guard let gestureView = gesture.view else { return }
        
        let transOffsetY = gesture.translation(in: gestureView).y * 0.4
        
        var imageCenterY = imageView!.centerY
        imageCenterY += transOffsetY
        
        
        if imageCenterY <= imageMinstCenterY {
            imageCenterY = imageMinstCenterY
        }
        if imageCenterY >= imageMaxCenterY {
            imageCenterY = imageMaxCenterY
        }
        
        imageView?.centerY = imageCenterY

        let progress = 1 - (imageCenterY - imageMinstCenterY) / (height - ballSize)
        
        progressCallback?(progress)
        
        gesture.setTranslation(.zero, in: gestureView)
    }
}
