//
//  GPCheetManager.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/13.
//  中国区防作弊

import Foundation

class GPCheetManager {
    
    static let whiteList: [String] = ["BFF7BBB0-BD6F-4FE9-AC83-7C8932E243FB", "A8EFFEE6-3D60-4919-813B-150A7EE09AC1","B55F5A9B-3957-46E3-9868-25C1533E4086", "511DEB5F-B474-40CE-AD2A-B1AF61A81D1D", "54CD73A4-7F5F-49A3-901A-DB2F94A79316"]
    // 13F75AD2-EB56-4118-8A34-1110DA230ADF
    
    @GPPersistance(key: "com.gpscamera.key.cheatmode", defaultValue: false)
    static var isCheetMode: Bool

    // 处理中国模式
    static func handleChineseMode() {

        // 白名单先去掉
        if whiteList.contains(where: { $0 == DeviceIDManager.deviceID }) {
            GPCheetManager.isCheetMode = false
            return
        }
        
        if !GPCountryManager.mockCountryCode.isEmpty {
            GPCheetManager.isCheetMode = false
            return
        }
        
        // 1、钥匙串中是否是中国模式
        let keychainChineseModeKey = "com.gpscamera.keychain.cheatmode"
        if GPKeychainManager.shared.string(forKey: keychainChineseModeKey) != nil {
            GPCheetManager.isCheetMode = true
            return
        }
        
        // 2、逆地理国家是否是中国模式
        if GPCountryManager.geoCountryCode == "CN" {
            GPKeychainManager.shared.set("true", forKey: keychainChineseModeKey)
            GPCheetManager.isCheetMode = true
            return
        }
        
        // 3、设备国家是否是中国模式
        if GPCountryManager.deviceCountryCode == "CN" {
            GPKeychainManager.shared.set("true", forKey: keychainChineseModeKey)
            GPCheetManager.isCheetMode = true
            return
        }
    }
    
}



