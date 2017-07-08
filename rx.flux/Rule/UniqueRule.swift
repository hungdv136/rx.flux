//
//  CancelRule.swift
//  rx.flux
//  This rule is to ensure that only one action can be executed at the same time. 
//  If there are two actions in the queue, one of them will be canceled. 
//  If cancelBehavior = .first, the first action will be cancel. 
//
//  Created by Hung Dinh Van on 7/6/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//


public enum CancelBehavior: Int {
    case first
    case latest
}

public class UniqueRule: ConditionalRule {
    public convenience init<T: AnyAction>(_ dispatchingType: T.Type, cancelBehavior: CancelBehavior = .first) {
        self.init(dispatchingType: dispatchingType, executingType: dispatchingType, cancelBehavior: cancelBehavior)
    }
    
    public init<T1: AnyAction, T2: AnyAction>(dispatchingType: T1.Type,
                executingType: T2.Type,
                cancelBehavior: CancelBehavior = .first,
                condition: ((_ dispatchingAction: T1, _ executingAction: T2) -> Bool)? = nil) {
        
        self.dispatchingType = dispatchingType
        self.executingType = executingType
        self.condition = convert(condition: condition)
        self.cancelBehavior = cancelBehavior
    }
    
    
    public func execute(dispatchingAction: ExecutingAction, actions: [ExecutingAction]) {
        guard type(of: dispatchingAction.action) == dispatchingType else { return }
        actions.forEach {
            if type(of: $0.action) == executingType && evaluteCondition(dispatchingAction.action, $0.action) {
                switch cancelBehavior {
                case .first:
                    $0.cancel()
                    
                case .latest:
                    dispatchingAction.cancel()
                }
            }
        }
    }
    
    private let cancelBehavior: CancelBehavior
    private let dispatchingType: AnyAction.Type
    private let executingType: AnyAction.Type
    let condition: ConditionalHandler?
}
