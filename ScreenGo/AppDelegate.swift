//
//  AppDelegate.swift
//  ScreenGo
//
//  Created by wangzhuo on 17/06/2023.
//

import UIKit
class AppDelegate: NSObject, UIApplicationDelegate, ObservableObject {
    @Published var orientation = UIInterfaceOrientation.unknown

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
        return true
    }

    @objc private func orientationChanged() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            if let window = windowScene.windows.first {
                orientation = window.windowScene?.interfaceOrientation ?? .unknown
            }
        }
    }
}
