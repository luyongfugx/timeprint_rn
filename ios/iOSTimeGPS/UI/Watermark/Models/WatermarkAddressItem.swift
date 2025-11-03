//
//  WatermarkAddressItem.swift
//  iOSTimeGPS
//
//

import Foundation

// 地址补充信息
class WatermarkAddressItem: NSObject, GPCodable {
    
    private var addressStyleInt: Int?
    var addressStyle: GPAddressStyle {
        get {
            return GPAddressStyle.init(rawValue: addressStyleInt ?? 0) ?? .formatAddress
        } set {
            addressStyleInt = newValue.rawValue
        }
    }
       
}
