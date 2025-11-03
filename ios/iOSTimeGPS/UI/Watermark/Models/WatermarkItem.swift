//
//  WatermarkItem.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/29.
//

import Foundation
import UIKit
import CoreLocation

enum WatermarkItemID: Int {
    case customItem = -1
    // 品牌图
    case logo = 1
    // 时间
    case time = 2
    // 地址
    case address = 3
    // 经纬度
    case coordinate = 4
    // 地图
    case map = 5
    // 天气
    case weather = 6
    // 海拔
    case altitude = 7
    // 备注
    case note = 8
    // 标题
    case watermarkTitle = 9
    // 副标题
    case watermarkSubtitle = 10
    

    case serviceDetail1 = 41
    case serviceDetail2 = 42
    case serviceDetail3 = 43
    case phoneNumber1 = 44
    case phoneNumber2 = 45
    
    // Project
    case wm7_project = 70
    case wm7_developer = 71
    case wm7_description = 72
    case wm7_area = 73
    case wm7_operator = 74
    case wm7_inspectior = 75
    case wm7_inspection = 76
    case wm8_meeting_title = 80
    case wm10_clean_title = 100
    // 简短地址名
    case shortAddress = 300
    
    func getIkey() -> String? {
        switch self {
        case .logo:
            return "k_logo".localized()
        case .time:
            return "k_time".localized()
        case .address:
            return "k_address".localized()
        case .coordinate:
            return "k_coordinate".localized()
        case .map:
            return "k_map".localized()
        case .weather:
            return "k_weather".localized()
        case .altitude:
            return "k_altitude".localized()
       
//        case .serviceDetail1:
//            return "k_service_details1".localized()
//        case .serviceDetail2:
//            return "k_service_details2".localized()
//        case .serviceDetail3:
//            return "k_service_details3".localized()
//        case .note:
//            return "k_note".localized()
        case .customItem:
            return nil
//        case .watermarkTitle:
//            return "k_title".localized()
//        case .watermarkSubtitle:
//            return "k_subtitle".localized()
        default:
            return nil
        }
    }
    
    func isBasicType() -> Bool {
        switch self {
        case .address, .altitude, .coordinate, .logo, .map ,.shortAddress, .time, .weather:
            return true
        default:
            return false
        }
    }
}

class WatermarkItem: NSObject, GPCodable {
   
    var idType: WatermarkItemID {
        get {
            return WatermarkItemID.init(rawValue: id ?? 1) ?? .customItem
        }
    }
    
    // 特殊时间条目，包括时和分
    static let specialTimeID: [WatermarkModelBaseID] = [.ID4, .ID6, .ID7,.ID10,.ID11, .ID13]
    
    // 显示标题id
    static let showTitleTimeID: [WatermarkModelBaseID] = [.ID10,.ID11]
    
    var id: Int?
    var isOpen: Bool?
    var title: String?
    var content: String?
    var editType: Int?
    // 缩放比例
    var scale: CGFloat?
    
    // 时间信息
    private var extraTimeInfo: WatermarkTimeItem?
    var extraTime: WatermarkTimeItem {
        get {
            if extraTimeInfo == nil {
                extraTimeInfo = WatermarkTimeItem()
                extraTimeInfo?.is12Hour = false
                extraTimeInfo?.dateStyle = 1
                extraTimeInfo?.showWeak = true
            }
            return extraTimeInfo!
        } set {
            extraTimeInfo = newValue
        }
    }

    // 地址信息
    private var extraAddressInfo: WatermarkAddressItem?
    var extraAddress: WatermarkAddressItem {
        get {
            if extraAddressInfo == nil {
                extraAddressInfo = WatermarkAddressItem()
                extraAddressInfo?.addressStyle = .formatAddress
            }
            return extraAddressInfo!
        } set {
            extraAddressInfo = newValue
        }
    }
    
    // Logo信息
    private var logoInfo: WatermarkLogoItem?
    var extraLogo: WatermarkLogoItem {
        get {
            if logoInfo == nil {
                logoInfo = WatermarkLogoItem()
                logoInfo?.scale = 0.23
                logoInfo?.enumPosition = .onWatermark
                // 默认将logo从content迁移至此
                logoInfo?.selectLogoPath = content
            }
            return logoInfo!
        } set {
            logoInfo = newValue
        }
    }
    
