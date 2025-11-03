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
    var logRate: String?
    var close_new_five_star: String?
    // 天气缓存时长,单位小时
    var weatherCachHour: String?
    var guideToNewApp: String?
    // 例如腾讯水印相机id637428894
    var guideToNewAppID: String?
    var close_recommend_tf: String?

    class func defaultM() -> GPConfigModel {
        let model = GPConfigModel()
        model.uploadRate = "100"
        model.logRate = "100"
        model.close_new_five_star = "0"
        model.weatherCachHour = "1"
        model.close_recommend_tf = "0"
        return model
    }
}
