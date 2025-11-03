//
//  UIView.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/18.
//

import Foundation
import UIKit

// MARK: UIView的构造和函数
public extension UIView {
    
    convenience init(backgroundColor: UIColor = UIColor.white, cornerRadius: CGFloat? = nil) {
        self.init()
        self.backgroundColor = backgroundColor
        
        if let radius = cornerRadius {
            self.layerCornerRadius = radius
        }
    }

    // 设置边框线颜色
    func setBorder(color: UIColor, width: CGFloat = 1.0) {
        self.layer.masksToBounds = true
        self.layer.borderColor = color.cgColor
        self.layer.borderWidth = width
    }
    
    //添加自定义圆角边框
    func addCustomCornerLayer(showTopTwoCorner:Bool,radius:CGFloat, colorStr:String = "#D0021B", boderW:CGFloat = 1) {
        
        let path = UIBezierPath()
        path.lineWidth = boderW
        if showTopTwoCorner == true {
            // 左上角
            path.move(to: CGPoint(x:0, y:radius))
            path.addQuadCurve(to: CGPoint(x:radius, y:0), controlPoint: CGPoint(x:radius, y:radius))
            // 右上角
            path.addLine(to: CGPoint(x:width-radius, y:0))
            path.addQuadCurve(to: CGPoint(x:width, y:radius), controlPoint: CGPoint(x:width-radius, y:radius))
            // 右下角
            path.addLine(to: CGPoint(x:width, y:height))
            // 左下角
            path.addLine(to: CGPoint(x:0, y:height))
        } else {
            
            path.move(to: CGPoint(x:0, y:0))
            path.addLine(to: CGPoint(x:width, y:0))
            path.addLine(to: CGPoint(x:width, y:height-radius))
            
            // 右下角
            path.addQuadCurve(to: CGPoint(x:width-radius, y:height), controlPoint:CGPoint(x:width-radius, y:height-radius))
            
            // 左下角
            path.addLine(to: CGPoint(x:radius, y:height))
            path.addQuadCurve(to: CGPoint(x:0, y:height-radius), controlPoint: CGPoint(x:radius, y:height-radius))
        }
        
        path.close()
        
        let boderLayer = CAShapeLayer()
        boderLayer.path = path.cgPath
        boderLayer.fillColor = UIColor.white.cgColor
        boderLayer.lineWidth = boderW
        boderLayer.strokeColor = UIColor.fromHex(colorStr).cgColor
        self.layer.insertSublayer(boderLayer, at: 0)
    }

    /// 添加阴影
    ///
    /// - Parameters:
    ///   - color: shadow color (default is #137992).
    ///   - radius: shadow radius (default is 3).
    ///   - offset: shadow offset (default is .zero).
    ///   - opacity: shadow opacity (default is 0.5).
    func addShadow(ofColor color: UIColor = UIColor(red: 0.07, green: 0.47, blue: 0.57, alpha: 1.0), radius: CGFloat = 3, offset: CGSize = .zero, opacity: Float = 0.5) {
        layer.shadowColor = color.cgColor
        layer.shadowOffset = offset
        layer.shadowRadius = radius
        layer.shadowOpacity = opacity
        layer.masksToBounds = false
    }
    
    /// 添加阴影
    /// - Parameters:
    ///   - radius: layer radius
    ///   - shadowColor: shadow color
    ///   - shadowOffset: shadow offset
    ///   - shadowRadius: shadow radius
    ///   - shadowOpacity: shadow opacity
    func addShadow(radius:CGFloat?=nil,shadowColor:UIColor?=nil,shadowOffset:CGSize?=nil,shadowRadius:CGFloat?=nil,shadowOpacity:Float?=1.0){
        
        if radius != nil{
            layer.cornerRadius = radius!
            layer.masksToBounds = true
        }
        
        if shadowColor != nil{
            layer.shadowColor = shadowColor!.cgColor
        }
        
        if shadowOffset != nil{
            layer.shadowOffset = shadowOffset!
        }
        
        if shadowRadius != nil{
            layer.shadowRadius = shadowRadius!
        }

        layer.shadowOpacity = shadowOpacity ?? 1.0
        layer.masksToBounds = false
    }
    
