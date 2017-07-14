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
    var store: AnyStore? { get }
}

protocol ActionDispatchLifecycle {
    func willDispatch()
    func didDispatch()
}

extension ActionDispatchLifecycle {
    func willDispatch() { }
    func didDispatch() { }
}

open class Action<State>: AnyExecutableAction, ActionDispatchLifecycle {
    public init() { }
    
    open func reduce(state: State) -> State? {
        return nil
    }
    
    func reduce() {
        guard let store = self.store, let newState = self.reduce(state: store.getState()) else { return }
        store.applyChanges(newState)
    }
    
    func excutor() -> Observable<Void> {
        return Observable.just()
            .do(onNext: reduce)
    }
    
    open var store: Store<State>? {
        fatalError("\(type(of: self)) - The sub-class have to override the 'store' property.")
    }
}

// MARK: AnyExecutableAction

extension Action {
    var store: AnyStore? {
        return store
    }
}

// MARK: Dispatch Methods

extension Action {
    public func dispatchAsObservable() -> Observable<ActionEvent> {
        return store?.dispatchAsObservable(action: self)
            .do(onSubscribe: {
                self.willDispatch()
            }, onSubscribed: {
                self.didDispatch()
            }) ?? Observable.empty()
    }
    
    public func dispatch() {
        willDispatch()
        store?.dispatch(action: self)
        didDispatch()
    }
}

