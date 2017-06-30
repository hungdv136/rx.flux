//
//  DbConnection.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import Foundation
import YapDatabase

protocol DbConnection {
    func read(_ block: @escaping (ReadTransaction) -> Void)
    func asyncRead(_ block: @escaping (ReadTransaction) -> Void, completionQueue: DispatchQueue?, completion: (() -> Void)?)
    
    func write(_ block: @escaping (WriteTransaction) throws -> Void) rethrows
    func asyncWrite(_ block: @escaping (WriteTransaction) throws -> Void, completionQueue: DispatchQueue?, completion: (() -> Void)?)
}

extension DbConnection {
    func asyncRead(_ block: @escaping (ReadTransaction) -> Void) {
        asyncRead(block, completionQueue: nil, completion: nil)
    }
    func asyncRead(_ block: @escaping (ReadTransaction) -> Void, completion: (() -> Void)?) {
        asyncRead(block, completionQueue: nil, completion: completion)
    }
    
    func asyncWrite(_ block: @escaping (WriteTransaction) throws -> Void) {
        asyncWrite(block, completionQueue: nil, completion: nil)
    }
    func asyncWrite(_ block: @escaping (WriteTransaction) throws -> Void, completion: (() -> Void)?) {
        asyncWrite(block, completionQueue: nil, completion: completion)
    }
}

extension YapDatabaseConnection: DbConnection {
    func read(_ block: @escaping (ReadTransaction) -> Void) {
        read(block as ((YapDatabaseReadTransaction) -> Void))
    }
    
    func asyncRead(_ block: @escaping (ReadTransaction) -> Void, completionQueue: DispatchQueue?, completion: (() -> Void)?) {
        asyncRead(block, completionQueue: completionQueue, completionBlock: completion)
    }
    
    func write(_ block: @escaping (WriteTransaction) throws -> Void) rethrows {
        var failure: Error?
        readWrite { tx in
            do {
                try block(tx)
            }
            catch {
                tx.rollback()
                failure = error
            }
        }
        if let failure = failure {
            try { () -> Void in throw failure }()
        }
    }
    
    func asyncWrite(_ block: @escaping (WriteTransaction) throws -> Void, completionQueue: DispatchQueue?, completion: (() -> Void)?) {
        asyncReadWrite({ tx in
            do {
                try block(tx)
            }
            catch {
                tx.rollback()
            }
        }, completionQueue: completionQueue, completionBlock: completion)
    }
}
