//
//  UIColor+Extension.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/18.
//

import Foundation
import UIKit

public extension UIColor {
    
    static let yellow_color = UIColor.fromRGBA(248, g: 214, b: 73)
    static let theme_yellow_color = UIColor.fromRGBA(255, g: 220, b: 50)
    static let icon_green_color = UIColor.fromRGBA(69, g: 180, b: 99)
    static let icon_blue_color = UIColor.fromRGBA(0, g: 139, b: 249)
    static let text_black_color = UIColor.fromHex("222222")
    static let text_grey_color = UIColor.fromHex("999999")
    static let table_line_color = UIColor(hex: "#f0f0f0")
    static let button_blue = UIColor(hex: "#007AFF")
    // 系统按钮蓝色
    static let btnprimary_normal = UIColor(hex: "#0093ff")
    static let bg_default = UIColor(hex: "#f0f0f0")
    static let text_weak = UIColor(hex: "#848484")
    static let button_black = UIColor.fromRGBA(35, g: 35, b: 35)
    static let btnprimary_press = UIColor(hex: "#0084e5")
    static let btnsecondary_normal = UIColor(hex: "#ebf6ff")
    static let btnprimary_disable = UIColor(hex: "#C1E5FF")
    static let fill_blue = UIColor(hex: "#ebf6ff")
    static let text_highlight = UIColor(hex: "#0093ff")
    static let border_medium = UIColor(hex: "#dedede")
    static let location_color = UIColor.fromRGBA(237, g: 112, b: 45)
    static let cover_color = UIColor.fromRGBA(115, g: 123, b: 132)

    /// text_ultrastrong            一级文本（ 最重文本色）
    static let text_ultrastrong = UIColor(hex: "#222222")
    
    /// text_strong    #444444        二级文本（次级重文本色）
    static let text_strong = UIColor(hex: "#444444")
    
    /// text_medium    #666666        三级文本
    static let text_medium = UIColor(hex: "#666666")
        
    /// text_ultraweak    #999999        不可点击文本
    static let text_ultraweak = UIColor(hex: "#999999")
    
    /// text_white    #ffffff        白色文本
    static let text_white = UIColor(hex: "#ffffff")
        
    /// icon_ultraweak    #dedede        不可点击图标色
    static let icon_ultraweak = UIColor(hex: "#dedede")

    /// text_error    #ea4d3d         警示、错误提示文本
    static let text_error = UIColor(hex: "#ea4d3d")

    // Hex String -> UIColor
    convenience init(hex: String, _ alpha: CGFloat = 1.0) {
        
        let tempStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let hexint = UIColor.intFromHexString(tempStr)
        self.init(red: ((CGFloat) ((hexint & 0xFF0000) >> 16))/255, green: ((CGFloat) ((hexint & 0xFF00) >> 8))/255, blue: ((CGFloat) (hexint & 0xFF))/255, alpha: alpha)
    }
    
    class func fromHex(_ hex: String, alpha: CGFloat = 1.0) -> UIColor{
        
        let tempStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let hexint = intFromHexString(tempStr)
        let color = UIColor(red: ((CGFloat) ((hexint & 0xFF0000) >> 16))/255, green: ((CGFloat) ((hexint & 0xFF00) >> 8))/255, blue: ((CGFloat) (hexint & 0xFF))/255, alpha: alpha)
        return color
    }
    
    // 通过rgb设置颜色
    class func fromRGBA(_ r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) -> UIColor {
        return UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }
    
    // UIColor -> Hex String
    var toHexString: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let multiplier = CGFloat(255.999999)
        
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        
        if alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier)
            )
        }
        else {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier),
                Int(alpha * multiplier)
            )
        }
    }
    
    /// 左右渐变色
    /// - Parameters:
    ///   - left: 左侧颜色
    ///   - right: 右侧颜色
    ///   - rect: 渐变区域
    ///   return :  渐变图层
    static func gradient(left:UIColor,right:UIColor,rect:CGRect)->CAGradientLayer{
        func gradientLayer(rect:CGRect)->CAGradientLayer{
            let colorLayer = CAGradientLayer()
            colorLayer.frame = rect
            colorLayer.colors = [left.cgColor,right.cgColor]
            colorLayer.startPoint = CGPoint(x: 0, y: 0.5)
            colorLayer.endPoint = CGPoint(x: 1, y: 0.5)
            return colorLayer
        }
        return gradientLayer(rect: rect)
    }
    
    // MARK: - 生成随机颜色
    class func randromColor() -> UIColor {
        let r = CGFloat(arc4random()%256)/255.0
        let g = CGFloat(arc4random()%256)/255.0
        let b = CGFloat(arc4random()%256)/255.0
        let color = UIColor(displayP3Red: r, green: g, blue: b, alpha: 1)
        return color
    }
    
    // 从Hex装换int
    class func intFromHexString(_ hexString:String)->UInt32{
        let scanner = Scanner(string: hexString)
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "#")
        var result : UInt32 = 0
        scanner.scanHexInt32(&result)
        return result
    }
    
    class func UIColorFromRGBA(_ r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) -> UIColor {
        return UIColor(red: r / 255.0, green: g / 255.0, blue: b / 255.0, alpha: a)
    }
    
    class func UIColorFromHex(_ hex6: UInt32, alpha: CGFloat = 1) -> UIColor {
        let divisor = CGFloat(255)
        let red     = CGFloat((hex6 & 0xFF0000) >> 16) / divisor
        let green   = CGFloat((hex6 & 0x00FF00) >>  8) / divisor
        let blue    = CGFloat( hex6 & 0x0000FF       ) / divisor
        return UIColor(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    class func RandomColor() -> UIColor {
        let red = CGFloat(arc4random_uniform(256))
        let green = CGFloat(arc4random_uniform(256))
        let blue = CGFloat(arc4random_uniform(256))
        return UIColorFromRGBA(red, g: green, b: blue)
    }
}


/*
 convenience init(hexString: String, alpha: CGFloat = 1.0) {
 let hexString = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
 let scanner = Scanner(string: hexString)
 
 if hexString.hasPrefix("#") {
 scanner.scanLocation = 1
 }
 
 var color: UInt32 = 0
 scanner.scanHexInt32(&color)
 
 let mask = 0x000000FF
 let r = Int(color >> 16) & mask
 let g = Int(color >> 8) & mask
 let b = Int(color) & mask
 
 let red   = CGFloat(r) / 255.0
 let green = CGFloat(g) / 255.0
 let blue  = CGFloat(b) / 255.0
 
 self.init(red: red, green: green, blue: blue, alpha: alpha)
 }
 */
