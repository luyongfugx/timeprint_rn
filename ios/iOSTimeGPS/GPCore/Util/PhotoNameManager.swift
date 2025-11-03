//
//  PhotoNameManager.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/11/26.
//

import Foundation
//文件名
class PhotoNameManager {
    static var lastTimeStr = ""
    static var sameTimeCount = 0
    //根据水印生成信息
    static func generateJsonString(items: [WatermarkItem]) -> String {
        let itemDicts = items.map { item -> [String: Any] in
            var dict: [String: Any] = [:]
            if let id = item.id {
                dict["id"] = id
            }
            if let title = item.title {
                dict["title"] = title
            }
            //
            if let content = item.content {
                switch item.idType {
                    case .address: //地址
                        dict["content"] = item.getFileNameAddrContent()
                    case .watermarkTitle: //标题
                        dict["content"] = item.getShowContent()
                    case .note:  //note
                        let title = item.title, content = item.content
                        if isNotEmpty(title) && isNotEmpty(content) && isValidFileName(title!) && isValidFileName(content!) {
                            dict["content"] = content
                        }
                    case .coordinate: // 经纬度
                    dict["content"] = "\(GPSGeoManager.wartermarkGPSInfo.location?.coordinate.latitude ?? 0),\(GPSGeoManager.wartermarkGPSInfo.location?.coordinate.longitude ?? 0)"
                    default:
                        dict["content"] = content
                }
            }
            return dict
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: itemDicts, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("Error converting to JSON: \(error)")
        }
        return "[]" // Return empty array string if conversion fails
    }
    static func generateFileName(items: [WatermarkItem]) -> String {
        var fileName = ""
        // 时间,用真实时间
        let date = TimeManager.shared.getRealTime()
        let formatter = DateFormatter()
        //formatter.dateFormat = "yyyyMMddHHmmss"
        //默认格式
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timeStrDefault = formatter.string(from: date)
        //使用本地化格式时间前缀
        let timeStr = GPDateFormat.localizedDateString(TimeManager.shared.getRealTime(), style: GPDateStyle.yearMonthDateSpecialCountry, is12Hours: false, isShowWeek: false, isShowTimezone: false,needSecond: true) ?? timeStrDefault;
        if timeStr == lastTimeStr {
            sameTimeCount += 1
            fileName += "\(timeStr)(\(sameTimeCount))"
        } else {
            sameTimeCount = 0
            fileName += timeStr
        }
        lastTimeStr = timeStr
        //如果是中国模式，直接用时间戳作为文件名
        if GPCheetManager.isCheetMode {
            return fileName;
        }
        
        let excludFileNameItems: [WatermarkItemID] = [.address, .altitude, .coordinate, .time, .logo, .map, .weather]
        //遍历item,取地址或者title 或者name
        for item in items {
            switch item.idType {
            case .address:
                if isValidFileName(item.getFileNameAddrContent()) {
                    fileName += "_\(item.getFileNameAddrContent() )"
                }
            case .watermarkTitle:
                if isNotEmpty(item.getShowContent()) && isValidFileName(item.getShowContent()) {
                    fileName += "_( \(item.getShowTitle() ?? "") - \(item.getShowContent()) )"
                }
            default:
                if !excludFileNameItems.contains(item.idType), item.isOpen == true {
                    let title = item.title, content = item.content
                    if isNotEmpty(title) && isNotEmpty(content) && isValidFileName(title!) && isValidFileName(content!) {
                        fileName += "_( \(title!) - \(content!) )"
                    } else if isNotEmpty(title) && isValidFileName(title!) {
                        fileName += "_( \(title!) - )"
                    } else if isNotEmpty(content) && isValidFileName(content!) {
                        fileName += "_( - \(content!) )"
                    }
                    
                    fileName += ""
                }
            }
        }
        
        // 如果fileName长度超过251字节,进行截断
        if fileName.lengthOfBytes(using: .utf8) >= 251 {
            while fileName.lengthOfBytes(using: .utf8) >= 251 {
                fileName.removeLast()
            }
        }
        return fileName
    }

    static func isValidFileName(_ name: String) -> Bool {
        !name.containEmoji && !name.containsInvalidChars && !name.containsNewline
    }
}
