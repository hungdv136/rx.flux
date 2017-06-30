//
//  DbStorePersistence.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

private let collection = "store"

final class DbStorePersistence<S: Codable>: StorePersistence {
    init(db: Database) {
        self.db = db
    }
    
    func saveState(_ state: S) -> Observable<Void> {
        return db.connection.rx.write { tx in
            let key = String(reflecting: S.self)
            tx.save(state.archivedData, forKey: key, inCollection: collection)
        }
    }
    
    func loadState() -> Observable<S?> {
        return db.connection.rx.read { tx in
            let key = String(reflecting: S.self)
            let data = tx.objectWithKey(key, inCollection: collection) as? Data
            return data.flatMap { NSKeyedUnarchiver.unarchiveCodableObject(with: $0) }
        }
    }
    
    //MARK: Properties
    
    private let db: Database
}
