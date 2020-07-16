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
    let didSignIn: (_ userId: String) -> Void
    
    var body: some View {
        Button("Sign Up", action: signInWithWebUI)
            .onAppear(perform: fetchCurrentAuthSession)
    }
    
    func fetchCurrentAuthSession() {
        _ = Amplify.Auth.fetchAuthSession { result in
            switch result {
            
            // is signed in
            case .success(let session as AWSAuthCognitoSession):
                switch session.getIdentityId() {
                case .success(let identityId):
                    print(identityId)
                    didSignIn(identityId)
                    
                case .failure(let error):
                    print(error)
                    signInWithWebUI()
                }
                
            // start sign in flow
            default:
                print("Not signed in")
                signInWithWebUI()
            }
        }
    }
    
    func signInWithWebUI() {
        _ = Amplify.Auth.signInWithWebUI(presentationAnchor: window) { result in
            switch result {
            case .success(_):
                print("Sign in succeeded")
                fetchCurrentAuthSession()
                
            case .failure(let error):
                print("Sign in failed \(error)")
            }
        }
    }
    
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView(window: UIWindow()){_ in}
    }
}
