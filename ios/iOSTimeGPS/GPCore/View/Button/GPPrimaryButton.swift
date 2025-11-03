//
//  GPPrimaryButton.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/13.
//

import UIKit

class GPPrimaryButton: GPButton {
    
    enum PrimaryButtonState {
        /// 正常状态
        case normal
        /// 点击状态
        case pressed
        /// 不可用状态
        case disabled
        
        /// 不同状态下的按钮背景色
        var backgroundColor: UIColor? {
            switch self {
            case .normal: return .btnprimary_normal
            case .pressed: return .btnprimary_press
            case .disabled: return .btnprimary_disable
            }
        }
    }
    
    private var buttonState: PrimaryButtonState = .normal {
        didSet {
            backgroundColor = buttonState.backgroundColor
        }
    }
    
    var sizeMode: ButtonSizeMode = .large {
        didSet {
            titleLabel?.font = sizeMode.font
        }
    }
    
    override var isEnabled: Bool {
        didSet {
            buttonState = isEnabled ? .normal : .disabled
            enabledObserver?(isEnabled)
        }
    }

    var enabledObserver: ((Bool) -> Void)?
    
    init(frame: CGRect = .zero, title: String = "", icon: UIImage? = nil, sizeMode: ButtonSizeMode = .large, iconTextSpace: CGFloat = 8) {
        super.init(frame: frame, style: .imageLeftTextRight(iconTextSpace, icon, .init(title: title, font: nil, titleColor: .white)))
        
        self.buttonState = .normal
        self.sizeMode = sizeMode
        
        layer.cornerRadius = 4

        backgroundColor = buttonState.backgroundColor
        titleLabel?.font = sizeMode.font

        addTarget(self, action: #selector(buttonTouchDown), for: .touchDown)
        addTarget(self, action: #selector(buttonTouchUp), for: [.touchCancel, .touchDragExit, .touchUpInside, .touchUpOutside])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@objc private extension GPPrimaryButton {
    
    func buttonTouchDown() {
        self.buttonState = .pressed
    }
    
    func buttonTouchUp() {
        self.buttonState = .normal
    }
}
