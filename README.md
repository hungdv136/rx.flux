# OOP variant of Flux Architecture in Swift
A Flux library for those who want to use Flux for building an application with Object Oriented Programming. It also uses Reactive Programming for state change propagation.

Example: https://github.com/hungdv136/rx.flux-counter-example

What are the differences between this framework and other Flux framework?

## Multiple Threads

Unlike the most of Flux frameworks, we don’t dispatch and execute all actions in the the main thread. Instead, we do it under background thread. We also execute actions in different stores in different threads and execute all of actions in each store in the same thread. This helps to improve performance if the application has a lot of stores and actions.

## Object Oriented Programming

If you want to use Flux for building your applications with Object Oriented Programing, this might be a good option for you. 

In the original Flux implementation, when you add a new Action, you also have to add a new ‘case’ statement into ‘reduce’ function in the store. That makes OOP folks like me confused if we are violating the Open Close principle in SOLID or not.

In this framework, what you have to do is to add a new action that inherits from Action or AsyncAcion, then override these methods:

```swift
// This method is a pure function describes how to transform you state 

override func reduce(state: CountState, result: Int) -> CountState? {
	var state = state
	state.currentValue *= result
	return state
}

// This method is for executing side-effects like calling API, reading database or doing intensive calculation

override func execute(state: State) -> Observable<Int> {
	return Observable<Int>.interval(5, scheduler: MainScheduler.instance).map { _ in 2 }
}

// This property is to identify what the store this action belongs to

override var store: Store<State>? {
	return DI.resolve() as CounterStore?
}
```

That's all. No more extra code requires.

## Control executing sequence.

If you want to have only one action can be executed at the same time, you can define like this
```swift 
UniqueRule(YourAction.self, cancelBehavior: .first) 
```

Then attach it into the store (cancelBehavior: .first means that the first action will be canceled). In addition, you can use ’condition’ parameter that is a closure parameter to add a condition into your rule.

Another case, you have two or more actions such as: A1, A2, … you want these actions to be executed in sequence (complete side-effects, reduce in sequence). You can achieve easily by adding a new rule:  

```swift
SequenceRule(A1.self, A2.self, condition: your-closure) 
```
or 

```swift
SequenceRule(A1.self, A2.self, … An.self)
```

Or you can define your new rules by subclassing the protocol Rule.

```swift
public protocol Rule {
    func execute(dispatchingAction: ExecutingAction, actions: [ExecutingAction])
}
```

## Support Offline

If you want to cache your data to support offline mode, you should create a new class that inherits from this protocol. Then attach it into the store. Otherwise, everything is still working without supporting offline storage.

```swift
public protocol Persistence {
	associatedtype State
	func save(_ state: State) -> Observable<Void>
	func load() -> Observable<State?>
}
```

