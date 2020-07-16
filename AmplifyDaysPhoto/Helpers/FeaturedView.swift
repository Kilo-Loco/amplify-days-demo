//
//  FeaturedView.swift
//  AmplifyDaysPhoto
//
//  Created by Kyle Lee on 7/16/20.
//

import SwiftUI

struct FeaturedView: View {
    
    let photos: [Photo]
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack {
                ForEach(photos) { photo in
                    AsyncImage(imageKey: photo.key, size: .large)
                }
            }
        }
    }
}

struct FeaturedView_Previews: PreviewProvider {
    static var previews: some View {
        FeaturedView(photos: [])
    }
}
