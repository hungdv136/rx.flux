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

