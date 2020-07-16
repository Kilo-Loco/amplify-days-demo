//
//  GalleryView.swift
//  AmplifyDaysPhoto
//
//  Created by Kyle Lee on 7/14/20.
//

import Amplify
import Combine
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

struct PhotosGrid: View {
    let columns = [GridItem(.adaptive(minimum: 80))]
    
    let photos: [Photo]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(photos) { photo in
                AsyncImage(imageKey: photo.key, size: .small)
            }
        }
    }
}

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

struct GalleryView: View {
    let columns = [GridItem(.adaptive(minimum: 80))]
    
    @State var observationToken: AnyCancellable?
    @State var shouldShowPhotoPicker = false
    @State var isUploading = false
    
    @State var featuredPhotos = [Photo]()
    @State var photos = [Photo]()
    
    let userId: String
    let shouldLogOut: () -> Void
    
    
    init(userId: String, shouldLogOut: @escaping () -> Void) {
        self.userId = userId
        self.shouldLogOut = shouldLogOut
    }
    
    var body: some View {
        NavigationView {
            
            ZStack {
                ScrollView {
                    VStack {
                        FeaturedView(photos: featuredPhotos)
                    
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(photos) { photo in
                                AsyncImage(imageKey: photo.key, size: .small)
                            }
                        }
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
            
        } //navigationView
        .onAppear {
            getFeaturedPhotos()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                getPhotos()
            }
            observePhotos()
        }
        
    } //body
    
    func getPhotos() {
        Amplify.DataStore.query(Photo.self) { result in
            switch result {
            case .success(let photos):
                print(photos)
                DispatchQueue.main.async {
                    self.photos = photos.filter { $0.photographerId == self.userId }
                    
                }
                                
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func getFeaturedPhotos() {
        _ = Amplify.API.query(request: .list(Photo.self)) { eventResult in

            do {
                let photos = try eventResult.get().get()
                DispatchQueue.main.async {
                self.featuredPhotos = photos.filter { $0.isFeatured }
                }

            } catch {
                print(error)
            }

        }
    }
    
    func observePhotos() {
        observationToken = Amplify.DataStore.publisher(for: Photo.self).sink { completion in
            print(completion)
        } receiveValue: { event in
            print("Observing event", event)
            do {
                let photo = try event.decodeModel(as: Photo.self)
                
                if
                    !self.photos.contains(where: {$0.id == photo.id}),
                    photo.photographerId == self.userId
                {
                    self.photos.append(photo)
                }
                
                self.featuredPhotos = photos.filter { $0.isFeatured }
                
            } catch {
                print(error)
            }
        }

    }
    
    func showPhotoPicker() {
        guard !isUploading else { return }
        shouldShowPhotoPicker.toggle()
    }
    
    func upload(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMdd-HHmm"
        let dateString = formatter.string(from: Date())

        let key = "p\(dateString).jpg"
        
        isUploading = true
        
        _ = Amplify.Storage.uploadData(key: key, data: imageData) { result in
            isUploading = false
            
            switch result {
            case .success(let imageKey):
                print("uploaded")
                savePhoto(with: imageKey)
                
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func savePhoto(with key: String) {
        let photo = Photo(key: key, photographerId: userId)
          
        Amplify.DataStore.save(photo) { savePhotoResult in
            switch savePhotoResult {
            case .success:
                print("photo saved")

            case .failure(let error):
                print("Failed to save photo", error)
            }
        }
    }
    
    private func logOut() {
        let options = AuthSignOutRequest.Options(globalSignOut: true)
        _ = Amplify.Auth.signOut(options: options) { result in
            switch result {
            case .success:
                shouldLogOut()
                
            case .failure(let error):
                print(error)
            }
        }
    }
}

struct GalleryView_Previews: PreviewProvider {
    static var previews: some View {
        GalleryView(userId: "My-UserID", shouldLogOut: {})
    }
}
