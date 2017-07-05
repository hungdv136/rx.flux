//
//  StoreAssembly.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/30/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import Swinject
import RxSwift

final class StoreAssembly: Assembly {
    func assemble(container: Container) {
        container.register(Database.self) { _ in
            Database(databaseName: "rx.flux-database")
        }.inObjectScope(.container)
        
        container.register(CounterStore.self) { r in
            let db = r.resolve(Database.self)!
            return CounterStore(persistence: DbPersistence(db: db, collectionName: "store"))
        }.inObjectScope(.weak)
    }
}
