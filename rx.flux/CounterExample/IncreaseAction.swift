//
//  IncreaseAction.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import Foundation

final class IncreaseAction: Action {
    typealias State = CounterStore.State
    
    init(additionValue: Int) {
        self.additionValue = additionValue
    }
    
    func reduce(state: State) -> State? {
        var state = state
        state.currentValue += additionValue
        return state
    }
    
    let store: Store<State>? = DI.resolve() as CounterStore?
    private let additionValue: Int
}
