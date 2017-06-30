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
            Database(userId: "test-flux-user")
        }.inObjectScope(.container)
        
        container.register(Dispatcher.self) { r in
            let db = r.resolve(Database.self)!
            let persistence = DbDispatcherPersistence(db: db)
            return Dispatcher(persistence: persistence, stop: Observable.never())
        }.inObjectScope(.container)
        
        container.register(CounterStore.self) { r in
          return CounterStore()
        }.inObjectScope(.weak)
    }
}
