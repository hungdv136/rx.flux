//
//  Rule.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 7/3/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

public protocol Rule {
    func execute(dispatchingAction: ExecutingAction, actions: [ExecutingAction])
}

public typealias ConditionalHandler = (_ dispatchingAction: AnyActionType, _ executingAction: AnyActionType) -> Bool

protocol ConditionalRule: Rule {
    var condition: ConditionalHandler? { get }
}

extension ConditionalRule {
    func evaluateCondition(_ dispatchingAction: AnyAction, _ executingAction: AnyAction) -> Bool {
        guard let condition = condition else { return true }
        return condition(dispatchingAction, executingAction)
    }
}
