//
//  GPChooseAddLogoVC.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/5.
//

import Foundation
import UIKit

enum AddLogoType {
    case album
    case google
}

class GPChooseAddLogoVC: GPHalfBaseVC {
    
    lazy var albumView: UIView = {
        let view = UIView(frame: .zero)
        view.layerCornerRadius = 8
        view.backgroundColor = UIColor.fromRGBA(243, g: 246, b: 249)
        let fontsize = GPApp.screenWidth * 0.38 * 0.26
        let iconLabel = UILabel.iconLabel(fontSize: fontsize, labelWidth: fontsize, iconType: .icon_camera2)
        iconLabel.textColor = .icon_blue_color
        view.addSubview(iconLabel)
        iconLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        view.addTapGestureRecognizer(target: self, action: #selector(clickChooseAlbum))
        return view
    }()
    
    lazy var chooseAlbumLabel: UILabel = {
        let label = UILabel(text: "k_choose_from_album".localized(), textColor: .text_black_color, textFont: .body_normal)
        return label
    }()
    
    lazy var searchWebView: UIView = {
        let view = UIView(frame: .zero)
        view.layerCornerRadius = 8
        view.backgroundColor = UIColor.fromRGBA(243, g: 246, b: 249)
        let fontsize = GPApp.screenWidth * 0.38 * 0.26
        let iconLabel = UILabel.iconLabel(fontSize: fontsize, labelWidth: fontsize, iconType: .icon_search)
        iconLabel.textColor = .icon_green_color
        view.addSubview(iconLabel)
        iconLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        view.addTapGestureRecognizer(target: self, action: #selector(clickChooseWeb))
        return view
    }()
    
    lazy var searchWebLabel: UILabel = {
        let label = UILabel(text: "k_choose_from_web".localized(), textColor: .text_black_color, textFont: .body_normal)
        return label
    }()
    
    private var viewHeight: CGFloat = 0
    
    override var preferredContentSize: CGSize {
        
        get { .init(width: view.bounds.width, height: editWatermarkHeightRate * GPApp.screenHeight) }
        set {}
    }
    var complete: ((UIImage) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        vcTitle = "k_add_logo".localized()
        buildViews()
    }
    
    func buildViews() {
        view.addSubview(albumView)
        view.addSubview(chooseAlbumLabel)
        view.addSubview(searchWebView)
        view.addSubview(searchWebLabel)
        
        let buttonRate = 0.24
        let buttonWidth = buttonRate * GPApp.screenWidth
        albumView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom).offset(40)
            make.width.height.equalTo(buttonWidth)
        }
        chooseAlbumLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(albumView.snp.bottom).offset(10)
        }
        searchWebView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(chooseAlbumLabel.snp.bottom).offset(50)
            make.width.height.equalTo(buttonWidth)
        }
        searchWebLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(searchWebView.snp.bottom).offset(10)
        }
    }
        
    @objc
    func clickChooseAlbum() {
        
        albumView.viewClickAnimation()
        
        let minItemSpacing: CGFloat = 2
        let minLineSpacing: CGFloat = 2
        
        ZLPhotoUIConfiguration.default()
            .minimumInteritemSpacing(minItemSpacing)
            .minimumLineSpacing(minLineSpacing)
            .columnCountBlock { Int(ceil($0 / (428.0 / 4))) }
            .showScrollToBottomBtn(true)
            .sortAscending(false)
        
        if ZLPhotoUIConfiguration.default().languageType == .arabic {
            UIView.appearance().semanticContentAttribute = .forceRightToLeft
        } else {
            UIView.appearance().semanticContentAttribute = .unspecified
        }
        
        let config = ZLPhotoConfiguration.default()
        config.allowSelectVideo = false
        config.maxSelectCount = 1
        let ac = ZLPhotoPreviewSheet(results: nil)
        ac.selectImageBlock = { [weak self] results, isOriginal in
            guard let `self` = self else { return }
            
            if let img = results.first?.image {
                var compressImg = img
                if img.size.width > 200 || img.size.height > 200 {
                    compressImg = UIImage.resizeImage(image: img, targetSize: .init(width: 200, height: 200)) ?? img
                }
                // 设置图片到logo中
                self.handleChooseImage(compressImg)
            }
        }
        ac.cancelBlock = {
            debugPrint("cancel select")
        }
        ac.selectImageRequestErrorBlock = { errorAssets, errorIndexs in
            debugPrint("fetch error assets: \(errorAssets), error indexs: \(errorIndexs)")
        }
        
        ac.showPhotoLibrary(sender: self)
    }
    
    @objc
    func clickChooseWeb() {
        
        searchWebView.viewClickAnimation()
        
        LogoSearchGoogleVC.show() { [weak self] img in
            guard let self = self else { return }
            self.handleChooseImage(img)
        }
    }
    
    func handleChooseImage(_ img: UIImage) {
        //增加add logo 事件上报
        GPFirebaseManager.add_logo()
        // 设置图片到logo中
        self.complete?(img)
        self.popOrDismissVC()
    }
}

