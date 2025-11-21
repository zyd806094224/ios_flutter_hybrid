//
//  AppDelegate.swift
//  ios_flutter_hybrid
//
//  Created by zhaoyudong on 2025/11/19.
//

import UIKit
import Flutter

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    // Create a lazy FlutterEngine.
    lazy var flutterEngine = FlutterEngine(name: "my_flutter_engine")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Pre-warm the FlutterEngine.
        flutterEngine.run()
        return true
    }

    // MARK: UISceneSession Lifecycle
}


