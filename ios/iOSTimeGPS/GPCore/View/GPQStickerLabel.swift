//
//  GPQStickerLabel.swift
//  XCamera_global
//
//  Created by
//  Copyright © 2024 xhey. All rights reserved.
//

import UIKit

@IBDesignable
class GPQStickerLabel: UILabel {

    @IBInspectable var xShadowOffset = CGSize.zero {
        didSet {
            layer.shadowOffset = xShadowOffset
        }
    }

    @IBInspectable var xShadowColor = UIColor.black {
        didSet {
            layer.shadowColor = xShadowColor.cgColor
        }
    }

    @IBInspectable var xShadowRadius: CGFloat = 0 {
        didSet {
            layer.shadowRadius = xShadowRadius
        }
    }

    @IBInspectable var xShadowOpacity: Float = 0 {
        didSet {
            layer.shadowOpacity = xShadowOpacity
        }
    }

    @IBInspectable var isStroke: Bool = false
    @IBInspectable var strokeColor: UIColor = .black
    @IBInspectable var strokeWidth: CGFloat = 0

    @IBInspectable var leftInset: CGFloat = 0
    @IBInspectable var topInset: CGFloat = 0
    @IBInspectable var rightInset: CGFloat = 0
    @IBInspectable var bottomInset: CGFloat = 0

    var isAddShodow: Bool = false
    var shouldOffsetContextDrawStartPointByStrokeWidth: Bool = false

    // 添加描边阴影
    func setLabShadow() {
        isAddShodow = true
    }

    override var text: String? {
        didSet {
            customAttributedText()
        }
    }

    // V2.9.213:自定义属性文字
    func customAttributedText() {

        if isAddShodow == true {
            let shadow = NSShadow()
            shadow.shadowColor = UIColor.fromHex("#000000", alpha: 0.4)
            shadow.shadowOffset = CGSize(width: 0.4, height: 0.5) // 设置阴影大小
            shadow.shadowBlurRadius = 2

            var attri_string = NSMutableAttributedString()
            if let oldAttributedText = attributedText {
                attri_string = NSMutableAttributedString(attributedString: oldAttributedText)
            } else {
                attri_string = NSMutableAttributedString(string: text ?? "")
            }
            // attri_string.addAttribute(NSAttributedString.Key.strokeWidth, value: -0.5, range: NSMakeRange(0, attri_string.length))
            // attri_string.addAttribute(NSAttributedString.Key.strokeColor, value: UIColor.black.withAlphaComponent(1), range: NSMakeRange(0, attri_string.length))
            attri_string.addAttribute(NSAttributedString.Key.shadow, value: shadow, range: NSMakeRange(0, attri_string.length))
            attributedText = attri_string
        } else {
            // self.attributedText = NSMutableAttributedString()
        }
    }

//    func changeFontModel(_ fontModel: XHLabelModel) {
//
//        if fontModel.font != nil {
//            font = fontModel.font
//        }
//        if fontModel.message != nil {
//            text = fontModel.message
//        }
//        if fontModel.fontColor != nil {
//            textColor = fontModel.fontColor
//        }
//        if fontModel.textAlignment != nil {
//            textAlignment = fontModel.textAlignment!
//        }
//
//        isStroke = fontModel.isStroke
//        strokeColor = fontModel.strokeColor
//        strokeWidth = fontModel.strokeWidth
//
//        leftInset = fontModel.leftInset
//        topInset = fontModel.topInset
//        rightInset = fontModel.rightInset
//        bottomInset = fontModel.bottomInset
//
//        xShadowOffset = fontModel.xShadowOffset
//        xShadowColor = fontModel.xShadowColor
//        xShadowRadius = fontModel.xShadowRadius
//        xShadowOpacity = fontModel.xShadowOpacity
//    }
//
//    func createFontModel() -> XHLabelModel {
//        return XHLabelModel(xShadowOffset: xShadowOffset,
//                            xShadowColor: xShadowColor,
//                            xShadowRadius: xShadowRadius,
//                            xShadowOpacity: xShadowOpacity,
//                            isStroke: isStroke,
//                            strokeColor: strokeColor,
//                            strokeWidth: strokeWidth,
//                            leftInset: leftInset,
//                            topInset: topInset,
//                            rightInset: rightInset,
//                            bottomInset: bottomInset,
//                            font: font,
//                            message: text,
//                            fontColor: textColor,
//                            textAlignment: textAlignment)
//    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        var rect = super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines)
        rect.origin.x -= leftInset
        rect.origin.y -= topInset
        rect.size.width += rightInset + leftInset
        rect.size.height += topInset + bottomInset
        return rect
    }

    private var maskColor = UIColor.black

    private var glowSize: CGFloat = 1.0
    private var glowColor: UIColor = .red

    enum XHLabelOrientation: Int {
        case left = 0
        case right = 1
        case bottomLeft = 2
        case bottomRight = 3
    }

    private var subjectColor: UIColor = .white
    private var drawDepth: Int = 8
    private var bottomBlurColor: UIColor = .black
    private var orientation: XHLabelOrientation = .left

    override func draw(_ rect: CGRect) {
        guard isStroke else {
            super.draw(rect)
            return
        }

        guard let context: CGContext = UIGraphicsGetCurrentContext() else {
            return
        }

        // 描边
        let shadowOffset = self.shadowOffset
        defer {
            self.shadowOffset = shadowOffset
        }

        let textColor = self.textColor

        context.setLineWidth(strokeWidth)
        context.setLineJoin(.round)
        context.setTextDrawingMode(.stroke)
        self.textColor = strokeColor
        if shouldOffsetContextDrawStartPointByStrokeWidth {
            drawText(in: rect.offsetBy(dx: strokeWidth / 2, dy: 0))
        } else {
            drawText(in: rect)
        }

        context.setTextDrawingMode(.fill)
        self.textColor = textColor
        self.shadowOffset = CGSize(width: 0, height: 0)
        if shouldOffsetContextDrawStartPointByStrokeWidth {
            drawText(in: rect.offsetBy(dx: strokeWidth / 2, dy: 0))
        } else {
            drawText(in: rect)
        }
    }
}
