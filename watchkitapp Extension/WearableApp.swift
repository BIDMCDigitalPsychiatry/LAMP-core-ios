// watchkitapp Extension

//
//  WearableApp.swift
//
//  Created by Zco Engg.Dept. on 23/12/20.
//

import SwiftUI
import WatchKit

@main
struct WearableApp: App {
    
    @WKExtensionDelegateAdaptor(ExtensionDelegate.self) var extensionDelegate
    
    @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView {
                let isLogged = User.shared.isLogin()
                ContentView(userAuth: UserAuth(isLogged))
            }
        }
    }
}
