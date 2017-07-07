//
//  Action.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

public protocol AnyAction: class {
    var maxRetryCount: Int { get }
}

extension AnyAction {
    public var maxRetryCount: Int {
        return 0
    }
}

// MARK: Type Erasure to make these methods available in this library scope only.

protocol AnyExecutableAction: AnyAction {
    func excutor() -> Observable<Void>
    var storeReady: Observable<Void> { get }
}

open class Action<State>: AnyExecutableAction {
    public init() { }
    
    open func reduce(state: State) -> State? {
        return nil
    }
    
    public func dispatchAsObservable() -> Observable<ActionEvent> {
        return store?.dispatchAsObservable(action: self) ?? Observable.empty()
    }
    
    public func dispatch() {
        store?.dispatch(action: self)
    }
    
    func excutor() -> Observable<Void> {
        return Observable.empty()
            .do(onCompleted: {
                guard let store = self.store, let newState = self.reduce(state: store.getState()) else { return }
                store.applyChanges(newState)
            })
    }
    
    open var store: Store<State>? {
        fatalError("\(type(of: self)) - The sub-class have to override the 'store' property.")
    }
    
    var storeReady: Observable<Void> {
        return store?.ready ?? Observable.empty()
    }
}
