//
//  GPNetworkRequestManager.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/3.
//

import UIKit
import Foundation
import Alamofire

// 请求方法
enum MethodType {
    case get
    case post
}

// 网络请求的等级
enum XHNetworkRequestLevel: Int {
    case high = 2
    case normal = 1
    case low = 0
}

class XHNetworkRequestManager: NSObject {
    
    static let shared = XHNetworkRequestManager()
    
    // 正在执行的任务
    var tasks: [String : GPNetworkRequestTask] = [:]
    let tasksLock = NSRecursiveLock()
    
    // 等待的队列
    var waitQueue: [GPNetworkRequestTask] = []
    
    // 所有的任务,包括正在执行的和等待的
    var allTasks: [String : GPNetworkRequestTask] = [:]
    
    // 全球化版本：网络层重构,最大并发数从6改为10
    let maxCacheCount = 10 // 6
    
    var isStopDevice: Bool = false
    
    private override init() {
        super.init()
    }
    
    /// 网络请求外部调用的方法
    /// - Parameters:
    ///   - requestAPI: 调用的实例
    ///   - requestKey: 请求的key，用于标识本次请求的唯一性，如果等于nil，就根据参数生成
    ///   - path: 接口的名称
    ///   - methodType: 请求方法
    ///   - params: 参数
    ///   - encoding: 编码：默认是JSONEncoding.default 不能修改成这个，有些接口使用的是这个
    ///   - level: 请求等级：等级越高，请求的时机越靠前
    ///   - cache: 是否缓存数据，默认是：不缓存
    ///   - completionHandler: 请求结束的回调
    ///   - cacheCallback: 缓存数据的回调
    func request<T: Codable>(requestAPI: GPNetworkRequestAPI?,
                             requestKey: String? = nil,
                             path: String,
                             methodType: MethodType,
                             params: [String: Any]?,
                             encoding: ParameterEncoding = URLEncoding.default,
                             level: XHNetworkRequestLevel = .normal,
//                             cache: XHNetworkRequestCache = .noCache,
                             completionHandler: ((Error?, T?, GPNetworkRawResultModel) -> Void)?,
                             cacheCallback: ((T?, _ cacheKey: String?) -> Void)? = nil) {
        
        if self.isStopDevice {
            return
        }
        
        // 获取缓存数据
//        switch cache {
//        case .cache(let outsetKey, let cacheType):
//            if let callback = cacheCallback {
//                let cacheInfo = XHNetworkRequestCache.getCacheData(outsetKey: outsetKey, cacheType: cacheType, apiPath: path, paramDict: params, dataType: T.self)
//                callback(cacheInfo.cacheModel, cacheInfo.cacheKey)
//            }
//        default:
//            break
//        }
        
        let canMonitorApi = shouldMonitorApi(path: path)
        // V2.0.65：监控地址接口
        let startRequestTime = Date()

        requestRawData(requestAPI: requestAPI, requestKey: requestKey, path: path, methodType: methodType, params: params, encoding: encoding, level: level, dataModelType: T.self) { (httpResult, businessModel) in
            
            let endRequestTime = Date()
            let requestTotalTime = endRequestTime.timeIntervalSince(startRequestTime)
            var isApiSuccess = false
            var businessCode = 0
            var serverProcessTime: TimeInterval = 0
            
            if httpResult.requestState == .success {
                let model = businessModel as? GPNetworkBusinessResult<T>
                if let resultModel = model, let toast = resultModel.toast_msg, toast.count > 0{
                    GPApp.topViewController?.view.showText(toast)
                }
                
                businessCode = model?.code ?? 0
                serverProcessTime = TimeInterval(model?.serverProcessTime ?? 0)
                
                if model?.code == 200 || model?.data != nil {
                    completionHandler?(nil, model?.data, httpResult)
                    isApiSuccess = true
                    // 全球化版本：网络层重构，保存缓存数据
//                    switch cache {
//                    case .cache(let outsetKey, let cacheType):
//                        let cacheKey = XHNetworkRequestCache.buildCacheKey(outsetKey: outsetKey, apiPath: path, paramDict: params)
//                        XHNetworkRequestCache.saveCacheData(businessModel: model?.data, cacheKey: cacheKey, cacheType: cacheType)
//                    default:
//                        break
//                    }
                    
                } else {
                    LogDebug("[网络请求调试] - HTTP请求成功，但是code不等于200，按失败处理，code:[\((model?.code ?? -1))]")
                    let error = NSError(domain: model?.msg ?? "", code: (model?.code ?? -1), userInfo: ["message":model?.msg ?? ""])
                    httpResult.httpStatusCode = model?.code
                    completionHandler?(error, nil, httpResult)
                }
            } else {
                completionHandler?(httpResult.error, nil, httpResult)
            }
            
            if canMonitorApi {
                let requestInfo = "全球化版本 - 开始请求地址时间:[\(startRequestTime.toString_xh())] - 结束请求时间:[\(endRequestTime.toString_xh())] - 接口请求耗时[\(requestTotalTime)]秒]"
                var httpCode = httpResult.httpStatusCode ?? 0
                var errorString = ""
                if let error = httpResult.error as NSError? {
                    if httpCode == 0 {
                        httpCode = error.code
                    }
                    errorString = "\(String(describing: error))"
                }
                
                var otherParams: [String: Any]?
//                if XHAPPConfigureManager.shared.configureModel?.ios?.ios_enabel_more_api_info_switch == "1" {
//                    otherParams = ["fetchStartDate2": httpResult.timeLine?.fetchStartDate ?? "",
//                                                  "domainLookupStartDate2": httpResult.timeLine?.domainLookupStartDate ?? "",
//                                                  "domainLookupEndDate2": httpResult.timeLine?.domainLookupEndDate ?? "",
//                                                  "connectStartDate2": httpResult.timeLine?.connectStartDate ?? "",
//                                                  "secureConnectionStartDate2": httpResult.timeLine?.secureConnectionStartDate ?? "",
//                                                  "secureConnectionEndDate2": httpResult.timeLine?.secureConnectionEndDate ?? "",
//                                                  "connectEndDate2": httpResult.timeLine?.connectEndDate ?? "",
//                                                  "requestStartDate2": httpResult.timeLine?.requestStartDate ?? "",
//                                                  "requestEndDate2": httpResult.timeLine?.requestEndDate ?? "",
//                                                  "responseStartDate2": httpResult.timeLine?.responseStartDate ?? "",
//                                                  "responseEndDate2": httpResult.timeLine?.responseEndDate ?? "",
//                                                  "networkProtocolName2": httpResult.timeLine?.networkProtocolName ?? "",
//                                                  "remotePort2": httpResult.timeLine?.remotePort ?? -1,
//                                                  "localPort2": httpResult.timeLine?.localPort ?? -1,
//                                                  "isCellular2": httpResult.timeLine?.isCellular ?? false,
//                                                  "isExpensive": httpResult.timeLine?.isExpensive ?? false,
//                                                  "isConstrained2": httpResult.timeLine?.isConstrained ?? false,
//                                                  "isMultipath2": httpResult.timeLine?.isMultipath ?? false,
//                                                  "isProxyConnection2": httpResult.timeLine?.isProxyConnection ?? false,
//                                                  "isReusedConnection": httpResult.timeLine?.isReusedConnection ?? false]
//                }
//                
//                Report.global_api_monitor(isSucess: isApiSuccess, serverProcessTime: serverProcessTime, requestTotalTime: requestTotalTime*1000, apiPath: path, errorCode: businessCode, httpCode: httpCode, errorMsg: errorString, otherParams: otherParams)
            }

        }
    }
    
