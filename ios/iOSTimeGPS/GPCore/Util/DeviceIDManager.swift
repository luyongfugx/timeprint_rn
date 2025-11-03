//
//  DeviceIDManager.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/13.
//

import Foundation

class DeviceIDManager {
    
    static let shared = DeviceIDManager()
    static private var _deviceID: String = ""
    // 当前设备唯一ID
    static var deviceID: String {
        guard _deviceID.isEmpty else {
            return _deviceID
        }
        let timeGPSIDKey = "timeGPSIDKey"
        guard let idValue = GPKeychainManager.shared.string(forKey: timeGPSIDKey) else {
            _deviceID = NSUUID().uuidString
            GPKeychainManager.shared.set(_deviceID, forKey: timeGPSIDKey)
            return _deviceID
        }
        return idValue
    }

}
