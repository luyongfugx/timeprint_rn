//
//  GPNetworkRequestAPI.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/3.
//

import Foundation
import UIKit
import Alamofire

var networkRequestCallKey = "networkRequestCallKey"

// 全球化版本：网络层重构,网络接口协议
public protocol XHNetworkAPIProtocol {}

extension XHNetworkAPIProtocol where Self: AnyObject {
    
    // 每个实例的网络请求对应的key，同一个实例发起的网络请求是一样的
    var requestCallKey: String? {
        set {
            objc_setAssociatedObject(self, &networkRequestCallKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
        get {
            if let key = objc_getAssociatedObject(self, &networkRequestCallKey) as? String {
                return key
            }
            return nil
        }
    }
    
    // 实例变量
    var networkAPI: GPNetworkRequestAPI {
        
        let caller = GPNetworkRequestAPI(caller: self, callerKey: self.requestCallKey ?? "")
        return caller
    }
    
    // 类变量
    static var networkAPI: GPNetworkRequestAPI {
        let caller = GPNetworkRequestAPI(caller: self)
        return caller
    }
    
    // MARK: - 通过caller取消网络请求
    func cancelNetworkTask() {
        XHNetworkRequestManager.shared.cancelTasks(caller: self, callKey: self.requestCallKey)
    }
    
    // MARK: - 通过path取消网络请求
    func cancelNetworkTask(path: String) {
        XHNetworkRequestManager.shared.cancleTask(path: path)
    }
    
    // MARK: - 取消所有的任务
    func cancleAllNetworkTasks(){
        XHNetworkRequestManager.shared.cancleAllTasks()
    }
}

// 全球化版本：网络层重构，NSObject接受XHNetworkAPIProtocol
extension NSObject: XHNetworkAPIProtocol {
    
}


class GPNetworkRequestAPI: NSObject {
    
    weak var caller: AnyObject?
    var callerKey: String?
    
    deinit {
        // XHLogDebug("[网络请求调试] - deinit - XHNetworkRequestAPI")
    }
    
    init(caller: AnyObject?, callerKey: String? = nil) {
        self.caller = caller
        self.callerKey = callerKey
        super.init()
    }
}
