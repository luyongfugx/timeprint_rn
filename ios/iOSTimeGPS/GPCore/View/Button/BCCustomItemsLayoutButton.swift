//
//  BCCustomItemsLayoutButton.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/3.
//

import UIKit

public typealias BCCustomItemsLayoutHandle = (_ weakButton: BCCustomItemsLayoutButton?) -> ()


/// 自定义子View布局按钮
open class BCCustomItemsLayoutButton: GPButton {
    
    // 外部定义标题的位置
    open var titleRect: CGRect? {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    // 外部定义图片的位置
    open var imageRect: CGRect? {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    public var subviewLayoutHandle: BCCustomItemsLayoutHandle?
    
    // 便利构造方法，在外面设置frame
    public convenience init(type buttonType: UIButton.ButtonType ,_ subviewLayoutHandle:@escaping BCCustomItemsLayoutHandle){
        
        self.init(type: buttonType)
        
        self.disableMultipleClickTimeInterval = 0.25
        self.subviewLayoutHandle = subviewLayoutHandle
    }
    
    // 便利构造方法，在里面设置frame
    public convenience init(titleRect: CGRect?, imageRect: CGRect?, title: String?, titleColor: UIColor?, titleFont: UIFont?, imageName: String? = nil, imageColor: UIColor? = nil, backgroundColor: UIColor? = nil, cornerRadius: CGFloat? = nil, textAlignment: NSTextAlignment? = nil) {
        
        self.init()
        
        self.disableMultipleClickTimeInterval = 0.25
        
        self.titleRect = titleRect
        self.imageRect = imageRect
        
        self.btnTitle = title
        self.titleColor = titleColor
        self.titleFont = titleFont
        
        if let name = imageName, name.count > 0 {
            if let color = imageColor {
                if let img = UIImage(named: name)?.tint(with: color) {
                    setImage(img, for: .normal)
                }
            } else {
                if let img = UIImage(named: name) {
                    setImage(img, for: .normal)
                }
            }
        }
        
        if let bgColor = backgroundColor {
            self.backgroundColor = bgColor
        }
        
        if let radius = cornerRadius {
            self.layerCornerRadius = radius
        }
        
        if let alignment = textAlignment {
            self.titleLabel?.textAlignment = alignment
        }
    }
    
    open override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        
        if let rect = self.imageRect {
            return rect
        }
        return super.imageRect(forContentRect: contentRect)
    }
    
    open override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        if let rect = self.titleRect {
            return rect
        }
        return super.titleRect(forContentRect: contentRect)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if let handler = subviewLayoutHandle {
            weak var weakSelf = self
            handler(weakSelf)
        }
    }
}