    // 私有方法：生成请求任务，开始请求
    private func requestRawData<T: Codable>(requestAPI: GPNetworkRequestAPI?,
                                            requestKey: String? = nil,
                                            path: String,
                                            methodType: MethodType,
                                            params : [String : Any]?,
                                            encoding: ParameterEncoding = URLEncoding.default,
                                            level: XHNetworkRequestLevel = .normal,
                                            dataModelType: T.Type,
                                            completionHandler: XHNetworkRequestCompletionHandler?) {
        
        self.tasksLock.lock()
        
        // 用于标识接口的唯一性
        let currentRequestKey = buildRequestKey(outsetKey: requestKey, apiPath: path, paramDict: params)
        
        if let tempTask = self.allTasks[currentRequestKey], tempTask.requestAPI?.caller?.isEqual(requestAPI?.caller) == true {
            
            // LogDebug("[网络请求调试] - requestRawData - 该任务已经存在（执行或排队）,不再创建任务 - 正在执行的数量[\(self.tasks.count)] - 排队数量[\(self.waitQueue.count)] - 当前任务的path:[\(path)]")
            tempTask.requestHandlers.append(completionHandler)
            self.tasksLock.unlock()
            return
        }
        
        if let executingTask = self.tasks[currentRequestKey] {
            // LogDebug("[网络请求调试] - requestRawData - 已存在的任务 - 正在执行的数量[\(self.tasks.count)] - 排队数量[\(self.waitQueue.count)] - 当前任务的path:[\(path)]")
            executingTask.requestHandlers.append(completionHandler)
            executingTask.completeHandler = {[weak self] (currentTask, result, businessModel) in
                
                self?.oneRequestTaskCompleted(currentTask: currentTask, result: result, businessModel: businessModel)
            }
        } else {
            let singleTask = GPNetworkRequestTask()
            
            singleTask.requestKey = currentRequestKey
            singleTask.level = level
            singleTask.requestAPI = requestAPI
            
            singleTask.path = path
            singleTask.methodType = methodType
            singleTask.params = params
            singleTask.encoding = encoding
            singleTask.requestHandlers = [completionHandler]
            
            // 全球化版本：网络层重构
            singleTask.responseModelType = T.self
            
            // 添加到所有的任务列表
            self.allTasks[singleTask.requestKey] = singleTask
            
            if self.tasks.count >= self.maxCacheCount {
                var index = self.waitQueue.count
                for (i, waitTask) in self.waitQueue.enumerated() {
                    if waitTask.level.rawValue < singleTask.level.rawValue {
                        index = i
                        break
                    }
                }
                self.waitQueue.insert(singleTask, at: index)
                // LogDebug("[网络请求调试] - requestRawData - 创建新的任务 - 需要排队 - 正在执行的数量[\(self.tasks.count)] - 排队数量:[\(self.waitQueue.count)] - 插入的index[\(index)] - 新任务path[\(singleTask.path)]")
            } else {
                // LogDebug("[网络请求调试] - requestRawData - 创建新的任务 - 不需要排队 - 正在执行的数量[\(self.tasks.count)] - 排队数量[\(self.waitQueue.count)] - 新任务path[\(singleTask.path)]")
                self.startRequest(task: singleTask, dataModelType: dataModelType)
            }
        }
        
        self.tasksLock.unlock()
    }
    
