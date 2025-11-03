//
//  ZLPhotoManager.swift
//  ZLPhotoBrowser
//
//  Created by long on 2020/8/11.
//
//  Copyright (c) 2020 Long Zhang <495181165@qq.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit
import Photos

@objcMembers
public class ZLPhotoManager: NSObject {
    /// Save image to album.
    public class func saveImageToAlbum(image: UIImage, completion: ((Bool, PHAsset?) -> Void)?) {
        let status = PHPhotoLibrary.zl.authStatus(for: .addOnly)
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        
        var placeholderAsset: PHObjectPlaceholder?
        let completionHandler: ((Bool, Error?) -> Void) = { suc, _ in
            if suc {
                let asset = self.getAsset(from: placeholderAsset?.localIdentifier)
                ZLMainAsync {
                    completion?(suc, asset)
                }
            } else {
                ZLMainAsync {
                    completion?(false, nil)
                }
            }
        }

        if image.zl.hasAlphaChannel(), let data = image.pngData() {
            PHPhotoLibrary.shared().performChanges({
                let newAssetRequest = PHAssetCreationRequest.forAsset()
                newAssetRequest.addResource(with: .photo, data: data, options: nil)
                placeholderAsset = newAssetRequest.placeholderForCreatedAsset
            }, completionHandler: completionHandler)
        } else {
            PHPhotoLibrary.shared().performChanges({
                let newAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                placeholderAsset = newAssetRequest.placeholderForCreatedAsset
            }, completionHandler: completionHandler)
        }
    }
    
    /// Save video to album.
    public class func saveVideoToAlbum(url: URL, completion: ((Bool, PHAsset?) -> Void)?) {
        let status = PHPhotoLibrary.zl.authStatus(for: .addOnly)
        if status == .denied || status == .restricted {
            completion?(false, nil)
            return
        }
        
