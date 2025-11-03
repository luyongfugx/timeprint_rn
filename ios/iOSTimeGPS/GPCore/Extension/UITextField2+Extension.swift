//
//  UITextField2+Extension.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/17.
//

import Foundation
import UIKit

extension UITextField {
    convenience init(text: String?, textColor: UIColor, textFont: UIFont?, placeholder: String?, placeholderColor: UIColor?, placeholderFont: UIFont?, returnKeyType: UIReturnKeyType = .done, keyboardType: UIKeyboardType? = nil, clearButtonMode: UITextField.ViewMode? = nil, enablesReturnKeyAutomatically: Bool? = nil) {
        self.init()
        self.text = text
        self.textColor = textColor
        self.font = textFont
        
        self.placeholder = placeholder
        if let color = placeholderColor, let font = placeholderFont {
            self.setPlaceholder(placeholderColor: color, placeholderFont: font)
        }
        
        self.returnKeyType = returnKeyType
        
        if let type = keyboardType {
            self.keyboardType = type
        }
        
        if let tempMode = clearButtonMode {
            self.clearButtonMode = tempMode
        }
        
        // 当输入框没有文字的时候，右下角按钮自动致灰
        if let isEnble = enablesReturnKeyAutomatically {
            self.enablesReturnKeyAutomatically = isEnble
        }
    }
    
    /// 设置placeholder的颜色和字体
    /// - Parameters:
    ///   - placeholderColor: 颜色
    ///   - placeholderFont: 字体
    func setPlaceholder(placeholderColor: UIColor, placeholderFont: UIFont) {
        if let placeholderStr = self.placeholder, placeholderStr.count > 0 {
            self.attributedPlaceholder = NSAttributedString(string: placeholderStr, attributes: [NSAttributedString.Key.foregroundColor: placeholderColor, NSAttributedString.Key.font: placeholderFont])
        }
    }
    
    /// 给TextField设置左侧间距
    /// - Parameter amount: 间距值
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
    
    /// 给TextField设置右侧间距
    /// - Parameter amount: 间距值
    func setRightPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: self.frame.size.height))
        self.rightView = paddingView
        self.rightViewMode = .always
    }
    
    ///  在键盘上添加“完成”按钮
    /// - Parameters:
    ///   - target: 响应者
    ///   - action: 事件
    func addFinishButtonToKeyboard(target: Any?, action: Selector?) {
        let toobar = UIToolbar(frame: CGRect(x: 0, y: 0, width: GPApp.screenWidth, height: 38))
        toobar.isTranslucent = true
        toobar.barStyle = .default
        
        let spaceBarButtonItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        let doneBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: target, action: action)
        toobar.setItems([spaceBarButtonItem, doneBarButtonItem], animated: true)
        self.inputAccessoryView = toobar
    }
}
