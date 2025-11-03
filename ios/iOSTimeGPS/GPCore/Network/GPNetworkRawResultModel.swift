//
//  GPNetworkRawResultModel.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/3.
//

import UIKit
import Foundation
import Alamofire

enum XHNetworkRequestState: Int, GPCodable {
    // 请求成功
    case success = 1
    // 请求失败
    case failure = 2
    // 请求被取消
    case cancel = 3
}

/*
 * 说明：这个model记录的是本次http请求的数据以及详细的时间线，不涉及具体的业务。
 * 这里存储了获取的原始data和json数据，需要在业务层进行model的转化。
 */
class GPNetworkRawResultModel {
    
    // 请求结果状态
    var requestState: XHNetworkRequestState = .success
    
    // http的状态码，只用等于200的才算业务层的成功
    var httpStatusCode: Int?
    
    // 原始数据：加密情况下还没有解密，只有success才会有值，否则为nil
    var rawData: Data?
    // 全球化版本：网络层重构,新版本返回的是model;加密情况下还没有解密，只有success才会有值，否则为nil
    var rawModel: Codable?
    
    // 全球化版本：网络层重构，解析后的数据;解密后的数据，只有success才会有值，否则为nil
    var parsedData: Data?
    // 全球化版本：网络层重构，解析后的model; 解密后的数据，只有success才会有值，否则为nil
    var parsedModel: Codable?
    
    // 只有failure才会有值，否则为nil
    var error: Error?
    
    // 全球化版本：网络层重构：网络请求的时间线
    var timeLine: XHNetworkRequestTimeLine?
    
    // 方便查看数据类型，json:AnyObject 在控制台没有办法查看 Int 类型，还是 String类型
    var jsonString: String {
        if let data = parsedData {
            guard let str = String.init(data: data, encoding: .utf8) else { return "" }
            return str
        }else{
            return ""
        }
    }
}

// var metrics: URLSessionTaskMetrics?
class XHNetworkRequestTimeLine: GPCodable {
    
    // 开始时间
    var startDate: String?
    // 结束时间
    var endDate: String?
    // 总耗时：毫秒(ms)
    var totalDuration: Int? = 0
    
    // 序列化用时：毫秒(ms) The time taken to serialize the response.
    var serializationDuration: Int? = 0
    
    // 重定向的次数
    var redirectCount: Int?
    
    // 以下指标参考官网：https://developer.apple.com/documentation/foundation/urlsessiontasktransactionmetrics
    // The time when the task started fetching the resource, from the server or locally.
    var fetchStartDate: String?
    
    // The time immediately before the task started the name lookup for the resource.
    var domainLookupStartDate: String?
    
    // The time after the name lookup was completed.
    var domainLookupEndDate: String?
    
    // The time immediately before the task started establishing a TCP connection to the server.
    var connectStartDate: String?
    
    // The time immediately before the task started the TLS security handshake to secure the current connection.
    var secureConnectionStartDate: String?
    
    // The time immediately after the security handshake completed.
    var secureConnectionEndDate: String?
    
    // The time immediately after the task finished establishing the connection to the server.
    var connectEndDate: String?
    
    // The time immediately before the task started requesting the resource, regardless of whether it is retrieved from the server or local resources.
    var requestStartDate: String?
    
    // The time immediately after the task finished requesting the resource, regardless of whether it was retrieved from the server or local resources.
    var requestEndDate: String?
    
    // The time immediately after the task received the first byte of the response from the server or from local resources.
    var responseStartDate: String?
    
    // The time immediately after the task received the last byte of the resource.
    var responseEndDate: String?
    
    // The network protocol used to fetch the resource.
    var networkProtocolName: String?
    
    // The IP address string of the remote interface for the connection.
    var remoteAddress: String?
    
    // The port number of the remote interface for the connection.
    var remotePort: Int?
    
    // The IP address string of the local interface for the connection.
    var localAddress: String?
    
    // The port number of the local interface for the connection.
    var localPort: Int?
    
