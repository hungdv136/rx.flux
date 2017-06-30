//
//  Persistence.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

protocol StorePersistence {
    associatedtype State
    
    func saveState(_ state: State) -> Observable<Void>
    func loadState() -> Observable<State?>
}

protocol DispatcherPersistence {
    func loadActions() -> [(id: String, data: Data)]?
    func insertAction(data: Data, id: String)
    func updateAction(data: Data, id: String)
    func deleteAction(forId id: String)
    func deleteActions(forIds ids: [String])
}
