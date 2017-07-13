//
//  Action.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

// MARK: Public Type Erasure

public protocol AnyAction: class {
    var maxRetryCount: Int { get }
}

extension AnyAction {
    public var maxRetryCount: Int {
        return 0
    }
}

// MARK: Internal Type Erasure.

protocol AnyExecutableAction: AnyAction {
    func excutor() -> Observable<Void>
    func getStore() -> AnyStore?
}

open class Action<State>: AnyExecutableAction {
    public init() { }
    
    open func reduce(state: State) -> State? {
        return nil
    }
    
    func excutor() -> Observable<Void> {
        return Observable.just()
            .do(onNext: {
                guard let store = self.store, let newState = self.reduce(state: store.getState()) else { return }
                store.applyChanges(newState)
            })
    }
    
    func willDispatch() { }
    
    func didDispatch() { }
    
    func getStore() -> AnyStore? {
        return store
    }
    
    open var store: Store<State>? {
        fatalError("\(type(of: self)) - The sub-class have to override the 'store' property.")
    }
}

// MARK: Dispatch Methods

extension Action {
    final public func dispatchAsObservable() -> Observable<ActionEvent> {
        return store?.dispatchAsObservable(action: self)
            .do(onSubscribe: {
                self.willDispatch()
            }, onSubscribed: {
                self.didDispatch()
            }) ?? Observable.empty()
    }
    
    final public func dispatch() {
        willDispatch()
        store?.dispatch(action: self)
        didDispatch()
    }
}

