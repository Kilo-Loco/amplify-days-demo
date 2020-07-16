//
//  ImageLoader.swift
//  AmplifyDaysPhoto
//
//  Created by Kyle Lee on 7/14/20.
//

import Foundation

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    
    func loadImage(with imageKey: String) {
        if let image = ImageCache.shared.image(for: imageKey) {
            print("Returning cached image")
            self.image = image
        } else {
            
            // Download image data
            
        }
    }
}
