//
//  SerialAsyncAction.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

protocol SerialAsyncAction: AsyncAction, NSObjectProtocol, NSCoding {
    func reduce(actions: Set<ActionWrapper>) -> [ActionReduction]
}

extension SerialAsyncAction {
    func reduce(state: State, result: Result) -> State? {
        return nil
    }
    
    func reduce(actions: Set<ActionWrapper>) -> [ActionReduction] {
        return [.insert(ActionWrapper(self))]
    }
}
