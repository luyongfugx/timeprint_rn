//
//  UIFont+Extension.swift
//  XCamera
//
//  Created by batman on 2019/9/25.
//  Copyright © 2019 xhey. All rights reserved.
//

import Foundation
import UIKit

extension UIFont {
    
    //MARK: 普通文本 body
    /// body_large    较大普通文本    17    regular
    class var body_large: UIFont {
        return UIFont.regular(17)
    }
    
    /// body_normal    常规普通文本    16    regular
    class var body_normal: UIFont {
        return UIFont.regular(16)
    }

    /// body_small    较小普通文本    14    regular
    class var body_small: UIFont {
        return UIFont.regular(14)
    }
    
    /// title_large_bold    二级标题    20    semibold
    class var title_large_bold: UIFont {
        return UIFont.Semibold(20)
    }

    /// title_normal_bold    常规标题    17    semibold
    class var title_normal_bold: UIFont {
        return UIFont.Semibold(17)
    }

    /// title_small_bold    小标题    16    semibold
    class var title_small_bold: UIFont {
        return UIFont.Semibold(16)
    }
    
    class func light(_ size: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Light", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    class func regular(_ size: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Regular", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    class func Semibold(_ size: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Semibold", size: size) ?? UIFont.boldSystemFont(ofSize: size)
    }
    
    class func Medium(_ size: CGFloat) -> UIFont {
        return UIFont(name: "PingFangSC-Medium", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    /// HYQiHeiX2-85W
    class func HYQiHeiX2_85W(_ size: CGFloat) -> UIFont {
        return UIFont(name: "HYQiHeiX2-HEW", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
//    /// HYQiHeiX2-65W
//    class func HYQiHeiX2_65W(_ size: CGFloat) -> UIFont {
//        // V2.0.40: 将HYQiHeiX2都改成robotocondensed
//        return robotoCondensedRegular(size)
////        return UIFont(name: "HYQiHeiX2-FEW", size: size) ?? UIFont.systemFont(ofSize: size)
//    }
    
    class func Muyao_Softbrush(_ size: CGFloat) -> UIFont? {
        UIFont(name: "Muyao-Softbrush", size: size)
    }
    
    class func DINAlternate(_ size: CGFloat) -> UIFont {
        return UIFont(name: "DINAlternate-Bold", size: size) ?? UIFont.systemFont(ofSize: size)
    }
    
    class func DIN_Alternate_Bold(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: "DIN Alternate", size: size) {
            return font
        }
        return UIFont.systemFont(ofSize: size)
    }
    
    class func DIN_Alternate_Elvis(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: "DIN Alternate-Elvis", size: size) {
            return font
        }
        return UIFont.systemFont(ofSize: size)
    }
    
    class func DIN_Condensed(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: "DIN Condensed", size: size) {
            return font
        }
        return UIFont.systemFont(ofSize: size)
    }
    
    //MARK: -V2.9.215版本添加, 汉仪新人宋体, 仅用在拼图模块
    class func wensongRegular(_ size: CGFloat) -> UIFont {
        return UIFont(name: wensongRegularFontName, size: size) ?? UIFont.regular(size)
    }
    
    class var wensongRegularFontName: String {
        return "HYXinRenWenSong-EEW"
    }
    
    class func wensongBold(_ size: CGFloat) -> UIFont {
        return UIFont(name: wensongBoldFontName, size: size) ?? UIFont.Semibold(size)
    }
    
    class var wensongBoldFontName: String {
        return "HYXinRenWenSong-GEW"
    }
    
    // 2.9.245:增加中黑体：Oswald-SemiBold.ttf
    class func Oswald_SemiBold(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: "Oswald-SemiBold", size: size) {
            return font
        }
        return UIFont.systemFont(ofSize: size)
    }
    
    static func canUseFontFromSystem(fontName: String) -> Bool {
        
        var canUseFontFromSystem: Bool = false
        
        UIFont.familyNames.forEach { familyName in
            if UIFont.fontNames(forFamilyName: familyName).contains(fontName) {
                canUseFontFromSystem = true
            }
        }
        
        return canUseFontFromSystem
    }

    /// CKT字体
    /// - Date: 2023-02-23
    /// - Version: 2.9.355
    class func CKTKingKong(_ size: CGFloat) -> UIFont {
        return UIFont(name: "CKT", size: size) ?? UIFont.systemFont(ofSize: size, weight: .bold)
    }

    /// 阿里妈妈书黑体
    /// - Date: 2023-02-23
    /// - Version: 2.9.355
    class func AlimamaShuHeiTi(_ size: CGFloat) -> UIFont {
        let font = UIFont(name: "AlimamaShuHeiTi", size: size) ?? .systemFont(ofSize: size, weight: .bold)
        return font
    }
}

extension UIFont {

    class func bigShouldersMedium(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Big Shoulders Text", size: size) ?? UIFont.Medium(size)
    }

    func withTraits(traits:UIFontDescriptor.SymbolicTraits, size: CGFloat) -> UIFont? {
        guard let descriptor = fontDescriptor.withSymbolicTraits(traits) else {
            return nil
        }

        return UIFont(descriptor: descriptor, size: size) //size 0 means keep the size as it is
    }

    class func robotoCondensedBold(_ size: CGFloat) -> UIFont {
        return robotoCondensedRegular(size).withTraits(traits: .traitBold, size: size) ?? .systemFont(ofSize: size, weight: .bold)
    }

    class func robotoCondensedRegular(_ size: CGFloat) -> UIFont {
        return UIFont(name: "Roboto Condensed", size: size) ?? UIFont.systemFont(ofSize: size, weight: .regular)
    }
    
    class func robotoCondensedMedium(_ size: CGFloat) -> UIFont {
        return UIFont(name: "RobotoCondensed-Medium", size: size) ?? UIFont.systemFont(ofSize: size, weight: .medium)
    }
    
    class func MontserratBlackRegular(_ size: CGFloat) ->UIFont {
        return UIFont(name: "Montserrat", size: size) ?? UIFont.systemFont(ofSize: size, weight: .regular)
    }
    /// 数字字体,  这个字体@春节改了 '1'的字间距
    /// - Date: 2023-05-18
    /// - Version: 3.0.18
    class func bebasDaka(_ size: CGFloat) -> UIFont {
        let font = UIFont(name: "BebasDaka", size: size) ?? UIFont(name: "Baskerville", size: size)
        return font ?? .systemFont(ofSize: size, weight: .bold)
    }
    /// 数字字体,  这个字体@春节改了 '1'的字间距
    /// - Date: 2023-12-04
    /// - Version: 2.0.0
    class func typoDigitDemo(_ size: CGFloat) -> UIFont {
        let font = UIFont(name: "TypoDigitDemo", size: size) ?? .systemFont(ofSize: size, weight: .bold)
        return font
    }
    
    /// xiaohei数字字体,
    /// - Date: 2024-05-20
    /// - Version: 3.0.0
    class func xiaoXeiNumber(_ size: CGFloat) -> UIFont {
        if let font = UIFont(name: "XiaoHeiNumber", size: size) {
            return font
        } else {
            return .systemFont(ofSize: size, weight: .regular)
        }
    }
}
