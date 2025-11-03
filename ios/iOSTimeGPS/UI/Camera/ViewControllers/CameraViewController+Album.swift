//
//  CameraViewController+Album.swift
//  test001
//
//  Created by ganshiren on 2024/8/23.
//

import Foundation
import UIKit
import Photos

extension CameraViewController {


    
    func showImagePicker() {
        let minItemSpacing: CGFloat = 2
        let minLineSpacing: CGFloat = 2
        
        // Custom UI
        ZLPhotoUIConfiguration.default()
//            .navBarColor(.white)
//            .navViewBlurEffectOfAlbumList(nil)
//            .indexLabelBgColor(.black)
//            .indexLabelTextColor(.white)
            .minimumInteritemSpacing(minItemSpacing)
            .minimumLineSpacing(minLineSpacing)
            .columnCountBlock { Int(ceil($0 / (428.0 / 4))) }
            .showScrollToBottomBtn(true)
            
        if ZLPhotoUIConfiguration.default().languageType == .arabic {
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
        } else {
            UIView.appearance().semanticContentAttribute = .unspecified
        }
        
//        // Custom image editor
//        ZLPhotoConfiguration.default()
//            .editImageConfiguration
//            .imageStickerContainerView(ImageStickerContainerView())
////            .tools([.draw, .clip, .mosaic, .filter])
////            .adjustTools([.brightness, .contrast, .saturation])
//            .clipRatios(ZLImageClipRatio.all)
////            .imageStickerContainerView(ImageStickerContainerView())
////            .filters([.normal, .process, ZLFilter(name: "custom", applier: ZLCustomFilter.hazeRemovalFilter)])
//        
        /*
         ZLPhotoConfiguration.default()
             .cameraConfiguration
             .devicePosition(.front)
             .allowRecordVideo(false)
             .allowSwitchCamera(false)
             .showFlashSwitch(true)
          */
        ZLPhotoConfiguration.default()
            // You can first determine whether the asset is allowed to be selected.
            .canSelectAsset { _ in true }
            .didSelectAsset { _ in }
            .didDeselectAsset { _ in }
            .noAuthorityCallback { type in
                switch type {
                case .library:
                    debugPrint("No library authority")
                case .camera:
                    debugPrint("No camera authority")
                case .microphone:
                    debugPrint("No microphone authority")
                }
                
                GPApp.openAppSettings()
            }
            .gifPlayBlock { imageView, data, _ in
//                let animatedImage = FLAnimatedImage(gifData: data)
//                
//                var animatedImageView: FLAnimatedImageView?
//                for subView in imageView.subviews {
//                    if let subView = subView as? FLAnimatedImageView {
//                        animatedImageView = subView
//                        break
//                    }
//                }
//                
//                if animatedImageView == nil {
//                    animatedImageView = FLAnimatedImageView()
//                    imageView.addSubview(animatedImageView!)
//                }
//                
//                animatedImageView?.frame = imageView.bounds
//                animatedImageView?.animatedImage = animatedImage
//                animatedImageView?.runLoopMode = .default
            }
//            .pauseGIFBlock { $0.subviews.forEach { ($0 as? FLAnimatedImageView)?.stopAnimating() } }
//            .resumeGIFBlock { $0.subviews.forEach { ($0 as? FLAnimatedImageView)?.startAnimating() } }
//            .operateBeforeDoneAction { currVC, block in
//                // Do something before select photo result callback, and then call block to continue done action.
//                block()
//            }
        
        /// Using this init method, you can continue editing the selected photo
        let ac = ZLPhotoPreviewSheet(results: nil)
        
//        let ac = ZLPhotoPreviewSheet(selectedAssets: takeSelectedAssetsSwitch.isOn ? selectedAssets : nil)
        
        
        ac.selectImageBlock = { [weak self] results, isOriginal in
            guard let `self` = self else { return }
//            self.selectedImages = results.map { $0.image }
//            self.selectedAssets = results.map { $0.asset }
//            self.isOriginal = isOriginal
//            self.collectionView.reloadData()
//            debugPrint("images: \(self.selectedImages)")
//            debugPrint("assets: \(self.selectedAssets)")
//            debugPrint("isEdited: \(results.map { $0.isEdited })")
//            debugPrint("isOriginal: \(isOriginal)")
            
//            guard !self.selectedAssets.isEmpty else { return }
//            self.saveAsset(self.selectedAssets[0])
        }
        ac.cancelBlock = {
            debugPrint("cancel select")
        }
        ac.selectImageRequestErrorBlock = { errorAssets, errorIndexs in
            debugPrint("fetch error assets: \(errorAssets), error indexs: \(errorIndexs)")
        }
        
        ac.showPhotoLibrary(sender: self)
    }
    
}