        var placeholderAsset: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let newAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            placeholderAsset = newAssetRequest?.placeholderForCreatedAsset
        }) { suc, _ in
            if suc {
                let asset = self.getAsset(from: placeholderAsset?.localIdentifier)
                ZLMainAsync {
                    completion?(suc, asset)
                }
            } else {
                ZLMainAsync {
                    completion?(false, nil)
                }
            }
        }
    }
    
    private class func getAsset(from localIdentifier: String?) -> PHAsset? {
        guard let id = localIdentifier else {
            return nil
        }
        
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [id], options: nil)
        return result.firstObject
    }
    
    /// Fetch photos from result.
    public class func fetchPhoto(in result: PHFetchResult<PHAsset>, ascending: Bool, allowSelectImage: Bool, allowSelectVideo: Bool, limitCount: Int = .max,searchText:String = "") -> [ZLPhotoModel] {
        var models: [ZLPhotoModel] = []
        let option: NSEnumerationOptions = ascending ? .init(rawValue: 0) : .reverse
        var count = 1
        
        result.enumerateObjects(options: option) { asset, _, stop in
            let m = ZLPhotoModel(asset: asset)
            
            if m.type == .image, !allowSelectImage {
                return
            }
            if m.type == .video, !allowSelectVideo {
                return
            }
   
            if count == limitCount {
                stop.pointee = true
            }
            
           
        
            models.append(m)
            count += 1
        }
        
        return models
    }
    
    /// Fetch all album list.
    public class func getPhotoAlbumList(ascending: Bool, allowSelectImage: Bool, allowSelectVideo: Bool, completion: ([ZLAlbumListModel]) -> Void) {
        let option = PHFetchOptions()
        if !allowSelectImage {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
        }
        if !allowSelectVideo {
            option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
        }
        
        let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil) as? PHFetchResult<PHCollection>
        let albums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: nil) as? PHFetchResult<PHCollection>
        let streamAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumMyPhotoStream, options: nil) as? PHFetchResult<PHCollection>
        let syncedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumSyncedAlbum, options: nil) as? PHFetchResult<PHCollection>
        let sharedAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumCloudShared, options: nil) as? PHFetchResult<PHCollection>
        let arr = [smartAlbums, albums, streamAlbums, syncedAlbums, sharedAlbums].compactMap { $0 }
        
        var albumList: [ZLAlbumListModel] = []
        arr.forEach { album in
            album.enumerateObjects { collection, _, _ in
                guard let collection = collection as? PHAssetCollection else { return }
                if collection.assetCollectionSubtype == .smartAlbumAllHidden {
                    return
                }
                if #available(iOS 11.0, *), collection.assetCollectionSubtype.rawValue > PHAssetCollectionSubtype.smartAlbumLongExposures.rawValue {
                    return
                }
                let result = PHAsset.fetchAssets(in: collection, options: option)
                if result.count == 0 {
                    return
                }
                let title = self.getCollectionTitle(collection)
                
                if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                    // Album of all photos.
                    let m = ZLAlbumListModel(title: title, result: result, collection: collection, option: option, isCameraRoll: true)
                    albumList.insert(m, at: 0)
                } else {
                    let m = ZLAlbumListModel(title: title, result: result, collection: collection, option: option, isCameraRoll: false)
                    albumList.append(m)
                }
            }
        }
        
        completion(albumList)
    }
    
    /// Fetch camera roll album.
    public class func getCameraRollAlbum(albumTitle:String = "default", allowSelectImage: Bool, allowSelectVideo: Bool, searchText:String = "",date:Date? = nil ,completion: @escaping (ZLAlbumListModel) -> Void) {
        DispatchQueue.global().async {
            let option = PHFetchOptions()
            if !allowSelectImage {
                option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.video.rawValue)
            }
            if !allowSelectVideo {
                option.predicate = NSPredicate(format: "mediaType == %ld", PHAssetMediaType.image.rawValue)
            }
            //如果是非默认
            if albumTitle != "default" {
                let fetchOptions = PHFetchOptions()
                fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)
                // 获取所有自定义相册
                let userAlbums = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
                userAlbums.enumerateObjects { collection, _, stop in
                    print({collection.localizedTitle })
                    if collection.localizedTitle == albumTitle {
                        stop.pointee = true
                        let assetsFetchOptions = PHFetchOptions()
                        assetsFetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
                        if(date != nil) {
                            let startOfDay = Calendar.current.startOfDay(for: date!)
                            let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)
                            assetsFetchOptions.predicate = NSPredicate(format: "creationDate >= %@ AND creationDate < %@", startOfDay as NSDate, endOfDay! as NSDate)
                        }
                  
                        
                        
                        let allResult = PHAsset.fetchAssets(in: collection, options: assetsFetchOptions)
                             //过滤照片名字
                        if !searchText.isEmpty {
                            var filteredAssets: [PHAsset] = []
                            allResult.enumerateObjects { (asset, _, _) in
                                if let filename = asset.originalFilename?.lowercased(),
                                   filename.contains(searchText.lowercased()) {
                                  //  print("filename \(filename) searchText \(searchText)")
                                    filteredAssets.append(asset)
                                }
                            }
                            
                            
                            let   result = PHAsset.fetchAssets(withLocalIdentifiers: filteredAssets.map { $0.localIdentifier }, options: assetsFetchOptions)
                            let albumModel = ZLAlbumListModel(title: albumTitle, result: result, collection: collection, option: assetsFetchOptions, isCameraRoll: false)
                            ZLMainAsync {
                                completion(albumModel)
                            }
                        }
                        else {
                            let albumModel = ZLAlbumListModel(title: albumTitle, result: allResult, collection: collection, option: option, isCameraRoll: false)
                            ZLMainAsync {
                                completion(albumModel)
                            }
                        }
                        
                
                    }
                }
            } else {
                let smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .any, options: nil)
                smartAlbums.enumerateObjects { collection, _, stop in
                    if collection.assetCollectionSubtype == .smartAlbumUserLibrary {
                        stop.pointee = true
                        
                        let result = PHAsset.fetchAssets(in: collection, options: option)
                        let albumModel = ZLAlbumListModel(title: self.getCollectionTitle(collection), result: result, collection: collection, option: option, isCameraRoll: true)
                        ZLMainAsync {
                            completion(albumModel)
                        }
                    }
                }
            }
        }
    }
    
    /// Conversion collection title.
    private class func getCollectionTitle(_ collection: PHAssetCollection) -> String {
        if collection.assetCollectionType == .album {
            // Albums created by user.
            var title: String?
            if ZLCustomLanguageDeploy.language == .system {
                title = collection.localizedTitle
            } else {
                switch collection.assetCollectionSubtype {
                case .albumMyPhotoStream:
                    title = localLanguageTextValue(.myPhotoStream)
                default:
                    title = collection.localizedTitle
                }
            }
            return title ?? localLanguageTextValue(.noTitleAlbumListPlaceholder)
        }
        
        var title: String?
        if ZLCustomLanguageDeploy.language == .system {
            title = collection.localizedTitle
        } else {
            switch collection.assetCollectionSubtype {
            case .smartAlbumUserLibrary:
                title = localLanguageTextValue(.cameraRoll)
            case .smartAlbumPanoramas:
                title = localLanguageTextValue(.panoramas)
            case .smartAlbumVideos:
                title = localLanguageTextValue(.videos)
            case .smartAlbumFavorites:
                title = localLanguageTextValue(.favorites)
            case .smartAlbumTimelapses:
                title = localLanguageTextValue(.timelapses)
            case .smartAlbumRecentlyAdded:
                title = localLanguageTextValue(.recentlyAdded)
            case .smartAlbumBursts:
                title = localLanguageTextValue(.bursts)
            case .smartAlbumSlomoVideos:
                title = localLanguageTextValue(.slomoVideos)
            case .smartAlbumSelfPortraits:
                title = localLanguageTextValue(.selfPortraits)
            case .smartAlbumScreenshots:
                title = localLanguageTextValue(.screenshots)
            case .smartAlbumDepthEffect:
                title = localLanguageTextValue(.depthEffect)
            case .smartAlbumLivePhotos:
                title = localLanguageTextValue(.livePhotos)
            default:
                title = collection.localizedTitle
            }
            
            if #available(iOS 11.0, *) {
                if collection.assetCollectionSubtype == PHAssetCollectionSubtype.smartAlbumAnimated {
                    title = localLanguageTextValue(.animated)
                }
            }
        }
        
        return title ?? localLanguageTextValue(.noTitleAlbumListPlaceholder)
    }
    
    @discardableResult
    public class func fetchImage(for asset: PHAsset, size: CGSize, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        return fetchImage(for: asset, size: size, resizeMode: .fast, progress: progress, completion: completion)
    }
    
    @discardableResult
    public class func fetchOriginalImage(for asset: PHAsset, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        return fetchImage(for: asset, size: PHImageManagerMaximumSize, resizeMode: .fast, progress: progress, completion: completion)
    }
    
    public class func fetchOriginalImg(for asset: PHAsset, completion: @escaping (UIImage?, Bool) -> Void) {
        
        let option = PHImageRequestOptions()
        option.isSynchronous = true
        option.isNetworkAccessAllowed = true
        option.resizeMode = .none
        
        PHImageManager.default().requestImage(for: asset,
                                              targetSize: PHImageManagerMaximumSize , contentMode: .default,
                                              options: option, resultHandler: {
            (image, _: [AnyHashable : Any]?) in
            if let image = image {
                ZLMainAsync {
                    completion(image, true)
                }
            } else {
                ZLMainAsync {
                    completion(nil, false)
                }
            }})
    }
    
    
    /// Fetch asset data.
    @discardableResult
    public class func fetchOriginalImageData(for asset: PHAsset, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (Data, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        let option = PHImageRequestOptions()
        if asset.zl.isGif {
            option.version = .original
        }
        option.isNetworkAccessAllowed = true
        option.resizeMode = .fast
        option.deliveryMode = .highQualityFormat
        option.progressHandler = { pro, error, stop, info in
            ZLMainAsync {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        let resultHandler: (Data?, [AnyHashable: Any]?) -> Void = { data, info in
            let cancel = info?[PHImageCancelledKey] as? Bool ?? false
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            if !cancel, let data = data {
                completion(data, info, isDegraded)
            }
        }
        
        if #available(iOS 13.0, *) {
            return PHImageManager.default().requestImageDataAndOrientation(for: asset, options: option) { data, _, _, info in
                resultHandler(data, info)
            }
        } else {
            return PHImageManager.default().requestImageData(for: asset, options: option) { data, _, _, info in
                resultHandler(data, info)
            }
        }
    }
    
    /// Fetch image for asset.
    private class func fetchImage(for asset: PHAsset, size: CGSize, resizeMode: PHImageRequestOptionsResizeMode, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (UIImage?, Bool) -> Void) -> PHImageRequestID {
        let option = PHImageRequestOptions()
        option.resizeMode = resizeMode
        option.isNetworkAccessAllowed = true
        option.progressHandler = { pro, error, stop, info in
            ZLMainAsync {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        return PHImageManager.default().requestImage(for: asset, targetSize: size, contentMode: .aspectFill, options: option) { image, info in
            var downloadFinished = false
            if let info = info {
                downloadFinished = !(info[PHImageCancelledKey] as? Bool ?? false) && (info[PHImageErrorKey] == nil)
            }
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            if downloadFinished {
                ZLMainAsync {
                    completion(image, isDegraded)
                }
            }
        }
    }
    
    /// Fetch asset data.
    @discardableResult
    public class func fetchLivePhoto(for asset: PHAsset, completion: @escaping (PHLivePhoto?, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        let option = PHLivePhotoRequestOptions()
        option.version = .current
        option.deliveryMode = .opportunistic
        option.isNetworkAccessAllowed = true
        
        return PHImageManager.default().requestLivePhoto(for: asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: option) { livePhoto, info in
            let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
            completion(livePhoto, info, isDegraded)
        }
    }
    
    public class func fetchVideo(for asset: PHAsset, progress: ((CGFloat, Error?, UnsafeMutablePointer<ObjCBool>, [AnyHashable: Any]?) -> Void)? = nil, completion: @escaping (AVPlayerItem?, [AnyHashable: Any]?, Bool) -> Void) -> PHImageRequestID {
        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        option.progressHandler = { pro, error, stop, info in
            ZLMainAsync {
                progress?(CGFloat(pro), error, stop, info)
            }
        }
        
        // https://github.com/longitachi/ZLPhotoBrowser/issues/369#issuecomment-728679135
        if asset.zl.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset, options: option, exportPreset: AVAssetExportPresetHighestQuality) { session, info in
                // iOS11 and earlier, callback is not on the main thread.
                ZLMainAsync {
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                    if let avAsset = session?.asset {
                        let item = AVPlayerItem(asset: avAsset)
                        completion(item, info, isDegraded)
                    } else {
                        completion(nil, nil, true)
                    }
                }
            }
        } else {
            return PHImageManager.default().requestPlayerItem(forVideo: asset, options: option) { item, info in
                // iOS11 and earlier, callback is not on the main thread.
                ZLMainAsync {
                    let isDegraded = (info?[PHImageResultIsDegradedKey] as? Bool ?? false)
                    completion(item, info, isDegraded)
                }
            }
        }
    }
    
    class func getOriginalVideo(videoAsset: PHAsset, completed:((Error?, AVAsset?, URL?) -> ())?) {
        
        let option = PHVideoRequestOptions()
        option.isNetworkAccessAllowed = true
        option.deliveryMode = .highQualityFormat
        option.version = .current
        
        PHImageManager.default().requestAVAsset(forVideo: videoAsset, options:option,resultHandler:{ asset, _, info in
            DispatchQueue.main.async {
                if let avURLAsset = asset as? AVURLAsset{
                    completed?(nil,asset,avURLAsset.url)
                }else{
                    completed?(nil,asset,nil)
                }
            }
        })
    }
    
    class func isFetchImageError(_ error: Error?) -> Bool {
        guard let error = error as NSError? else {
            return false
        }
        if error.domain == "CKErrorDomain" || error.domain == "CloudPhotoLibraryErrorDomain" {
            return true
        }
        return false
    }
    
    public class func fetchAVAsset(forVideo asset: PHAsset, completion: @escaping (AVAsset?, [AnyHashable: Any]?) -> Void) -> PHImageRequestID {
        let options = PHVideoRequestOptions()
        options.deliveryMode = .automatic
        options.isNetworkAccessAllowed = true
        
        if asset.zl.isInCloud {
            return PHImageManager.default().requestExportSession(forVideo: asset, options: options, exportPreset: AVAssetExportPresetHighestQuality) { session, info in
                // iOS11 and earlier, callback is not on the main thread.
                ZLMainAsync {
                    if let avAsset = session?.asset {
                        completion(avAsset, info)
                    } else {
                        completion(nil, info)
                    }
                }
            }
        } else {
            return PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, _, info in
                ZLMainAsync {
                    completion(avAsset, info)
                }
            }
        }
    }
    
    /// Fetch the size of asset. Unit is KB.
    public class func fetchAssetSize(for asset: PHAsset) -> ZLPhotoConfiguration.KBUnit? {
        guard let resource = PHAssetResource.assetResources(for: asset).first,
              let size = resource.value(forKey: "fileSize") as? CGFloat else {
            return nil
        }
        
        return size / 1024
    }
    
    /// Fetch asset local file path.
    /// - Note: Asynchronously to fetch the file path. calls completionHandler block on the main queue.
    public class func fetchAssetFilePath(for asset: PHAsset, completion: @escaping (String?) -> Void) {
        asset.requestContentEditingInput(with: nil) { input, _ in
            var path = input?.fullSizeImageURL?.absoluteString
            if path == nil,
               let dir = asset.value(forKey: "directory") as? String,
               let name = asset.zl.filename {
                path = String(format: "file:///var/mobile/Media/%@/%@", dir, name)
            }
            completion(path)
        }
    }
    
    /// Save asset original data to file url. Support save image and video.
    /// - Note: Asynchronously write to a local file. Calls completionHandler block on the main queue. If the asset object is in iCloud, it will be downloaded first and then written in the method. The timeout time is `ZLPhotoConfiguration.default().timeout`.
    public class func saveAsset(_ asset: PHAsset, toFile fileUrl: URL, completion: @escaping ((Error?) -> Void)) {
        guard let resource = asset.zl.resource else {
            completion(NSError.assetSaveError)
            return
        }
        
        let pointer = UnsafeMutablePointer<PHImageRequestID>.allocate(capacity: MemoryLayout<Int32>.stride)
        pointer.pointee = PHInvalidImageRequestID
        var canceled = false
        
        var timer: Timer? = .scheduledTimer(
            withTimeInterval: ZLPhotoUIConfiguration.default().timeout,
            repeats: false
        ) { timer in
            timer.invalidate()
            canceled = true
            PHImageManager.default().cancelImageRequest(pointer.pointee)
            
            completion(NSError.timeoutError)
        }
        
        func cleanTimer() {
            timer?.invalidate()
            timer = nil
        }
        
        func write(_ isDegraded: Bool, _ error: Error?) {
            if error != nil {
                cleanTimer()
                completion(error)
            } else if !isDegraded {
                cleanTimer()
                let option = PHAssetResourceRequestOptions()
                option.isNetworkAccessAllowed = true
                PHAssetResourceManager.default().writeData(for: resource, toFile: fileUrl, options: option) { error in
                    ZLMainAsync {
                        completion(error)
                    }
                }
            }
        }
        
        if asset.mediaType == .video {
            pointer.pointee = fetchVideo(for: asset) { _, error, _, _ in
                write(true, error)
            } completion: { _, info, isDegraded in
                guard !canceled else { return }
                
                let error = info?[PHImageErrorKey] as? Error
                write(isDegraded, error)
            }
        } else if asset.zl.isInCloud {
            pointer.pointee = fetchOriginalImageData(for: asset) { _, error, _, _ in
                write(true, error)
            } completion: { _, info, isDegraded in
                guard !canceled else { return }
                
                let error = info?[PHImageErrorKey] as? Error
                write(isDegraded, error)
            }
        } else {
            write(false, nil)
        }
    }
    
    /// Save image to Timeprint album. add by waynelu
    public class func saveImageToTimeprintAlbum(image: UIImage, filename: String, completion: ((Bool, PHAsset?) -> Void)?) {
        let status = PHPhotoLibrary.zl.authStatus(for: .addOnly)
        if status == .denied || status == .restricted {
            LogDebug(" 保存失败：没有相册权限")
            completion?(false, nil)
            return
        }
        
        // 查找或创建Timeprint相册
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "Timeprint")
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        var timeprintAlbum: PHAssetCollection?
        if let album = collections.firstObject {
            timeprintAlbum = album
        } else {
            // 如果相册不存在，创建一个新的
            var placeholderCollection: PHObjectPlaceholder?
            try? PHPhotoLibrary.shared().performChangesAndWait {
                let createRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "Timeprint")
                placeholderCollection = createRequest.placeholderForCreatedAssetCollection
            }
            
            guard let placeholder = placeholderCollection else {
                completion?(false, nil)
                return
            }
            
            let collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
            timeprintAlbum = collection.firstObject
        }
        
        guard let album = timeprintAlbum else {
            completion?(false, nil)
            return
        }
        
        var placeholderAsset: PHObjectPlaceholder?
        PHPhotoLibrary.shared().performChanges({
            let createAssetRequest: PHAssetChangeRequest
            if image.zl.hasAlphaChannel(), let data = image.pngData() {
                let options = PHAssetResourceCreationOptions()
                options.originalFilename = filename
                let creationRequest = PHAssetCreationRequest.forAsset()
                creationRequest.addResource(with: .photo, data: data, options: options)
                createAssetRequest = creationRequest
            } else {
                createAssetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                createAssetRequest.creationDate = Date()
            }
            
            placeholderAsset = createAssetRequest.placeholderForCreatedAsset
            
            if let request = PHAssetCollectionChangeRequest(for: album) {
                request.addAssets([placeholderAsset!] as NSArray)
            }
        }) { success, error in
            if success {
                let asset = self.getAsset(from: placeholderAsset?.localIdentifier)
                ZLMainAsync {
                    completion?(true, asset)
                }
            } else {
                ZLMainAsync {
                    completion?(false, nil)
                }
            }
        }
    }
    
    /// Save video to Timeprint album.  by waynelu
    public class func saveVideoToTimeprintAlbum(url: URL, filename: String, completion: ((Bool, PHAsset?) -> Void)?) {
        let status = PHPhotoLibrary.zl.authStatus(for: .addOnly)
        if status == .denied || status == .restricted {
            LogDebug("保存失败：没有相册权限")
            completion?(false, nil)
            return
        }
        
        // 检查视频文件是否存在和可读
        guard FileManager.default.fileExists(atPath: url.path),
              let _ = try? Data(contentsOf: url, options: .alwaysMapped) else {
            LogDebug("保存失败：视频文件不存在或无法读取 - \(url.path)")
            completion?(false, nil)
            return
        }
        
        // 查找或创建Timeprint相册
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "Timeprint")
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        var timeprintAlbum: PHAssetCollection?
        if let album = collections.firstObject {
            timeprintAlbum = album
            LogDebug("找到Timeprint相册")
        } else {
            LogDebug("Timeprint相册不存在，尝试创建")
            var placeholderCollection: PHObjectPlaceholder?
            try? PHPhotoLibrary.shared().performChangesAndWait {
                let createRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: "Timeprint")
                placeholderCollection = createRequest.placeholderForCreatedAssetCollection
            }
            
            guard let placeholder = placeholderCollection else {
                LogDebug("创建相册失败：无法获取placeholder")
                completion?(false, nil)
                return
            }
            
            let collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
            timeprintAlbum = collection.firstObject
        }
        
        guard let album = timeprintAlbum else {
            LogDebug("无法获取或创建Timeprint相册")
            completion?(false, nil)
            return
        }

        // 保存视频到系统相册并移动到Timeprint相册
        var assetIdentifier: String?
        
        PHPhotoLibrary.shared().performChanges({
            // 创建视频资源
            let creationRequest = PHAssetCreationRequest.forAsset()
            let options = PHAssetResourceCreationOptions()
            options.shouldMoveFile = true
            options.originalFilename = filename
            
            creationRequest.addResource(with: .video, fileURL: url, options: options)
            assetIdentifier = creationRequest.placeholderForCreatedAsset?.localIdentifier
            
            // 直接添加到Timeprint相册
            guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
                  let placeholder = creationRequest.placeholderForCreatedAsset else {
                LogDebug("无法创建相册修改请求")
                return
            }
            
            albumChangeRequest.addAssets([placeholder] as NSFastEnumeration)
            LogDebug("添加视频到Timeprint相册")
            
        }) { success, error in
            if success {
                LogDebug("视频成功保存到Timeprint相册")
                // 获取保存的视频asset
                if let identifier = assetIdentifier {
                    let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
                    if let savedAsset = assets.firstObject {
                        ZLMainAsync {
                            completion?(true, savedAsset)
                        }
                        return
                    }
                }
                ZLMainAsync {
                    completion?(true, nil)
                }
            } else {
                if let error = error {
                    LogDebug("保存视频失败: \(error.localizedDescription)")
                } else {
                    LogDebug("保存视频失败：未知错误")
                }
                ZLMainAsync {
                    completion?(false, nil)
                }
            }
        }
    }
}

/// Authority related.
public extension ZLPhotoManager {
    class func hasPhotoLibratyReadWriteAuthority() -> Bool {
        return PHPhotoLibrary.zl.authStatus(for: .readWrite) == .authorized
    }
    
    class func hasCameraAuthority() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        if status == .restricted || status == .denied {
            return false
        }
        return true
    }
    
    class func hasMicrophoneAuthority() -> Bool {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        if status == .restricted || status == .denied {
            return false
        }
        return true
    }
}
