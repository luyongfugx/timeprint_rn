//
//  GPCodable.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/17.
//

import Foundation
protocol GPCodable: Codable {
    
    func deepCopy() -> Self
    
    func toJSONString() -> String?
    
    func toCompactJSONString() -> String?
    
    func toJSON() -> AnyObject?
    
    static func toModel(from param: Any) -> Self?
    
    static func deserialize(from param: Any) -> Self?
}

extension GPCodable {
    
    // 深拷贝，如果失败则使用现有的
    func deepCopy() -> Self {
        do {
            let data = try JSONEncoder().encode(self)
            let target = try JSONDecoder().decode(Self.self, from: data)
            return target
        } catch {
            LogDebug("深拷贝失败，error - [\(error)]")
        }
        return self
    }
    
    /*
    func deepCopy() -> Self {
        guard let data = try? JSONEncoder().encode(self) else {
            fatalError("encode失败")
        }
        guard let target = try? JSONDecoder().decode(Self.self, from: data) else {
           fatalError("decode失败")
        }
        return target
    }
 */
    func toCompactJSONString() -> String? {
        let str = SpeedyModel.modelToString(self, isNeedPrettyPrinted: false)
        return str
    }
    
    func toJSONString() -> String? {
        let str = SpeedyModel.modelToString(self)
        return str
    }
    
    func toJSON() -> AnyObject? {
        let object = SpeedyModel.modelToAnyObject(self)
        return object
    }
    
    static func toModel(from param: Any) -> Self? {
        
        let model = SpeedyModel.anyToModel(Self.self, param: param)
        return model
    }
    
    static func deserialize(from param: Any) -> Self? {
        let model = SpeedyModel.anyToModel(Self.self, param: param)
        return model
    }
    
}
