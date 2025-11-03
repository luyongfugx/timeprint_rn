//
//  GPEditLogoPositionView.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/6.
//

import Foundation
import UIKit

class GPEditLogoPositionView: GPView {
    
    var currentPosition: LogoPosition = .onWatermark {
        didSet {
            positionButtonList.forEach { btn in
                makeButtonChoose(btn)
            }
        }
    }
    
    var positionButtonList: [GPButton] = []
    
    var selectHandle: ((LogoPosition) -> Void)?
        
    override func buildUI() {
        let padding = 12.0
        var startX = padding + 8
        for position in [LogoPosition.onWatermark, LogoPosition.leftTop] {
            let btn = createButton(position)
            let buttonWidth = position.getTitle().size(WithFont: .systemFont(ofSize: 14), ConstrainedToWidth: GPApp.screenWidth).width + 12
            btn.frame = .init(x: startX, y: 0, width: buttonWidth, height: 32)
            addSubview(btn)
            startX = startX + padding + buttonWidth
            positionButtonList.append(btn)
        }
        
    }
    
    func createButton(_ position: LogoPosition) -> GPButton {
        let button = GPButton()
        button.backgroundColor = .white
        button.setBorder(color: .border_medium, width: 1)
        button.layer.cornerRadius = 4
        button.tag = position.rawValue
        button.setTitle(position.getTitle(), for: .normal)
        button.setTitleColor(.border_medium, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.titleEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 4)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.addTarget(self, action: #selector(didClickButton(sender:)), for: .touchUpInside)
        return button
    }
    
    @objc func didClickButton(sender: UIButton) {
        currentPosition = LogoPosition.init(rawValue: sender.tag) ?? LogoPosition.onWatermark
        selectHandle?(currentPosition)
    }

    private func makeButtonChoose(_ button: GPButton) {
        if button.tag == currentPosition.rawValue {
            button.setBorder(color: .text_highlight, width: 1)
            button.setTitleColor(.text_highlight, for: .normal)
        } else {
            button.setBorder(color: .border_medium, width: 1)
            button.setTitleColor(.text_black_color, for: .normal)
        }
    }
    
}
