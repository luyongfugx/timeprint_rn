//
//  CodablePropertyWrapper.swift
//  XCamera
//
//  Created by batman on 2021/7/16.
//  Copyright © 2021 xhey. All rights reserved.
//

import Foundation

typealias LosslessStringCodable = LosslessStringConvertible & Codable
protocol LosslessValue {
    associatedtype Value: LosslessStringCodable
    static var defaultValue: Value { get }
    static var decodableTypes: [(Decoder) -> LosslessStringCodable?] { get }
}

extension LosslessValue {
    static var decodableTypes: [(Decoder) -> LosslessStringCodable?] {
        @inline(__always)
        func decode<T: LosslessStringCodable>(_: T.Type) -> (Decoder) -> LosslessStringCodable? {
            return { try? T.init(from: $0) }
        }

        return [
            decode(String.self),
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

@propertyWrapper
struct Lossless<T: LosslessValue>: Codable {
    private let type: LosslessStringCodable.Type

    var wrappedValue: T.Value

    init(wrappedValue: T.Value) {
        self.wrappedValue = wrappedValue
        self.type = T.Value.self
    }

    init(from decoder: Decoder) throws {
        do {
            self.wrappedValue = try T.Value.init(from: decoder)
            self.type = T.Value.self
        } catch let error {
                        
            guard let rawValue = T.decodableTypes.lazy.compactMap({ $0(decoder) }).first else {
                throw error
            }
            
            self.wrappedValue = T.Value.init("\(rawValue)") ?? T.defaultValue
            self.type = Swift.type(of: rawValue)
        }
    }

    func encode(to encoder: Encoder) throws {
        let string = String(describing: wrappedValue)

        guard let original = type.init(string) else {
            let description = "[CodablePropertyWrapper] - '\(wrappedValue)' to '\(type)'"
            throw EncodingError.invalidValue(string, .init(codingPath: [], debugDescription: description))
        }

        try original.encode(to: encoder)
    }
}

extension KeyedDecodingContainer {
    func decode<T>(
        _ type: Lossless<T>.Type,
        forKey key: Key
    ) throws -> Lossless<T> where T: LosslessValue {
        try decodeIfPresent(type, forKey: key) ?? Lossless(wrappedValue: T.defaultValue)
    }
}

extension Lossless: Equatable where T.Value: Equatable {
    static func == (lhs: Lossless<T>, rhs: Lossless<T>) -> Bool {
        return lhs.wrappedValue == rhs.wrappedValue
    }
}

extension Lossless: Hashable where T.Value: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(wrappedValue)
    }
}