    // 工程水印logo是否能展示
    func canShowID7Logo() -> Bool {
        if idType != .logo {
            return false
        }
        
        if !(isOpen ?? false) {
            return false
        }
        
        let logoList = extraLogoListInfo.logoList?.filter({ $0.isOpen == true }) ?? []
        if logoList.isEmpty {
            return false
        }
        
        return true
    }
    
    // 多Logo信息(ID7 工程水印用到)
    private var logoListInfo: WatermarkLogoListItem?
    var extraLogoListInfo: WatermarkLogoListItem {
        get {
            if logoListInfo == nil {
                logoListInfo = WatermarkLogoListItem()
                logoListInfo?.logoList = []
            }
            return logoListInfo!
        } set {
            logoListInfo = newValue
        }
    }
    
    // add by waynelu ,用来生成文件名
    var fileNameAddrContent:String? {
        switch idType {
        case .address:
            return GPSGeoManager.wartermarkGPSInfo.address?.clPlacemark?.fileNameAddress
        default:
            return content
        }
            
    }
    var itemContent: String? {
        switch idType {
        case .coordinate:
            let location = GPSGeoManager.wartermarkGPSInfo.location
            return WatermarkItem.getCoordinateString(latitude: location?.coordinate.latitude ?? 0, longitude: location?.coordinate.longitude ?? 0)
        case .address: 
            return GPSGeoManager.wartermarkGPSInfo.address?.getShowAddress(extraAddress.addressStyle, isForCover: false)
        case .shortAddress:
            return GPSGeoManager.wartermarkGPSInfo.address?.clPlacemark?.name
        case .altitude:
            let altitude = GPSGeoManager.wartermarkGPSInfo.location?.altitude ?? 0
            return "\(Int(altitude)) M"
        default:
            return content
        }
    }
    
    func getItemContentFavoriteHistory() -> [String] {
        guard let itemId = id, !idType.isBasicType()  else { return [] }

        // 非基础条目，看下有没有历史记录
        let contentList = WatermarkItemHistoryManager.loadHistory(for: "\(itemId)", type: .content)
        // 假设原始数组名为 historyItems
        let favoriteTexts = contentList
            .filter { $0.isFavorite }  // 过滤出收藏项
            .sorted { $0.date > $1.date }  // 按日期降序排序
            .map { $0.text }  // 提取text属性
        return favoriteTexts
    }

}

extension WatermarkItem {
    
    static let cannotShowDot: [WatermarkItemID] = [WatermarkItemID.logo, WatermarkItemID.map, WatermarkItemID.time]
    
    func getShowText(baseID: WatermarkModelBaseID? = nil) -> String {
        
        var showTitle: String? = getShowTitle()
//        print("showTitle \(showTitle)")
        //ID12 的 logo,map,note cusitem 还是显示标题，不然很空
        if [WatermarkModelBaseID.ID12, WatermarkModelBaseID.ID2, WatermarkModelBaseID.ID15, WatermarkModelBaseID.ID13].contains(baseID) && idType != .logo && idType != .map  && idType != .note && idType != .customItem {
            //  特殊水印处理，不显示标题，更简洁一些
            showTitle = nil
        }

        if idType == .weather, !GPSGeoManager.weatherCach.isEmpty {
            content = GPSGeoManager.weatherCach
        }
        //service name 的 这几个不显示标题
        if idType == .serviceDetail1 || idType == .serviceDetail2 || idType == .serviceDetail3 || idType == .phoneNumber1 || idType == .phoneNumber2 {
            showTitle = nil
        }
        if idType == .time {
       
            //清洁记录 显示标题
            if let baseID, !WatermarkItem.showTitleTimeID.contains(baseID) {
                showTitle = nil
           }
    
            // 需要显示具体时间
            if let baseID, WatermarkItem.specialTimeID.contains(baseID) {
                
                content = GPDateFormat.localizedDateString(TimeManager.shared.getRealTime(), style: GPDateStyle(rawValue: extraTime.dateStyle!) ?? .yearMonthDateSpecialCountry, is12Hours: extraTime.is12Hour ?? true, isShowWeek: extraTime.showWeak ?? true, isShowTimezone: extraTime.showTimeZone ?? false)
          
            } else {
                content = GPDateFormat.getDateFormatString(with: TimeManager.shared.getRealTime(), sytle: GPDateStyle(rawValue: extraTime.dateStyle!) ?? .dayMonthYear, needWeek: extraTime.showWeak ?? true)
            }
        }
       // .ID10  .ID11 特殊处理,需要显示标题
        if let baseID, WatermarkItem.showTitleTimeID.contains(baseID) ,idType == .time {
            return "\(showTitle ?? ""): \(itemContent ?? "")"
       }
        if let showTitle, !showTitle.isEmpty {
            if WatermarkItem.cannotShowDot.contains(idType) {
                return showTitle
            }
            if let itemContent, !itemContent.isEmpty {
                return "\(showTitle): \(itemContent)"
            } else {
                return showTitle
            }
        } else if let itemContent {
            return itemContent
        }
        return ""
    }
    // add by waynelu ,用来生成文件名
    
