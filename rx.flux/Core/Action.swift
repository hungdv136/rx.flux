//
//  Action.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

enum ActionBehavior {
    case alwaysExecute
    case first
    case latest
}

enum ActionReduction {
    case insert(ActionWrapper)
    case update(ActionWrapper)
    case remove(ActionWrapper)
}

enum ActionEvent {
    case start
    case failed(Error)
    case completed
}

protocol AnyAction: class {
    func dispatch(dispatcher: Dispatcher)
}

protocol Action: AnyAction {
    associatedtype State
    
    func reduce(state: State) -> State?
    func produceActions() -> [AnyAction]?
    
    var store: Store<State>? { get }
}

extension Action {
    func produceActions() -> [AnyAction]? {
        return nil
    }
}
