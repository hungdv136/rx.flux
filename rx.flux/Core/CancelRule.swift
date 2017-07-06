//
//  CancelRule.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 7/6/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//


public enum CancelBehavior: Int {
    case first
    case latest
}

public class CancelRule: ConditionalRule {
    public convenience init<T: AnyAction>(_ dispatchingType: T.Type, cancelBehavior: CancelBehavior = .first) {
        self.init(dispatchingType: dispatchingType, executingType: dispatchingType, cancelBehavior: cancelBehavior)
    }
    
    public init<T: AnyAction>(dispatchingType: T.Type,
                executingType: T.Type,
                cancelBehavior: CancelBehavior = .first,
                condition: ConditionalHandler? = nil) {
        
        self.dispatchingType = dispatchingType
        self.executingType = executingType
        self.condition = condition
        self.cancelBehavior = cancelBehavior
    }
    
    
    public func execute(dispatchingAction: ExecutingAction, actions: [ExecutingAction]) {
        guard type(of: dispatchingAction.action) == dispatchingType else { return }
        actions.forEach {
            if type(of: $0.action) == executingType && self.evaluateCondition(dispatchingAction.action, $0.action) {
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
