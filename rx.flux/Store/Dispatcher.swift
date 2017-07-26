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

public final class Dispatcher {
    public init() {
        queue = DispatchQueue(label: "flux-queue.dispatcher.\(name)", qos: .userInitiated)
    }
    
    public let name = UUID().uuidString
    fileprivate let disposeBag = DisposeBag()
    fileprivate var isExecuting = false
    fileprivate var waitingItems: [ExecutingAction] = []
    fileprivate var executingItems: Set<ExecutingAction> = Set<ExecutingAction>()
    fileprivate let queue: DispatchQueue
}

// MARK: Dispatch

extension Dispatcher {
    func dispatchAsObservable(action: AnyExecutableAction) -> Observable<ActionEvent> {
        let executingAction = ExecutingAction(action: action)
        return executingAction.event
            .do(onSubscribed: {
                self.dispatch(executingAction)
            })
    }
    
    func dispatch(action: AnyExecutableAction) {
        dispatch(ExecutingAction(action: action))
    }
    
    private func dispatch(_ executableAction: ExecutingAction) {
        queue.async {
            executableAction.action.store?.rules.forEach { $0.execute(dispatchingAction: executableAction, actions: self.waitingItems) }
            self.waitingItems.append(executableAction)
            self.registerExecuting(executableAction)
        }
    }
    
    private func registerExecuting(_ executableAction: ExecutingAction) {
        executableAction.ready
            .subscribe(onNext: { [weak self] in
                guard let strongSelf = self else { return }
                strongSelf.queue.async(execute: strongSelf.execute)
            }).disposed(by: disposeBag)
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
            guard action.shouldRetry else {
                self?.queue.async { self?.executeNextAction(action) }
                return
            }
            
            self?.queue.async {
                self?.executingItems.remove(action)
                self?.execute()
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
        return waitingItems.filter { $0.isReady && $0.previousIds.isEmpty && !self.executingItems.contains($0) }
    }
}
