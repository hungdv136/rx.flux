//
//  CounterViewController.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PureLayout

final class CounterViewController: UIViewController {
    init(counterStore: CounterStore) {
        self.counterStore = counterStore
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(stackView)
        view.backgroundColor = UIColor.white
        NSLayoutConstraint.autoCreateAndInstallConstraints {
            stackView.autoPinEdgesToSuperviewEdges(with: UIEdgeInsets(top: 64, left: 12, bottom: 0, right: 12), excludingEdge: .bottom)
        }
        
        let minus = minusButton.rx.tap.map { -1 }
        let plus = plusButton.rx.tap.map { 1 }
    
        Observable.merge(minus, plus)
            .flatMap { IncreaseAction(additionValue: $0).dispatch() }
            .subscribe()
            .disposed(by: disposeBag)
        
        counterStore.state
            .map { "\($0.currentValue)" }
            .do(onNext: {
                print("state: \($0)")
            })
            .drive(textField.rx.text)
            .disposed(by: disposeBag)
        
        let queue: DispatchQueue = DispatchQueue(label: "testing-con", qos: .userInitiated, attributes: .concurrent)
        let queue2: DispatchQueue = DispatchQueue(label: "testing-con2", qos: .userInitiated, attributes: .concurrent)
        
        for i in 1...30 {
            test(queue: queue, i: i)
        }
        
        for i in 1...30 {
            test(queue: queue2, i: -i)
        }
    }
    
    func test(queue: DispatchQueue, i: Int) {
        queue.async {
            //sleep(UInt32(i))
            IncreaseAction(additionValue: i)
                .dispatch()
                .do(onNext: { event in
                    print("\(i) - \(event)")
                })
                .subscribe()
                .disposed(by: self.disposeBag)
        }
    }
    
    // MARK: Properties
    
    private lazy var textField: UITextField = {
        let textField = UITextField()
        textField.autoSetDimension(.height, toSize: 44)
        textField.textAlignment = .center
        textField.layer.borderWidth = 1
        textField.layer.borderColor = UIColor.lightGray.cgColor
        return textField
    }()
    
    private lazy var minusButton: UIButton = {
        let button = UIButton()
        button.setTitle("-", for: .normal)
        button.setTitleColor(UIColor.red, for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        return button
    }()
    
    private lazy var plusButton: UIButton = {
        let button = UIButton()
        button.setTitle("+", for: .normal)
        button.setTitleColor(UIColor.red, for: .normal)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.lightGray.cgColor
        return button
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [self.textField, self.minusButton, self.plusButton])
        stackView.axis = .vertical
        stackView.alignment = .fill
        stackView.spacing = 8
        return stackView
    }()
    
    private let disposeBag = DisposeBag()
    private let counterStore: CounterStore
}

