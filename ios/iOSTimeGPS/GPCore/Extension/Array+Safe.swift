//
//  Array+Safe.swift
//  XCamera
//
//  Copyright © 2022 xhey. All rights reserved.
//

import Foundation

extension Array {

    /// 防止数组越界的取值方法
    ///
    ///     let list: [Int] = [1, 34, 23, 36, 335]
    ///     if let number = list[safe: 3] {
    ///         ...
    ///     }
    ///
    /// - Parameters:
    ///   - index: index
    /// - Returns: 如果`index`越界，则返回`nil`，反之则取到对应的值
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
    
    mutating func safeInsert(_ element: Element, at index: Int) {
        if index >= 0 && index < count {
            insert(element, at: index)
        }
    }
}