    private func startRequest<T: Codable>(task: GPNetworkRequestTask, dataModelType: T.Type) {
        
        self.tasks[task.requestKey] = task
        task.startRequest(dataModelType: dataModelType)
        task.completeHandler = {[weak self] (currentTask, result, businessModel) in
            
            self?.oneRequestTaskCompleted(currentTask: currentTask, result: result, businessModel: businessModel)
        }
        // LogDebug("[网络请求调试] - 开始新的任务 - 正在执行的数量[\(self.tasks.count)] - 排队数量[\(self.waitQueue.count)]")
    }
    
    /// 2.9.233:一次网络请求完成
    private func oneRequestTaskCompleted(currentTask: GPNetworkRequestTask, result: GPNetworkRawResultModel, businessModel: Codable?) {
        
        // LogDebug("[网络请求调试] - 一次网络请求完成 - url:[\(currentTask.currentUrl)]")
        self.removeTask(key: currentTask.requestKey)
        for handler in currentTask.requestHandlers {
            if let handler = handler {
                // LogDebug("[网络请求调试] - 网络请求完成 - url:[\(currentTask.currentUrl)] - 回调给外部的使用者")
                handler(result, businessModel)
            }
        }
    }
    
    // MARK: - 移除任务
    private func removeTask(key: String) {
        
        self.tasksLock.lock()
        
        self.allTasks.removeValue(forKey: key)
        self.tasks.removeValue(forKey: key)
        if self.waitQueue.count > 0, let firstTask = self.waitQueue.first {
            
            self.startRequest(task: firstTask, dataModelType: firstTask.responseModelType)
            self.waitQueue.removeFirst()
        }
        
        // LogDebug("[网络请求调试] - 正在执行的数量[\(self.tasks.count)] - 排队的数量[\(self.waitQueue.count)]")
        self.tasksLock.unlock()
    }
    
    func shouldMonitorApi(path: String) -> Bool {
        return false
    }
}

// MARK: - 取消网络请求
extension XHNetworkRequestManager {
    
    // MARK: - 取消所有的任务
    func cancleAllTasks(){
        for (_, currentTask) in self.allTasks {
            self.cancleTask(path: currentTask.path)
        }
    }
    
    func cancelTasks(caller: AnyObject?, callKey: String?) {
        
        if let callKey = callKey, callKey.count > 0 {
            for (_, currentTask) in self.allTasks {
                if currentTask.requestAPI?.callerKey == callKey {
                    self.cancleTask(path: currentTask.path)
                    // LogDebug("[网络请求调试] - 通过key取消，path[\(currentTask.path)]")
                }
            }
        } else {
            if let caller = caller {
                for (_, currentTask) in self.allTasks {
                    if currentTask.requestAPI?.caller?.isEqual(caller) == true {
                        self.cancleTask(path: currentTask.path)
                        // LogDebug("[网络请求调试] - 通过caller取消，path[\(currentTask.path)]")
                    }
                }
            }
        }
    }
    
