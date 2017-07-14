//
//  AsyncAction.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 7/6/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//
import RxSwift

open class AsyncAction<State, Result>: Action<State> {
    open func reduce(state: State, result: Result) -> State? {
        return nil
    }
    
    open func reduce(state: State, error: Error) -> State? {
        return nil
    }
    
    open func execute(state: State) -> Observable<Result> {
        fatalError("\(type(of: self)) - The sub-class have to override the 'execute' method.")
    }
    
    override func excutor() -> Observable<Void> {
        guard let store = store else { return Observable.empty() }
        
        return execute(state: store.getState())
            .do(onNext: {
                guard let newState = self.reduce(state: store.getState(), result: $0) else { return }
                store.applyChanges(newState)
            }).map { _ in }
    }
}

// MARK: ActionDispatchLifecycle

extension AsyncAction {
    func willDispatch() {
        reduce()
    }
}
