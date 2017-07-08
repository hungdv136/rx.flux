//
//  SequenceRule.swift
//  rx.flux
//  This rule is to ensure that two or more actions will be ran in sequence.
//
//  Created by Hung Dinh Van on 7/6/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

public class SequenceRule: ConditionalRule {
    public init<T: AnyAction>(type: T.Type, types: AnyAction.Type...) {
        condition = nil
        var types = types
        types.insert(type, at: 0)
        self.types = types
    }
    
    public init<T1: AnyAction, T2: AnyAction>(type1: T1.Type, type2: T2.Type, condition: ((_ dispatchingAction: T1, _ executingAction: T2) -> Bool)? = nil) {
        self.condition = convert(condition: condition)
        self.types = [type1, type2]
    }
    
    public func execute(dispatchingAction: ExecutingAction, actions: [ExecutingAction]) {
        guard types.count > 1 else { return }
        let dispatchingType = type(of: dispatchingAction.action)
        
        if condition != nil && dispatchingType == type(of: types.last) {
            actions.forEach {
                if type(of: $0.action) == type(of: types.first) && evaluteCondition(dispatchingAction.action, $0.action) {
                    dispatchingAction.after(executingAction: $0)
                }
            }
        }
        
        guard condition == nil, let index = types.index(where: { $0 == dispatchingType }) else { return }
        actions.forEach {
            for i in 0...index {
                if types[i] == type(of: $0.action) {
                    dispatchingAction.after(executingAction: $0)
                }
            }
        }
    }
    
    private let types: [AnyAction.Type]
    let condition: ConditionalHandler?
}
