//
//  AutoResizeButton.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/8.
//

import Foundation
import UIKit

open class AutoResizeButton : GPButton {
    
    lazy var textLabel2: UILabel = {
        var label = UILabel()
        label.textColor = .black
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    public init(_ padding: CGFloat = 10) {
        super.init(frame: .zero)
        addSubview(textLabel2)
        
        textLabel2.translatesAutoresizingMaskIntoConstraints = false
        let labelTop = NSLayoutConstraint.init(item: textLabel2, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1, constant: padding)
        self.addConstraint(labelTop)
        
        let labelLeft = NSLayoutConstraint.init(item: textLabel2, attribute: .left, relatedBy: .equal, toItem: self, attribute: .left, multiplier: 1, constant: padding)
        self.addConstraint(labelLeft)
        
        let labelBottom = NSLayoutConstraint.init(item: textLabel2, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1, constant: -padding)
        self.addConstraint(labelBottom)
        
        let labelRight = NSLayoutConstraint.init(item: textLabel2, attribute: .right, relatedBy: .equal, toItem: self, attribute: .right, multiplier: 1, constant: -padding)
        self.addConstraint(labelRight)

    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func setTitle(_ title: String?, for state: UIControl.State) {
        textLabel2.text = title
    }
    
    open override var titleLabel: UILabel? {
        return textLabel2
    }
    
    open override func setTitleColor(_ color: UIColor?, for state: UIControl.State) {
        textLabel2.textColor = color
    }
}
