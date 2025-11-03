//
//  GPNetworkRequestTask.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/3.
//

import UIKit
import Foundation
import Alamofire

typealias XHNetworkRequestCompletionHandler = (_ rawResult: GPNetworkRawResultModel, _ businessModel: Codable?) -> Void

class GPNetworkRequestTask: NSObject {
    
    var manager = GPNetManager.manager
    var longTimeoutManager = GPNetManager.longTimeoutManager
    var defauleHeader: Alamofire.HTTPHeaders {
        
        let version: String = GPApp.version
//        let deviceId: String = "\(XCAMERA_SENSORS_DEVICE_ID)"
        let deviceId: String = DeviceIDManager.deviceID
        let token = "" //XHUserManager.shared.userModel.token
        // V2.9.190版本添加, 跟后台商量, 稳妥起见移动端传标识 , 后台case
//        let deviceModel = GPDevice.shared.getDeviceIdentifier()
        
        var dict = ["iOS-Version": version, "device_id": deviceId, "platform": "iOS", "Authorization": token, "App-UUID": deviceId]
        
        // V2.9.195:网络请求的header中添加x-user-id和x-sign-id 字段，header中 增加的两个key： x-user-id  和  x-sign-id
//        if XHUserManager.shared.isLogin {
//            let userID = XHUserManager.shared.userModel.userId
//            let sign = (userID + sign_key).md5
//            dict["x-user-id"] = userID
//            dict["x-sign-id"] = sign
//        }
        
        // 2.9.273版本：header中增加versionCode
        dict["versionCode"] = version
        
        // V2.0.26：添加国家、语言、时区等通用字段
//        dict["realTimeZone"] = "\(XHRealTimeManager.shared.getGlobalTimeZone().identifier)"
        dict["systemTimeZone"] = "\(TimeZone.current.identifier)"
        dict["countryCode"] = GPCountryManager.geoCountryCode
        dict["appLan"] = "\(GPLanguageManager.xhSpecialLocaleIdentifier())"

        let headers = Alamofire.HTTPHeaders(dict)
        return headers
    }
    
    // 每一次请求都有一个唯一的标识（用于区分每次请求）
    var requestKey: String = ""
    
    // 请求的等级，等级越高越优先调用（用于优先调用重要接口）
    var level: XHNetworkRequestLevel = .normal
    
    // 保存所有传过来的handler
    var requestHandlers: [XHNetworkRequestCompletionHandler?] = []
    
    // 保存谁调用的接口
    var requestAPI: GPNetworkRequestAPI?
    
    // 请求接口的具体参数
    var path: String = ""
    var methodType: MethodType = .get
    var params : [String : Any]?
    var encoding: ParameterEncoding = URLEncoding.default
    
    // 完成的回调
    var completeHandler: ((_ task: GPNetworkRequestTask, _ rawResult: GPNetworkRawResultModel, _ businessModel: Codable?) -> Void)?
    
    // 请求的url
    var currentUrl: String = ""
    
    // 记录当前的请求
    var currentRequest: DataRequest?
    
    // 全球化版本：网络层重构：响应的model类型, 指的是GPNetworkBusinessResult中的data字段
    var responseModelType: Codable.Type = GPNetworkResponseBaseResult.self
    
    deinit {
        // LogDebug("[网络请求调试] - deinit - XHNetworkRequestTask")
    }
    
    // 构建Url， 获取主机名+路径（hostname+path）
    func buildUrl(by path: String) -> String {
        if path == "feedback" {
            return "https://www.aigf.art/api/feedback/new"
        }
        if path == "timezone_old" {
            return "https://www.aigf.art/api/mask/timezone"
        }
        // 新接口通用域名
        let hostname = "timeprint.aiboot.cloud/api/mask/"
        let currentUrl = "https://" + hostname + path
        return currentUrl
    }
    
