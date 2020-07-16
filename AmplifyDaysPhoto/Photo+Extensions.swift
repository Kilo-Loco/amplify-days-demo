//
//  Photo+Extensions.swift
//  AmplifyDaysPhoto
//
//  Created by Kyle Lee on 7/15/20.
//

import SwiftUI

extension Photo {
    init(key: String, photographerId: String) {
        self.init(
            id: UUID().uuidString,
            key: key,
            isFeatured: false,
            photographerId: photographerId
        )
    }
}

extension Photo: Identifiable {}
