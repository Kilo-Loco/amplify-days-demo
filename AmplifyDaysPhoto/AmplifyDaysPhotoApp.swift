//
//  AmplifyDaysPhotoApp.swift
//  AmplifyDaysPhoto
//
//  Created by Kyle Lee on 7/14/20.
//

import Amplify
import AmplifyPlugins
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
    
    @State var userId: String?
    
    init() {
        configureAmplify()
    }
    
    var body: some Scene {
        WindowGroup {
            if let userId = self.userId {
                GalleryView(userId: userId) {
                    self.userId = nil
                }
                
            } else {
                AuthView(window: window) { userId in
                    self.userId = userId
                }
            }
        }
    }
    
    func configureAmplify() {
        do {
            // Auth
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            
            // DataStore
            let models = AmplifyModels()
            try Amplify.add(plugin: AWSDataStorePlugin(modelRegistration: models))
            try Amplify.add(plugin: AWSAPIPlugin(modelRegistration: models))
            
            // Storage
            try Amplify.add(plugin: AWSS3StoragePlugin())
            
            try Amplify.configure()
            
            print("Amplify configured with auth plugin")
            
        } catch {
            print("Failed to initialize Amplify with \(error)")
        }
    }
}
