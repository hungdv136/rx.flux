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
    init(dispatcher: Dispatcher, counterStore: CounterStore) {
        self.dispatcher = dispatcher
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
            .action(IncreaseAction.init)
            .dispatch(dispatcher: dispatcher)
            .subscribe()
            .disposed(by: disposeBag)
        
        counterStore.state
            .map { "\($0.currentValue)" }
            .drive(textField.rx.text)
            .disposed(by: disposeBag)
        
//        Observable.merge(minus, plus)
//            .map { String(format: "%d", $0 + (Int(textField.text ?? "0") ?? 0)) }
//            .bind(to: textField.rx.text)
//            .disposed(by: disposeBag)
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
        button.backgroundColor = UIColor.lightGray
        return button
    }()
    
    private lazy var plusButton: UIButton = {
        let button = UIButton()
        button.setTitle("+", for: .normal)
        button.setTitleColor(UIColor.red, for: .normal)
        button.backgroundColor = UIColor.lightGray
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
    private let dispatcher: Dispatcher
    private let counterStore: CounterStore
}

