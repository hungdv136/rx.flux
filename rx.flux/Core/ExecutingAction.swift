//
//  ExecutingAction.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/30/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

public final class ExecutingAction: Hashable {
    init(action: AnyAction) {
        self.action = action
    }
    
    public func after(executingAction: ExecutingAction) {
        previousIds.insert(executingAction.id)
        executingAction.hasNextId = true
    }
    
    // MARK: Internal
    
    func executor() -> Observable<Void> {
        return action.excutor()
            .take(1)
            .takeUntil(cancelSubject)
            .do(onNext: {
                self.eventSubject.onNext(.completed)
            }, onError: {
                self.errorCount += 1
                self.eventSubject.onNext(.failed($0))
            }, onCompleted: {
                self.eventSubject.onNext(.completed)
                self.eventSubject.onCompleted()
            }, onSubscribe: {
                self.eventSubject.onNext(.start)
            }, onDispose: {
                self.cancelSubject.onCompleted()
            })
    }
    
    func remove(previousId: String) {
        previousIds.remove(id)
    }
    
    public func cancel() {
        guard eventSubject.isDisposed else { return }
        
        cancelSubject.onNext(true)
        eventSubject.onCompleted()
        cancelSubject.onCompleted()
    }

    // MARK: Properties
    
    public let action: AnyAction
    public private(set) lazy var id: String = NSUUID().uuidString
    public var hashValue: Int {
        return id.hashValue
    }
    
    // MARK: Internal
    
    private(set) var hasNextId: Bool = false
    private(set) lazy var previousIds: Set<String> = Set<String>()
    
    var event: Observable<ActionEvent> {
        return eventSubject.takeUntil(cancelSubject)
    }
    
    var shouldRetry: Bool {
        return errorCount <= action.maxRetryCount
    }
    
    // MARK: Private
    
    private lazy var errorCount: Int = 0
    private lazy var cancelSubject = PublishSubject<Bool>()
    private lazy var eventSubject = PublishSubject<ActionEvent>()
}

public func ==(lhs: ExecutingAction, rhs: ExecutingAction) -> Bool {
    return lhs.id == rhs.id
}
