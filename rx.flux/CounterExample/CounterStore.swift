//
//  SampleStore.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import Foundation

final class CounterStore: Store<CountState> {
    init(persistence: DbPersistence<State>) {
        super.init(initialState: CountState(), persistence: persistence)
    }
    
    override var persistenceTimeout: Double {
        return 5
    }
    
    override func createRules() -> [Rule] {
        return [CancelRule(IncreaseAction.self, cancelBehavior: .latest)]
    }
}

struct CountState {
    var currentValue: Int = 0
}

extension CountState: Codable {
    init?(coder: Coder) {
        currentValue = coder.decodeInteger(forKey: "currentValue")
    }
    
    func encode(with coder: Coder) {
        coder.encode(currentValue, forKey: "currentValue")
    }
}
