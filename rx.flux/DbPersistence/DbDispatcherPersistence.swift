//
//  DbDispatcherPersistence.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import Foundation

private let collection = "action"

final class DbDispatcherPersistenceItem: NSObject, NSCoding {
    init(data: Data) {
        self.data = data
        self.time = Date()
    }
    
    required init?(coder aDecoder: NSCoder) {
        guard let data = aDecoder.decodeObject(forKey: "data") as? Data,
            let time = aDecoder.decodeObject(forKey: "time") as? Date else {
                return nil
        }
        self.data = data
        self.time = time
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(data, forKey: "data")
        aCoder.encode(time, forKey: "time")
    }
    
    var data: Data
    let time: Date
}

final class DbDispatcherPersistence: DispatcherPersistence {
    init(db: Database) {
        self.db = db
    }
    
    func loadActions() -> [(id: String, data: Data)]? {
        var result: [(String, DbDispatcherPersistenceItem)] = []
        db.connection.read { tx in
            tx.enumerateKeysAndObjects(inCollection: collection) { key, object, _ in
                guard let item = object as? DbDispatcherPersistenceItem else { return }
                result.append((key, item))
            }
        }
        return result.sorted { a, b in
            a.1.time < b.1.time
            }.map { key, item in
                (key, item.data)
        }
    }
    
    func insertAction(data: Data, id: String) {
        db.connection.write { tx in
            let item = DbDispatcherPersistenceItem(data: data)
            tx.save(item, forKey: id, inCollection: collection)
        }
    }
    
    func updateAction(data: Data, id: String) {
        db.connection.write { tx in
            guard let item = tx.objectWithKey(id, inCollection: collection) as? DbDispatcherPersistenceItem else { return }
            item.data = data
            tx.save(item, forKey: id, inCollection: collection)
        }
    }
    
    func deleteAction(forId id: String) {
        db.connection.write { tx in
            tx.delete(withKey: id, inCollection: collection)
        }
    }
    
    func deleteActions(forIds ids: [String]) {
        db.connection.write { tx in
            for id in ids {
                tx.delete(withKey: id, inCollection: collection)
            }
        }
    }
    
    //MARK: Properties
    
    private let db: Database
}

