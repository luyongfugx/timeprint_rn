//
//  CameraVC+Album.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/23.
//  相机相关按钮动作

import Foundation
import UIKit
import GPCam
import Photos
import AVFoundation
// topAction
extension CameraVC {
    
    @objc func centerTopBtnAction(sender: UIButton) {
        if currentWatermarkView?.hasLogo() == true {
            // 分享App
            let shareText = "k_share_app".localized()
            GPShareManager.shareSystem(activityItems: [shareText])
        } else {
            gotoEditLogo()
        }
    }
    
    func gotoEditLogo() {
        // 点击添加logo
        currentWatermarkView?.gotoAddLogo()
    }
    
    func gotoEditMap() {
        // 点击添加logo
        currentWatermarkView?.gotoEditMap()
    }
}

// bottomAction
extension CameraVC {
    
    @objc func folderBtnAction() {
        //let folderVC = FolderViewController()
        let folderVC = FolderHomeViewController()
        navigationController?.pushViewController(folderVC, animated: true)
        LogDebug("folderBtnAction click")
    }
    
    @objc func flashBtnAction(sender: UIButton) {
        
        var titleArray = ["i_flash_close".localized(), "i_flash_auto".localized(), "i_flash_open".localized(), "i_flashlight".localized(), "i_nighmode".localized()]
        var iconArray = [IconFontType.btn_flash_close.rawValue, IconFontType.btn_flash_auto.rawValue, IconFontType.btn_flash_open.rawValue, IconFontType.btn_flashlight.rawValue, IconFontType.btn_nighmode.rawValue]
        //如果是视频，只有两个菜单
        if cameraMode == .video {
            titleArray = ["i_flash_close".localized(), "i_flashlight".localized()];
            iconArray = [IconFontType.btn_flash_close.rawValue,  IconFontType.btn_flashlight.rawValue]
            //如果切换到视频后，不是i_flash_close 或者 i_flashlight，则使用 i_flash_close
            if flashlightMode  != .off, flashlightMode != .always {
                
                self.flashlightMode =  .off
            }
        }
        
        let menu = DropDownMenuView.pullDropDrownMenu(anchorView: sender, titleArray: titleArray, iconFontArray: iconArray, startTrianglePadding: 8, selectIndex: flashlightMode.rawValue)
        menu.selectionAction = { [weak self] index , str in
            if self?.cameraMode == .video {
                var id = index
                if(id != 0) {
                    id = 3
                }
                self?.flashlightMode = GPFlashMode.init(rawValue: id) ?? .off
                let str = "\(id)" + " " + str + " \(String(describing: self?.flashlightMode))"
                LogDebug(str)
            }
            else {
                self?.flashlightMode = GPFlashMode.init(rawValue: index) ?? .off
                let str = "\(index)" + " " + str + " \(String(describing: self?.flashlightMode))"
                LogDebug(str)
            }
            
        }
    }
    
    @objc func timeBtnAction(sender: UIButton) {
        let titleArray = ["i_0_second".localized(), "i_5_second".localized(), "i_10_second".localized()]
        let menu = DropDownMenuView.pullDropDrownMenu(anchorView: sender, titleArray: titleArray, startTrianglePadding: 8, selectIndex: delayTakephotoType.rawValue)
        menu.selectionAction = { (index: Index, str: String) -> (Void) in
            self.delayTakephotoType = DelayTakePhotoType(rawValue: index) ?? .none
            let str = "\(index)" + " " + str
            LogDebug(str)
        }
    }
    
    @objc func ratioBtnAction(sender: UIButton) {
        let titleArray = ["i_ratio_3x4".localized(), "i_ratio_9x16".localized(), "i_ratio_1x1".localized(), "i_ratio_full".localized()]
        let iconArray = [IconFontType.btn_ratio_3X4.rawValue, IconFontType.btn_ratio_9X16.rawValue, IconFontType.btn_ratio_1X1.rawValue, IconFontType.btn_ratio_full.rawValue]
        let menu = DropDownMenuView.pullDropDrownMenu(anchorView: sender, titleArray: titleArray, iconFontArray: iconArray, startTrianglePadding: 8, selectIndex: photoRatio.rawValue)
        menu.selectionAction = { [weak self] index , str in
            self?.photoRatio = PhotoRatioType.init(rawValue: index) ?? .ratio3x4
            let str = "\(index)" + " " + str + " \(String(describing: self?.photoRatio))"
            LogDebug(str)
        }
    }
    
