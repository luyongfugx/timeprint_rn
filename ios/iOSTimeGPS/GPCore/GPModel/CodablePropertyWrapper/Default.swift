//
//  CodablePropertyWrapper.swift
//  XCamera
//
//  Created by batman on 2021/7/16.
//  Copyright © 2021 xhey. All rights reserved.
//

import Foundation


protocol DefaultValue {
    associatedtype Value: Codable
    static var defaultValue: Value { get }
}

@propertyWrapper
struct Default<T: DefaultValue> {
    var wrappedValue: T.Value
}

extension Default: Decodable where T.Value: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = (try? container.decode(T.Value.self)) ?? T.defaultValue
    }
}

extension Default: Encodable where T.Value: Encodable {
    func encode(to encoder: Encoder) throws {
        try wrappedValue.encode(to: encoder)
    }
}

extension KeyedDecodingContainer {
    func decode<T>(
        _ type: Default<T>.Type,
        forKey key: Key
    ) throws -> Default<T> where T: DefaultValue {
        try decodeIfPresent(type, forKey: key) ?? Default(wrappedValue: T.defaultValue)
    }
}


