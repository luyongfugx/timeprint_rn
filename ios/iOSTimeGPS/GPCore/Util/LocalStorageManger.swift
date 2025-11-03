//
//  LocalStorageManger.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/9/16.
//

import Foundation

class LocalStorageManger {
    
    static let prefixLocalKey = "pre_key_"
    
    //删除
    static func delDataFormLocal(_ modelKey: String? = nil) {
        guard let modelKey else { return }
        GPDataCacheManager.shared.asyncDelCache(cacheKey: modelKey, cacheType: .GPLocalBusinessData) { (isSuccess) in
        }
    }
    // 把信息保存到沙盒
    static func saveDataToLocal(_ modelKey: String? = nil, _ model: GPCodable?) {
        
        guard let model = model, let dict = SpeedyModel.modelToAnyObject(model) else {
            return
        }
        
        var key = "\(LocalStorageManger.prefixLocalKey)\(String(describing: model.self))"
        if let modelKey {
            key = modelKey
        }
        GPDataCacheManager.shared.asyncSaveCache(dict as AnyObject, cacheKey: key, cacheType: .GPLocalBusinessData) { (isSuccess) in
        }
        
    }
    
    // 从沙盒获取信息
    static func getDataFromLocal<T: Decodable>(_ modelKey: String? = nil, _ type: T) -> T? {
        
        var key = "\(LocalStorageManger.prefixLocalKey)\(String(describing: type.self))"
        if let modelKey {
            key = modelKey
        }
        
        var resultModel: T?
        if let dict = GPDataCacheManager.shared.getCacheObject(cacheKey: key, cacheType: .GPLocalBusinessData) as? [String: Any],
           let model = try? SpeedyModel.dictionaryToModel(T.self, param: dict) {
            
            resultModel = model
        }
        return resultModel
    }
    
    func getLocalDataKey<T: Decodable>(_ type: T) -> String {
        return "\(LocalStorageManger.prefixLocalKey)\(String(describing: type.self))"
    }
}
