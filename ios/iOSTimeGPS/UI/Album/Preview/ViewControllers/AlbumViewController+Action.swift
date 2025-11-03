//
//  AlbumViewController+Action.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/25.
//

import Foundation
import UIKit
import Photos

// MARK: - Album Actions
extension AlbumViewController {
    
    /// 跳转多图预览
    @objc func toMultiSharePhotoVC() {
        
        AlbumViewController.hasShowMultiRedPoint = true
        checkShowRedPoint()
        
        //增加越界监测,并上报到服务器
        guard isValidIndex(currentIndex) else {
            let errorText = "currentIndex \(currentIndex) arrDataSources.count : \(arrDataSources.count)"
            GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText:errorText)
            return
        }
        let model = arrDataSources[currentIndex]
        
        let vc = MultiPhotoShowViewController(asset: model.asset, defaultAssetLocated: false)
        //添加对timeprint 的多图分享处理参数
        vc.isFromTimeprint = isFromTimeprint
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    // 直接调起对应shareType的分享
    func toCustomShare(shareType: XHPhotoShowShareType) {
        //增加越界监测
        guard currentIndex < 0 || (currentIndex >= 0 && currentIndex < arrDataSources.count) else {
            let errorText = "currentIndex \(currentIndex) arrDataSources.count : \(arrDataSources.count)"
            GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText:errorText)
            return
        }
        let model = arrDataSources[currentIndex]
        let hud = ZLProgressHUD.show()
        switch model.type {
        case .image, .gif, .livePhoto:
            ZLPhotoManager.fetchOriginalImg(for: model.asset) { img, isSuccess in
                hud.hide()
                if let img = img {
                    GPShareManager.shareCustomType(activityItems: [img], shareType: shareType, isPhoto: true)
                }
            }
        case .video:
            ZLPhotoManager.getOriginalVideo(videoAsset: model.asset) { error, asset, url in
                hud.hide()
                if let url = url {
                    GPShareManager.shareCustomType(activityItems: [url], shareType: shareType, isPhoto: false)
                }
            }
        case .unknown:
            hud.hide()
            break
        }
        
    }
    
    @objc func watermarkBtnClick() {
        // Implementation pending
    }
    
    @objc func infoBtnClick() {
        let config = ZLPhotoConfiguration.default()
        let model = arrDataSources[currentIndex]
       // print("Info button clicked for index: \(currentIndex)")
        //增加越界监测,并上报到服务器
        guard model.type == .image || (!config.allowSelectGif && model.type == .gif) || (!config.allowSelectLivePhoto && model.type == .livePhoto) else {
            return
        }
        
        let options = PHImageRequestOptions()
        options.version = .original
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.resizeMode = .none
        
        PHImageManager.default().requestImageDataAndOrientation(
            for: model.asset,
            options: options
        ) { [weak self] (imageData, dataUTI, orientation, info) in
            guard let self = self,
                  let imageData = imageData,
                  let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil) else {
                return
            }
            
            var metadataInfo: [String: String] = [:]
            
            // Extract GPS metadata
            if let gpsDic = imageSource.gpsDic() {
                if let latitude = gpsDic[kCGImagePropertyGPSLatitude as String] as? Double,
                   let latitudeRef = gpsDic[kCGImagePropertyGPSLatitudeRef as String] as? String,
                   let longitude = gpsDic[kCGImagePropertyGPSLongitude as String] as? Double,
                   let longitudeRef = gpsDic[kCGImagePropertyGPSLongitudeRef as String] as? String {
                    
                    let finalLatitude = latitudeRef == "S" ? -latitude : latitude
                    let finalLongitude = longitudeRef == "W" ? -longitude : longitude
                    metadataInfo["Location"] = String(format: "%.6f, %.6f", finalLatitude, finalLongitude)
                }
                
                
                if let altitude = gpsDic[kCGImagePropertyGPSAltitude as String] as? Double {
                    metadataInfo["Altitude"] = String(format: "%.1f meters", altitude)
                }
            }
            
            // Extract EXIF metadata
            if let exifDic = imageSource.exifDic() {
                if let dateTimeOriginal = exifDic[kCGImagePropertyExifDateTimeOriginal as String] as? String {
                    metadataInfo["Date Taken"] = dateTimeOriginal
                }
                
                if let userComment = exifDic[kCGImagePropertyExifUserComment as String] as? String {
                    let deComment = GPSecurityManager.shared.decryptAES(str: userComment);
                    let commentJson = deComment.removingPercentEncoding ?? ""
                    metadataInfo["Comment"] = commentJson
                }
            }
            // Extract TIFF metadata
            if let tiffDic = imageSource.tiffDic() {
                if let artist = tiffDic[kCGImagePropertyTIFFArtist as String] as? String {
                    metadataInfo["Artist"] = artist
                }
                
                if let modifyDate = tiffDic[kCGImagePropertyTIFFDateTime as String] as? String {
                    metadataInfo["Modified Date"] = modifyDate
                }
            }
            
            // Present metadata alert
            self.presentMetadataAlert(with: metadataInfo)
        }
    }
    
    private func presentMetadataAlert(with metadata: [String: String]) {
        let alert = UIAlertController(title: "Image Info", message: "", preferredStyle: .alert)
        
        let message = metadata.map { key, value in
            return "\(key): \(value)"
        }.joined(separator: "\n")
        
        alert.message = message.isEmpty ? "No metadata available" : message
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
    
    @objc func editBtnClick() {
        let config = ZLPhotoConfiguration.default()
        let uiConfig = ZLPhotoUIConfiguration.default()
        //增加越界监测,并上报到服务器
        guard currentIndex<0 || (currentIndex >= 0 && currentIndex < arrDataSources.count) else {
            let errorText = "currentIndex \(currentIndex) arrDataSources.count : \(arrDataSources.count)"
            GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText:errorText)
            return
        }
        
        let model = arrDataSources[currentIndex]
        
        var requestAssetID: PHImageRequestID?
        let hud = ZLProgressHUD(style: uiConfig.hudStyle)
        hud.timeoutBlock = { [weak self] in
            showAlertView(localLanguageTextValue(.timeout), self)
            if let requestAssetID = requestAssetID {
                PHImageManager.default().cancelImageRequest(requestAssetID)
            }
        }
        
        if model.type == .image || (!config.allowSelectGif && model.type == .gif) || (!config.allowSelectLivePhoto && model.type == .livePhoto) {
            hud.show(timeout: ZLPhotoUIConfiguration.default().timeout)
            requestAssetID = ZLPhotoManager.fetchImage(for: model.asset, size: model.previewSize) { [weak self] image, isDegraded in
                if !isDegraded {
                    if let image = image {
                        self?.showEditImageVC(image: image)
                    } else {
                        showAlertView(localLanguageTextValue(.imageLoadFailed), self)
                    }
                    hud.hide()
                }
            }
        } else if model.type == .video || config.allowEditVideo {
            hud.show(timeout: uiConfig.timeout)
            // fetch avasset
            requestAssetID = ZLPhotoManager.fetchAVAsset(forVideo: model.asset) { [weak self] avAsset, _ in
                hud.hide()
                if let avAsset = avAsset {
                    self?.showEditVideoVC(model: model, avAsset: avAsset)
                } else {
                    showAlertView(localLanguageTextValue(.timeout), self)
                }
            }
        }
    }
    
    @objc func deleteBtnClick() {
        
        func removeCurrentModel() {
            // 如果本来就没有数据，直接刷新并返回
            guard !arrDataSources.isEmpty else {
                currentIndex = 0
                self.reloadCollectionView()
                return
            }

            // 计算安全删除下标
            let removeIndex = max(0, min(currentIndex, arrDataSources.count - 1))
            arrDataSources.remove(at: removeIndex)

            // 重新设定 currentIndex（如果删的是最后一个，向前移一位；如果删完空了，归零）
            if arrDataSources.isEmpty {
                currentIndex = 0
            } else {
                currentIndex = min(removeIndex, arrDataSources.count - 1)
            }

            self.reloadCollectionView()
        }
        
        guard isValidIndex(currentIndex) else {
            let errorText = "currentIndex \(currentIndex) arrDataSources.count : \(arrDataSources.count)"
            GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText:errorText)
            return
        }
        
        let model = arrDataSources[currentIndex]
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets([model.asset] as NSArray)
        }, completionHandler: { (bool, error) in
            LogDebug("删除相册回调：\(bool), error:\(String(describing: error))")
            if bool{
                ZLMainAsync {
                    removeCurrentModel()
                }
            }
            if bool { //add by waynelu 删除的时候也发通知
                // 发送通知
                NotificationCenter.default.post(name: AlbumViewController.timeprintAlbumDidUpdateNotification, object: nil)
            }
        })
    }
    
    @objc func zipBtnClick() {
        
    }
    
    func tapPreviewCell() {
        
        hideNavView = !hideNavView
        let cell = collectionView.cellForItem(at: IndexPath(row: currentIndex, section: 0))
        if let cell = cell as? ZLVideoPreviewCell, cell.isPlaying {
            hideNavView = true
        }
        infoButton.isHidden = hideNavView
        topView.isHidden = hideNavView
        bottomCollectionView.isHidden = hideNavView
    }
    
    private func isValidIndex(_ i: Int) -> Bool {
        return i >= 0 && i < arrDataSources.count
    }
    
    private func showEditImageVC(image: UIImage) {
        //增加越界监测,并上报到服务器
        guard isValidIndex(currentIndex) else {
            let errorText = "currentIndex \(currentIndex) arrDataSources.count : \(arrDataSources.count)"
            GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText:errorText)
            return
        }
        
        let model = arrDataSources[currentIndex]
        let nav = navigationController as? ZLImageNavController
        ZLEditImageViewController.showEditImageVC(parentVC: self, image: image, editModel: model.editImageModel) { [weak self, weak nav] editImage, editImageModel in
            guard let `self` = self else { return }
            model.editImage = editImage
            model.editImageModel = editImageModel
            if nav?.arrSelectedModels.contains(where: { $0 == model }) == false {
                model.isSelected = true
                nav?.arrSelectedModels.append(model)
            }
                       
            self.collectionView.reloadItems(at: [IndexPath(row: self.currentIndex, section: 0)])
    
            let originalFilename = model.asset.originalFilename ?? "image"
            let filename = originalFilename.components(separatedBy: ".").first ?? originalFilename
            let ext = originalFilename.components(separatedBy: ".").last ?? "jpg"
            // 构建新文件名 "原文件(1).ext"
            let newFilename = "\(filename)(1).\(ext)"
            
            // 保存到Timeprint相册
            self.saveEditImage(image: editImage,filename: newFilename) { [weak self] success, asset  in
                if success {
                    LogDebug("保存编辑图片到Timeprint相册成功")
                    // 如果保存成功，将新的asset添加到数据源
                    if let asset = asset {
                        let newModel = ZLPhotoModel(asset: asset)
                        self?.arrDataSources.insert(newModel, at: self?.currentIndex ?? 0)
                        self?.collectionView.reloadData()
                    }
                } else {
                    LogDebug("保存编辑图片到Timeprint相册失败，尝试保存到默认相册")
                    // 如果保存到Timeprint相册失败，则保存到默认相册
                    ZLPhotoManager.saveImageToAlbum(image: editImage) { [weak self] success, asset in
                        if success {
                            LogDebug("保存编辑图片到默认相册成功")
                            // 如果保存成功，将新的asset添加到数据源
                            if let asset = asset {
                                let newModel = ZLPhotoModel(asset: asset)
                                self?.arrDataSources.insert(newModel, at: self?.currentIndex ?? 0)
                                self?.collectionView.reloadData()
                            }
                        } else {
                            LogDebug("保存编辑图片到默认相册也失败")
                        }
                    }
                }
            }
        }
    }
    
    private func showEditVideoVC(model: ZLPhotoModel, avAsset: AVAsset) {
        let nav = navigationController as? ZLImageNavController
        let vc = ZLEditVideoViewController(avAsset: avAsset)
        vc.modalPresentationStyle = .fullScreen
        
        vc.editFinishBlock = { [weak self, weak nav] url in
            if let url = url {
                // 获取原文件名
                let originalFilename = model.asset.originalFilename ?? "video"
                let filename = originalFilename.components(separatedBy: ".").first ?? originalFilename
                let ext = originalFilename.components(separatedBy: ".").last ?? "mp4"
                // 构建新文件名 "原文件(1).ext"
                let newFilename = "\(filename)(1).\(ext)"
                
                // 首先尝试保存到Timeprint相册
                self?.saveEditVideo(url: url,filename: newFilename) { [weak self, weak nav] success, asset in
                    if success {
                        LogDebug("保存编辑视频到Timeprint相册成功")
                        let m = ZLPhotoModel(asset: model.asset)
                        nav?.arrSelectedModels.removeAll()
                        nav?.arrSelectedModels.append(m)
                        nav?.selectImageBlock?()
                    } else {
                        LogDebug("保存编辑视频到Timeprint相册失败，尝试保存到默认相册")
                        // 如果保存到Timeprint相册失败，则保存到默认相册
                        ZLPhotoManager.saveVideoToAlbum(url: url) { [weak self, weak nav] success, asset in
                            if success, let asset = asset {
                                LogDebug("保存编辑视频到默认相册成功")
                                let m = ZLPhotoModel(asset: asset)
                                nav?.arrSelectedModels.removeAll()
                                nav?.arrSelectedModels.append(m)
                                nav?.selectImageBlock?()
                            } else {
                                LogDebug("保存编辑视频到默认相册也失败")
                                showAlertView(localLanguageTextValue(.saveVideoError), self)
                            }
                        }
                    }
                }
            } else {
                nav?.arrSelectedModels.removeAll()
                nav?.arrSelectedModels.append(model)
                nav?.selectImageBlock?()
            }
        }
        
        present(vc, animated: false, completion: nil)
    }
    
    // 添加通知名称
    static let timeprintAlbumDidUpdateNotification = Notification.Name("TimeprintAlbumDidUpdate")
    
    // 保存编辑图片
    func saveEditImage(image: UIImage,filename:String,  completion: ((Bool, PHAsset?) -> Void)?) {

        ZLPhotoManager.saveImageToTimeprintAlbum(image: image, filename: filename) { [weak self] (success, asset) in
            if success {
                // 发送通知
                NotificationCenter.default.post(name: AlbumViewController.timeprintAlbumDidUpdateNotification, object: nil)
            }
            completion?(success,asset)
        }
    }
    
    // 保存编辑视频
    func saveEditVideo(url: URL,filename:String, completion: ((Bool, PHAsset?) -> Void)?) {

        ZLPhotoManager.saveVideoToTimeprintAlbum(url: url, filename: filename) { [weak self] (success, asset) in
            if success {
                // 发送通知
                NotificationCenter.default.post(name: AlbumViewController.timeprintAlbumDidUpdateNotification, object: nil)
            }
            completion?(success,asset)
        }
    }
}