    /// 添加颜色渐变
    ///
    /// - Parameters:
    ///   - colors: 颜色数组
    ///   - layerframe: 坐标
    ///   - startPoint: 开始值
    ///   - endPoint: 结束值
    func addGradualLayerWith(colors:Array<CGColor>,layerframe:CGRect,startPoint:CGPoint,endPoint:CGPoint) -> Void
    {
        let _gradientLayer = CAGradientLayer()
        _gradientLayer.startPoint = startPoint
        _gradientLayer.endPoint = endPoint
        _gradientLayer.frame = layerframe
        _gradientLayer.colors = colors
        self.layer.insertSublayer(_gradientLayer, at: 0)

    }
        
    // MARK: - 添加点击手势
    
    /// 添加点击手势
    /// - Parameters:
    ///   - target: 事件响应者
    ///   - action: 事件
    ///   - numberOfTapsRequired: 点击次数
    ///   - numberOfTouchesRequired: 手指个数
    /// - Returns:
    @discardableResult func addTapGestureRecognizer(target : Any?, action : Selector?, numberOfTapsRequired: Int = 1, numberOfTouchesRequired: Int = 1) -> UITapGestureRecognizer {
        
        let tapGesture = UITapGestureRecognizer.init(target: target, action: action)
        tapGesture.numberOfTapsRequired    = numberOfTapsRequired;
        tapGesture.numberOfTouchesRequired = numberOfTouchesRequired;
        tapGesture.cancelsTouchesInView    = true;
        tapGesture.delaysTouchesBegan      = true;
        tapGesture.delaysTouchesEnded      = true;
        
        self.addGestureRecognizer(tapGesture)
        self.isUserInteractionEnabled = true
        
        return tapGesture
    }
    
    // MARK: - 获取view的UIViewController
    func parentViewController() -> UIViewController?{
        for view in sequence(first: self.superview, next: {$0?.superview}){
            if let responder = view?.next{
                if responder.isKind(of: UIViewController.self){
                    return responder as? UIViewController
                }
            }
        }
        return nil
    }
    
    // MARK: - 空内容的抖动动画
    func shakeAnimation() {
        let lbl = self.layer
        let posLbl = lbl.position
        let x = CGPoint(x: posLbl.x + 5, y: posLbl.y)
        let y = CGPoint(x: posLbl.x - 5, y: posLbl.y)
        
        let animation = CABasicAnimation.init(keyPath: "position")
        animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        animation.fromValue = NSValue.init(cgPoint: x)
        animation.toValue = NSValue.init(cgPoint: y)
        animation.autoreverses = true
        animation.duration = 0.08
        animation.repeatCount = 3
        lbl.add(animation, forKey: nil)
    }
    
    // MARK: - 获取当前的viewController
    var currentViewController: UIViewController? {
        var next: UIView? = self
        while (next != nil) {
            if let nextResponder = next?.next as? UIViewController {
                return nextResponder
            }
            next = next?.superview
        }
        return nil
    }
    
    // 使用贝塞尔曲线设置圆角
    func setBezierCornerRadius(position: UIRectCorner, cornerRadius: CGFloat, roundedRect: CGRect) {
        
        let path = UIBezierPath(roundedRect:roundedRect, byRoundingCorners: position, cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        let layer = CAShapeLayer()
        layer.frame = roundedRect
        layer.path = path.cgPath
        self.layer.mask = layer
    }
    
    //将当前视图转为UIImage
    func screenshots() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        return renderer.image { (rendererContext) in
            layer.render(in: rendererContext.cgContext)
        }
    }
    