    func getFileNameAddrContent(baseID: WatermarkModelBaseID? = nil) -> String {
        if let fileNameAddrContent {
            return fileNameAddrContent
        }
        return ""
    }
    func getShowTitle() -> String? {
        if let key = idType.getIkey() {
            return key
        } else {
            // 自定义条目使用item的title
            return title
        }
    }
    
    func getShowContent(baseID: WatermarkModelBaseID? = nil) -> String {
        
        if idType == .weather, !GPSGeoManager.weatherCach.isEmpty {
            content = GPSGeoManager.weatherCach
        }
        
        if idType == .time {
            // 需要显示具体时间
            if let baseID, WatermarkItem.specialTimeID.contains(baseID) {
                content = GPDateFormat.localizedDateString(TimeManager.shared.getRealTime(), style: GPDateStyle(rawValue: extraTime.dateStyle!) ?? .yearMonthDateSpecialCountry, is12Hours: extraTime.is12Hour ?? true, isShowWeek: extraTime.showWeak ?? true, isShowTimezone: extraTime.showTimeZone ?? false)
            } else {
                content = GPDateFormat.getDateFormatString(with: TimeManager.shared.getRealTime(), sytle: GPDateStyle(rawValue: extraTime.dateStyle!) ?? .dayMonthYear, needWeek: extraTime.showWeak ?? true)
            }
        }
                
        if let itemContent {
            return itemContent
        }
        return ""
    }
    
    static func getCoordinateString(latitude: Double, longitude: Double) -> String {
        if latitude == 0 && longitude == 0 {
            return "-- °S, -- °W"
        }
        let _latitude = String.init(format: "%.6f", abs(latitude))
        let _longitude = String.init(format: "%.6f", abs(longitude))
        let latitudeString = "\(_latitude)°\(latitude>0 ? "N" : "S")"
        let longitudeString = "\(_longitude)°\(longitude>0 ? "E" : "W")"
        return "\(latitudeString), \(longitudeString)"
    }
    
}

extension WatermarkItem {
    
    func getLogo() -> UIImage? {
        guard let logoPath = extraLogo.selectLogoPath, idType == .logo else { return nil }
        return GPDataCacheManager.shared.getCachLogo(fileName: logoPath)
    }
    
    func addLogo(_ img: UIImage) {
        guard idType == .logo else { return }
        // 将图片保存到本地沙盒
        let fileName = NSUUID().uuidString + ".png"
        GPDataCacheManager.shared.cachLogo(logoImg: img, fileName: fileName)
        extraLogo.selectLogoPath = fileName
        extraLogo.originLogoPath = fileName
        extraLogo.isRemoveBg = false
    }
}

extension WatermarkItem {
    
    func getMapStyle() -> WatermarkMapStyle? {
        guard idType == .map else {
            return nil
        }
        return (content == "1") ? .satellite : .standard
    }
    
    func updateMapStyle(_ style: WatermarkMapStyle) {
        guard idType == .map else {
            return
        }
        content = "\(style.rawValue)"
    }
}
