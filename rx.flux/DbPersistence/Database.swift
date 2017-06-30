//
//  Database.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import YapDatabase

final class Database {
    init(userId: String) {
        path = Database.path(forUserId: userId)
        db = YapDatabase(path: path)
        db.defaultObjectPolicy = .share
        db.defaultMetadataCacheEnabled = false
        
        connection = db.newConnection()
    }
    
    //MARK: Properties
    
    private let path: String
    let connection: DbConnection
    private let db: YapDatabase
    
    static func databaseExisting(forUserId userId: String) -> Bool {
        return FileManager.default.fileExists(atPath: path(forUserId: userId))
    }
    
    func delete() {
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
    
    private static func path(forUserId userId: String) -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let folderPath = paths.first ?? NSTemporaryDirectory()
        return (folderPath as NSString).appendingPathComponent("rx.flux-\(userId).sqlite")
    }
}
