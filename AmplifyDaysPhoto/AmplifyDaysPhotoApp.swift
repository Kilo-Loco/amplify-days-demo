//
//  AmplifyDaysPhotoApp.swift
//  AmplifyDaysPhoto
//
//  Created by Kyle Lee on 7/14/20.
//

import SwiftUI

@main
struct AmplifyDaysPhotoApp: App {
    
    var window: UIWindow {
        guard
            let scene = UIApplication.shared.connectedScenes.first,
            let windowSceneDelegate = scene.delegate as? UIWindowSceneDelegate,
            let window = windowSceneDelegate.window as? UIWindow
        else { return UIWindow() }
        
        return window
    }
    
    
    var body: some Scene {
        WindowGroup {
            AuthView(window: window)
        }
    }
}
