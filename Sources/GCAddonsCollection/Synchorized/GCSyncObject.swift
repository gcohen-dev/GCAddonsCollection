//
//  File.swift
//  
//
//  Created by Guy Cohen on 21/06/2020.
//

import Foundation

public struct GCSyncValue<Value> {
    
    private let queue = DispatchQueue(label: "gc.addons.SynchronizedBarrier", attributes: .concurrent)
    
    private var _value: Value
 
    public init(_ value: Value) {
        self._value = value
    }
 
    public var value: Value { queue.sync { _value } }
 
    public mutating func value<T>(execute task: (inout Value) throws -> T) rethrows -> T {
        try queue.sync(flags: .barrier) { try task(&_value) }
    }
}
