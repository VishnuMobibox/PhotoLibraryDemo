//
//  ScreenshotsView.swift
//  PhotoLibraryDemo
//
//  Created by Vishnu's Macbook Air on 27/03/24.
//

import Foundation
import Photos
import SwiftUI

struct ScreenshotsView: View {
    @StateObject private var viewModel = SreenshotsGalleryViewModel()

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
                ForEach(viewModel.images, id: \.self) { image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                }
            }
        }
        .onAppear {
            viewModel.loadImages()
        }
    }
}

class SreenshotsGalleryViewModel: ObservableObject {
    @Published var images: [UIImage] = []

    func loadImages() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            switch status {
            case .authorized:
                let fetchOptions = PHFetchOptions()
                let collections = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumScreenshots, options: fetchOptions)

                collections.enumerateObjects { collection, _, _ in
                    let assets = PHAsset.fetchAssets(in: collection, options: nil)
                    assets.enumerateObjects { asset, _, _ in
                        self?.fetchImage(asset: asset)
                    }
                }
            default:
                print("PHPhotoLibrary access is not authorized.")
            }
        }
    }

    private func fetchImage(asset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .current
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        let targetSize = CGSize(width: 200, height: 200)
        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { [weak self] image, _ in
            DispatchQueue.main.async {
                if let image = image {
                    self?.images.append(image)
                }
            }
        }
    }
}
