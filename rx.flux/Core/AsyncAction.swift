//
//  AsyncAction.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

protocol AsyncAction: Action {
    associatedtype Result
    
    func reduce(state: State, result: Result) -> State?
    func reduce(state: State, error: Error) -> State?
    func execute(state: State) -> Observable<Result>
    
    var identifier: String { get }
    var behavior: ActionBehavior { get }
}

extension AsyncAction {
    func reduce(state: State) -> State? {
        return nil
    }
    
    func reduce(state: State, error: Error) -> State? {
        return nil
    }
    
    var identifier: String {
        return String(reflecting: type(of: self))
    }
    
    var behavior: ActionBehavior {
        return .alwaysExecute
    }
}
