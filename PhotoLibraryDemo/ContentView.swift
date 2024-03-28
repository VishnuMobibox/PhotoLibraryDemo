//
//  ContentView.swift
//  PhotoLibraryDemo
//
//  Created by Vishnu's Macbook Air on 27/03/24.
//

import Foundation
import SwiftUI

struct ContentView: View {
    
    var body: some View {
//        VStack {
//            Image(systemName: "globe")
//                .imageScale(.large)
//                .foregroundStyle(.tint)
//            Text("Hello, world!")
//        }
//        .padding()
        VStack {
            HomePageView()
                .ignoresSafeArea(.all)
        }
    }
}

#Preview {
    ContentView()
}

struct HomePageView: View {
    @StateObject private var viewModel = ImageGalleryViewModel()

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(viewModel.images, id: \.self) { img in
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                    }
                }
            }
        }
        .onAppear {
            viewModel.loadImages()
        }
    }
}

import PhotosUI



class ImageGalleryViewModel: ObservableObject {

    @Published var images: [UIImage] = []



    func loadImages() {

        PHPhotoLibrary.requestAuthorization(for: .readWrite) { [weak self] status in

            guard status == .authorized else {

                // Handle unauthorized case

                return

            }

            let fetchOptions = PHFetchOptions()

            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]

            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)



            // Consider limiting the number of assets fetched or fetched in batches

            let targetSize = CGSize(width: 100, height: 100) // Adjust based on your UI needs



            fetchResult.enumerateObjects { (asset, _, stop) in

                let options = PHImageRequestOptions()

                options.version = .current

                options.isSynchronous = false

                options.deliveryMode = .highQualityFormat // Consider using .fastFormat for thumbnails

                

                PHImageManager.default().requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { (image, info) in

                    DispatchQueue.main.async {

                        if let image = image {

                            self?.images.append(image)

                        }

                    }

                }

            }

        }

    }

}
