//
//  CameraView.swift
//  PhotoLibraryDemo
//
//  Created by Vishnu's Macbook Air on 27/03/24.
//


import Foundation
import SwiftUI
import Photos
import ImageIO

struct CameraView: View {
    @StateObject private var viewModel = CameraImageViewModel()

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
            viewModel.loadCameraCapturedImages()
        }
    }
}

class CameraImageViewModel: ObservableObject {
    @Published var images: [UIImage] = []

    func loadCameraCapturedImages() {
        PHPhotoLibrary.requestAuthorization { [weak self] status in
            guard status == .authorized else {
                return // Handle unauthorized case
            }

            let fetchOptions = PHFetchOptions()
            let allPhotos = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: fetchOptions)

            allPhotos.enumerateObjects { collection, _, _ in
                let assets = PHAsset.fetchAssets(in: collection, options: nil)
                assets.enumerateObjects { asset, _, _ in
                    self?.fetchImageAssetMetadata(asset: asset) { exifDictionary in
                        guard let exifDictionary = exifDictionary,
                              exifDictionary["FNumber"] != nil else { return }
                              
                        // If this point is reached, the image likely came from a camera
                        self?.fetchImage(asset: asset)
                    }
                }
            }
        }
    }

    private func fetchImage(asset: PHAsset) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.version = .current
        options.isSynchronous = false
        options.deliveryMode = .highQualityFormat

        let targetSize = CGSize(width: 200, height: 200) // Example target size
        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFit, options: options) { [weak self] image, _ in
            DispatchQueue.main.async {
                if let image = image {
                    self?.images.append(image)
                }
            }
        }
    }

    private func fetchImageAssetMetadata(asset: PHAsset, completion: @escaping ([String: Any]?) -> Void) {
        let options = PHContentEditingInputRequestOptions()
        options.canHandleAdjustmentData = { _ in true }

        asset.requestContentEditingInput(with: options) { (contentEditingInput, _) in
            guard let url = contentEditingInput?.fullSizeImageURL else {
                completion(nil)
                return
            }

            let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)
            guard let imageSourceRef = imageSource else {
                completion(nil)
                return
            }

            let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, nil) as? [String: Any]
            let exifDictionary = imageProperties?[kCGImagePropertyExifDictionary as String] as? [String: Any]

            completion(exifDictionary)
        }
    }
}
