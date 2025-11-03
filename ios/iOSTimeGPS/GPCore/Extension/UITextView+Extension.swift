//
//  UITextView+Extension.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/9/16.
//

import UIKit

extension UITextView {
    
    private static let kPlaceholderTag = 20240202
    
    var placeholder: String {
        set {
            if let lb = viewWithTag(UITextView.kPlaceholderTag) as? UILabel {
                lb.text = newValue
            } else {
                let lb = UILabel()
                lb.tag = UITextView.kPlaceholderTag
                lb.font = font
                lb.numberOfLines = 0
                lb.textColor = .lightGray
                lb.text = newValue
                addSubview(lb)
                setValue(lb, forKey: "_placeholderLabel")
            }
        }
        get {
            let lb = value(forKey: "_placeholderLabel") as? UILabel
            return lb?.text ?? ""
        }
    }
}
