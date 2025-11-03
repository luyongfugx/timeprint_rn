//
//  AppConfigManager.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/17.
//  阿波罗配置

import Foundation

class AppConfigManager: NSObject {
    static let shared = AppConfigManager()
    var config = GPConfigModel()
    func initConfig() {
        config = LocalStorageManger.getDataFromLocal(nil, GPConfigModel()) ?? GPConfigModel.defaultM()
    }
    func fetchConfig() {
        networkAPI.appConfig { [weak self] error, message in
            if let message {
                self?.config = message
                LocalStorageManger.saveDataToLocal(nil, message)
            }
        }
    }
}
