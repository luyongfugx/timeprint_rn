//
//  WatermarkLogoItem.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/6.
//

import Foundation

// logo在水印上的位置
enum LogoPosition: Int {
    case onWatermark = 0
    case leftTop
    case rightTop
    case center
    case inline
    
    func getTitle() -> String {
        switch self {
        case .onWatermark:
            return "k_follow".localized()
        case .leftTop:
            return "k_any_position".localized()
        case .rightTop:
            return "k_upper_right".localized()
        case .center:
            return "k_middle".localized()
        default:
            return ""
        }
    }
}

// Logo补充信息
class WatermarkLogoItem: NSObject, GPCodable {
    
    // 缩放大小
    var scale: CGFloat?
    
    // 透明度大小
    var alpha: CGFloat?
    
    // 位置，0 跟随水印位置，1左上 2右上 3中间
    private var position: Int?
    var enumPosition: LogoPosition {
        set(newValue) {
            position = newValue.rawValue
        }
        get {
            LogoPosition(rawValue: position ?? 0) ?? .onWatermark
        }
    }
    
    // 当前下发的logo url
    var logoUrl: String?
    // 当前logo
    var selectLogoPath: String?
    // 原始logo，
    var originLogoPath: String?
    // 是否删除
    var isRemoveBg: Bool?
    
    // 当前预览的logoList
    var logoList: [String]?
    
    
}
