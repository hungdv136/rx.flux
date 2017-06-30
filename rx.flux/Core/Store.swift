//
//  Dispatcher.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift
import RxCocoa

private struct CancelError: Error { }

private struct AssociatedKeys {
    static var event = "event"
    static var id = "id"
}

extension AnyAction {
    var events: Observable<ActionEvent> {
        return eventSubject.asObservable()
    }
    
    fileprivate var eventSubject: PublishSubject<ActionEvent> {
        get {
            if let value = objc_getAssociatedObject(self, &AssociatedKeys.event) as? PublishSubject<ActionEvent> {
                return value
            }
            let value = PublishSubject<ActionEvent>()
            objc_setAssociatedObject(self, &AssociatedKeys.event, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return value
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.event, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    fileprivate var eventSubjectIfAny: PublishSubject<ActionEvent>? {
        return objc_getAssociatedObject(self, &AssociatedKeys.event) as? PublishSubject<ActionEvent>
    }
    
    fileprivate var id: String? {
        get {
            return objc_getAssociatedObject(self, &AssociatedKeys.id) as? String
        }
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.id, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}

final class Dispatcher {
    fileprivate typealias Completion = () -> Bool
    
    init(persistence: DispatcherPersistence, stop: Observable<Void>) {
        self.persistence = persistence
        self.stop = stop
        
        serialExecuteSubject.concat().subscribe().disposed(by: disposeBag)
        
        restoreActions()
    }
    
    private func restoreActions() {
        queue.async {
            var deleted = [String]()
            self.persistence.loadActions()?.forEach { id, data in
                guard let action = NSKeyedUnarchiver.unarchiveObject(with: data) as? AnyAction else {
                    deleted.append(id)
                    return
                }
                self.dispatch(action, restoreId: id)
            }
            
            guard !deleted.isEmpty else { return }
            self.persistence.deleteActions(forIds: deleted)
        }
    }
    
    private func insertAction<A: SerialAsyncAction>(_ action: A, id: String) {
        let data = NSKeyedArchiver.archivedData(withRootObject: action)
        persistence.insertAction(data: data, id: id)
    }
    
    private func updateAction(_ action: AnyAction) {
        guard let id = action.id else { return }
        let data = NSKeyedArchiver.archivedData(withRootObject: action)
        persistence.updateAction(data: data, id: id)
    }
    
    private func deleteAction(forId id: String) {
        persistence.deleteAction(forId: id)
    }
    
    fileprivate func dispatch<A: Action>(_ action: A) {
        guard let store = action.store else { return }
        _ = store.ready.subscribe(onNext: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.dispatch(action, store: store) {
                _ = store
                return !strongSelf.produceActions(from: action)
            }
        })
    }
    
    private func dispatch<A: Action>(_ action: A, store: Store<A.State>, completion: @escaping Completion) {
        queue.async {
            action.eventSubject.onNext(.start)
            if let state = action.reduce(state: store.stateVar.value) {
                store.stateVar.value = state
            }
            action.eventSubject.onNext(.completed)
            if completion() {
                action.eventSubject.onCompleted()
            }
        }
    }
    
    fileprivate func dispatch<A: AsyncAction>(_ action: A) {
        guard let store = action.store else { return }
        _ = store.ready.subscribe(onNext: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.dispatch(action, store: store) {
                _ = store
                return !strongSelf.produceActions(from: action)
            }
        })
    }
    
    private func dispatch<A: AsyncAction>(_ action: A, store: Store<A.State>, completion: @escaping Completion) {
        queue.async {
            switch action.behavior {
            case .first:
                if self.disposables[action.identifier] != nil {
                    return
                }
                
            case .latest:
                if let disposable = self.disposables[action.identifier] as? Disposable {
                    disposable.dispose()
                }
                
            case .alwaysExecute:
                break
            }
            
            action.eventSubject.onNext(.start)
            if let state = action.reduce(state: store.stateVar.value) {
                store.stateVar.value = state
            }
            
            let disposable = action
                .execute(state: store.stateVar.value)
                .takeUntil(self.stop)
                .subscribe(onNext: { [weak self] in
                    self?.reduce(action: action, result: $0, store: store)
                    }, onError: { [weak self] in
                        self?.reduceAndRemoveDisposable(action: action, error: $0, store: store)
                        self?.onError($0)
                        action.eventSubject.onNext(.failed($0))
                        action.eventSubject.onCompleted()
                    }, onCompleted: { [weak self] in
                        self?.removeDisposable(forIdentifier: action.identifier)
                        action.eventSubject.onNext(.completed)
                        if completion() {
                            action.eventSubject.onCompleted()
                        }
                })
            
            disposable.disposed(by: self.disposeBag)
            
            self.disposables[action.identifier] = disposable
        }
    }
    
    fileprivate func dispatch<A: SerialAsyncAction>(_ action: A) {
        guard let store = action.store else { return }
        _ = store.ready.subscribe(onNext: { [weak self] in
            guard let strongSelf = self else { return }
            strongSelf.dispatch(action, store: store) {
                _ = store
                return !strongSelf.produceActions(from: action)
            }
        })
    }
    
    private func dispatch<A: SerialAsyncAction>(_ action: A, store: Store<A.State>, completion: @escaping Completion) {
        serialRetrySubject.onNext()
        
        queue.async {
            let options = action.reduce(actions: self.actionQueue)
            for option in options {
                switch option {
                case .insert(let wrapper):
                    let id = action.id ?? UUID().uuidString
                    if action.id == nil {
                        action.id = id
                        self.insertAction(action, id: id)
                    }
                    self.actionQueue.insert(wrapper)
                    
                case .update(let wrapper):
                    self.updateAction(wrapper.action)
                    
                case .remove(let wrapper):
                    self.actionQueue.remove(wrapper)
                    if let id = wrapper.action.id {
                        self.deleteAction(forId: id)
                    }
                }
            }
            
            guard self.actionQueue.contains(ActionWrapper(action)) else {
                return
            }
            
            action.eventSubject.onNext(.start)
            if let state = action.reduce(state: store.stateVar.value) {
                store.stateVar.value = state
            }
            
            let conditional = self.conditional(for: action)
            
            let o: Observable<Void> = Observable.deferred { [weak self] _ -> Observable<Void> in
                return action
                    .execute(state: store.stateVar.value)
                    .do(onNext: { [weak self] in
                        self?.reduce(action: action, result: $0, store: store)
                        }, onError: { [weak self] in
                            self?.reduce(action: action, error: $0, store: store)
                    })
                    .map { _ in }
            }
            
            let final = conditional
                .concat(o)
                .catchError { error in
                    if error is CancelError {
                        return Observable.empty()
                    }
                    throw error
                }
                .do(onError: { [weak self] in
                    self?.onError($0)
                    action.eventSubject.onNext(.failed($0))
                    action.eventSubject.onCompleted()
                    }, onCompleted: { [weak self] in
                        if let strongSelf = self {
                            strongSelf.queue.async {
                                if let id = action.id {
                                    strongSelf.deleteAction(forId: id)
                                }
                                strongSelf.actionQueue.remove(ActionWrapper(action))
                            }
                        }
                        action.eventSubject.onNext(.completed)
                        if completion() {
                            action.eventSubject.onCompleted()
                        }
                })
                .retryWhen { [weak self] errors in
                    errors.flatMap { self?.serialRetrySubject ?? Observable.error($0) }
                }
                .takeUntil(self.stop)
            
            self.serialExecuteSubject.onNext(final)
        }
    }
    
    private func conditional<A: SerialAsyncAction>(for action: A) -> Observable<Void> {
        return Observable.create { [weak self] observer in
            if let strongSelf = self {
                strongSelf.queue.async {
                    let contains = strongSelf.actionQueue.contains(ActionWrapper(action))
                    if contains {
                        observer.onCompleted()
                    }
                    else {
                        observer.onError(CancelError())
                    }
                }
            }
            return Disposables.create()
        }
    }
    
    private func dispatch<A>(_ action: A, restoreId: String?) {
        guard let action = action as? AnyAction else { return }
        action.id = restoreId
        action.dispatch(dispatcher: self)
    }
    
    func dispatch<A>(_ action: A) {
        dispatch(action, restoreId: nil)
    }
    
    private func produceActions<A: Action>(from action: A) -> Bool {
        guard let newActions = action.produceActions(), !newActions.isEmpty else {
            return false
        }
        newActions.forEach {
            if let subject = action.eventSubjectIfAny {
                $0.eventSubject = subject
            }
            dispatch($0)
        }
        return true
    }
    
    private func reduce<A: AsyncAction>(action: A, result: A.Result, store: Store<A.State>) {
        queue.async {
            if let state = action.reduce(state: store.stateVar.value, result: result) {
                store.stateVar.value = state
            }
        }
    }
    
    private func reduce<A: AsyncAction>(action: A, error: Error, store: Store<A.State>) {
        queue.async {
            if let state = action.reduce(state: store.stateVar.value, error: error) {
                store.stateVar.value = state
            }
        }
    }
    
    private func reduceAndRemoveDisposable<A: AsyncAction>(action: A, error: Error, store: Store<A.State>) {
        queue.async {
            if let state = action.reduce(state: store.stateVar.value, error: error) {
                store.stateVar.value = state
            }
            self.disposables.removeObject(forKey: action.identifier)
        }
    }
    
    private func removeAction<A: SerialAsyncAction>(_ action: A) {
        queue.async {
            self.actionQueue.remove(ActionWrapper(action))
        }
    }
    
    private func removeDisposable(forIdentifier identifier: String) {
        queue.async {
            self.disposables.removeObject(forKey: identifier)
        }
    }
    
    private func onError(_ error: Error) {
        //DDLogError(error.localizedDescription)
    }
    
    //MARK: Properties
    
    private lazy var queue: DispatchQueue = DispatchQueue(label: "dispatcher", qos: .userInitiated)
    private let persistence: DispatcherPersistence
    private let stop: Observable<Void>
    private let serialExecuteSubject = PublishSubject<Observable<Void>>()
    private let serialRetrySubject = PublishSubject<Void>()
    private var actionQueue = Set<ActionWrapper>()
    private let disposables = NSMutableDictionary()
    private let disposeBag: DisposeBag = DisposeBag()
}

//MARK: Protocol extensions

extension Action {
    func dispatch(dispatcher: Dispatcher) {
        dispatcher.dispatch(self)
    }
}

extension AsyncAction {
    func dispatch(dispatcher: Dispatcher) {
        dispatcher.dispatch(self)
    }
}

extension SerialAsyncAction {
    func dispatch(dispatcher: Dispatcher) {
        dispatcher.dispatch(self)
    }
}

//MARK: - Store

class Store<S> {
    typealias State = S
    
    init<P: StorePersistence>(initialState: S, persistence: P) where P.State == S {
        stateVar = Variable(initialState)
        
        persistence.loadState().subscribe(onNext: { [weak self] in
            guard let state = $0 else { return }
            self?.stateVar.value = state
        }, onError: { [weak self] in
            self?.onError($0)
        }, onDisposed: { [weak self] in
            self?.setupSavingState(persistence)
            self?.readySubject.onNext(true)
        }).disposed(by: disposeBag)
    }
    
    init(initialState: S) {
        stateVar = Variable(initialState)
        
        readySubject.onNext(true)
    }
    
    func getState() -> S {
        return stateVar.value
    }
    
    private func onError(_ error: Error) {
        //DDLogError(error.localizedDescription)
    }
    
    private func setupSavingState<P: StorePersistence>(_ persistence: P) where P.State == S {
        stateVar.asObservable().flatMapLatest(persistence.saveState).subscribe(onError: { [weak self] in
            self?.onError($0)
        }).disposed(by: disposeBag)
    }
    
    //MARK: Properties
    
    lazy var state: Driver<S> = self.stateVar.asDriver()
    
    fileprivate let stateVar: Variable<S>
    private let readySubject = BehaviorSubject<Bool>(value: false)
    lazy var ready: Observable<Void> = self.readySubject.filter { $0 }.take(1).map { _ in }
    private let disposeBag: DisposeBag = DisposeBag()
}
