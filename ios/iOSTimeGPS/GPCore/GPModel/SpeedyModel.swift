//
//  SpeedyModel.swift
//  XCamera
//
//  Created by batman on 2019/9/18.
//  Copyright © 2019 xhey. All rights reserved.
//

import UIKit

public enum SpeedyModelError: Error {
    case message(String)
}

public struct SpeedyModel {
    
    //TODO:转换模型(单个) 把字典转换成model
    public static func dictionaryToModel<T>(_ type: T.Type, param: [String:Any]) throws -> T where T: Decodable {
        
        guard let jsonData = GPJson.jsonToData(param) else {
            let errorMsg = "[Codable调试] - dictionaryToModel失败 - 转换data失败 - 类名:[\(type)]"
            self.showErrorAlert(errorMsg: errorMsg, type: type)
            throw SpeedyModelError.message("转换data失败")
        }
        guard let model = try? JSONDecoder().decode(type, from: jsonData) else {
            
            let errorMsg = "[Codable调试] - dictionaryToModel失败 - 类名:[\(type)]"
            self.showErrorAlert(errorMsg: errorMsg, type: type)
            
            throw SpeedyModelError.message("转换模型失败")
        }
        return model
    }
    
    //TODO:转换模型(多个) 把数组转换成models
    public static func arrayToModels<T>(_ type: T.Type, array: [[String:Any]]) throws -> T where T: Decodable{
        
        if let data = GPJson.jsonToData(array) {
            if let models = try? JSONDecoder().decode([T].self, from: data) {
                return models as! T
            }
        } else {
            let errorMsg = "[Codable调试] - 模型转换->转换data失败 - 类名:[\(type)]"
            self.showErrorAlert(errorMsg: errorMsg, type: type)
        }
        throw SpeedyModelError.message("模型转换->转换data失败")
    }
    
    public static func modelsToJsonString<T: Encodable>(_ models: [T]) throws -> String? {
        
        do {
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(models)
            if let jsonStr = String(data: data, encoding: .utf8)  {
                return jsonStr
            }
        } catch {
            let errorMsg = "[Codable调试] - modelsToJsonString失败 - 类名:[\(T.self)] - error:[\(error)]"
            self.showErrorAlert(errorMsg: errorMsg, type: T.self)
        }
        
        return nil
    }
    
    // MARK: - 把model转换成json字符串
    public static func modelToString<T>(_ model: T, isNeedPrettyPrinted: Bool = true) -> String? where T: Encodable {
        
        do {
            let encoder = JSONEncoder()
            
            if isNeedPrettyPrinted {
                encoder.outputFormatting = .prettyPrinted
            }
            
            let data = try encoder.encode(model)
            if let jsonStr = String(data: data, encoding: .utf8)  {
                return jsonStr
            }
        } catch {
            let errorMsg = "[Codable调试] - modelToString失败 - 类名:[\(model.self)] - error:[\(error)]"
            self.showErrorAlert(errorMsg: errorMsg, type: T.self)
        }
        return nil
    }
    
    // MARK: - 把model转换成data
    public static func modelToData<T>(_ model: T) -> Data? where T: Encodable {
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(model)
            return data
        } catch {
            let errorMsg = "[Codable调试] - modelToData失败 - 类名:[\(model.self)] - error:[\(error)]"
            self.showErrorAlert(errorMsg: errorMsg, type: T.self)
        }
        return nil
    }
    
    // MARK: - 把model转换成字典
    public static func modelToDictionary<T>(_ model: T) -> [String:Any]? where T: Encodable {
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(model)
            if let dict = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as? [String:Any] {
                return dict
            }
        } catch {
            let errorMsg = "[Codable调试] - modelToDictionary失败 - 类名:[\(model.self)] - error:[\(error)]"
            self.showErrorAlert(errorMsg: errorMsg, type: T.self)
        }
        
        return nil
    }
    
    // MARK: - 把model转换成AnyObject
    public static func modelToAnyObject<T>(_ model: T) -> AnyObject? where T: Encodable {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(model)
            let object = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves) as AnyObject
            return object
        } catch {
            let errorMsg = "[Codable调试] - modelToAnyObject失败 - 类名:[\(model.self)] - error:[\(error)]"
            self.showErrorAlert(errorMsg: errorMsg, type: T.self)
        }
        return nil
    }
    
    // MARK: - 把AnyObject转换成model
    public static func anyToModel<T: Codable>(_ type: T.Type, param: Any) -> T? {
        
        // 2.9.167:如果是空的字符串，直接返回nil
        if let str = param as? String, str.count == 0 {
            return nil
        }
        
        guard let jsonData = GPJson.jsonToData(param) else {
            self.showErrorAlert(errorMsg: "[Codable调试] - 转换data失败", type: type)
            return nil
        }
        
        do {
            let model = try JSONDecoder().decode(type, from: jsonData)
            return model
        } catch {
            let errorMsg = "[Codable调试] - dataToModel失败 - 类名:[\(type)] - error:[\(error)]"
            self.showErrorAlert(errorMsg: errorMsg, type: type)
        }
        return nil
    }
    
    // MARK: - 把data转换成model
    public static func dataToModel<T>(_ type: T.Type, data: Data?) -> T? where T : Decodable {
        
        if let currentData = data {
            do {
                let model = try JSONDecoder().decode(type, from: currentData)
                return model
            } catch {
                let errorMsg = "[Codable调试] - dataToModel失败 - 类名:[\(type)] - error:[\(error)]"
                self.showErrorAlert(errorMsg: errorMsg, type: T.self)
            }
        }
        return nil
    }
    
    // 弹出Codable解析失败的错误弹框 [Codable调试]
    private static func showErrorAlert<T>(errorMsg: String, type: T.Type) {
        
//        LogDebug("[Codable调试] 失败类- \(type) - \(errorMsg)")
//        
//        // 2.9.355:优化iOS_CodableError埋点上报，对部分model不采集
//        if type != XHPhotoUserCommentModel.self, type != XHPhotoInfo.self, type != XHNewPhotoInfo.self, type != XHNewPhotoInfo_2.self {
//                        
//            Report.iOS_CodableError(errorMsg, typeStr: "\(type)")
//            
//            // 非线上包弹出提示弹框
//            if isAppStore == false {
//                UIAlertController.showAlert(title: "Codable Error", message: errorMsg, buttonTitles: ["复制信息", "取消"], viewController: BCApp.topViewController) { index, _ in
//                    
//                    if index == 0 {
//                        UIPasteboard.general.string = errorMsg
//                    }
//                }
//            }
//            
//        }
    }
}
