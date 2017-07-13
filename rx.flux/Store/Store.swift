//
//  Store.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift
import RxCocoa
import Foundation

protocol AnyStore: class {
    var ready: Observable<Void> { get }
    var rules: [Rule] { get }
}

open class Store<S>: AnyStore {
    public typealias State = S
    
    public init<P: Persistence>(initialState: S, dispatcher: Dispatcher, rules: [Rule], persistence: P) where P.State == S {
        self.rules = rules
        self.dispatcher = dispatcher
        stateVar = Variable(initialState)
        state = stateVar.asDriver()
        ready = readySubject.filter { $0 }.take(1).map { _ in }
        
        let timeout = persistenceTimeout == 0 ? Observable.never() : Observable<Int>
            .interval(persistenceTimeout, scheduler: MainScheduler.instance)
            .do(onNext: { _ in
                print("Initializing the state takes long time to run. It's being cancelled.")
            })
        
        persistence
            .load()
            .take(1)
            .takeUntil(timeout)
            .subscribe(onNext: { [weak self] in
                guard let state = $0 else { return }
                self?.applyChanges(state)
                }, onError: {
                    print("An error occurred: \($0.localizedDescription)")
            }, onDisposed: { [weak self] in
                self?.readySubject.onNext(true)
            }).disposed(by: disposeBag)
        
        ready
            .flatMap { [weak self] in self?.stateVar.asObservable() ?? Observable.empty() }
            .flatMapLatest(persistence.save)
            .subscribe(onError: {
                print("An error occurred: \($0.localizedDescription)")
            }).disposed(by: disposeBag)
    }
    
    public init(initialState: S, dispatcher: Dispatcher, rules: [Rule]) {
        self.rules = rules
        self.dispatcher = dispatcher
        stateVar = Variable(initialState)
        state = stateVar.asDriver()
        ready = readySubject.filter { $0 }.take(1).map { _ in }
        readySubject.onNext(true)
    }
    
    // MARK: Internal methods
    
    func dispatchAsObservable(action: AnyExecutableAction) -> Observable<ActionEvent>  {
        return dispatcher.dispatchAsObservable(action: action)
    }
    
    func dispatch(action: AnyExecutableAction)  {
        dispatcher.dispatch(action: action)
    }
    
    func getState() -> S {
        return stateVar.value
    }
    
    func applyChanges(_ newState: S) {
        lock.lock(); defer { lock.unlock() }
        stateVar.value = newState
    }
    
    // MARK: Public properties
    
    public let state: Driver<S>
    public let ready: Observable<Void>
    open var persistenceTimeout: Double { return 60 }
    
    let rules: [Rule]
    
    // MARK: Private properties
    
    private let dispatcher: Dispatcher
    private let stateVar: Variable<S>
    private let readySubject = BehaviorSubject<Bool>(value: false)
    private let disposeBag: DisposeBag = DisposeBag()
    private let lock = NSLock()
}
