//
//  GPGlobal.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/9/16.
//

import Foundation

typealias GPVoidBlock = () -> Void
typealias GPStringBlock = (String) -> Void
typealias GPBoolBlock = (Bool) -> Void
typealias GPCGFloatBlock = (CGFloat) -> Void

/// 安全的主线程异步切换
func GPSafeMainAsync(callback: @escaping GPVoidBlock) {
    
    if Thread.isMainThread {
        callback()
    } else {
        DispatchQueue.main.async {
            callback()
        }
    }
}

//MARK:音量记录
var XCAMERA_APP_VOLUME:Float = 0
