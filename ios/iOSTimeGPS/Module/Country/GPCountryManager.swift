//
//  GPCountryManager.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/18.
//

import Foundation
class GPCountryManager {
    
    @GPPersistance(key: "com.gpscamera.key.countryCode", defaultValue: "")
    private static var cachCountryCode: String
    
    @GPPersistance(key: "com.gpscamera.key.mockCountryCode", defaultValue: "")
    static var mockCountryCode: String
    
    /* 获取设备国家编码唯一入口:
        CN 中国
        US 美国
        ID 印尼
        JP 日本
        VN 越南
        TH 泰国
        ES 西班牙
        PT 葡萄牙 */
    static var geoCountryCode: String {
        set {
            GPCountryManager.cachCountryCode = newValue
            // 逆地理国家更新时，重新处理防作弊模式
            GPCheetManager.handleChineseMode()
        }
        get {
            
            if !GPCountryManager.mockCountryCode.isEmpty {
                // 模拟的国家code
                return GPCountryManager.mockCountryCode
            }
            
            if !GPCountryManager.cachCountryCode.isEmpty {
                return GPCountryManager.cachCountryCode
            } else {
                return (NSLocale.autoupdatingCurrent as NSLocale).countryCode?.uppercased() ?? "US"
            }
        }
    }
    
    static var deviceCountryCode: String {
        return (NSLocale.autoupdatingCurrent as NSLocale).countryCode?.uppercased() ?? "US"
    }
    
    static var isChina: Bool {
        return GPCountryManager.geoCountryCode == "CN"
    }
    
    static var isVietname: Bool {
        return GPCountryManager.geoCountryCode == "VN"
    }
    
    static var isIndonesia: Bool {
        return GPCountryManager.geoCountryCode == "ID"
    }
    
    static var isAmerica: Bool {
        return GPCountryManager.geoCountryCode == "US"
    }
}
