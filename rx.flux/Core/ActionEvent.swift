//
//  ActionEvent.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 7/3/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

public enum ActionEvent {
    case start
    case failed(Error)
    case retry
    case completed
}

extension ObservableType where E == ActionEvent {
    public func completedOrError() -> Observable<Void> {
        return map { event -> Bool in
                if case let .failed(error) = event { throw error }
                if case .completed = event { return true }
                return false
            }
            .filter { $0 }
            .map { _ in }
    }
}