    // MARK: - 取消多个任务
    func cancleTasks(paths: [String]) {
        for tempPath in paths {
            self.cancleTask(path: tempPath)
        }
    }
    
    // MARK: - 取消单条任务
    func cancleTask(path: String) {
        
        self.tasksLock.lock()
        
        for (_, currentTask) in self.tasks {
            if path == currentTask.path {
                // LogDebug("[网络请求调试] - 从正在执行的队列里 - 取消请求任务path[\(path)]")
                currentTask.cancleRequset()
            }
        }
        
        let waitTask = self.getTaskFromWaitQueue(path)
        if waitTask.0 < self.waitQueue.count, let currentTask = waitTask.1 {
            let result = GPNetworkRawResultModel()
            result.requestState = .cancel
            result.error = NSError(domain: "用户手动取消请求", code: NSURLErrorCancelled, userInfo: nil)
            
            for handler in currentTask.requestHandlers {
                if let handler = handler {
                    handler(result, nil)
                }
            }
            
            // LogDebug("[网络请求调试] - 从等待队列里 - 取消请求任务path[\(path)]")
            self.waitQueue.remove(at: waitTask.0)
        }
        
        for (key, currentTask) in self.allTasks {
            if path == currentTask.path {
                self.allTasks.removeValue(forKey: key)
                break
            }
        }
        
        // LogDebug("[网络请求调试] - 已经取消请求任务path[\(path)]")
        self.tasksLock.unlock()
    }
}

// MARK: - 私有方法
extension XHNetworkRequestManager {
    
    // 从等待队列里查找任务
    private func getTaskFromWaitQueue(_ path: String) -> (Int, GPNetworkRequestTask?) {
        
        var result: (Int, GPNetworkRequestTask?) = (-1, nil)
        for (index, tempTask) in self.waitQueue.enumerated() {
            if tempTask.path == path {
                result = (index, tempTask)
                break
            }
        }
        return result
    }
    
    /// 根据接口信息生成requestKey
    /// - Parameters:
    ///   - outsetKey: 外面设置的key
    ///   - apiPath: 接口的path
    ///   - paramDict: 参数
    /// - Returns: requestKey
    private func buildRequestKey(outsetKey: String?, apiPath: String, paramDict: [String: Any]?) -> String {
        
        var currentRequestKey: String = ""
        
        let tempOutsetKey = outsetKey ?? ""
        if tempOutsetKey.count > 0 {
            // 1、如果外部设置的key存在，优先使用外部设置的key
            currentRequestKey = tempOutsetKey
        } else {
            // 2、如果外部没有设置，就根据接口的path和参数生成一个唯一的字符串
            var paramStr = ""
            if let tempParams = paramDict {
                paramStr = self.getParamsString(dict: tempParams)
            }
            
            if paramStr.count > 0 {
                currentRequestKey = "\(apiPath)_\(paramStr)"
            } else {
                currentRequestKey = apiPath
            }
            
//            currentRequestKey = currentRequestKey.md5()
            // 测试代码，替换md5
            currentRequestKey = NSUUID().uuidString
            
        }
        
        // LogDebug("[网络请求调试] - buildRequestKey - path:[\(apiPath)] - requestKey:[\(currentRequestKey)]")
        return currentRequestKey
    }
    
    /// 根据参数生成唯一的字符串：相同的字典，每次转化成字符串也是不同的，字典中顺序是不一样的,所以先对keys排序，然后取values数组
    /// - Parameter dict: 参数的字典
    /// - Returns: 参数数组生成的字符串
    /// 注意：这个方法是把所有的参数的value放到数组中，然后生成字符串，如果参数特别多会不会有性能问题呢？
    /// 经过测试：不会超过1毫秒，所以性能问题可以忽略不计
    func getParamsString(dict: [String: Any]) -> String {
        
        if dict.count == 0 {
            return ""
        }
        
        var newArray:[Any] = []
        let keys = dict.keys.sorted()
        for oneKey in keys {
            if let oneValue = dict[oneKey] {
                newArray.append(oneValue)
            }
        }
        let paramsStr = GPJson.arrayToJsonString(newArray)
        // LogDebug("[网络请求调试] - paramsStr:[\(paramsStr)]")
        return paramsStr
    }
}