    @objc func watermarkAction() {
        handleWatermarkAction(.list)
    }
    
    @objc func quickEditAction() {
        handleWatermarkAction(.quickEdit)
    }
    
    @objc func refreshAction(sender: UIButton) {
        switchCam()
    }
    
    func switchCam() {
        isCameraBack = !isCameraBack
        LogDebug("switchCam isCameraBack: \(isCameraBack)")
    }
    
    @objc func albumAction(sender: UIButton) {
        LogDebug("albumAction click")
        let nav = UINavigationController(rootViewController: AlbumViewController())
        nav.modalPresentationStyle = .fullScreen
        self.navigationController?.present(nav, animated: true)
    }
    
    @objc func settingBtnAction(sender: UIButton) {
        clickSettingBtn(sender)
    }
    
    func clickSettingItem(index: Int) {
        if index == 0 {
            
        }
    }
    
    @objc func takePhotoAction(sender: UIButton) {
        currentWatermarkView?.removeDotLineAnimation()
        
        // 如果有倒计时设置，启动倒计时
        if delayTakephotoType != .none && cameraMode == .photo && !isCountdownActive {
            startCountdownPhoto()
        } else {
            // 没有倒计时或正在倒计时中，直接拍照
            let feedBack = UISelectionFeedbackGenerator()
            feedBack.selectionChanged()
            takePhotoAnimation()
            gotoTakePhoto()
        }
    }
    
    func gotoTakePhoto() {
        if cameraMode == .photo {
            LogDebug("takePhotoAction cameraMode: .photo")
            takePhoto()
            self.bottomView.updateState(state: .photoNormal)
        } else {
            if isRecording {
                LogDebug("takePhotoAction stop recording ")
                // 停止录制视频
                isRecording = false
                self.bottomView.updateState(state: .videoNormal)
                endRecord()
            } else {
                LogDebug("takePhotoAction start recordding ")
                // 开始录制视频
                isRecording = true
                self.bottomView.updateState(state: .videoRecording)
                startRecord()
            }
        }
    }
    
    func takePhotoAnimation() {
        //白屏动画
        UIView.animate(withDuration: 0.1, animations: {
            self.takePhotoViewBG.alpha = 1
        }) { (result) in
            UIView.animate(withDuration: 0.1, animations: {
                self.takePhotoViewBG.alpha = 0
            }, completion: nil)
        }
    }
    
    func startRecord() {
        isRecording = true
        let watermarkInfo = prepareWatermarkInfo()
        let fileName = generateFileName(ext: "mp4")
        let filePath = GPDataCacheManager.shared.getFilePath(fileName, cacheType: .Video)
        self.tmpVideoFileName = fileName
        let videoURL = URL(fileURLWithPath: filePath)
        let orientation = currentWatermarkView?.orientation ?? .portraitDirection
        let cameraOrientation = BMWDeviceOrientation(rawValue: orientation.rawValue)!
        
        camera?.startRecord(
            withWatermarkViewInfo: watermarkInfo,
            profileBuilder: { [weak self] profile in
                guard let self = self else { return }
                profile.deviceOrientation = cameraOrientation
                profile.videoUrl = videoURL
                profile.bitrate = Int32(3*1024*1024)
                profile.videoSize = CGSize(width: 720, height: 1280)
                profile.shouldOptimizeForNetworkUse = false
                profile.frameRate = CGFloat(GPCamConfigurator.sharedInstance().videoRecordFPS)
            },
            recordDurationCallBack: { [weak self] pg in
                guard let self = self else { return }
                self.bottomView.watchView.updateTime(progress: Double(pg))
                
            }
        )
        
        // 视频长度大于60分钟停止录制
        bottomView.watchView.moreThanAnHourHandler = { [weak self] in
            if let weakSelf = self {
                weakSelf.endRecord()
            }
        }
        
        GPFirebaseManager.take_video()
    }
    
