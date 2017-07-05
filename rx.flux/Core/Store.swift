//
//  Dispatcher.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift
import RxCocoa
import Foundation

public class Store<S> {
    typealias State = S
    
    public init<P: Persistence>(initialState: S, persistence: P) where P.State == S {
        stateVar = Variable(initialState)
        
        let timeout = Observable<Int>
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
    
    public init(initialState: S) {
        stateVar = Variable(initialState)
        readySubject.onNext(true)
    }
    
    open func createRules() -> [DispatchRule] {
        return []
    }
    
    // MARK: Internal methods
    
    func dispatch(action: AnyAction) -> Observable<ActionEvent>  {
        return ready.flatMap { self.dispatcher.dispatch(action: action) }
    }
    
    func getState() -> S {
        return stateVar.value
    }
    
    func applyChanges(_ newState: S) {
        lock.lock()
        stateVar.value = newState
        lock.unlock()
    }
    
    // MARK: Public properties
    
    public lazy var state: Driver<S> = self.stateVar.asDriver()
    public var persistenceTimeout: Double {
        return 60
    }
    
    // MARK: Internal properties
    
    lazy var ready: Observable<Void> = self.readySubject.filter { $0 }.take(1).map { _ in }
    
    // MARK: Private properties
    
    private lazy var dispatcher: Dispatcher<S> = { Dispatcher<S>(rulesCreator: self.createRules) }()
    private let stateVar: Variable<S>
    private let readySubject = BehaviorSubject<Bool>(value: false)
    private let disposeBag: DisposeBag = DisposeBag()
    private let lock = NSLock()
}
