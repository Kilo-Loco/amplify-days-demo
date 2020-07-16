//
//  PhotosGrid.swift
//  AmplifyDaysPhoto
//
//  Created by Kyle Lee on 7/16/20.
//

import SwiftUI

struct PhotosGrid: View {
    let columns = [GridItem(.adaptive(minimum: 80))]
    
    let photos: [Photo]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(photos) { photo in
                AsyncImage(imageKey: photo.key)
            }
        }
    }
}

struct PhotosGrid_Previews: PreviewProvider {
    static var previews: some View {
        PhotosGrid(photos: [])
    }
}
