//
//  Action.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

public protocol AnyAction: class {
    func excutor() -> Observable<Void>
    var maxRetryCount: Int { get }
}

extension AnyAction {
    var maxRetryCount: Int {
        return 0
    }
}

public protocol Action: AnyAction {
    associatedtype State
    
    func reduce(state: State) -> State?
    var store: Store<State>? { get }
}

extension Action {
    public func dispatch() -> Observable<ActionEvent>{
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

public protocol AsyncAction: Action {
    associatedtype Result
    
    func reduce(state: State, result: Result) -> State?
    func reduce(state: State, error: Error) -> State?
    func execute(state: State) -> Observable<Result>
}

extension AsyncAction {
    public func dispatch() -> Observable<ActionEvent> {
        guard let store = store else { return Observable.empty() }
        
        if let newState = reduce(state: store.getState()) {
            store.applyChanges(newState)
        }
        
        return store.dispatch(action: self)
    }
    
    func excutor() -> Observable<Void> {
        guard let store = store else { return Observable.empty() }
        
        return execute(state: store.getState())
            .do(onNext: {
                guard let newState = self.reduce(state: store.getState(), result: $0) else { return }
                store.applyChanges(newState)
            }).map { _ in }
    }
}
