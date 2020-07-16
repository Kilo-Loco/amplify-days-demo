//
//  NewPhotoButton.swift
//  AmplifyDaysPhoto
//
//  Created by Kyle Lee on 7/16/20.
//

import SwiftUI

struct NewPhotoButton: View {
    
    let action: () -> Void
    let isInProgress: Bool
    
    var body: some View {
        Button(action: action, label: {
            if isInProgress {
                ProgressView()
                    .padding()
                    .background(Color.blue)
                    .clipShape(Circle())
                
            } else {
                Image(systemName: "plus")
                    .font(.largeTitle)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .clipShape(Circle())
            }
        })
    }
}

struct NewPhotoButton_Previews: PreviewProvider {
    static var previews: some View {
        NewPhotoButton(action: {}, isInProgress: false)
    }
}
