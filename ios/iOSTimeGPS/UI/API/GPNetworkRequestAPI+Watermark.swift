//
//  GPNetworkRequestAPI+Watermark.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/3.
//

import Foundation
import Alamofire

extension GPNetworkRequestAPI {
        
    // 真实时间接口
    func realtime(lat: Double, lon: Double, finishedHandle: @escaping ((_ error:Error?, _ message: GPRealTimeModel?)->())){
        
        let params = ["lat": lat,
                      "lon": lon] as [String : Any]
        
        XHNetworkRequestManager.shared.request(requestAPI: self, path: "timezone", methodType: .post, params:params,encoding:JSONEncoding.default, completionHandler: { (error, result:GPRealTimeModel?, httpResult) in
            if error != nil {
                // 新接口失败，使用老接口兜底
                tryOldTimeApiWhenFail()
            } else {
                // 新接口成功
                finishedHandle(error, result)
            }
        })
        
        func tryOldTimeApiWhenFail() {
            XHNetworkRequestManager.shared.request(requestAPI: self, path: "timezone_old", methodType: .post, params:params,encoding:JSONEncoding.default, completionHandler: { (error, result:GPRealTimeModel?, httpResult) in
                
                finishedHandle(error, result)
            })
        }
    }

}
