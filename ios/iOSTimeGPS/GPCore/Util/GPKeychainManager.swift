//
//  GPKeychainManager.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/4.
//

import Foundation
import UIKit
import KeychainAccess

class GPKeychainManager: NSObject {
    
    static let shared = GPKeychainManager()
    
    private let keychain = Keychain(service: "com.timeGPS.Keychain")
    
    private override init() {
        super.init()
    }
    
    /// 把字符串写入到钥匙串
    /// - Parameters:
    ///   - value: 要写入的值
    ///   - defaultName: key的名称
    open func set(_ value: String, forKey defaultName: String) {
        
        do {
            try keychain.set(value, key: defaultName)
            // XHLogDebug("[钥匙串调试] - 字符串写入钥匙串成功key:[\(defaultName)] - value:[\(value)]")
        } catch  {
            LogDebug("[钥匙串调试] - 字符串写入钥匙串失败key:[\(defaultName)] - error:[\(error)]")
        }
    }
    
    /// 把Data写入到钥匙串
    /// - Parameters:
    ///   - value: 要写入的值
    ///   - defaultName: key的名称
    open func set(_ value: Data, forKey defaultName: String) {
        
        do {
            try keychain.set(value, key: defaultName)
            // XHLogDebug("[钥匙串调试] - data写入钥匙串成功key:[\(defaultName)] - value:[\(value)]")
        } catch  {
            LogDebug("[钥匙串调试] - 写入钥匙串失败 - data - error:[\(error)]")
        }
    }
    
    /// 从钥匙串中获取字符串
    /// - Parameter defaultName: key
    /// - Returns: 结果
    open func string(forKey defaultName: String) -> String? {
        
        var resultStr: String?
        do {
            resultStr = try keychain.getString(defaultName, ignoringAttributeSynchronizable: true)
            // XHLogDebug("[钥匙串调试] - 从钥匙串中获取字符串成功key:[\(defaultName)] - value:[\(resultStr ?? "")]")
        } catch  {
            LogDebug("[钥匙串调试] - 从钥匙串中获取字符串失败error:[\(error)]")
        }
        return resultStr
    }
    
    
    /// 从钥匙串中获取data
    /// - Parameter defaultName: key
    /// - Returns: 结果
    open func data(forKey defaultName: String) -> Data? {
        
        var resultData: Data?
        do {
            resultData = try keychain.getData(defaultName)
            // XHLogDebug("[钥匙串调试] - 从钥匙串中获取data成功key:[\(defaultName)] - value:[\(resultData ?? Data())]")
        } catch  {
            LogDebug("[钥匙串调试] - 从钥匙串中获取data失败error:[\(error)]")
        }
        return resultData
    }
    
    /// 从钥匙串中删除
    /// - Parameter defaultName: key
    open func removeObject(forKey defaultName: String) {
        
        do {
            try keychain.remove(defaultName)
            // XHLogDebug("[钥匙串调试] - 从钥匙串中删除成功key:[\(defaultName)]")
        } catch {
            LogDebug("[钥匙串调试] - 从钥匙串中删除失败error:[\(error)]")
        }
    }
}
