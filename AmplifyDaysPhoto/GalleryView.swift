//
//  GalleryView.swift
//  AmplifyDaysPhoto
//
//  Created by Kyle Lee on 7/16/20.
//

import Amplify
import SwiftUI

struct GalleryView: View {
    
    @State var isUploading = false
    @State var shouldShowPhotoPicker = false
    
    @State var featuredPhotos = [Photo]()
    @State var photos = [Photo]()
    
    let userId: String
    let didSignOut: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                ScrollView {
                    VStack {
                        FeaturedView(photos: featuredPhotos)
                        PhotosGrid(photos: photos)
                    }
                }
                
                VStack {
                    
                    Spacer()
                    NewPhotoButton(action: showPhotoPicker, isInProgress: isUploading)
                    
                } //vstack
            } //zstack
                .navigationTitle("Photos")
                .navigationBarItems(
                    trailing: Button("Log Out", action: logOut)
                )
                .sheet(isPresented: $shouldShowPhotoPicker) {
                    PhotoPicker(
                        isPresented: $shouldShowPhotoPicker,
                        didProvideImage: upload
                    )
                }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                getPhotos()
            }
            getFeaturedPhotos()
        }
    }
    
    func showPhotoPicker() {
        guard !isUploading else { return }
        shouldShowPhotoPicker.toggle()
    }
    
    func getPhotos() {
        Amplify.DataStore.query(Photo.self) { result in
            switch result {
            case .success(let photos):
                self.photos = photos
                
            case .failure(let error):
                print("Error retrieving posts \(error)")
            }
        }
    }
    
    func getFeaturedPhotos() {
        
        _ = Amplify.API.query(request: .list(Photo.self)) { event in
            do {
                let featuredPhotos = try event.get().get().filter {
                    $0.isFeatured
                }
                self.featuredPhotos = featuredPhotos
                
            } catch {
                print(error)
            }
        }
            
    }
    
    func upload(_ image: UIImage) {
        let imageData = image.jpegData(compressionQuality: 0.5)!
        
        let key = UUID().uuidString + ".jpg"
        
        
        _ = Amplify.Storage.uploadData(key: key, data: imageData,
            progressListener: { progress in
                print("Progress: \(progress)")
            }, resultListener: { event in
                switch event {
                case .success(let data):
                    print("Completed: \(data)")
                    createNewPhoto(with: key)
                    
                case .failure(let storageError):
                    print("Failed: \(storageError.errorDescription). \(storageError.recoverySuggestion)")
                }
        })
    }
    
    func createNewPhoto(with key: String) {
        let photo = Photo(key: key, photographerId: userId)
        
        Amplify.DataStore.save(photo) { result in
            switch result {
            case .success(let photo):
                print("Post saved successfully!")
                
                self.photos.append(photo)
                
                
            case .failure(let error):
                print("Error saving post \(error)")
            }
        }
    }
    
    func logOut() {
        let options = AuthSignOutRequest.Options(globalSignOut: true)
        _ = Amplify.Auth.signOut(options: options) { result in
            switch result {
            case .success:
                print("Successfully signed out")
                didSignOut()
                
            case .failure(let error):
                print("Sign out failed with error \(error)")
            }
        }
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView(userId: "", didSignOut: {})
    }
}
