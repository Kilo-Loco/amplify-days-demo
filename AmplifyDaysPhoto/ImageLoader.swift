//
//  ImageLoader.swift
//  AmplifyDaysPhoto
//
//  Created by Kyle Lee on 7/14/20.
//

import Amplify
import SwiftUI

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    
    func loadImage(with imageKey: String) {
        if let image = ImageCache.shared.image(for: imageKey) {
            print("Returning cached image")
            self.image = image
        } else {
            
            // Download image data
            _ = Amplify.Storage.downloadData(key: imageKey,
                progressListener: { progress in
                    print("Progress: \(progress)")
                }, resultListener: { (event) in
                    switch event {
                    case let .success(data):
                        
                        guard let image = UIImage(data: data) else { return }
                        
                        ImageCache.shared.add(image, for: imageKey)
                        
                        DispatchQueue.main.async {
                            self.image = image
                        }
                        
                    case let .failure(storageError):
                        print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                }
            })
        }
    }
}
