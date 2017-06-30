//
//  ActionWrapper.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

struct ActionWrapper: Hashable {
    init<A: SerialAsyncAction>(_ action: A) {
        self.action = action
        hash = { action.hash }
    }
    
    static func == (lhs: ActionWrapper, rhs: ActionWrapper) -> Bool {
        return lhs.action === rhs.action
    }
    
    var hashValue: Int {
        return hash()
    }
    
    let action: AnyAction
    private let hash: () -> Int
}
