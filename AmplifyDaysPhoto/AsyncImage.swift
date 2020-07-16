//
//  AsyncImage.swift
//  AmplifyDaysPhoto
//
//  Created by Kyle Lee on 7/14/20.
//

import SwiftUI

struct AsyncImage: View {
    
    @ObservedObject var imageLoader = ImageLoader()
    
    let imageKey: String
    let size: ImageSize
    
    var body: some View {
        Group {
            if let image = imageLoader.image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: size.dimension, height: size.dimension)
                    .clipped()
            } else {
                ProgressView()
                    .padding()
            }
        }
        .onAppear {
            
            imageLoader.loadImage(with: imageKey)
        }
    }
}

extension AsyncImage {
    enum ImageSize {
        case small, large
        
        var dimension: CGFloat {
            switch self {
            case .small: return 95
            case .large: return 200
            }
        }
    }
}
