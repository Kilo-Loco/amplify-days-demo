//
//  ImageLoader.swift
//  AmplifyDaysPhoto
//
//  Created by Kyle Lee on 7/14/20.
//

import Amplify
import Foundation

class ImageLoader: ObservableObject {
    @Published var image: UIImage?
    
    
    func loadImage(with imageKey: String) {
        if let image = ImageCache.shared.image(for: imageKey) {
            print("Returning cached image")
            self.image = image
        } else {
            _ = Amplify.Storage.downloadData(key: imageKey) { [weak self] result in
                switch result {
                case .success(let data):
                    print("Got data: \(data)")
                    guard let image = UIImage(data: data) else { return }
                    
                    ImageCache.shared.add(image, for: imageKey)
                    
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                    
                case .failure(let error):
                    print("Failed to get data")
                    print(error)
                }
            }
        }
    }
}
