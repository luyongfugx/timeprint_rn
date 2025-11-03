//
//  XHElementSetPropertyWrapper.swift
//  XCamera
//
//  Copyright © 2022 xhey. All rights reserved.
//

import Foundation

@propertyWrapper
struct XHElementSetPropertyWrapper<Value: Hashable> {

    private var value: Value
    private var elements: Set<Value>

    init(value: Value, elements: Set<Value>) {
        self.value = value
        self.elements = elements
    }

    var wrappedValue: Value {
        get { value }
        set {
            if elements.contains(newValue) {
                value = newValue
            }
        }
    }
}

@propertyWrapper
public struct XHClamping<Value: Comparable> {

    var value: Value
    let range: ClosedRange<Value>

    public init(initial value: Value, range: ClosedRange<Value>) {
        precondition(range.contains(value))
        self.value = value
        self.range = range
    }

    public var wrappedValue: Value {
        get { value }
        set { value = min(max(range.lowerBound, newValue), range.upperBound) }
    }
}

@propertyWrapper
struct XHClamped<T: Comparable> {
    let wrappedValue: T

    init(wrappedValue: T, range: ClosedRange<T>) {
        self.wrappedValue = min(max(wrappedValue, range.lowerBound), range.upperBound)
    }
}


// MARK: GPPersistance

/// key
protocol GPPersistanceKey {
    var rawValue: String { get }
}

/// 字符串默认实现
extension String: GPPersistanceKey {

    var rawValue: String {
        self
    }
}

/// 持久化存储的storage
protocol GPPersistanceStorage {

    func xh_getValue(for key: GPPersistanceKey) -> Any?

    func xh_setValue(_ value: Any, for key: GPPersistanceKey)
}

/// `UserDefaults`默认实现
extension UserDefaults: GPPersistanceStorage {

    func xh_getValue(for key: GPPersistanceKey) -> Any? {
        self.value(forKey: key.rawValue)
    }

    func xh_setValue(_ value: Any, for key: GPPersistanceKey) {
        self.set(value, forKey: key.rawValue)
        self.synchronize()
    }
}

/// 持久化存储器属性包装器
/// 用于简化`UserDefaults`
/// 使用示例:
///
///     struct JigsawHistoryGuide {
///         @GPPersistance<Bool>(key: "yourkey", defaultValue: false)
///         static var didShownGuide: Bool
///     }
///
///     func foo() {
///         ...
///         JigsawHistoryGuide.didShowGuide = true
///     }
///
@propertyWrapper
struct GPPersistance<Value> {

    private let key: GPPersistanceKey
    private let defaultValue: Value
    private let storage: GPPersistanceStorage

    init(key: GPPersistanceKey, defaultValue: Value, storage: GPPersistanceStorage = UserDefaults.standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
    }

    var wrappedValue: Value {
        get {
            guard let value = storage.xh_getValue(for: key.rawValue) as? Value else { return defaultValue }
            return value
        }
        set {
            storage.xh_setValue(newValue, for: key.rawValue)
        }
    }
}

@propertyWrapper
public struct UpperOrLowerCased {

    public var wrappedValue: String {
        get { backend }
        set { backend = isUpperCase ? newValue.uppercased() : newValue.lowercased() }
    }

    let isUpperCase: Bool

    private var backend: String = ""

    public init(isUpperCase: Bool) {
        self.isUpperCase = isUpperCase
    }

    public init(wrappedValue: String, isUpperCase: Bool) {
        self.backend = isUpperCase ? wrappedValue.uppercased() : wrappedValue.lowercased()
        self.isUpperCase = isUpperCase
    }
}

@propertyWrapper
struct XHDebugLogger<T: CustomStringConvertible> {

    private let label: String
    init(wrappedValue: T, label: String) {
        self.wrappedValue = wrappedValue
        self.label = label
    }

    var wrappedValue: T {
        didSet {
            #if DEBUG
            if label.isEmpty {
                print(wrappedValue)
            } else {
                LogDebug("\(label): \(wrappedValue)")
            }
            #endif
        }
    }
}
