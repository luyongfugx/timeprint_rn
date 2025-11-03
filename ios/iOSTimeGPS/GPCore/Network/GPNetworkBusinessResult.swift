//
//  GPNetworkBusinessResult.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/3.
//

import Foundation

/*
 * 说明：这个model记录的是业务数据格式
 * 直接使用这个model中的data进行业务开发
 */
struct GPNetworkBusinessResult<T: Codable>: GPCodable {
    var code: Int? = 0
    var msg: String? = ""
    var toast_msg: String?
    var data: T?
    
    // 全球化版本：网络层重构，客户端添加，当加密的时候，用result字段接收加密的字符串
    var result: String?
    
    // V2.0.65: 服务端内部耗时时间
    var serverProcessTime: Int?

}

// MARK: - 只返回status和msg的时候使用这个model
class GPNetworkResponseBaseResult: GPCodable {
    
    var status: Int?
    var msg: String?
}
