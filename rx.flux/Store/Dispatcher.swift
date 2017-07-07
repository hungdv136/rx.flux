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

final class Dispatcher<S> {
    init(dispatchRules: [Rule]) {
        self.dispatchRules = dispatchRules
    }
    
    fileprivate let dispatchRules: [Rule]
    fileprivate let disposeBag = DisposeBag()
    fileprivate var isExecuting = false
    fileprivate lazy var waitingItems: [ExecutingAction] = []
    fileprivate lazy var executingItems: Set<ExecutingAction> = Set<ExecutingAction>()
    fileprivate lazy var queue: DispatchQueue = DispatchQueue(label: "flux-queue.dispatcher.\(UUID().uuidString)", qos: .userInitiated)
}

// MARK: Dispatch

extension Dispatcher {
    func dispatchAsObservable(action: AnyExecutableAction) -> Observable<ActionEvent> {
        let executingAction = ExecutingAction(action: action)
        return executingAction.event.do(onSubscribe: {
            self.dispatching(executingAction)
        })
    }
    
    func dispatch(action: AnyExecutableAction) {
        dispatching(ExecutingAction(action: action))
    }
    
    private func dispatching(_ executableAction: ExecutingAction) {
        queue.async {
            self.dispatchRules.forEach { $0.execute(dispatchingAction: executableAction, actions: self.waitingItems) }
            self.waitingItems.append(executableAction)
            executableAction.action.storeReady.subscribe(onNext: { [weak self] in
                self?.execute()
            }).disposed(by: self.disposeBag)
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
    
    private func executeRecursive() {
        let readyActions = getReadyActions()
        isExecuting = !readyActions.isEmpty
        
        guard isExecuting else { return }
        
        readyActions.forEach {
            executingItems.insert($0)
            executeAction($0)
        }
        executeRecursive()
    }
    
    private func executeAction(_ action: ExecutingAction) {
        action.executor().subscribe(onError: { [weak self] _ in
            if action.shouldRetry {
                self?.queue.async {
                    self?.executingItems.remove(action)
                    self?.execute()
                }
            }
            else {
                self?.queue.async { self?.executeNextAction(action) }
            }
        }, onCompleted: { [weak self] in
            self?.queue.async { self?.executeNextAction(action) }
        }).disposed(by: disposeBag)
    }
    
    private func executeNextAction(_ action: ExecutingAction) {
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