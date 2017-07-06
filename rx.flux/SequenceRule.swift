//
//  SequenceRule.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 7/6/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

public class SequenceRule: ConditionalRule {
    init<T: AnyActionType>(type: T.Type, types: T.Type...) {
        condition = nil
        var types = types
        types.insert(type, at: 0)
        self.types = types
    }
    
    init<T: AnyActionType>(type1: T.Type, type2: T.Type, condition: ConditionalHandler? = nil) {
        self.condition = condition
        self.types = [type1, type2]
    }
    
    public func execute(dispatchingAction: ExecutingAction, actions: [ExecutingAction]) {
        guard types.count > 1 else { return }
        let dispatchingType = type(of: dispatchingAction.action)
        
        if condition != nil && dispatchingType == type(of: types.last) {
            actions.forEach {
                if type(of: $0.action) == type(of: types.first) && evaluateCondition(dispatchingAction.action, $0.action) {
                    dispatchingAction.after(executingAction: $0)
                }
            }
        }
        
        guard condition == nil, let index = types.index(where: { $0 == dispatchingType }) else { return }
        actions.forEach {
            for i in 0...index {
                if types[i] ==  type(of: $0.action) {
                    dispatchingAction.after(executingAction: $0)
                }
            }
        }
    }
    
    private let types: [AnyActionType.Type]
    let condition: ConditionalHandler?
}