    func endRecord() {
        isRecording = false
        camera?.stopRecord({ [weak self] img, error in
            
            //增加拍视频错误上报
            if let error = error {
                let errorMsg = "\(error)"
                GPFirebaseManager.take_video_fail(errorMsg: errorMsg)
                //把错误原因 作为文件文件上报到
                let errorText = "take_video_fail, \(String(describing: errorMsg)), systemInfo: \(GPApp.getDeviceInfoStr()) )"
                GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function, errorText: errorText)
            }
            
            GPSafeMainAsync {
                self?.bottomView.albumButton.updateImage(img: img)
            }
            // 保存视频到相册
            if let fileName = self?.tmpVideoFileName {
                let fileUrl = GPDataCacheManager.shared.getFilePath(fileName, cacheType: .Video)
                self?.saveVideo(fileUrl)
            }
            
        }, completionBlock: { error,arg  in
            //增加拍视频错误上报
            if let error = error {
                let errorMsg = "\(error)"
                GPFirebaseManager.take_video_fail(errorMsg: errorMsg)
                //把错误原因 作为文件文件上报到
 
                let errorText = "take_video_fail, \(String(describing: errorMsg)), systemInfo:  \(GPApp.getDeviceInfoStr())"
                GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText: errorText)
            }
            //
        })
    }
        
    func takePhoto() {
        
        guard !tryRestartCamera() else {
            LogDebug("相机未启动不能拍照")
            return
        }

        let watermarkInfo = prepareWatermarkInfo()
        CameraConfig.takephotoTime2 += 1
        GoodReviewsManager.shared.fiveStartCheck()
        let orientation = currentWatermarkView?.orientation ?? .portraitDirection

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            camera?.capturePhoto(builder: { [weak self] builder in
                guard let self else { return }
                builder.quality = 0.7
                builder.mode = self.cameraKitMode
                builder.orientaion = BMWDeviceOrientation(rawValue: orientation.rawValue)!
                builder.enableSliceImage = false
                // 【2.9.345】支持id20无遮挡模式去水印
//                self.enableSliceImage = builder.enableSliceImage
                builder.needOriginalImage = CameraConfig.openOriginPhoto
                builder.enableTakePhotoImmediately = 0
                if let watermarkInfo {
                    builder.watermarkModel = watermarkInfo

                }
                
                builder.codeDataModel = nil
            }, statusCallBack: { [weak self] status in
//                if status == XHCameraTakeImageStatus.beginCaptureWatermark {
//                    if watermarkInfo?.renderingSync == true {
//                        Report.get_watermark_QRcode_generate_shortlinks(type: "takePhoto", isShortQRcodeLink: XHWatermarkQRManager.shared.shortQRUrlSuc)
//                    }
//                    return
//                }
//                DispatchQueue.main.async { [weak self] in
//                    guard let self else { return }
//
//                    // 2.9.225 [二维码水印lzw]
//                    if let currentWatermarkView,
//                       let tempM = currentWatermarkView.twModel,
//                       tempM.getItemModel(by: XHWatermarkCommonItemID.qrcode.rawValue)?.switchStatus == true
//                    {
//                        XHDecibelManager.shared.isTakingPhoto = false
//                        isTaking = false
//                        watermarkContentView.isUserInteractionEnabled = true
//                    } else {
//                        XHDecibelManager.shared.isTakingPhoto = false
//                        isTaking = false
//                        watermarkContentView.isUserInteractionEnabled = true
//                    }
//                    // [lxg ADD] 2.9.275 拍照原子操作中，不修改水印方向，操作完成刷新最新方向到水印
//                    // refresh watermark orientation
//                    let lastestOrientation = XHOrientationManager.shared.getOrientation()
//                    XHOrientationMamagerOrientationChange(currentOrientation: lastestOrientation, oldOrientation: lastestOrientation)
//                }
                
            }, previewImgCallBack: { [weak self] preImg, error in
                guard let self else { return }
                //增加拍照错误上报
                if let error = error {
                    let errorMsg = "\(error)"
                    LogDebug("previewImgCallBack照片失败：\(error)")

                    GPFirebaseManager.take_photo_fail(errorMsg: errorMsg)
                    //把错误原因 作为文件文件上报到
                    let errorText = "take_photo_fail, \(String(describing: error.localizedDescription)), systemInfo:  \(GPApp.getDeviceInfoStr())"
                    GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText: errorText)
                    //弹出错误提醒用户去设置权限
                    DispatchQueue.main.async {
                            let ac = UIAlertController(title: "i_save_photo_failed".localized(), message: error.localizedDescription, preferredStyle: .alert)
                            ac.addAction(UIAlertAction(title: "i_ok".localized(), style: .default))
                            self.present(ac, animated: true)
                    
                    }
                    
                }
                DispatchQueue.main.async { [weak self] in
                    guard let self else { return }
                    self.bottomView.albumButton.updateImage(img: preImg)
                }
            }, originalImgCallBack: { [weak self] _, orgImgData, error in
                guard let self else { return }
                //增加拍照错误上报
                if let error = error {
                    let errorMsg = "\(error)"
                    GPFirebaseManager.take_photo_fail(errorMsg: errorMsg)
                    //把错误原因 作为文件文件上报到
                    LogDebug("originalImgCallBack照片失败：\(error)")

                    let errorText = "take_photo_fail, \(String(describing: error.localizedDescription)), systemInfo:  \(GPApp.getDeviceInfoStr())"
                    GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText: errorText)
                    
                    //弹出错误提醒用户去设置权限
                    DispatchQueue.main.async {
                            let ac = UIAlertController(title: "i_save_photo_failed".localized(), message: error.localizedDescription, preferredStyle: .alert)
                            ac.addAction(UIAlertAction(title: "i_ok".localized(), style: .default))
                            self.present(ac, animated: true)
                    
                    }
                    
                }
                if CameraConfig.openOriginPhoto, let orgImgData, let originImage = UIImage(data: orgImgData) {
                    saveImage(img: originImage)
                }
//                var errorMsg = ""
//                if let error = error {
//                    errorMsg = "\(error)"
//                }
//                xLog(.error, module: .takePhoto(process: .saveToAlbum), message: "2、生成无水印图片的回调 - error:[\(errorMsg)]")
//                self.processedOriginalImaggData(orgImgData: orgImgData,
//                                                noWatermarkUserCommentModel: noWatermarkUserCommentModel)
            }, processedImgCallBack: { [weak self] metaData, processedImg, error in
                guard let self else { return }
                //增加拍照错误上报
                if let error = error {
                    let errorMsg = "\(error)"
                    LogDebug("processedImgCallBack照片失败：\(error)")

                    GPFirebaseManager.take_photo_fail(errorMsg: errorMsg)
                                //把错误原因 作为文件文件上报到
                    let errorText = "take_photo_fail, \(String(describing: error.localizedDescription)), systemInfo:  \(GPApp.getDeviceInfoStr())"
                    GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText: errorText)
        
                    //弹出错误提醒用户去设置权限
                    DispatchQueue.main.async {
                            let ac = UIAlertController(title: "i_save_photo_failed".localized(), message: error.localizedDescription, preferredStyle: .alert)
                            ac.addAction(UIAlertAction(title: "i_ok".localized(), style: .default))
                            self.present(ac, animated: true)
                    
                    }
                    
                }
                guard let processedImg, let processedImage = UIImage(data: processedImg) else { return }
                
                saveImage(img: processedImage)
                SEANotificationStrategy.shared.recordPhotoShot()
            })
        }
        
        // 埋点
    
        GPFirebaseManager.take_photo()
        
        
    }
    
    // MARK: - Album Helper
    private func getOrCreateAlbum(albumName: String = "Timeprint") -> PHAssetCollection? {
        var albumAssetCollection: PHAssetCollection?
        
        // 查找相册
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
        let collections = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
        
        if let collection = collections.firstObject {
            albumAssetCollection = collection
        } else {
            // 创建新相册
            var albumPlaceholder: String?
            do {
                try PHPhotoLibrary.shared().performChangesAndWait {
                    let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                    albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection.localIdentifier
                }
                
                if let identifier = albumPlaceholder {
                    let collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [identifier], options: nil)
                    albumAssetCollection = collection.firstObject
                }
            } catch {
                //上报新建新建相册错误
                GPFirebaseManager.create_album_fail(errorMsg: "\(error)")
         
                //把错误原因 作为文件文件上报到
                let errorText = "create_album_fail, \(String(describing: error.localizedDescription)), systemInfo:  \(GPApp.getDeviceInfoStr())"
                GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText: errorText)
    
                
             
            }
        }
        
        return albumAssetCollection
    }
    
    private func generateFileName(ext: String) -> String {
        var name = ""
        //获取文件名
        if let watermarkView = currentWatermarkView {
            name = PhotoNameManager.generateFileName(items: watermarkView.watermarkModel?.items ?? [])
        }
        return "\(name).\(ext)"
    }
    
    private func generateImageFileName() -> String {
        return generateFileName(ext: "jpg")
    }
    
    private func generateVideoFileName() -> String {
        return generateFileName(ext: "mp4")
    }
    
    func saveImage(img: UIImage) {
        // 异步执行保存操作
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            // 检查相册权限
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else { return }
            
                let imgData = img // 原始图片
                let currentDate: Date = TimeManager.shared.getRealTime()
                let currentLocation = GPSGeoManager.wartermarkGPSInfo.location
                //usercomment
                var userComment = "";
                if let watermarkView = self.currentWatermarkView {
                    userComment = PhotoNameManager.generateJsonString(items: watermarkView.watermarkModel?.items ?? [])
                }
                GpImageManager.generateNewImage(originalImage: imgData,
                                                userCommentStr: userComment,
                                                createDate: currentDate,
                                                modifyDate: currentDate,
                                                location: currentLocation
                                                ) { [weak self] (imageData) in
                    guard let self else { return }
                    //
                    // 获取或创建相册
                    let albumAssetCollection = self.getOrCreateAlbum()
                    
                    // Generate filename with date and random number
                    let fileName = self.generateImageFileName()
                    
                    // 保存图片到相册
                    PHPhotoLibrary.shared().performChanges({
                        // 创建图片资源
                        let request = PHAssetCreationRequest.forAsset()
                        let options = PHAssetResourceCreationOptions()
                        options.originalFilename = fileName
                        request.addResource(with: .photo, data: imageData!, options: options)
                        
                        if let assetPlaceholder = request.placeholderForCreatedAsset {
                            // 如果有自定义相册，则添加到自定义相册
                            if let albumAssetCollection = albumAssetCollection,
                               let albumChangeRequest = PHAssetCollectionChangeRequest(for: albumAssetCollection) {
                                albumChangeRequest.addAssets([assetPlaceholder] as NSFastEnumeration)
                            } else {
                                // 如果没有自定义相册，获取相机胶卷相册
                                if let cameraRoll = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject,
                                   let cameraRollChangeRequest = PHAssetCollectionChangeRequest(for: cameraRoll) {
                                    cameraRollChangeRequest.addAssets([assetPlaceholder] as NSFastEnumeration)
                                }
                            }
                        }
                    }, completionHandler: { [weak self] success, error in
                        // 测试
      
//                        let errorText = "\(GPErrorUploadManager.getReportStatusDesc()) \(GPErrorUploadManager.getStorageInfo())"
//                        GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText: errorText)
//            
                        //GPFirebaseManager.add_logo();
                        DispatchQueue.main.async {
                            if let error = error {
                                //上报保存照片错误
                                GPFirebaseManager.save_photo_fail(errorMsg: "\(error)")
                                LogDebug("保存照片失败：\(error)")
                                //把错误原因 作为文件文件上报到
                                let errorText = "save_photo_fail , \(String(describing: error.localizedDescription)), systemInfo:  \(GPApp.getDeviceInfoStr())"
                                GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText: errorText)
                    
                                let ac = UIAlertController(title: "i_save_photo_failed".localized(), message: error.localizedDescription, preferredStyle: .alert)
                                ac.addAction(UIAlertAction(title: "i_ok".localized(), style: .default))
                                self?.present(ac, animated: true)
                            }
                        }
                    })
                    
                }
                
         
            }
        }
        
        // 上传照片
        OSSUploadManager.shared.uploadTakePhotoImg(image: img) { error in
            //
        }
    }
    
    func saveVideo(_ urlStr: String) {
        LogDebug("文件存在:\(FileManager.default.fileExists(atPath: urlStr))")
        
        // 异步执行保存操作
        DispatchQueue.global().async { [weak self] in
            guard let self = self else { return }
            
            guard let videoURL = URL(string: urlStr) else { return }
            
            // 检查相册权限
            PHPhotoLibrary.requestAuthorization { status in
                guard status == .authorized else { return }
                
                // 获取或创建相册
                let albumAssetCollection = self.getOrCreateAlbum()
                
                // Generate filename with date and random number
                let fileName = self.generateVideoFileName()
                
                // 保存视频到相册
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    options.originalFilename = fileName
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .video, fileURL: videoURL, options: options)
                    
                    if let assetPlaceholder = request.placeholderForCreatedAsset {
                        // 如果有自定义相册，则添加到自定义相册
                        if let albumAssetCollection = albumAssetCollection,
                           let albumChangeRequest = PHAssetCollectionChangeRequest(for: albumAssetCollection) {
                            albumChangeRequest.addAssets([assetPlaceholder] as NSFastEnumeration)
                        } else {
                            // 如果没有自定义相册，获取相机胶卷相册
                            if let cameraRoll = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: nil).firstObject,
                               let cameraRollChangeRequest = PHAssetCollectionChangeRequest(for: cameraRoll) {
                                cameraRollChangeRequest.addAssets([assetPlaceholder] as NSFastEnumeration)
                            }
                        }
                    }
                }, completionHandler: { success, error in
                    if success {
                        LogDebug("视频保存成功")
                    } else if let error = error {
                        DispatchQueue.main.async { // add by waynelu ，fixed crash bug
                            //上报保存相册错误
                            GPFirebaseManager.save_video_fail(errorMsg: "\(error)")
                            //把错误原因 作为文件文件上报到
                            let errorText = "save_video_fail, \(String(describing: error.localizedDescription)), systemInfo:  \(GPApp.getDeviceInfoStr())"
                            GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText: errorText)
                      
                            let ac = UIAlertController(title: "i_save_photo_failed".localized(), message: error.localizedDescription, preferredStyle: .alert)
                            ac.addAction(UIAlertAction(title: "i_ok".localized(), style: .default))
                            self.present(ac, animated: true)
                            LogDebug("视频保存失败: \(error)")
                        }
                    }
                    
                    // 清理临时视频文件
                    if let tmpVideoFileName = self.tmpVideoFileName {
                        let fileUrl = GPDataCacheManager.shared.getFilePath(tmpVideoFileName, cacheType: .Video)
                        do {
                            try FileManager.default.removeItem(atPath: fileUrl)
                            LogDebug("[cache debug] - 删除文件成功")
                        } catch let error as NSError {
                            LogDebug("[cache debug] - 删除文件失败，error - [\(error)]")
                        }
                        self.tmpVideoFileName = nil
                    }
                })
            }
        }
    }
    
    // MARK: - 拍照或录制视频前，准备水印的信息
    func prepareWatermarkInfo() -> BMWWatermarkItem? {
        guard let watermView = currentWatermarkView else { return nil }

        let watermarkViewInfo = BMWWatermarkItem()
        watermarkViewInfo.h = 1
        watermarkViewInfo.w = 1
        watermarkViewInfo.x = 0
        watermarkViewInfo.y = 0
        watermarkViewInfo.water = watermView // 赋值水印信息
        watermarkViewInfo.refreshTime = 1.0

        if cameraMode == .photo, canShowOfficial() {
            watermarkViewInfo.refreshWatermark = { _, _, block in
                // 先显示官方水印（需要参与占位判断）
                watermView.offcialLogoView.isHidden = false

                // 判断右上角100x100区域是否被占用（排除官方水印自身）
                let shouldPlaceBottomRight = self.gp_hasOccupiedTopRight100(in: watermView)

                // 依据占用结果调整官方水印位置；立即刷新布局，确保拍照帧生效
                if shouldPlaceBottomRight {
                    watermView.offcialLogoView.placeBottomRight()
                } else {
                    watermView.offcialLogoView.placeTopRight()
                }
                watermView.setNeedsLayout()
                watermView.layoutIfNeeded()

                // 调用底层拍照
                block?()

                // 隐藏官方水印（按你原先逻辑）
                watermView.offcialLogoView.isHidden = true
            }
        }

        return watermarkViewInfo
    }
    
    func canShowOfficial() -> Bool {
        guard let watermarkModel = currentWatermarkView?.watermarkModel else { return false }
        return CameraConfig.canShowOfficialWatermark && watermarkModel.isSpecialMapWatermark() == false
    }
    
}

