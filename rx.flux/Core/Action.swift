//
//  Action.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

public protocol AnyActionType: class { }

protocol AnyAction: AnyActionType {
    func excutor() -> Observable<Void>
    var maxRetryCount: Int { get }
}

extension AnyAction {
    public var maxRetryCount: Int {
        return 0
    }
}

open class Action<State>: AnyAction {
    public init() { }
    
    open func reduce(state: State) -> State? {
        return nil
    }
    
    open var store: Store<State>? {
        fatalError("\(type(of: self)) - The sub-class have to override the 'store' property.")
    }
    
    public func dispatch() -> Observable<ActionEvent> {
        return store?.dispatch(action: self) ?? Observable.empty()
    }
    
    func excutor() -> Observable<Void> {
        return Observable.empty()
            .do(onCompleted: {
                guard let store = self.store, let newState = self.reduce(state: store.getState()) else { return }
                store.applyChanges(newState)
            })
    }
}
