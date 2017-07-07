//
//  Persistence.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

public protocol Persistence {
    associatedtype State
    
    func save(_ state: State) -> Observable<Void>
    func load() -> Observable<State?>
}
