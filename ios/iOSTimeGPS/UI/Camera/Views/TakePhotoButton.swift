//
//  TakePhotoButton.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/19.
//

import Foundation
import UIKit

enum TakePhotoButtonState {
    case photoNormal
    case videoNormal
    case videoRecording
}

class TakePhotoButton: GPButton {
     
    private var buttonState: TakePhotoButtonState = .photoNormal
    private static var centerViewWidth = 58.0
    private let redColor = UIColor(red: 233/255.0, green: 77/255.0, blue: 62/255.0, alpha: 1)
    
    var centerView: GPView = {
        let v = GPView(frame: .zero)
        v.isUserInteractionEnabled = false
        v.backgroundColor = .white
        v.layerCornerRadius = TakePhotoButton.centerViewWidth/2.0
        return v
    }()
    
    override func buildUI() {
        backgroundColor = .clear
        setBorder(color: .white, width: 4)

        addSubview(centerView)
        centerView.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: TakePhotoButton.centerViewWidth, height: TakePhotoButton.centerViewWidth))
            make.center.equalToSuperview()
        }
        
    }
    
    func updateState(state: TakePhotoButtonState) {
        switch state {
        case .photoNormal:
            centerView.backgroundColor = .white
            showNormalImage(canShow: true)
        case .videoNormal:
            if buttonState == .videoRecording {
                // 动画恢复正常
                UIView.animate(withDuration: 0.3) {
                    self.centerView.snp.remakeConstraints { make in
                        make.size.equalTo(CGSize(width: TakePhotoButton.centerViewWidth, height: TakePhotoButton.centerViewWidth))
                        make.center.equalToSuperview()
                    }
                } completion: { finish in
                    //
                    self.centerView.layerCornerRadius = TakePhotoButton.centerViewWidth/2.0
                }
            }
            centerView.backgroundColor = redColor
            showNormalImage(canShow: false)
        case .videoRecording:
            if buttonState == .videoNormal {
                // 动画
                UIView.animate(withDuration: 0.3) {
                    self.centerView.snp.remakeConstraints { make in
                        make.size.equalTo(CGSize(width: 26, height: 26))
                        make.center.equalToSuperview()
                    }
                } completion: { finish in
                    //
                    self.centerView.layerCornerRadius = 4
                }
            }
            centerView.backgroundColor = redColor
            showNormalImage(canShow: false)
            break
        }
        buttonState = state
    }
    
    func showNormalImage(canShow: Bool) {
        if canShow {
            centerView.isHidden = true
            setBorder(color: .clear, width: 0)
            setImage(UIImage(named: "take_photo_btn_white2"), for: .normal)
        } else {
            centerView.isHidden = false
            setBorder(color: .white, width: 4)
            setImage(nil, for: .normal)
        }
    }
}
