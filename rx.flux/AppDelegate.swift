//
//  AppDelegate.swift
//  rx.flux
//
//  Created by Hung Dinh Van on 6/26/17.
//  Copyright © 2017 ChuCuoi. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        DI.setup([StoreAssembly(), ViewControllerAssembly()])
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = DI.resolve() as CounterViewController?
        window?.makeKeyAndVisible()
        return true
    }
}

