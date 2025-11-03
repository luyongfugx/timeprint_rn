//
//  CameraBottomView.swift
//  iOSTimeGPS
//
// 相机底部按钮面板，高度:196-tabBottom

import Foundation
import UIKit

class CameraBottomView: GPContentView {
    
    static let refreshWidth = 46.0
    static let albumWidth = 34.0
    var watchView = GPRecordTimeView(frame: .zero)
    
    var takePhotoButton: TakePhotoButton = {
        return TakePhotoButton(frame: .zero)
    }()
    
    var refreshButton: GPButton = {
        let btn = GPButton(frame: .zero)
        let refreshFontLabel = UILabel.iconLabel(fontSize: 30, labelWidth: CameraBottomView.refreshWidth, iconType: IconFontType.btn_refresh)
        refreshFontLabel.textAlignment = .center
        refreshFontLabel.textColor = .white
        btn.addSubview(refreshFontLabel)
        refreshFontLabel.centerX = CameraBottomView.refreshWidth/2.0
        refreshFontLabel.centerY = CameraBottomView.refreshWidth/2.0
        
        return btn
    }()
    
    var teamButton: GPButton = {
        let btn = GPButton(frame: .zero)
        let folderImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        folderImageView.image = UIImage(systemName: "person.3.fill")
        folderImageView.tintColor = .white
        folderImageView.contentMode = .scaleAspectFit
        btn.addSubview(folderImageView)
        folderImageView.centerX = CameraBottomView.refreshWidth/2.0
        folderImageView.centerY = CameraBottomView.refreshWidth/2.0
        btn.addTarget(nil, action: #selector(CameraVC.folderBtnAction), for: .touchUpInside)
        return btn
    }()
    
    
    var folderButton: GPButton = {
        let btn = GPButton(frame: .zero)
        let folderImageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
        folderImageView.image = UIImage(systemName: "folder.fill")
        folderImageView.tintColor = .white
        folderImageView.contentMode = .scaleAspectFit
        btn.addSubview(folderImageView)
        folderImageView.centerX = CameraBottomView.refreshWidth/2.0
        folderImageView.centerY = CameraBottomView.refreshWidth/2.0
        btn.addTarget(nil, action: #selector(CameraVC.folderBtnAction), for: .touchUpInside)
        return btn
    }()
    
    var albumButton: AlbumButton = {
        let btn = AlbumButton(frame: .init(x: 0, y: 0, width: CameraBottomView.albumWidth, height: CameraBottomView.albumWidth))
        return btn
    }()
    
//    var watermarkButton: GPButton = {
//        let btn = GPButton(frame: .init(x: 0, y: 0, width: CameraBottomView.albumWidth, height: CameraBottomView.albumWidth))
//        btn.backgroundColor = .white
//        let imageV = UIImageView(frame: .init(x: 0, y: 0, width: 30, height: 30))
//        btn.layerCornerRadius = 4
//        imageV.image = UIImage(named: "wmbtn_bg")
//        imageV.contentMode = .scaleAspectFit
//        btn.addSubview(imageV)
//        imageV.centerX = CameraBottomView.albumWidth/2.0
//        imageV.centerY = CameraBottomView.albumWidth/2.0
//        return btn
//    }()
    
    var tabBarView: CameraTabView = {
        var modelList = [
            CameraTabModel(title: "i_photo".localized(), mode: .photo),
            CameraTabModel(title: "i_video".localized(), mode: .video),
        ]
        
        if !GPCheetManager.isCheetMode {
            modelList.insert(CameraTabModel(title: "i_share".localized(), mode: .report), at: 0)
        }
        let bar = CameraTabView(modelList: modelList)
        return bar
    }()
    
    override func buildUI() {
        
        addSubview(takePhotoButton)
        takePhotoButton.layerCornerRadius = 35
        takePhotoButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: 70, height: 70))
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        addSubview(refreshButton)
        refreshButton.layerCornerRadius = CameraBottomView.refreshWidth/2.0
        refreshButton.backgroundColor = UIColor(red: 28/255.0, green: 28/255.0, blue: 28/255.0, alpha: 1)
        
        addSubview(teamButton)
        teamButton.layerCornerRadius = CameraBottomView.refreshWidth/2.0
        teamButton.backgroundColor = UIColor(red: 28/255.0, green: 28/255.0, blue: 28/255.0, alpha: 1)
        
        // 计算右侧区域的宽度（从拍照按钮中心到屏幕右边）
        let rightAreaWidth = GPApp.screenWidth/2.0
        // 计算两个按钮之间的间距（考虑按钮宽度和均匀分布）
        let rightSpacing = 0 - (rightAreaWidth - CameraBottomView.refreshWidth * 2) / 3
       // let rightSpacing = (rightAreaWidth - CameraBottomView.albumWidth - CameraBottomView.refreshWidth) / 3
       


        teamButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: CameraBottomView.refreshWidth, height: CameraBottomView.refreshWidth))
            make.right.equalToSuperview().offset(rightSpacing)
            make.centerY.equalTo(takePhotoButton.snp.centerY)
        }
