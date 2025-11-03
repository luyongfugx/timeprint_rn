//
//  BaseWatermarkModel.swift
//  iOSTimeGPS
// 
//  Created by batman on 2024/8/17.
//

import Foundation
import UIKit

enum WatermarkModelBaseID: String {
    case ID1 = "1" // 默认时间地点水印
    case ID2 = "2" // 自定义文本水印
    case ID3 = "3" // 签到水印，签退水印
    case ID4 = "4" // 电话号码服务水印
    case ID5 = "5" // 安保水印
    case ID6 = "6" // 工作记录
    case ID7 = "7" // 工程水印
    case ID8 = "8" // 会议记录
    case ID9 = "9" // 时刻水印
    case ID10 = "10" //清洁水印
    case ID11 = "11" //签收水印
    case ID12 = "12" //新简单水印
    case ID13 = "13" //gps map地图水印1
    case ID14 = "14" //gps map地图水印2
    case ID15 = "15" //新打卡水印，类似马克
    case ID16 = "16" //新服务名字水印
}
// 水印ID，水印的唯一标识 BaseID 和id 的对应关系
//dict baseID: Optional("1") id: Optional("1")
//dict baseID: Optional("2") id: Optional("2")
//dict baseID: Optional("3") id: Optional("3")
//dict baseID: Optional("4") id: Optional("4")
//dict baseID: Optional("4") id: Optional("5")
//dict baseID: Optional("5") id: Optional("6")
//dict baseID: Optional("6") id: Optional("7")
//dict baseID: Optional("7") id: Optional("8")
//dict baseID: Optional("8") id: Optional("8_1")
//dict baseID: Optional("9") id: Optional("9_1")
//dict baseID: Optional("10") id: Optional("10_1")
//dict baseID: Optional("11") id: Optional("11_1")

enum WatermarkID: String {
    case ID1 = "1" // 默认时间地点水印
    case ID2 = "2" // 自定义文本水印
    case ID3 = "3" // 签到水印，签退水印
    case ID4 = "4" //工作记录
    case ID5 = "5" // 电话号码服务水印
    case ID6 = "6" //安保水印
    case ID7 = "7" // 工程水印
    case ID8 = "8" // 会议记录
    case ID8_1 = "8_1" // 会议记录
    case ID9_1 = "9_1" // 时刻水印
    case ID10_1 = "10_1" //清洁水印
    case ID11_1 = "11_1" //签收水印
    case ID12 = "12"  //新水印
    case ID13 = "13"  //新水印
    case ID14 = "14"  //新水印
    case ID15_1 = "15_1"  //新水印
    case ID15_2 = "15_2"  //新水印
}


class BaseWatermarkModel: NSObject, GPCodable {
    
    // 水印ID，水印的唯一标识
    var id: String?
    // 水印名称
    var name: String?
    // 水印的模板ID
    var base_id: String?
    // 条目List
    var items: [WatermarkItem]?
    // 模版风格颜色
    var templateColorStr: String?
    var templateColor: UIColor? {
        get {
            if let templateColorStr {
                return UIColor.fromHex(templateColorStr)
            } else {
                return nil
            }
        }
    }
    
    // 模版文字颜色
    var textColorStr: String?
    var textColor: UIColor? {
        get {
            if let textColorStr = textColorStr {
                return UIColor.fromHex(textColorStr)
            } else {
                return nil
            }
        }
    }
    
    // 模版缩放大小
    var templateScale: CGFloat?
    // Logo缩放大小
    var logoScale: CGFloat?
    
    var baseID: WatermarkModelBaseID {
        get {
            return WatermarkModelBaseID.init(rawValue: "\(base_id ?? "")") ?? .ID1
        }
    }
    
