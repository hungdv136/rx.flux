//
//  DI.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/30/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import Swinject
import SwinjectStoryboard

struct DI {
    private static var assembler: Assembler?
    private static var resolver: Resolver?
    
    static func setup(_ assemblies: [Assembly]) {
        Container.loggingFunction = nil
        assembler = Assembler(assemblies, container: SwinjectStoryboard.defaultContainer)
        
        let container = assembler?.resolver as? Container
        resolver = container?.synchronize() ?? assembler?.resolver
    }
    
    static func reset() {
        assembler = nil
        resolver = nil
        SwinjectStoryboard.defaultContainer.removeAll()
    }
    
    static func resolve<Service>(name: String? = nil) -> Service? {
        return resolver?.resolve(Service.self, name: name)
    }
    
    static func resolve<Service, Arg1>(name: String? = nil, argument: Arg1) -> Service? {
        return resolver?.resolve(Service.self, name: name, argument: argument)
    }
    
    static func resolve<Service, Arg1, Arg2>(name: String? = nil, arguments arg1: Arg1, _ arg2: Arg2) -> Service? {
        return resolver?.resolve(Service.self, name: name, arguments: arg1, arg2)
    }
    
    static func resolve<Service, Arg1, Arg2, Arg3>(name: String? = nil, arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3) -> Service? {
        return resolver?.resolve(Service.self, name: name, arguments: arg1, arg2, arg3)
    }
    
    static func resolve<Service, Arg1, Arg2, Arg3, Arg4>(name: String? = nil, arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4) -> Service? {
        return resolver?.resolve(Service.self, name: name, arguments: arg1, arg2, arg3, arg4)
    }
    
    static func resolve<Service, Arg1, Arg2, Arg3, Arg4, Arg5>(name: String? = nil, arguments arg1: Arg1, _ arg2: Arg2, _ arg3: Arg3, _ arg4: Arg4, _ arg5: Arg5) -> Service? {
        return resolver?.resolve(Service.self, name: name, arguments: arg1, arg2, arg3, arg4, arg5)
    }
}

