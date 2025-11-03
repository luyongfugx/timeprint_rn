
import Foundation
import Photos

struct Pagination {
    let batchSize = 100 // 每次加载的照片数量
    var currentOffset = 0 // 当前加载的偏移量
    var hasMore = true // 是否还有更多照片待加载
}

enum MediaFetchError: Error {
    case failedToFetchVideo
    case failedToFetchImage
}

struct MediaResult {
    enum Item {
        case video(url: URL, asset: PHAsset)
        case image(image: UIImage, asset: PHAsset)
    }
    
    let items: [Item]
}

class MultiPhotoManager {
    private var fetchResult: PHFetchResult<PHAsset>?
    private let imageManager = PHCachingImageManager()
    var albumTitle: String = "default"
    // 初始化时预先获取所有照片的 fetch result
    func prepareFetchResult(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]

                // 获取指定相册(Timeprint)
                let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: nil)

                var targetCollection: PHAssetCollection?
                
                collections.enumerateObjects { (collection, _, stop) in
                    if collection.localizedTitle == self.albumTitle {
                        targetCollection = collection
                        stop.pointee = true
                    }
                }
                
                if let collection = targetCollection {
                    self.fetchResult = PHAsset.fetchAssets(in: collection, options: fetchOptions)
                } else {
                    // 如果找不到指定相册，使用所有照片
                    self.fetchResult = PHAsset.fetchAssets(with: fetchOptions)
                }
                
//                self.allPhotosFetchResult = PHAsset.fetchAssets(with: fetchOptions)

                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }

    // 分页获取照片
    func fetchPhotosBatch(pagination: inout Pagination, completion: @escaping ([PHAsset]) -> Void) {
        guard let allPhotos = fetchResult else {
            completion([])
            return
        }

        let start = pagination.currentOffset
        let end = min(start + pagination.batchSize, allPhotos.count)

        guard start < end else {
            pagination.hasMore = false
            completion([])
            return
        }

        var assets: [PHAsset] = []
        allPhotos.enumerateObjects { asset, index, stop in
            if index >= start, index < end {
                assets.append(asset)
            }
            if index >= end - 1 {
                stop.pointee = true
            }
        }

        pagination.currentOffset += assets.count
        if pagination.currentOffset >= allPhotos.count {
            pagination.hasMore = false
        }

        completion(assets)
    }

    // 通过 PHAsset 获取 UIImage
    func requestImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.deliveryMode = .opportunistic
        options.resizeMode = .fast

        imageManager.requestImage(
            for: asset,
            targetSize: targetSize,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            completion(image)
        }
    }
    
    // MARK: 批量从[PHAsset]中获取图片和视频
    
    func fetchMediaFromAssets(_ assets: [PHAsset]) async throws -> MediaResult {
        var items: [MediaResult.Item?] = Array(repeating: nil, count: assets.count)
        
        try await withThrowingTaskGroup(of: (Int, MediaResult.Item?).self) { group in
            for (index, asset) in assets.enumerated() {
                group.addTask { [self] in
                    switch asset.mediaType {
                    case .video:
                        if let (url, asset) = try await self.fetchVideo(from: asset) {
                            return (index, .video(url: url, asset: asset))
                        }
                    case .image:
                        if let (image, asset) = try await self.fetchImage(from: asset) {
                            return (index, .image(image: image, asset: asset))
                        }
                    default:
                        break
                    }
                    return (index, nil)
                }
            }
            
            for try await (index, item) in group {
                items[index] = item
            }
        }
        
        return MediaResult(items: items.compactMap { $0 })
    }
    
    private func fetchVideo(from asset: PHAsset) async throws -> (URL, PHAsset)? {
        guard asset.mediaType == .video else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            let options = PHVideoRequestOptions()
            options.isNetworkAccessAllowed = true
            options.deliveryMode = .highQualityFormat
            options.version = .current

            PHImageManager.default().requestAVAsset(forVideo: asset, options: options, resultHandler: { avAsset, _, _ in
                if let urlAsset = avAsset as? AVURLAsset {
                    continuation.resume(returning: (urlAsset.url, asset))
                } else {
                    continuation.resume(throwing: MediaFetchError.failedToFetchVideo)
                }
            })
        }
    }
    
    private func fetchImage(from asset: PHAsset) async throws -> (UIImage, PHAsset)? {
        guard asset.mediaType == .image else { return nil }

        return try await withCheckedThrowingContinuation { continuation in
            
            ZLPhotoManager.fetchOriginalImg(for: asset) { image, isSuccess in
                if let image {
                    continuation.resume(returning: (image, asset))
                } else {
                    continuation.resume(throwing: MediaFetchError.failedToFetchImage)
                }
            }
                        
        }
    }
}

extension Date {
    func photoDateFormattedString() -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        
        if calendar.isDateInToday(self) {
            return "i_today".localized()
        } else {
            let currentYear = calendar.component(.year, from: Date())
            let assetYear = calendar.component(.year, from: self)
            
            if assetYear == currentYear {
                formatter.dateFormat = "MMM d"
            } else {
                formatter.dateFormat = "MMM d yyyy"
            }
            return formatter.string(from: self)
        }
    }
}
