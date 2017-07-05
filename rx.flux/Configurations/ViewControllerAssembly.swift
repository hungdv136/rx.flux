//
//  ViewControllerAssembly.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/30/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import Swinject
import RxSwift

final class ViewControllerAssembly: Assembly {
    func assemble(container: Container) {
        container.register(CounterViewController.self) { r in
            let counterStore = r.resolve(CounterStore.self)!
            return CounterViewController(counterStore: counterStore)
        }
    }
}
