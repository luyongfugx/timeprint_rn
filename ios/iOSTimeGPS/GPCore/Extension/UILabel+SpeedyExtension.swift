//
//  UILabel+Extension.swift
//  XCamera
//
//  Created by batman on 2019/9/2.
//  Copyright © 2019 xhey. All rights reserved.
//

import UIKit

extension UILabel {
    // 设置渐变色
    func setGradientText(colors: [UIColor], startPoint: CGPoint = CGPoint(x: 0, y: 0.5), endPoint: CGPoint = CGPoint(x: 1, y: 0.5)) {
         // 确保 label 有文字和大小
         guard let text = self.text, !text.isEmpty else { return }
         self.layoutIfNeeded()

         // 创建渐变层
         let gradientLayer = CAGradientLayer()
         gradientLayer.frame = self.bounds
         gradientLayer.colors = colors.map { $0.cgColor }
         gradientLayer.startPoint = startPoint
         gradientLayer.endPoint = endPoint

         // 创建文字遮罩
         let textMask = CATextLayer()
         textMask.string = text
         textMask.font = self.font
         textMask.fontSize = self.font.pointSize
         textMask.frame = self.bounds
         textMask.alignmentMode = .center
         textMask.contentsScale = UIScreen.main.scale

         gradientLayer.mask = textMask

         // 移除旧的渐变层（避免重复叠加）
         self.layer.sublayers?.removeAll(where: { $0.name == "GradientTextLayer" })

         gradientLayer.name = "GradientTextLayer"
         self.layer.addSublayer(gradientLayer)
     }
    /// UILabel根据文字的需要的高度
    public var requiredHeight: CGFloat {
        let label = UILabel(frame: CGRect(
            x: 0,
            y: 0,
            width: frame.width,
            height: CGFloat.greatestFiniteMagnitude)
        )
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = font
        label.text = text
        label.attributedText = attributedText
        label.sizeToFit()
        return label.frame.height
    }
    
    /// UILabel根据文字实际的行数
    public var actualLines: Int {
        return Int(requiredHeight / font.lineHeight)
    }
    
    /// 便利构造方法
    convenience init(text: String?, textColor: UIColor?, textFont: UIFont?, textAlignment: NSTextAlignment? = nil, numberLines: Int? = nil, lineBreakMode: NSLineBreakMode? = nil, backgroundColor: UIColor? = nil, cornerRadius: CGFloat? = nil) {
        
        self.init()
        
        self.text = text
        self.textColor = textColor ?? UIColor.black
        self.font = textFont ?? UIFont.systemFont(ofSize: 17.0)
        
        if let ali = textAlignment {
            self.textAlignment = ali
        }
        
        if let number = numberLines {
            self.numberOfLines = number
        }
        
        if let bgColor = backgroundColor {
            self.backgroundColor = bgColor
        }
        
        if let radius = cornerRadius {
            self.layerCornerRadius = radius
        }
        
        if let mode = lineBreakMode {
            self.lineBreakMode = mode
        }
        
        self.clipsToBounds = false
    }
    
    /*
    // 文字渐变色
    func textGradient(colors: [UIColor]) {
        
        if let testImage = UIImage.imageWithGradientColors(colors: colors, size: (self.frame.size)) {
            self.textColor = UIColor.init(patternImage: testImage)
        }
    }
 */
    
    /*
     // 文字渐变色
     解决因为关闭定位后，返回的self.frame是CGRect.zero导致的崩溃，导火索是self.frame是CGRect.zero,
     本质原因是class func imageWithView(_ view : UIView, compressionQuality : CGFloat) -> UIImage?方法中的强制解包
     V2.9.183版本对CGRect.zero的这种情况作了容错处理，对上述方法中强制解包作了修改；
     */
//    func textGradient(colors: [UIColor]) {
//        
//        // LogDebug("[设置渐变色调试] - frame:[\(self.frame)]")
//        if self.frame.size.width == 0 || self.frame.size.height == 0 {
//            return
//        }
//        
//        if let testImage = UIImage.imageWithGradientColors(colors: colors, size: (self.frame.size)) {
//            self.textColor = UIColor.init(patternImage: testImage)
//        }
//    }
//    
//    // 限制宽度计算实际的行数
//    func actualLinesConstrainedToWidth(maxWidth: CGFloat) -> Int {
//        var height: CGFloat = 0
//        if let tempText = self.text {
//            height = tempText.size(WithFont: self.font, ConstrainedToWidth: maxWidth).height
//        }
//        return Int(height / font.lineHeight)
//    }
    
    // 限制宽度计算实际的高度
    func actualHeight(maxWidth: CGFloat,maxLine:Int = 0) -> CGFloat {
        let label = UILabel(frame: CGRect(
            x: 0,
            y: 0,
            width: maxWidth,
            height: CGFloat.greatestFiniteMagnitude)
        )
        label.numberOfLines = 0
        label.backgroundColor = backgroundColor
        label.lineBreakMode = lineBreakMode
        label.font = font
        label.text = text
        label.textAlignment = textAlignment
        label.numberOfLines = maxLine
        label.attributedText = attributedText
        label.sizeToFit()
        return label.frame.height
    }
    
    // 限制宽度计算实际的size
    func actualSize(maxWidth: CGFloat,maxLine:Int = 0) -> CGSize {
        let label = UILabel(frame: CGRect(
            x: 0,
            y: 0,
            width: maxWidth,
            height: CGFloat.greatestFiniteMagnitude)
        )
        label.numberOfLines = 0
        label.backgroundColor = backgroundColor
        label.lineBreakMode = lineBreakMode
        label.font = font
        label.text = text
        label.textAlignment = textAlignment
        label.numberOfLines = maxLine
        label.attributedText = attributedText
        label.sizeToFit()
        return label.frame.size
    }
    
    // 设置行高
    func setLineHeight(_ lineHeight: CGFloat) {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = lineHeight
        style.alignment = textAlignment
        style.lineBreakMode = .byWordWrapping
        
        let attributedText = NSAttributedString(string: self.text ?? "", attributes: [.kern: 0, .font: self.font ?? UIFont.systemFont(ofSize: 14), .foregroundColor: self.textColor ?? UIColor.black, .paragraphStyle: style])
        self.attributedText = attributedText
    }
}

