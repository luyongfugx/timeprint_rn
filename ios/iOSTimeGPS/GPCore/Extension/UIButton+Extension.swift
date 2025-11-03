//
//  UIButton+Extension.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/3.
//

extension UIButton {
    
    var image: UIImage? {
        set {
            self.setImage(newValue, for: .normal)
        }
        
        get {
            return self.image(for: .normal)
        }
    }
    
    var backgroundImage: UIImage? {
        set {
            self.setBackgroundImage(newValue, for: .normal)
        }
        
        get {
            return self.backgroundImage(for: .normal)
        }
    }
    
    var btnTitle: String? {
        set {
            self.setTitle(newValue, for: .normal)
        }
        
        get {
            return self.title(for: .normal) ?? ""
        }
    }
    
    var titleColor : UIColor? {
        set {
            self.setTitleColor(newValue, for: .normal)
        }
        
        get {
            return self.titleColor(for: .normal)
        }
    }
    
    var titleFont : UIFont? {
        set {
            self.titleLabel?.font = newValue
        }
        
        get {
            return self.titleLabel?.font
        }
    }
    
    // title的对齐方式
    var titleAlignment: NSTextAlignment {
        
        set {
            self.titleLabel?.textAlignment = newValue
        }
        
        get {
            return self.titleLabel?.textAlignment ?? .center
        }
    }
    
    convenience init(title: String?, titleColor: UIColor?, titleFont: UIFont?, backgroundColor: UIColor? = nil, cornerRadius: CGFloat? = nil) {
        self.init()
        self.btnTitle = title
        self.titleColor = titleColor
        self.titleFont = titleFont
        
        if let bgColor = backgroundColor {
            self.backgroundColor = bgColor
        }
        
        if let radius = cornerRadius {
            self.layerCornerRadius = radius
        }
    }
    
    convenience init(imageName: String) {
        self.init()
        self.image = UIImage(named: imageName)
    }
    
    convenience init(normalImageName: String, selectImageName: String) {
        self.init()
        self.setImage(UIImage(named: normalImageName), for: .normal)
        self.setImage(UIImage(named: selectImageName), for: .selected)
        self.setImage(UIImage(named: selectImageName), for: .highlighted)
    }
    
    // 设置按钮的相关属性
    func setProperties(title: String?, titleColor: UIColor?, titleFont: UIFont?, backgroundColor: UIColor? = nil, cornerRadius: CGFloat? = nil) {
        self.btnTitle = title
        self.titleColor = titleColor
        self.titleFont = titleFont
        
        if let bgColor = backgroundColor {
            self.backgroundColor = bgColor
        }
        
        if let radius = cornerRadius {
            self.layerCornerRadius = radius
        }
    }
    
    // 设置按钮的图片
    func setBtnImage(normal: String, selected: String, highlighted: String) {
        
        self.setImage(UIImage(named: normal), for: .normal)
        self.setImage(UIImage(named: selected), for: .selected)
        self.setImage(UIImage(named: highlighted), for: .highlighted)
    }
    
    func setBtnBackgroundImage(normal: String, selected: String, highlighted: String) {
        
        self.setBackgroundImage(UIImage(named: normal), for: .normal)
        self.setBackgroundImage(UIImage(named: selected), for: .selected)
        self.setBackgroundImage(UIImage(named: highlighted), for: .highlighted)
    }
    
    // 设置按钮的标题
    func setBtnTitle(normal: String, selected: String, highlighted: String) {
        
        self.setTitle(normal, for: .normal)
        self.setTitle(selected, for: .selected)
        self.setTitle(highlighted, for: .highlighted)
    }
    
    // 设置按钮的标题的颜色
    func setBtnTitleColor(normal: UIColor, selected: UIColor, highlighted: UIColor) {
        
        self.setTitleColor(normal, for: .normal)
        self.setTitleColor(selected, for: .selected)
        self.setTitleColor(highlighted, for: .highlighted)
    }
}

import UIKit

extension UIButton {
    func setBackgroundColor(_ color: UIColor, forState state: UIControl.State) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setFillColor(color.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: state)
    }
}