extension CameraVC {
    func updateLatestPhoto() {
        fetchLatestPhoto { [weak self] img in
            self?.updateAlbumPhoto(img)
        }
    }
    
    func updateAlbumPhoto(_ img: UIImage?) {
        guard let img = img else { return }
        ZLMainAsync {
            self.bottomView.albumButton.updateImage(img: img)
        }
    }
    
    func fetchLatestPhoto(completion: @escaping (UIImage?) -> Void) {
        guard PHPhotoLibrary.authorizationStatus() == .authorized else { return }
        // 请求用户授权
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
               // print("没有访问相册的权限")
                completion(nil)
                return
            }
            
            // 创建一个fetch请求来获取最近的照片
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 1
            
            let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            // 确保有照片
            guard let asset = fetchResult.firstObject else {
               // print("没有找到照片")
                completion(nil)
                return
            }
            
            // 请求图片数据
            let imageManager = PHImageManager.default()
            let imageRequestOptions = PHImageRequestOptions()
            imageRequestOptions.isSynchronous = true
            
            imageManager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100), contentMode: .aspectFill, options: imageRequestOptions) { image, _ in
                completion(image)
            }
        }
    }
}

// MARK: - 官方水印避让：检测右上角100x100区域是否被其它子视图占用
private extension CameraVC {
    /// 是否需要把官方水印放右下角（即：右上角100x100内存在其它可见子视图）
    func gp_hasOccupiedTopRight100(in watermark: BaseWatermark) -> Bool {
        let size: CGFloat = 100
        let bounds = watermark.bounds
        guard bounds.width > 0, bounds.height > 0 else { return false }

        // 右上角区域（以 watermark 自身坐标为准）
        let probeRect = CGRect(x: bounds.width - size, y: 0, width: size, height: size)

        // 遍历所有后代子视图；排除官方水印自身及其所有子视图
        return gp_anyVisibleView(in: watermark, intersecting: probeRect, excluding: watermark.offcialLogoView)
    }

