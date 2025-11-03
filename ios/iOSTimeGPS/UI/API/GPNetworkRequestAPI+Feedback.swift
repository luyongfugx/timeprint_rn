//
//  GPNetworkRequestAPI+Feedback.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/20.
//

import Foundation
import Alamofire

extension GPNetworkRequestAPI {
        
    func feedback(title: String, content: String, finishedHandle: @escaping ((_ error:Error?, _ message: GPResModel?)->())){
        
        let params = ["title": title,
                      "user": DeviceIDManager.deviceID,
                      "version": GPApp.version,
                      "content": content] as [String : Any]
        
        XHNetworkRequestManager.shared.request(requestAPI: self, path: "feedback", methodType: .post, params:params,encoding:JSONEncoding.default, completionHandler: { (error, result:GPResModel?, httpResult) in
            
            finishedHandle(error, result)
        })
    }

}
