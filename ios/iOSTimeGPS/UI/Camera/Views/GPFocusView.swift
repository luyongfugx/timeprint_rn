//
//  GPFocusView.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/28.
//

import Foundation
import UIKit

class GPFocusView: UIView {
    
    class var width: CGFloat {
        230
    }
    
    class var height: CGFloat {
        230
    }
    
    class var pointWH: CGFloat {
        68
    }

    private var progressCallback: ((_ progress: CGFloat)->())?
    
    weak var focusView: UIImageView?
    weak var expouseSlider: GPExposureSlider?
    
    private var displayDuration: Double = 0
    private var timer: Timer?
    private var timerRepeat: Double = 0.1
    private var isTimerPause: Bool = false
    var isInShowAnimage: Bool = false
    
    deinit {
        LogDebug("GPFocusView--deinit")
    }
    
    class func focusView(progressCallback: ((_ progress: CGFloat)->())?) -> GPFocusView {
        
        let view = GPFocusView()
        view.progressCallback = progressCallback
        view.buildUI()
        view.isHidden = true
        view.isUserInteractionEnabled = false
        return view
    }
    
    private func buildUI() {
        
        backgroundColor = UIColor.clear
        
        let _focusView = UIImageView.init(image: GPButton.createImage(size: .init(width: 66, height: 66), iconType: .cam_focus, imgColor: UIColor.yellow_color))
        _focusView.frame = CGRect(x: 90, y: (GPFocusView.height - GPFocusView.pointWH) * 0.5, width:GPFocusView.pointWH, height: GPFocusView.pointWH)
        focusView = _focusView
        addSubview(_focusView)
        
        let _expouseSlider = GPExposureSlider(frame: CGRect.init(x: _focusView.right + 12, y: (GPFocusView.height - GPExposureSlider.height)*0.5, width: GPExposureSlider.width, height: GPExposureSlider.height))
        _expouseSlider.progressCallback = {[weak self] progress in
            
            self?.progressCallback?(progress)
        }
        expouseSlider = _expouseSlider
        addSubview(_expouseSlider)
    }
    
    @objc func panGestureAction(_ gesture: UIPanGestureRecognizer) {
        
        guard let _ = gesture.view else { return }
        
        switch gesture.state {
        case .began, .changed: displayDuration = 2
        case .ended, .failed, .cancelled:
            resumeTimer()
        default:
            break
        }
        
        expouseSlider?.panGestureAction(gesture)
    }

    func updateDateFocusCenter(with point: CGPoint) {
            
        isHidden = false
        expouseSlider?.isHidden = false
        
        let isLeft = point.x <= GPApp.screenWidth * 0.5
        let focusXSpace: CGFloat = isLeft ? 44 : (width - 44 - GPFocusView.pointWH)
        
        focusView?.x = focusXSpace
        if isLeft {
            
            expouseSlider?.x = (focusView?.right ?? 0) + 6
            
        } else {
            expouseSlider?.x = (focusView?.left ?? 0) - 6 - GPExposureSlider.width
        }
        
        var centerTransfer =  point.x + (GPFocusView.width * 0.5 - GPFocusView.pointWH * 0.5 - 44)
        if !isLeft {
            centerTransfer = point.x - (GPFocusView.width * 0.5 - GPFocusView.pointWH * 0.5 - 44)
        }
        center = CGPoint.init(x: centerTransfer, y: point.y)
            
        if isInShowAnimage == false {
            
            isInShowAnimage = true
    //            layer.removeAllAnimations()
            focusView?.layer.add(animate(), forKey: "focusAnimation")
            // 延时以保证不重复展示动画
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.isInShowAnimage = false
            }
        }
        
        display(timeDuration: 2)
    }
    
    func animate() -> CABasicAnimation{
        
        let scalaAnimation = CABasicAnimation.init(keyPath: "transform.scale")
        scalaAnimation.fromValue = 2
        scalaAnimation.toValue = 1
        scalaAnimation.duration = 0.15
        scalaAnimation.beginTime = 0
        
        return scalaAnimation
    }
    
    func display(timeDuration: Double) {
        
        displayDuration = timeDuration
        expouseSlider?.imageView?.centerY = GPExposureSlider.height / 2
        
        animateHidden(false)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: timerRepeat, target: self, selector: #selector(observeRetainCount(_:)), userInfo: nil, repeats: true)
    }
    
    private func animateHidden(_ isHidden: Bool) {
        UIView.animate(withDuration: 0.1) {[weak self] in
            
            if self?.isHidden == isHidden {
                return
            }
            self?.isHidden = isHidden
        }
    }

    private func pauseTimer() {
        isTimerPause = true
    }
    
    private func resumeTimer() {
        isTimerPause = false
    }
    
    @objc func observeRetainCount(_ timer: Timer) {
        if isTimerPause {
            return
        }

        displayDuration -= timerRepeat
        
        if displayDuration <= 0 {
            
            timer.invalidate()
            displayDuration = 0
            animateHidden(true)
            
            expouseSlider?.imageView?.centerY = GPExposureSlider.height / 2
        }
    }

}
