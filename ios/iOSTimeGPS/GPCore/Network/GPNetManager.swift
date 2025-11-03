//
//  GPNetManager.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/3.
//

import Foundation
import Alamofire

class GPNetManager{
    // MARK: - 不校验的域名列表
    private static var disabledTrustEvaluators: [String: ServerTrustEvaluating] {
        
        var paraments = [String: ServerTrustEvaluating]()
        
//        for info in XHIPManager.shared.realAccountIpList{
//            paraments[info] = DisabledTrustEvaluator()
//        }
        
        /* 全球版适配：移除体验账号相关的代码
        for info in XHIPManager.shared.tryAccountIpList{
            paraments[info] = DisabledTrustEvaluator()
        }*/
        return paraments
    }
    
    public static let manager: Alamofire.Session = {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.urlCredentialStorage = nil
        configuration.protocolClasses = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 60
        configuration.httpMaximumConnectionsPerHost = 50
        
        let serverTrustManager = Alamofire.ServerTrustManager(allHostsMustBeEvaluated: false, evaluators: disabledTrustEvaluators)
        let session = Alamofire.Session(configuration: configuration, serverTrustManager: serverTrustManager)
        
        return session
    }()
    
    public static let longTimeoutManager: Alamofire.Session = {
        let timeOut:TimeInterval = 60
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.urlCredentialStorage = nil
        configuration.protocolClasses = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.timeoutIntervalForRequest = timeOut
        configuration.timeoutIntervalForResource = timeOut
        configuration.httpMaximumConnectionsPerHost = 50
        
        let serverTrustManager = Alamofire.ServerTrustManager(allHostsMustBeEvaluated: false, evaluators: disabledTrustEvaluators)
        
        let session = Alamofire.Session(configuration: configuration, serverTrustManager: serverTrustManager)
        return session
    }()
    
    public static let shortTimeoutManager: Alamofire.Session = {
        let timeOut:TimeInterval = 1
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.urlCredentialStorage = nil
        configuration.protocolClasses = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.timeoutIntervalForRequest = timeOut
        configuration.timeoutIntervalForResource = timeOut
        configuration.httpMaximumConnectionsPerHost = 50
        
        let serverTrustManager = Alamofire.ServerTrustManager(allHostsMustBeEvaluated: false, evaluators: disabledTrustEvaluators)
        
        let session = Alamofire.Session(configuration: configuration, serverTrustManager: serverTrustManager)
        return session
    }()
    
    public static let selfAdRequestTimeoutManager: Alamofire.Session = {
        
        var timeOut:TimeInterval = 1
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.urlCredentialStorage = nil
        configuration.protocolClasses = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.timeoutIntervalForRequest = timeOut
        configuration.timeoutIntervalForResource = timeOut
        configuration.httpMaximumConnectionsPerHost = 50
        
        let serverTrustManager = Alamofire.ServerTrustManager(allHostsMustBeEvaluated: false, evaluators: disabledTrustEvaluators)
        
        let session = Alamofire.Session(configuration: configuration, serverTrustManager: serverTrustManager)
        return session
    }()
}
