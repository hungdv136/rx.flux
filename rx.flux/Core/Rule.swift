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

typealias ConditionalHandler = (_ dispatchingAction: AnyAction, _ executingAction: AnyAction) -> Bool

protocol ConditionalRule: Rule {
    var condition: ConditionalHandler? { get }
}

extension ConditionalRule {
    func evaluteCondition(_ dispatchingAction: AnyExecutableAction, _ executingAction: AnyExecutableAction) -> Bool {
        guard let condition = condition else { return true }
        return condition(dispatchingAction, executingAction)
    }
}

func convert<T1: AnyAction, T2: AnyAction>(condition: ((_ dispatchingAction: T1, _ executingAction: T2) -> Bool)?) -> ConditionalHandler? {
    guard let condition = condition else { return nil }
    return { (t1, t2) -> Bool in
        guard let t1 = t1 as? T1, let t2 = t2 as? T2 else { return false }
        return condition(t1, t2)
    }
}