    /// 递归判断是否存在与探测区域相交的“可见”视图
    func gp_anyVisibleView(in container: UIView, intersecting probeRect: CGRect, excluding excludeRoot: UIView) -> Bool {
        // DFS 栈遍历，避免递归过深
        var stack: [UIView] = container.subviews
        while let v = stack.popLast() {
            // 排除：官方水印自身及其子孙
            if v === excludeRoot || v.isDescendant(of: excludeRoot) {
                continue
            }
            // 排除：隐藏、透明（近似不可见）、完全无尺寸的视图
            if v.isHidden || v.alpha < 0.01 || v.bounds.isEmpty {
                // 继续看其它
            } else {
                // 转换到 container 坐标系再判断是否相交
                let frameInContainer = v.convert(v.bounds, to: container)
                if frameInContainer.intersects(probeRect) {
                    return true
                }
            }
        }
        return false
    }
}

extension CameraVC {
    // 开始倒计时拍照
    private func startCountdownPhoto() {
        guard !isCountdownActive else { return }
        
        // 根据倒计时类型设置秒数
        switch delayTakephotoType {
        case .five:
            remainingSeconds = 5
        case .ten:
            remainingSeconds = 10
        case .none:
            return
        }
        
        isCountdownActive = true
        
        // 隐藏所有控制元素
        setCameraControlsHidden(true)
        
        // 显示倒计时标签和取消按钮
        countdownLabel.isHidden = false
        cancelButton.isHidden = false
        
        // 更新倒计时显示
        updateCountdownDisplay()
        
        // 启动倒计时定时器
        startCountdownTimer()
    }
    
