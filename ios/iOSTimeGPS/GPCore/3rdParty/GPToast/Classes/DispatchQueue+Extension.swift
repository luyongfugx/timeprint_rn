//
//  DispatchQueue+Extension.swift
//  BTFoundation
//
//  Created by batman on 2020/12/2.
//

import Foundation


extension DispatchQueue {
    
    /// 确保切换主线程安全
    func safeSync(_ block: ()->()) {
        if self === DispatchQueue.main && Thread.isMainThread {
            block()
        } else {
            sync { block() }
        }
    }
}




