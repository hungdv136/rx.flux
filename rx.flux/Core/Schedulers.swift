//
//  Scheduler.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import RxSwift

struct Schedulers {
    static var main: SchedulerType {
        return MainScheduler.instance
    }
    
    static let backgroundDefault: SchedulerType = {
        return ConcurrentDispatchQueueScheduler(qos: .default)
    }()
    
    static let backgroundUserInitiated: SchedulerType = {
        return ConcurrentDispatchQueueScheduler(qos: .userInitiated)
    }()
    
    static var JSONParsing: SchedulerType {
        return backgroundDefault
    }
}

