//
//  GPJson.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/13.
//

import UIKit

open class GPJson {
    
    
    /// JSONString转换为字典
    /// - Parameter jsonString: jsonString
    /// - Returns: 字典
    open class func stringToDictionary(_ jsonString: String) -> [String : Any]? {
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        
        do {
            let dict = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [String : Any]
            return dict
        } catch let error as NSError {
            LogDebug("把jsonString转换成字典，error - [\(error)]")
        }
        return nil
    }
    
    
    /// JSONString转换为数组
    /// - Parameter jsonString: jsonString
    /// - Returns: 数组
    open class func stringToArray(_ jsonString:String) -> [Any]?{
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }
        
        do {
            let array = try JSONSerialization.jsonObject(with: jsonData, options: .mutableContainers) as? [Any]
            return array
        } catch let error as NSError {
            LogDebug("把jsonString转换成Array，error - [\(error)]")
        }
        
        return nil
    }
    
    
    /// 字典转换成字符串
    /// - Parameter dictionary: dictionary
    /// - Returns: jsonString
    open class func dictionaryToJsonString(_ dictionary: Dictionary<AnyHashable, Any>) -> String {
        
        if (!JSONSerialization.isValidJSONObject(dictionary)) {
            LogDebug("无法解析出JSONString")
            return ""
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: dictionary, options: []) else {
            LogDebug("解析成data失败")
            return ""
        }
        
        if let jsonStr = String(data: data, encoding: .utf8) {
            return jsonStr
        } else {
            return ""
        }
    }
    
    
    /// 数组转换为JSONString
    /// - Parameter array: array
    /// - Returns: JsonString
    open class func arrayToJsonString(_ array: Array<Any>) -> String {
        
        if (!JSONSerialization.isValidJSONObject(array)) {
            LogDebug("无法解析出JSONString")
            return ""
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: array, options: []) else {
            LogDebug("解析成data失败")
            return ""
        }
        
        if let jsonStr = String(data: data, encoding: .utf8) {
            return jsonStr
        } else {
            return ""
        }
    }
    
    
    ///  data转换成json
    /// - Parameter data: data
    /// - Returns: AnyObject
    open class func dataToJson(_ data: Data) -> AnyObject? {
        do{
            let json = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as AnyObject
            return json
        } catch {
            LogDebug("data转换成json失败，error - [\(error)]")
            return nil
        }
    }
    
    
    /// 把任意类型的数据转换成data
    /// - Parameter param: Any
    /// - Returns: Data
    open class func jsonToData(_ param: Any) -> Data?{
        
        if let string = param as? String, let strData = string.data(using: .utf8) {
            return strData
        }
        
        if !JSONSerialization.isValidJSONObject(param) {
            LogDebug("转换成data失败-非法的JSONObject")
            return nil
        }
        
        do {
            let data = try JSONSerialization.data(withJSONObject: param, options: [])
            return data
        } catch let error as NSError {
            LogDebug("转换成data失败，error - [\(error)]")
        }
        return nil
    }
    
    
    /// 把data转换成json
    /// - Parameter data: Data
    /// - Returns: AnyObject
    open class func dataToAnyObject(data: Data) -> AnyObject? {
        
        var result: AnyObject?
        do {
            result = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as AnyObject
        } catch {
            LogDebug("转换成json失败，error - [\(error)]")
        }
        return result
    }
    
    
    /// 把data转换成json
    /// - Parameter data: data
    /// - Throws: AnyObject
    /// - Returns: 成功则返回AnyObject,失败则抛NSError
    open class func dataToAnyObject2(data: Data) throws -> AnyObject {
        
        guard let result = try? JSONSerialization.jsonObject(with: data as Data, options: .mutableContainers) as AnyObject else {
            throw NSError.init(domain: "转换成json失败", code: -1, userInfo: nil)
        }
        return result
    }
}
