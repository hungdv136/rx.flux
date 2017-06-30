//
//  DictionaryExtensions.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

extension Dictionary {
    func mapValues<T>(_ transform: (Value) -> T) -> [Key: T] {
        var out = [Key: T]()
        for (k, v) in Swift.zip(keys, values.map(transform)) {
            out[k] = v
        }
        return out
    }
    
    func flatMapValues<T>(_ transform: (Value) -> T?) -> [Key: T] {
        var out = [Key: T]()
        for (k, v) in Swift.zip(keys, values.flatMap(transform)) {
            out[k] = v
        }
        return out
    }
}

