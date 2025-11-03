//
//  WatermarkTimeItem.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/2.
//

import Foundation

// 时间补充信息
class WatermarkTimeItem: NSObject, GPCodable {
    var dateStyle: Int?
    var dateStyleEnum: GPDateStyle {
        get {
            return GPDateStyle.init(rawValue: dateStyle ?? 1) ?? .dayMonthYear
        }
    }
    var is12Hour: Bool?
    var showWeak: Bool?
    var showTimeZone: Bool?

}
