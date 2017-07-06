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
    
    public override func dispatchWithObservable() -> Observable<ActionEvent> {
        guard let store = store else { return Observable.empty() }
        
        if let newState = reduce(state: store.getState()) {
            store.applyChanges(newState)
        }
        
        return store.dispatchWithObservable(action: self)
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
