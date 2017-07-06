//
//  IncreaseAction.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

final class IncreaseAction: Action<CounterStore.State> {
    typealias State = CounterStore.State
    
    init(additionValue: Int) {
        self.additionValue = additionValue
        super.init()
    }
    
    override func reduce(state: State) -> State? {
        var state = state
        state.currentValue += additionValue
        return state
    }
    
    override var store: Store<State>? {
        return DI.resolve() as CounterStore?
    }
    
    let additionValue: Int
}