    // 具体请求的方法
    func startRequest<T: Codable>(dataModelType: T.Type) {
        var using_manager = manager
        let _headers = defauleHeader
        
        let currentUrl = buildUrl(by: path)
        let method: HTTPMethod = methodType == .get ? HTTPMethod.get : HTTPMethod.post
        var finalParams = params
        
//        if isEncryptTransport == true, let currentParams = params, let _ = encoding as? JSONEncoding {
//            var encryptParams:[String : Any] = [:]
//            let jsonStr = BCJson.dictionaryToJsonString(currentParams)
//            let encryptStr = XHSecurityManager.shared.encryptAES(str: jsonStr)
//            encryptParams["params"] = encryptStr
//            
//            finalParams = encryptParams
//        }
                
        // 完整的url
        let paramsStr = String(describing: params ?? [:])
        LogDebug("[网络请求调试] - 开始请求 - url:[\(currentUrl)] - 请求参数:[\(paramsStr)]") // header:[\(_headers)]
        self.currentUrl = currentUrl
        self.currentRequest = using_manager.request(currentUrl, method: method, parameters: finalParams, encoding: encoding, headers: _headers)
        
        /* 全球化版本：网络层重构,该方法已经废弃
         self.currentRequest?.responseJSON(completionHandler: { [weak self] (response) in
         if let weakSelf = self {
         weakSelf.requestFinished(response: response)
         }
         })*/
        
        // 全球化版本：网络层重构
        self.currentRequest?.responseDecodable(of: GPNetworkBusinessResult<T>.self, completionHandler: { [weak self] (response) in
            
            self?.requestFinished(response: response)
        })
    }
    
    /// 请求结束，处理结果
    /// - Parameter response: 结果
    /// 这里虽然使用泛型传过来了GPNetworkBusinessResult，但是不建议使用，因为数据是加密的，解密后才能使用
    private func requestFinished<T: Codable>(response: AFDataResponse<GPNetworkBusinessResult<T>>) {
        
        let result = GPNetworkRawResultModel()
        // http状态码
        let httpCode: Int? = response.response?.statusCode
        
        switch response.result{
        case .success(_): // 枚举里的值不能使用，和response.value值对不上
            
            result.requestState = .success
            result.httpStatusCode = httpCode
            
            result.rawData = response.data
            // 全球化版本：网络层重构,新版本返回的是model
            result.rawModel = response.value
            
            // 下面解析数据
            var finalData = response.data
            
//            if isEncryptTransport == true, let successModel = response.value, let encryptStr = successModel.result, encryptStr.count > 0 {
//                
//                let decryptStr = XHSecurityManager.shared.decryptAES(str: encryptStr)
//                if let decryptDict = BCJson.stringToDictionary(decryptStr), let decryptData = BCJson.jsonToData(decryptDict) {
//                    finalData = decryptData
//                }
//            } else if isEncryptTransport == true, let currentData = response.data, let jsonStr = String(data: currentData, encoding: .utf8), let jsonDict = BCJson.stringToDictionary(jsonStr), let encryptStr = jsonDict["result"] as? String {
//                
//                let decryptStr = XHSecurityManager.shared.decryptAES(str: encryptStr)
//                if let decryptDict = BCJson.stringToDictionary(decryptStr),
//                   let decryptData = BCJson.jsonToData(decryptDict) {
//                    finalData = decryptData
//                }
//            }
            
            result.parsedData = finalData
            
            // 全球化版本：网络层重构
            let businessModel = SpeedyModel.dataToModel(GPNetworkBusinessResult<T>.self, data: result.parsedData)
            result.parsedModel = businessModel
            
//            XHIPManager.shared.update_default_ip(path: path)
            
            // 时间线
            result.timeLine = XHNetworkRequestTimeLine.buildModel(response: response, result: result, apiPath: self.path, url: currentUrl)
            if let handler = self.completeHandler {
                handler(self, result, businessModel)
            }
            
            // 一般情况下注释掉，log太多了会刷屏，需要看接口返回数据的时候打开
            LogDebug("[网络请求调试] - 请求结束 - 请求成功:[\(result.httpStatusCode ?? -888)] - url:[\(self.currentUrl)]")
            
        case .failure(let error):
            // 这里直接使用 (error as NSError).code永远等于13，所以只能使用下面的方法
            if let currentError = error.underlyingError as NSError? {
                if currentError.code == NSURLErrorCancelled {
                    // 用户手动取消
//                    XHIPManager.shared.setRetryCount(path: path, count: 1)
//                    XHIPManager.shared.setIpIndex(path: path, count: nil)
                    
                    LogDebug("[网络请求调试] - 请求结束 - 请求取消:[\(httpCode ?? -888)] - url:[\(self.currentUrl)] - error:[\(String(describing: error))]")
                    result.requestState = .cancel
                    result.error = error
                    result.httpStatusCode = httpCode
                    // 时间线
                    result.timeLine = XHNetworkRequestTimeLine.buildModel(response: response, result: result, apiPath: self.path, url: currentUrl)
                    if let handler = self.completeHandler {
                        handler(self, result, nil)
                    }
                } else {
                    LogDebug("[网络请求调试] - 请求结束 - 请求失败:[\(httpCode ?? -888)] - url:[\(self.currentUrl)] - error:[\(String(describing: error))]")
                    result.requestState = .failure
                    result.error = error
                    result.httpStatusCode = httpCode
                    // 时间线
                    result.timeLine = XHNetworkRequestTimeLine.buildModel(response: response, result: result, apiPath: self.path, url: currentUrl)
//                    self.retryRequest(response: response, error: error, result: result, businessModel: nil)
                    
                    if let handler = self.completeHandler {
                        handler(self, result, nil)
                    }
                    
                }
            } else {
                LogDebug("[网络请求调试] - 请求结束 - 请求失败:[\(httpCode ?? -888)] - url:[\(self.currentUrl)] - error:[\(String(describing: error))]")
                result.requestState = .failure
                result.error = error
                result.httpStatusCode = httpCode
                // 时间线
                result.timeLine = XHNetworkRequestTimeLine.buildModel(response: response, result: result, apiPath: self.path, url: currentUrl)
//                self.retryRequest(response: response, error: error, result: result, businessModel: nil)
                
                if let handler = self.completeHandler {
                    handler(self, result, nil)
                }
            }
        }
    }
    
