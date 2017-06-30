//
//  SampleStore.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import Foundation

final class CounterStore: Store<CountState> {
    init() {
        super.init(initialState: CountState())
    }
}

struct CountState {
    var currentValue: Int = 0
}
