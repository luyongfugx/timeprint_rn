//
//  UIView+BCFrame.swift
//  XCamera
//
//  Created by 管理员 Cc on 2021/1/7.
//  Copyright © 2021 xhey. All rights reserved.
//

import UIKit

public extension UIView{
    
    var x : CGFloat {
        get {
            return frame.origin.x
        }
        set(newVal) {
            var tmpFrame : CGRect = frame
            tmpFrame.origin.x     = newVal
            frame                 = tmpFrame
        }
    }
    
    // y
    var y : CGFloat {
        get {
            return frame.origin.y
        }
        set(newVal) {
            var tmpFrame : CGRect = frame
            tmpFrame.origin.y     = newVal
            frame                 = tmpFrame
        }
    }
    
    // height
    var height : CGFloat {
        get {
            return frame.size.height
        }
        set(newVal) {
            var tmpFrame : CGRect = frame
            tmpFrame.size.height  = newVal
            frame                 = tmpFrame
        }
    }
    
    // width
    var width : CGFloat {
        get {
            return frame.size.width
        }
        set(newVal) {
            
            var tmpFrame : CGRect = frame
            tmpFrame.size.width   = newVal
            frame                 = tmpFrame
        }
    }
    
    // left
    var left : CGFloat {
        get {
            return x
        }
        set(newVal) {
            x = newVal
        }
    }
    
    // right
    var right : CGFloat {
        get {
            return x + width
        }
        set(newVal) {
            x = newVal - width
        }
    }
    
    // top
    var top : CGFloat {
        get {
            return y
        }
        set(newVal) {
            y = newVal
        }
    }
    
    // bottom
    var bottom : CGFloat {
        get {
            return y + height
        }
        set(newVal) {
            y = newVal - height
        }
    }
    
    var centerX : CGFloat {
        get {
            return center.x
        }
        set(newVal) {
            center = CGPoint(x: newVal, y: center.y)
        }
    }
    
    var centerY : CGFloat {
        get {
            return center.y
        }
        set(newVal) {
            center = CGPoint(x: center.x, y: newVal)
        }
    }
    
    var middleX : CGFloat {
        get {
            return width / 2
        }
    }
    
    var middleY : CGFloat {
        get {
            return height / 2
        }
    }
    
    var middlePoint : CGPoint {
        get {
            return CGPoint(x: middleX, y: middleY)
        }
    }
    
    
    var viewFrameX: CGFloat {
        set {
            self.frame = CGRect(x: newValue, y: self.viewFrameY, width:self.viewFrameWidth, height: self.viewFrameHeight)
        }
        
        get {
            return self.frame.origin.x
        }
    }
    
    var viewFrameY: CGFloat {
        set {
            self.frame = CGRect(x: self.viewFrameX, y: newValue, width: self.viewFrameWidth, height: self.viewFrameHeight)
        }
        
        get {
            return self.frame.origin.y;
        }
    }
    
    var viewFrameWidth: CGFloat {
        set {
            self.frame = CGRect(x: self.viewFrameX, y: self.viewFrameY, width: newValue, height: self.viewFrameHeight)
        }
        
        get {
            return self.frame.size.width;
        }
    }
    
    var viewFrameHeight: CGFloat {
        set {
            self.frame = CGRect(x: self.viewFrameX, y: self.viewFrameY, width: self.viewFrameWidth, height: newValue)
        }
        
        get {
            return self.frame.size.height;
        }
    }
    
    var viewCenterX: CGFloat {
        set{
            self.center = CGPoint(x: newValue, y: self.viewCenterY)
        }
        
        get {
            return self.center.x
        }
    }
    
    var viewCenterY: CGFloat {
        set {
            self.center = CGPoint(x: self.viewCenterX, y: newValue)
        }
        
        get {
            return self.center.y
        }
    }
    
    var viewXY: CGPoint {
        set {
            self.viewFrameX = newValue.x
            self.viewFrameY = newValue.y
        }
        
        get {
            return CGPoint(x: self.viewFrameX, y: self.viewFrameY)
        }
    }
    
    var viewSize: CGSize {
        set {
            self.viewFrameWidth = newValue.width
            self.viewFrameHeight = newValue.height
        }
        
        get {
            return CGSize(width: self.viewFrameWidth, height: self.viewFrameHeight)
        }
    }
    
    var viewRightX: CGFloat {
        get {
            return self.viewFrameX + self.viewFrameWidth;
        }
    }
    
    var viewBottomY: CGFloat {
        get {
            return self.viewFrameY+self.viewFrameHeight;
        }
    }
    
    var viewMidX: CGFloat {
        
        set {
            self.center = CGPoint(x: newValue, y: self.center.y)
        }
        
        get {
            return self.viewFrameX / 2
        }
    }
    
    var viewMidY: CGFloat {
        
        set {
            self.center = CGPoint(x: self.center.x, y: newValue)
        }
        
        get {
            return self.viewFrameY / 2
        }
    }
    
    var viewMidWidth: CGFloat {
        get {
            return self.viewFrameWidth / 2
        }
    }
    
    var viewMidHeight: CGFloat {
        get {
            return self.viewFrameHeight / 2
        }
    }
    
    var viewMidWidthAndHeight: CGPoint {
        get {
            return CGPoint(x: self.viewMidWidth, y: self.viewMidHeight)
        }
    }
    
    // 设置圆角
    var layerCornerRadius: CGFloat {
        set {
            self.layer.masksToBounds = true
            self.layer.cornerRadius = newValue
        }
        
        get {
            return self.layer.cornerRadius
        }
    }
    
    func forceRefresh() {
        setNeedsLayout()
        layoutIfNeeded()
    }
}

