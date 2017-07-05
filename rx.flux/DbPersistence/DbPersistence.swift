//
//  DbStorePersistence.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

final class DbPersistence<S: Codable>: Persistence {
    init(db: Database, collectionName: String) {
        self.db = db
        self.collectionName = collectionName
    }
    
    func save(_ state: S) -> Observable<Void> {
        return db.connection.rx.write { tx in
            let key = String(reflecting: S.self)
            tx.save(state.archivedData, forKey: key, inCollection: self.collectionName)
        }
    }
    
    func load() -> Observable<S?> {
        return db.connection.rx.read { tx in
            let key = String(reflecting: S.self)
            let data = tx.objectWithKey(key, inCollection: self.collectionName) as? Data
            return data.flatMap { NSKeyedUnarchiver.unarchiveCodableObject(with: $0) }
        }
    }
    
    // MARK: Properties
    
    private let collectionName: String
    private let db: Database
}
