//
//  AuthView.swift
//  AmplifyDaysPhoto
//
//  Created by Kyle Lee on 7/14/20.
//

import Amplify
import AmplifyPlugins
import SwiftUI

struct AuthView: View {
    
    let window: UIWindow
    let didSignIn: (String) -> Void
    
    var body: some View {
        Button("Sign Up", action: signInWithWebUI)
            .onAppear(perform: fetchCurrentAuthSession)
    }
    
    func fetchCurrentAuthSession() {
        _ = Amplify.Auth.fetchAuthSession { result in
            switch result {
            case .success(let session as AWSAuthCognitoSession):
                do {
                    let id = try session.getIdentityId().get()
                    didSignIn(id)
                } catch {
                    print(error)
                }
                
                
            default:
                print("Fetch session failed with error")
            }
        }
    }
    
    func signInWithWebUI() {
        _ = Amplify.Auth.signInWithWebUI(presentationAnchor: window) { result in
            switch result {
            case .success(_):
                fetchCurrentAuthSession()
                
            case .failure(let error):
                print("Sign in failed \(error)")
            }
        }
    }
    
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView(window: UIWindow(), didSignIn: {_ in})
    }
}
