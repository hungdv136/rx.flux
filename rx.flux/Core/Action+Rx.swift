//
//  Action+Rx.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

extension ObservableType where E == AnyAction {
    func dispatch(dispatcher: Dispatcher) -> Observable<ActionEvent> {
        return self.do(onNext: { action in
                DispatchQueue.main.async {
                    action.dispatch(dispatcher: dispatcher)
                }
            })
            .flatMap { $0.events }
            .observeOn(Schedulers.main)
    }
}

extension ObservableType where E == ActionEvent {
    func completedOrError() -> Observable<Void> {
        return filter { event in
                if case let .failed(error) = event { throw error }
                if case .completed = event { return true }
                return false
            }
            .map { _ in }
    }
}

extension ObservableType {
    func action(_ transform: @escaping (E) throws -> AnyAction) -> Observable<AnyAction> {
        return map(transform)
    }
    
    func actions(_ transform: @escaping (E) throws -> [AnyAction]) -> Observable<AnyAction> {
        return flatMap { Observable.from(try transform($0)) }
    }
}

extension AnyAction {
    func asObservable() -> Observable<AnyAction> {
        return Observable.just().action { self }
    }
}
