//
//  UILabel+Extension.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/1.
//

import Foundation
import UIKit

extension UILabel {
    
    class func iconLabel(fontSize: CGFloat, labelWidth: CGFloat, iconType: IconFontType) -> UILabel {
        let label = UILabel(frame: .init(x: 0, y: 0, width: labelWidth, height: labelWidth))
        label.font = UIFont.iconfont(fontSize)
        label.text = iconType.rawValue
        return label
    }
    
    class func chooseIconLabel(fontSize: CGFloat, labelWidth: CGFloat) -> UILabel {
        let label = UILabel(frame: .init(x: 0, y: 0, width: labelWidth, height: labelWidth))
        label.font = UIFont.iconfont(fontSize)
        label.textColor = .systemBlue
        label.text = IconFontType.icon_choose.rawValue
        return label
    }
    
    func textGradient(colors: [UIColor], start: CGPoint, end: CGPoint, locations: [NSNumber]? = nil) {
        if frame.size.width == 0 || frame.size.height == 0 {
            return
        }
        
        if let testImage = UIImage.imageWithGradientColors(
            colors: colors,
            size: (frame.size),
            startPoint: start,
            endPoint: end,
            locations: locations
        ) {
            textColor = UIColor(patternImage: testImage)
        }
    }
    
    
    /*
     // 文字渐变色
     解决因为关闭定位后，返回的self.frame是CGRect.zero导致的崩溃，导火索是self.frame是CGRect.zero,
     本质原因是class func imageWithView(_ view : UIView, compressionQuality : CGFloat) -> UIImage?方法中的强制解包
     V2.9.183版本对CGRect.zero的这种情况作了容错处理，对上述方法中强制解包作了修改；
     */
    func textGradient(colors: [UIColor]) {
        
        // XHLogDebug("[设置渐变色调试] - frame:[\(self.frame)]")
        if self.frame.size.width == 0 || self.frame.size.height == 0 {
            return
        }
        
        if let testImage = UIImage.imageWithGradientColors(colors: colors, size: (self.frame.size)) {
            self.textColor = UIColor.init(patternImage: testImage)
        }
    }
    
    func getOneLineSize() -> CGSize {
        let titleText = self.text ?? ""
        return titleText.size(WithFont: self.font , ConstrainedToWidth: GPApp.screenWidth)
    }
    
}