    func addOutSideBorder(with viewFrame: CGRect, borderColor: UIColor, borderWidth: CGFloat) {
        
        let outSideLayer = CALayer()
        
        outSideLayer.frame = CGRect(x: viewFrame.minX - borderWidth, y: viewFrame.minY - borderWidth, width: viewFrame.width + 2 * borderWidth, height: viewFrame.height + 2 * borderWidth)
        outSideLayer.masksToBounds = true
        outSideLayer.cornerRadius = layer.cornerRadius + borderWidth
        outSideLayer.borderWidth = borderWidth
        outSideLayer.borderColor = borderColor.cgColor
        layer.addSublayer(outSideLayer)
    }
    
    /// 添加颜色渐变
    ///
    /// - Parameters:
    ///   - colors: 颜色数组
    ///   - layerframe: 坐标
    ///   - startPoint: 开始值
    ///   - endPoint: 结束值
    func addGradientLayer(colors:Array<CGColor>, locations: Array<NSNumber>, layerframe:CGRect,startPoint:CGPoint,endPoint:CGPoint) -> Void
    {
        let _gradientLayer = CAGradientLayer()
        _gradientLayer.startPoint = startPoint
        _gradientLayer.endPoint = endPoint
        _gradientLayer.frame = layerframe
        _gradientLayer.colors = colors
        _gradientLayer.locations = locations
        self.layer.insertSublayer(_gradientLayer, at: 0)
    }
}

extension UIView {
    
    // 按钮点击动画
    func viewClickAnimation() {
        
        let fadeOut1 = CABasicAnimation(keyPath: "transform.scale")
        fadeOut1.duration = 0.1
        fadeOut1.beginTime = 0 // 0.3+1.0
        fadeOut1.fromValue = 1.0
        fadeOut1.toValue = 0.9
        let animateGroup = CAAnimationGroup()
        animateGroup.duration = 0.1 // 0.3+1+0.3
        animateGroup.animations = [fadeOut1]
        animateGroup.fillMode = CAMediaTimingFillMode.forwards
        animateGroup.isRemovedOnCompletion = true
        self.layer.add(animateGroup, forKey: "hint")
    }
}

extension UIView {
    
    func removeInternalDashedBorderAnimation() {
        // 移除旧图层
        layer.sublayers?
            .filter { $0.name == "InternalDashedBorder" }
            .forEach { $0.removeFromSuperlayer() }
    }
    
    func addInternalDashedBorderAnimation() {
        
        removeInternalDashedBorderAnimation()
        
        let dashedLayer = CAShapeLayer().then {
            $0.name = "InternalDashedBorder"
            $0.strokeColor = UIColor(red: 1.0, green: 0.8, blue: 0, alpha: 0.8).cgColor
            $0.fillColor = nil
            $0.lineWidth = 2
            $0.lineDashPattern = [6, 4]
            $0.lineCap = .round  // 使虚线端点更圆润
            
            // 关键调整：使用视图原始边界
            let path = UIBezierPath(
                roundedRect: bounds.insetBy(
                    dx: $0.lineWidth/2,
                    dy: $0.lineWidth/2
                ),
                cornerRadius: layer.cornerRadius
            )
            $0.path = path.cgPath
        }
        
        layer.addSublayer(dashedLayer)
        
        // 配置动画
        let fadeAnimation = CABasicAnimation(keyPath: "opacity").then {
            $0.fromValue = 1.0
            $0.toValue = 0.0
            $0.duration = 0.5
            $0.autoreverses = true
            $0.repeatCount = 2  // 完整循环两次（淡入淡出 × 2）
            
            // 动画完成处理
            $0.delegate = AnimationHandler {
                dashedLayer.removeFromSuperlayer()
            }
        }
        
        dashedLayer.add(fadeAnimation, forKey: nil)
    }
}

// 动画代理封装
private class AnimationHandler: NSObject, CAAnimationDelegate {
    let completion: () -> Void
    
    init(_ completion: @escaping () -> Void) {
        self.completion = completion
        super.init()
    }
    
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard flag else { return }
        completion()
    }
}

// 语法糖扩展
private extension NSObject {
    func then(_ configure: (Self) -> Void) -> Self {
        configure(self)
        return self
    }
}