    // 重试
    private func retryRequest<T: Codable>(response: AFDataResponse<GPNetworkBusinessResult<T>>, error: Error, result: GPNetworkRawResultModel, businessModel: Codable?) {
        
        let errorMsg = error.localizedDescription + "\(error)"
        let apiRequest = GPJson.dictionaryToJsonString(self.params ?? [:])
        let apiResponse = ""
        
//        let currentIpList = XHIPManager.shared.getCurrentUseIpList(path: nil)
        
        /*
         let ip_count = currentIpList.count - 1 //不包含域名
         let total_count = ip_count + 1 //包含域名
         let judgeCount = path == "ios/config" ? total_count : ip_count
         */
//        if let count = XHIPManager.shared.getRetryCount(path: path), currentIpList.count <= count{
//            
//            Report.connect_server_error(api: path, errorInfo: errorMsg, needPingBaidu: true, apiRequest: apiRequest, apiResponse: apiResponse)
//            
//            XHIPManager.shared.setRetryCount(path: path, count: 1)
//            XHIPManager.shared.setIpIndex(path: path, count: nil)
//            
//            LogDebug("[网络请求调试] - 重试次数达到上限，不再重试 - url:[\(self.currentUrl)]")
//            if let handler = self.completeHandler {
//                handler(self, result, businessModel)
//            }
//        }else{
//            if let count = XHIPManager.shared.getRetryCount(path: path){
//                let newCount = count + 1
//                XHIPManager.shared.setRetryCount(path: path, count: newCount)
//            }
//            XHIPManager.shared.updateIpIndex(path: path)
//            
//            // 开始下一次请求
//            LogDebug("[网络请求调试] - 请求失败，开始重试 - url:[\(self.currentUrl)]")
//            self.startRequest(dataModelType: T.self)
//        }
    }
}

extension GPNetworkRequestTask {
    // MARK: - 取消网络请求
    func cancleRequset(){
        LogDebug("[网络请求调试] - 取消网络请求 - url:[\(self.currentUrl)]")
        self.currentRequest?.task?.cancel()
    }
}
