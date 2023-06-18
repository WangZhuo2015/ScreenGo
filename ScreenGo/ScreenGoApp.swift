//
//  ScreenGoApp.swift
//  ScreenGo
//
//  Created by wangzhuo on 16/06/2023.
//

import SwiftUI

@main
struct ScreenGoApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(appDelegate)
        }
    }
}
