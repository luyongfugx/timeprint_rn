//
//  Adapter.swift
//  XCamera
//
//  Created by batman on 2021/7/18.
//  Copyright © 2021 xhey. All rights reserved.
//

import Foundation

// String 默认值
extension String: DefaultValue, LosslessValue {
    static let defaultValue = ""
    
    enum Empty: DefaultValue, LosslessValue {
        static let defaultValue = ""
    }
}

// Int 默认值
extension Int: DefaultValue, LosslessValue {
    static let defaultValue = Int.zero
    
    enum Zero: DefaultValue, LosslessValue {
        static let defaultValue = Int.zero
    }
}

// Double 默认值
extension Double: DefaultValue, LosslessValue {
    static let defaultValue = Double.zero
    
    enum Zero: DefaultValue, LosslessValue {
        static let defaultValue = Double.zero
    }
}

// CGFloat 默认值
extension CGFloat: DefaultValue {
    static let defaultValue = CGFloat.zero
    
    enum Zero: DefaultValue {
        static let defaultValue = CGFloat.zero
    }
}

// Bool 默认值
extension Bool: DefaultValue, LosslessValue {
    static var decodableTypes: [(Decoder) -> LosslessStringCodable?] {
        @inline(__always)
        func decode<T: LosslessStringCodable>(_: T.Type) -> (Decoder) -> LosslessStringCodable? {
            return { try? T.init(from: $0) }
        }

        @inline(__always)
         func decodeBoolFromNSNumber() -> (Decoder) -> LosslessStringCodable? {
             return { (try? Int.init(from: $0)).flatMap { Bool(exactly: NSNumber(value: $0)) } }
         }
        
        return [
            decode(String.self),
            decodeBoolFromNSNumber(),
            decode(Bool.self),
            decode(Int.self),
            decode(Int8.self),
            decode(Int16.self),
            decode(Int64.self),
            decode(UInt.self),
            decode(UInt8.self),
            decode(UInt16.self),
            decode(UInt64.self),
            decode(Double.self),
            decode(Float.self),
        ]
    }
    
    static let defaultValue = false
    
    enum False: DefaultValue, LosslessValue {
        static let defaultValue = false
        
        static var decodableTypes: [(Decoder) -> LosslessStringCodable?] {
            @inline(__always)
            func decode<T: LosslessStringCodable>(_: T.Type) -> (Decoder) -> LosslessStringCodable? {
                return { try? T.init(from: $0) }
            }

            @inline(__always)
             func decodeBoolFromNSNumber() -> (Decoder) -> LosslessStringCodable? {
                 return { (try? Int.init(from: $0)).flatMap { Bool(exactly: NSNumber(value: $0)) } }
             }
            
            return [
                decode(String.self),
                decodeBoolFromNSNumber(),
                decode(Bool.self),
                decode(Int.self),
                decode(Int8.self),
                decode(Int16.self),
                decode(Int64.self),
                decode(UInt.self),
                decode(UInt8.self),
                decode(UInt16.self),
                decode(UInt64.self),
                decode(Double.self),
                decode(Float.self),
            ]
        }
    }
    enum True: DefaultValue, LosslessValue {
        static let defaultValue = true
        
        static var decodableTypes: [(Decoder) -> LosslessStringCodable?] {
            @inline(__always)
            func decode<T: LosslessStringCodable>(_: T.Type) -> (Decoder) -> LosslessStringCodable? {
                return { try? T.init(from: $0) }
            }

            @inline(__always)
             func decodeBoolFromNSNumber() -> (Decoder) -> LosslessStringCodable? {
                 return { (try? Int.init(from: $0)).flatMap { Bool(exactly: NSNumber(value: $0)) } }
             }
            
            return [
                decode(String.self),
                decodeBoolFromNSNumber(),
                decode(Bool.self),
                decode(Int.self),
                decode(Int8.self),
                decode(Int16.self),
                decode(Int64.self),
                decode(UInt.self),
                decode(UInt8.self),
                decode(UInt16.self),
                decode(UInt64.self),
                decode(Double.self),
                decode(Float.self),
            ]
        }
    }
}

/// 枚举  Codable适配 , defaultCase 是协议实现者必须重写并设置默认value的 , 解决 : 枚举实现Codable , 解析时rawvalue不在枚举case范围内 ,  导致Codable解析失败的问题
public protocol CodableEnumeration: RawRepresentable, Codable where RawValue: Codable {
    static var defaultCase: Self { get }
}

public extension CodableEnumeration {
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        
        do {
            let decoded = try container.decode(RawValue.self)
            self = Self.init(rawValue: decoded) ?? Self.defaultCase
        } catch {
            self = Self.defaultCase
        }
    }
}