//        
        refreshButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: CameraBottomView.refreshWidth, height: CameraBottomView.refreshWidth))
            make.right.equalTo(teamButton.snp.left).offset(rightSpacing/2)
            make.centerY.equalTo(takePhotoButton.snp.centerY)
        }
        
        // 计算左侧区域的宽度（从屏幕左边到拍照按钮的中心）
        let leftAreaWidth = GPApp.screenWidth/2.0
        // 计算两个按钮之间的间距（考虑按钮宽度和均匀分布）
        let spacing = (leftAreaWidth - CameraBottomView.albumWidth - CameraBottomView.refreshWidth) / 3
        
        addSubview(albumButton)
        albumButton.backgroundColor = UIColor.clear
        albumButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: CameraBottomView.albumWidth, height: CameraBottomView.albumWidth))
            make.left.equalToSuperview().offset(spacing)
            make.centerY.equalTo(takePhotoButton.snp.centerY)
        }
        
        addSubview(folderButton)
        folderButton.layerCornerRadius = CameraBottomView.refreshWidth/2.0
        folderButton.backgroundColor = UIColor(red: 28/255.0, green: 28/255.0, blue: 28/255.0, alpha: 1)
        folderButton.snp.makeConstraints { make in
            make.size.equalTo(CGSize(width: CameraBottomView.refreshWidth, height: CameraBottomView.refreshWidth))
            make.left.equalTo(albumButton.snp.right).offset(spacing/2)
            make.centerY.equalTo(albumButton.snp.centerY)
        }
        
//        addSubview(watermarkButton)
//        let leftPadding = (GPApp.screenWidth/2.0 - 35 - 20 - CameraBottomView.albumWidth)/2.0 - 20.0
//        watermarkButton.snp.makeConstraints { make in
//            make.size.equalTo(CGSize(width: CameraBottomView.albumWidth, height: CameraBottomView.albumWidth))
//            make.left.equalTo(albumButton.snp.right).offset(leftPadding)
//            make.centerY.equalTo(takePhotoButton.snp.centerY)
//        }
        
        addSubview(tabBarView)
        
        watchView.frame = CGRect(x: 172, y: 20, width: 30, height: 30)
        watchView.isHidden = true
        addSubview(watchView)
        watchView.centerX = GPApp.screenWidth * 0.5
        
    }
    
    func updateState(state: TakePhotoButtonState) {
        switch state {
        case .photoNormal:
            refreshButton.isHidden = false
            folderButton.isHidden = false
            albumButton.isHidden = false
            tabBarView.isHidden = false
            watchView.isHidden = true
        case .videoNormal:
            refreshButton.isHidden = false
            folderButton.isHidden = false
            albumButton.isHidden = false
            tabBarView.isHidden = false
            watchView.stop()
            watchView.isHidden = true
        case .videoRecording:
            refreshButton.isHidden = true
            folderButton.isHidden = true
            albumButton.isHidden = true
            tabBarView.isHidden = true
            watchView.start()
            watchView.isHidden = false
        }
        takePhotoButton.updateState(state: state)
    }
}

struct CameraTabModel {
    var title: String
    var mode: CameraMode
}

class CameraTabView: GPView {
    
    var buttonList: [GPButton] = []
    var modelList: [CameraTabModel] = []
    var selectMode: CameraMode = .photo
    var chooseHandler: ((_ mode: CameraMode) -> Void)?
    
    init(modelList: [CameraTabModel]) {
        self.modelList = modelList
        super.init(frame: .zero)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func buildUI() {
        for item in modelList {
            let btn = GPButton(frame: .zero)
            btn.tag = item.mode.rawValue
            btn.setTitle(item.title, for: .normal)
            btn.setTitleColor(.white, for: .normal)
            btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            btn.addTarget(self, action: #selector(didClickButton(sender:)), for: .touchUpInside)
            addSubview(btn)
            buttonList.append(btn)
        }
        updateButtonFrame()
    }
    
    @objc func didClickButton(sender: UIButton) {
        let selecM = CameraMode(rawValue: sender.tag) ?? .photo
        if selecM != .report {
            selectMode(selecM, true)
        }
        GPSafeMainAsync {
            self.chooseHandler?(selecM)
        }
    }
    
    func updateButtonFrame() {
        
        var btnX:CGFloat = 0
        
        buttonList.forEach {
                        
            let itemW = ($0.title(for: .normal)?.size(WithFont: UIFont.boldSystemFont(ofSize: 16), ConstrainedToHeight: 32).width ?? 0)+20
            $0.frame = CGRect(x: btnX, y: 0, width: itemW, height: 32)
            btnX += itemW
    
        }
        
        self.frame = CGRect(x: 0, y: 4, width: btnX, height: 32)
        self.centerX = GPApp.screenWidth * 0.5
        selectMode(selectMode, false)
    }
    
    func selectMode(_ mode: CameraMode, _ animate: Bool = true) {
        
        guard let selectIndex = modelList.firstIndex(where: { $0.mode == mode })  else {
            return
        }
        let selectButton = buttonList[selectIndex]
        
        buttonList.forEach {
            if $0 == selectButton {
                $0.setTitleColor(UIColor.yellow_color, for: .normal)
                $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
            } else {
                $0.setTitleColor(.white, for: .normal)
                $0.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
            }
        }
        
        if animate == true {
            UIView.animate(withDuration: 0.25) { [weak self] in
                self?.left = GPApp.screenWidth * 0.5 - selectButton.centerX
            }
        } else {
            self.left = GPApp.screenWidth * 0.5 - selectButton.centerX
        }
        
//        if mode == .video {
//
//            if flashlightMode  != .off, flashlightMode != .always {
//                
//                self.flashlightMode =  .off
//            }
//        }
    }
    
}
