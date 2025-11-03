//
//  GPWideAngleTipView.swift
//  XCamera
//

import UIKit

class GPWideAngleTipView: GPQStickerLabel {
    
    private var displayDuration: Double = 0
    private var timer: Timer?
    private var timerRepeat: Double = 0.1
    
    deinit {
        LogDebug("Timeprint CenterWideAngleValueTipView -- deinit")
    }
    
    class func tipView() -> GPWideAngleTipView {
        
        let view = GPWideAngleTipView(text: "", textColor: UIColor.white, textFont: UIFont.robotoCondensedRegular(36), textAlignment: .center)
        view.isStroke = true
        view.strokeColor = UIColor.black.withAlphaComponent(0.1)
        view.strokeWidth = 1
        return view
    }
        
    private func animateHidden(_ isHidden: Bool) {
        UIView.animate(withDuration: 0.1) {[weak self] in
            
            if self?.isHidden == isHidden{return}
            self?.isHidden = isHidden
        }
    }
    
    func updateScale(_ scale: CGFloat?) {
        
        guard let _scale = scale else {
            return
        }

        text = GPWideAngleTipView.scaleString(_scale) + "x"
        display(timeDuration: 0.6)
    }
    
    class func scaleString(_ scale: CGFloat) -> String {
        
        if scale < 1 {
            return "0.\(Int(floor(scale * 100)/10))"
        }
        
        var scaleText = String(format: "%.1f", scale)
        let coms = scaleText.components(separatedBy: ".")
        
        if coms.last == "0" {
            scaleText = coms.first ?? scaleText
        }
        
        return scaleText
    }
    
    func display(timeDuration: Double) {
        
        displayDuration = timeDuration
        animateHidden(false)
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: timerRepeat, target: self, selector: #selector(observeRetainCount(_:)), userInfo: nil, repeats: true)
    }

    @objc func observeRetainCount(_ timer: Timer) {

        displayDuration -= timerRepeat
        
        if displayDuration <= 0 {
            
            timer.invalidate()
            displayDuration = 0
            animateHidden(true)
        }
    }
    
}