    // 启动倒计时定时器
    private func startCountdownTimer() {
        countdownTimer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCountdown), userInfo: nil, repeats: true)
    }
    
    @objc private func updateCountdown() {
        guard isCountdownActive else { return }
        
        remainingSeconds -= 1
        updateCountdownDisplay()
        
        if remainingSeconds <= 0 {
            // 倒计时结束，执行拍照
            finishCountdownPhoto()
        }
    }
    
    // 更新倒计时显示
    private func updateCountdownDisplay() {
        countdownLabel.text = "\(remainingSeconds)"
        
        // 添加缩放动画效果
        let animation = CABasicAnimation(keyPath: "transform.scale")
        animation.fromValue = 1.3
        animation.toValue = 1.0
        animation.duration = 0.3
        countdownLabel.layer.add(animation, forKey: "scale")
        
        // 最后3秒添加震动反馈
        if remainingSeconds <= 3 && remainingSeconds > 0 {
            let feedBack = UISelectionFeedbackGenerator()
            feedBack.selectionChanged()
        }
    }
    
    // 取消倒计时
    @objc func cancelCountdown() {
        guard isCountdownActive else { return }
        
        // 停止定时器
        countdownTimer?.invalidate()
        countdownTimer = nil
        isCountdownActive = false
        
        // 隐藏倒计时相关UI
        countdownLabel.isHidden = true
        cancelButton.isHidden = true
        
        // 恢复所有控制元素
        setCameraControlsHidden(false)
        
    }
    
    // 完成倒计时拍照
    private func finishCountdownPhoto() {
        // 停止定时器
        countdownTimer?.invalidate()
        countdownTimer = nil
        isCountdownActive = false
        
        // 隐藏倒计时标签和取消按钮
        countdownLabel.isHidden = true
        cancelButton.isHidden = true
        
        // 恢复所有控制元素
        setCameraControlsHidden(false)
        
        // 执行拍照
        let feedBack = UISelectionFeedbackGenerator()
        feedBack.selectionChanged()
        takePhotoAnimation()
        takePhoto()
    }
    
    // 控制相机界面元素的显示/隐藏
    private func setCameraControlsHidden(_ hidden: Bool) {
        self.topView.alpha = hidden ? 0 : 1
        self.bottomView.alpha = hidden ? 0 : 1
        self.wideAngleListView?.alpha = hidden ? 0 : 1
        self.watermarkBtn.alpha = hidden ? 0 : 1
        self.quickEditBtn.alpha = hidden ? 0 : 1
        
        // 控制用户交互
        self.topView.isUserInteractionEnabled = !hidden
        self.bottomView.isUserInteractionEnabled = !hidden
        self.wideAngleListView?.isUserInteractionEnabled = !hidden
        self.watermarkBtn.isUserInteractionEnabled = !hidden
        self.quickEditBtn.isUserInteractionEnabled = !hidden
        self.gestureView.isUserInteractionEnabled = !hidden
    }
}
