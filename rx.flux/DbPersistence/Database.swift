//
//  Database.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import YapDatabase

final class Database {
    init(databaseName: String) {
        path = Database.createPath(for: databaseName)
        db = YapDatabase(path: path)
        db.defaultObjectPolicy = .share
        db.defaultMetadataCacheEnabled = false
        connection = db.newConnection()
    }
    
    //MARK: Properties
    
    private let path: String
    let connection: DbConnection
    private let db: YapDatabase
}

extension Database {
    static func delete(databaseName: String) {
        let path = createPath(for: databaseName)
        do {
            try FileManager.default.removeItem(atPath: path)
            if let path = ((path as NSString).deletingPathExtension as NSString).appendingPathExtension("sqlite-shm") {
                try FileManager.default.removeItem(atPath: path)
            }
            if let path = ((path as NSString).deletingPathExtension as NSString).appendingPathExtension("sqlite-wal") {
                try FileManager.default.removeItem(atPath: path)
            }
        }
        catch { }
    }
    
    static func exists(databaseName: String) -> Bool {
        return FileManager.default.fileExists(atPath: createPath(for: databaseName))
    }
    
    fileprivate static func createPath(for databaseName: String) -> String {
        return "\(databaseName).sqlite"
    }
}