    // A Boolean value that indicastes whether the task used a proxy connection to fetch the resource.
    var isProxyConnection: Bool?
    
    // A Boolean value that indicates whether the task used a persistent connection to fetch the resource.
    var isReusedConnection: Bool?
    
    // A Boolean value that indicates whether the connection operates over a cellular interface.
    var isCellular: Bool?
    
    // A Boolean value that indicates whether the connection operates over an expensive interface.
    var isExpensive: Bool?
    
    // A Boolean value that indicates whether the connection operates over an interface marked as constrained.
    var isConstrained: Bool?
    
    // A Boolean value that indicates whether the connection uses a successfully negotiated multipath protocol.
    var isMultipath: Bool?
     
    
    static func buildModel<T: Codable>(response: AFDataResponse<GPNetworkBusinessResult<T>>, result: GPNetworkRawResultModel, apiPath: String, url: String) -> XHNetworkRequestTimeLine {
        
        guard let metrics = response.metrics else {
            return XHNetworkRequestTimeLine()
        }
        
        let timeFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let totalDurationMS = Int(metrics.taskInterval.duration * 1000)
        
        let newModel = XHNetworkRequestTimeLine()
        newModel.startDate = metrics.taskInterval.start.toString_xh(format: timeFormat)
        newModel.endDate = metrics.taskInterval.end.toString_xh(format: timeFormat)
        newModel.totalDuration = totalDurationMS
        newModel.serializationDuration = Int(response.serializationDuration * 1000)
        newModel.redirectCount = metrics.redirectCount
        
        
        if let transaction = metrics.transactionMetrics.first {
            
            newModel.fetchStartDate = transaction.fetchStartDate?.toString_xh(format: timeFormat)
            newModel.domainLookupStartDate = transaction.domainLookupStartDate?.toString_xh(format: timeFormat)
            newModel.domainLookupEndDate = transaction.domainLookupEndDate?.toString_xh(format: timeFormat)
            newModel.connectStartDate = transaction.connectStartDate?.toString_xh(format: timeFormat)
            newModel.secureConnectionStartDate = transaction.secureConnectionStartDate?.toString_xh(format: timeFormat)
            newModel.secureConnectionEndDate = transaction.secureConnectionEndDate?.toString_xh(format: timeFormat)
            newModel.connectEndDate = transaction.connectEndDate?.toString_xh(format: timeFormat)
            newModel.requestStartDate = transaction.requestStartDate?.toString_xh(format: timeFormat)
            newModel.requestEndDate = transaction.requestEndDate?.toString_xh(format: timeFormat)
            newModel.responseStartDate = transaction.responseStartDate?.toString_xh(format: timeFormat)
            newModel.responseEndDate = transaction.responseEndDate?.toString_xh(format: timeFormat)
            newModel.networkProtocolName = transaction.networkProtocolName
            if #available(iOS 13.0, *) {
                newModel.remoteAddress = transaction.remoteAddress
                newModel.remotePort = transaction.remotePort
                newModel.localAddress = transaction.localAddress
                newModel.localPort = transaction.localPort
                newModel.isCellular = transaction.isCellular
                newModel.isExpensive = transaction.isExpensive
                newModel.isConstrained = transaction.isConstrained
                newModel.isMultipath = transaction.isMultipath
            }
            newModel.isProxyConnection = transaction.isProxyConnection
            newModel.isReusedConnection = transaction.isReusedConnection
        }
        
        // 如果大于15秒，上报埋点
        if totalDurationMS > 15000 {
//            Report.iOS_network_request_took_more_than_15_seconds(apiPath: apiPath, requestUrl: url, totalDurationMS: totalDurationMS)
//            XHLogDebug("[网络请求调试] - 时间线 - 开始请求时间:[\(newModel.startDate ?? "")] - 结束请求时间:[\(newModel.endDate ?? "")] - 总耗时:[\(newModel.totalDuration ?? 0)] - 序列化时间:[\(newModel.serializationDuration ?? -1)]")
        }
        
        return newModel
    }
}
