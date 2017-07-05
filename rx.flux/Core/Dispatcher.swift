//
//  Dispatcher.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 7/3/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift
import RxCocoa
import Foundation

public final class Dispatcher<S> {
    init(rulesCreator: () -> [DispatchRule]) {
        dispatchRules = rulesCreator()
    }
    
    fileprivate let dispatchRules: [DispatchRule]
    fileprivate let disposeBag = DisposeBag()
    fileprivate var isExecuting = false
    fileprivate lazy var waitingItems: [ExecutingAction] = []
    fileprivate lazy var executingItems: Set<ExecutingAction> = Set<ExecutingAction>()
    fileprivate lazy var queue: DispatchQueue = DispatchQueue(label: "flux-queue.dispatcher.dispatching", qos: .userInitiated)
}

// MARK: Dispatch

extension Dispatcher {
    func dispatch(action: AnyAction) -> Observable<ActionEvent> {
        let executingAction = ExecutingAction(action: action)
        return executingAction.event.do(onSubscribe: {
            self.dispatching(executingAction)
        })
    }
    
    func dispatch(action: AnyAction) {
        dispatching(ExecutingAction(action: action))
    }
    
    private func dispatching(_ action: ExecutingAction) {
        queue.async {
            self.dispatchRules.forEach { $0.execute(dispatchingAction: action, actions: self.waitingItems) }
            self.waitingItems.append(action)
            self.execute()
        }
    }
}

// MARK: Execute

extension Dispatcher {
    fileprivate func execute() {
        guard !isExecuting else { return }
        
        isExecuting = true
        executeRecursive()
    }
    
    fileprivate func executeRecursive() {
        let readyActions = getReadyActions()
        isExecuting = !readyActions.isEmpty
        
        guard isExecuting else { return }
        
        readyActions.forEach {
            executingItems.insert($0)
            executeAction($0)
        }
        executeRecursive()
    }
    
    fileprivate func executeAction(_ action: ExecutingAction) {
        action.executor().subscribe(onError: { [weak self] _ in
            if action.shouldRetry {
                self?.queue.async {
                    self?.executingItems.remove(action)
                    self?.execute()
                }
            }
            else {
                self?.queue.async {
                    self?.executeNextAction(action)
                }
            }
        }, onCompleted: { [weak self] in
            self?.queue.async { self?.executeNextAction(action) }
        }).disposed(by: disposeBag)
    }
    
    fileprivate func executeNextAction(_ action: ExecutingAction) {
        waitingItems = waitingItems.filter { $0.id != action.id }
        executingItems.remove(action)
        
        guard action.hasNextId else { return }
        
        waitingItems.forEach { $0.remove(previousId: action.id) }
        getReadyActions().forEach(executeAction)
    }
    
    private func getReadyActions() -> [ExecutingAction] {
        return waitingItems.filter { $0.previousIds.isEmpty && !self.executingItems.contains($0) }
    }
}