    var allBottomOpenItem: [WatermarkItem] {
        get {
            var bottomList: [WatermarkItem] = []
            switch baseID {
            case .ID1:
                var excludeItemID: [WatermarkItemID] = [.logo, .map]
                excludeItemID.append(contentsOf: [.time, .address])
                bottomList = items?.filter({ $0.isOpen == true && !excludeItemID.contains(WatermarkItemID(rawValue: $0.id!) ?? .customItem) }) ?? []
            case .ID2, .ID15, .ID3, .ID4,.ID16:
                bottomList = items?.filter({ $0.isOpen == true && ($0.idType == .note
                                                                   || $0.idType == .serviceDetail1
                                                                   || $0.idType == .serviceDetail2
                                                                   || $0.idType == .serviceDetail3
                                                                   || $0.idType == .phoneNumber1
                                                                   || $0.idType == .phoneNumber2
                                                                   || $0.idType == .customItem) }) ?? []
            case .ID7:
                let excludeItemID: [WatermarkItemID] = [.logo, .wm7_project, .wm7_developer, .map,.wm8_meeting_title]
                bottomList =  items?.filter({ $0.isOpen == true && !excludeItemID.contains(WatermarkItemID(rawValue: $0.id!) ?? .customItem) }) ?? []
            case .ID8,.ID12:
                let excludeItemID: [WatermarkItemID] = [.logo, .map,.wm8_meeting_title, .time]
                bottomList =  items?.filter({ $0.isOpen == true && !excludeItemID.contains(WatermarkItemID(rawValue: $0.id!) ?? .customItem) }) ?? []
            case .ID10,.ID11, .ID13, .ID14:
                let excludeItemID: [WatermarkItemID] = [.logo, .map]
                bottomList =  items?.filter({ $0.isOpen == true && !excludeItemID.contains(WatermarkItemID(rawValue: $0.id!) ?? .customItem) }) ?? []
            case .ID5, .ID6, .ID9:
                bottomList = []
            }
            
            if baseID == .ID13, let firstItem = bottomList.first(where: { $0.idType == .address }) {
                let item = firstItem.deepCopy()
                item.id = WatermarkItemID.shortAddress.rawValue
                bottomList.insert(item, at: 0)
            }
            
            // 特殊处理天气
            if GPSGeoManager.weatherCach.isEmpty {
                return bottomList.filter({ $0.idType != .weather })
            } else {
                return bottomList
            }
            
        }
    }
    
    var allTopOpenItem: [WatermarkItem] {
        get {
            var itemList: [WatermarkItem] = []
            switch baseID {
            case .ID1, .ID9,.ID10,.ID11, .ID13, .ID14:
                return itemList
            case .ID2, .ID15, .ID3,.ID4, .ID16:
                let includeItemID: [WatermarkItemID] = [.time, .address, .coordinate, .weather, .altitude]
                itemList = items?.filter({ $0.isOpen == true && includeItemID.contains($0.idType) }) ?? []
            case .ID5:
                let includeItemID: [WatermarkItemID] = [.time, .map, .logo, .watermarkTitle, .watermarkSubtitle]
                itemList = items?.filter({ $0.isOpen == true && !includeItemID.contains($0.idType) }) ?? []
            case .ID6:
                let includeItemID: [WatermarkItemID] = [.map, .logo, .watermarkTitle]
                itemList = items?.filter({ $0.isOpen == true && !includeItemID.contains($0.idType) }) ?? []
            case .ID7:
                let includeItemID: [WatermarkItemID] = [.wm7_project, .wm7_developer]
                return items?.filter({ oneItem in
                    if oneItem.idType == .logo, oneItem.canShowID7Logo() {
                        return true
                    } else {
                        return oneItem.isOpen == true && includeItemID.contains(oneItem.idType)
                    }
                }) ?? []
            
            case .ID8,.ID12:
                let includeItemID: [WatermarkItemID] = [.wm8_meeting_title,.wm10_clean_title]
                return items?.filter({ oneItem in
                    if oneItem.idType == .logo {
                        return true
                    } else {
                        return oneItem.isOpen == true && includeItemID.contains(oneItem.idType)
                    }
                }) ?? []
            }
            guard !GPSGeoManager.weatherCach.isEmpty else {
                return itemList.filter({ $0.idType != .weather })
            }
            return itemList
        }
    }
    
    func logoItem() -> WatermarkItem? {
        return items?.first(where: { $0.idType == .logo })
    }
    
    func addressItem() -> WatermarkItem? {
        return items?.first(where: { $0.idType == .address })
    }
    
    func timeItem() -> WatermarkItem? {
        return items?.first(where: { $0.idType == .time })
    }
    
    func isSpecialMapWatermark() -> Bool {
        if let base_id, [WatermarkModelBaseID.ID13.rawValue, WatermarkModelBaseID.ID14.rawValue].contains(base_id) {
            return true
        } else {
            return false
        }
    }
}
