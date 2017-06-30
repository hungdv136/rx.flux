//
//  YapTransactionExtensions.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import Foundation
import YapDatabase

protocol Persistable: NSCoding {
    static var collection: String { get }
    var key: String { get }
}

protocol ReadTransaction: class {
    func objectWithKey<T: Persistable>(_ key: String) -> T?
    func objectWithKey(_ key: String, inCollection collection: String) -> AnyObject?
    func enumerateKeys(inCollection collection: String, block: @escaping (String, UnsafeMutablePointer<ObjCBool>) -> Void)
    func enumerateKeysAndObjects(inCollection collection: String, block: @escaping (String, Any, UnsafeMutablePointer<ObjCBool>) -> Void)
}

protocol WriteTransaction: ReadTransaction {
    func rollback()
    func save(_ object: Persistable)
    func save(_ object: Any, forKey key: String, inCollection collection: String)
    func delete(_ object: Persistable)
    func delete(withKey key: String, inCollection collection: String)
}

extension YapDatabaseReadTransaction: ReadTransaction {
    func objectWithKey<T: Persistable>(_ key: String) -> T? {
        return object(forKey: key, inCollection: T.collection) as? T
    }
    
    func objectWithKey(_ key: String, inCollection collection: String) -> AnyObject? {
        return object(forKey: key, inCollection: collection) as AnyObject?
    }
    
    func enumerateKeys(inCollection collection: String, block: @escaping (String, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateKeys(inCollection: collection, using: block)
    }
    
    func enumerateKeysAndObjects(inCollection collection: String, block: @escaping (String, Any, UnsafeMutablePointer<ObjCBool>) -> Void) {
        enumerateKeysAndObjects(inCollection: collection, using: block)
    }
}

extension YapDatabaseReadWriteTransaction: WriteTransaction {
    func save(_ object: Persistable) {
        setObject(object, forKey: object.key, inCollection: type(of: object).collection, withMetadata: nil)
    }
    
    func save(_ object: Any, forKey key: String, inCollection collection: String) {
        setObject(object, forKey: key, inCollection: collection)
    }
    
    func delete(_ object: Persistable) {
        delete(withKey: object.key, inCollection: type(of: object).collection)
    }
    func delete(withKey key: String, inCollection collection: String) {
        removeObject(forKey: key, inCollection: collection)
    }
}

