//
//  DispatchRule.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 7/3/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

public protocol DispatchRule {
    func execute(dispatchingAction: ExecutingAction, actions: [ExecutingAction])
}
