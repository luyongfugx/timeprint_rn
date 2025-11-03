//
//  GPBusinessModel.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/3.
//

import Foundation

class GPRealTimeModel: GPCodable{
    
    var status: Int?
    var msg: String?
    
    var time: String?
    var timeZone: String?
    
    // 秒级时间戳
    var timestamp: Int?
}

class GPResModel: GPCodable{
    
    var status: Int?
    var msg: String?
    
}

class GPConfigResModel: GPCodable{
    
    var appId: Int?
    var cluster: String?
    var namespaceName: String?
    var configurations: GPConfigModel?
    var releasekey: String?

}

class GPConfigModel: GPCodable{
    
    var test: String?
    var uploadRate: String?
    
    class func defaultM() -> GPConfigModel {
        let model = GPConfigModel()
        model.uploadRate = "100"
        return model
    }
}
