//
//  AlbumViewController.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/25.
//

import Foundation
import UIKit
import Photos

class AlbumViewController: UIViewController {
    
    static let colItemSpacing: CGFloat = 40
    
    static let selPhotoPreviewH: CGFloat = 100
    
    static let previewVCScrollNotification = Notification.Name("previewVCScrollNotification")
    
    var arrDataSources: [ZLPhotoModel] = []
    
    var currentIndex: Int = 0
    
    var firstIndex: Int = 0
    
    var createDate: Date?
    
    var hideNavView = false
    
    var isFromTimeprint = false
    //如果是 timeprint 相册,则有可能是搜索
    var searchText = ""
    
    @GPPersistance(key: "com.gpscamera.album.hasShowMultiRedPoint", defaultValue: false)
    static var hasShowMultiRedPoint: Bool
    
    lazy var collectionView: UICollectionView = {
        let layout = ZLCollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.dataSource = self
        view.delegate = self
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        
        ZLPhotoPreviewCell.zl.register(view)
        ZLGifPreviewCell.zl.register(view)
        ZLLivePhotoPreviewCell.zl.register(view)
        ZLVideoPreviewCell.zl.register(view)
        
        return view
    }()
    
    lazy var topView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black
        return view
    }()
        
    lazy var backBtn: UIButton = {
        let btn = UIButton(type: .custom)
        var image = UIImage.zl.getImage("zl_navClose")
        if isRTL() {
            image = image?.imageFlippedForRightToLeftLayoutDirection()
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: -10)
        } else {
            btn.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 0)
        }
        btn.setImage(image, for: .normal)
        btn.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
        return btn
    }()
    
    lazy var multiShareButton: AutoResizeButton = {
        let btn = AutoResizeButton(8)
        btn.setTitle("i_multi_share".localized(), for: .normal)
        btn.setTitleColor(.fromHex("#0093FF"), for: .normal)
        btn.titleLabel?.font = UIFont.Semibold(16)
        btn.addTarget(self, action: #selector(toMultiSharePhotoVC), for: .touchUpInside)
        return btn
    }()
    
    lazy var infoButton: UIButton = {
        let button = UIButton(type: .custom)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .medium)
        let image = UIImage(systemName: "info.circle", withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(infoBtnClick), for: .touchUpInside)
        return button
    }()
    
    var bottomCollectionView: AlbumBottomView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //print("viewDidLoad currentIndex: \(currentIndex)")
        self.view.backgroundColor = .black
        self.navigationController?.navigationBar.isHidden = true
        buildViews()
        loadDatas()
        ZLMainAsync(after: 0.5) {
            self.checkShowRedPoint()
        }
        if GPCheetManager.isCheetMode {
            multiShareButton.isHidden = true
        }
        PHPhotoLibrary.shared().register(self)
    }
    
    
    func buildViews() {
        view.addSubview(collectionView)
        view.addSubview(topView)
        topView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(GPApp.statusBarAndNavigationBarHeight)
        }
        topView.addSubview(backBtn)
        backBtn.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.top.equalTo(GPApp.statusBarHeight)
            make.height.equalTo(44)
            make.width.equalTo(60)
        }
        
        topView.addSubview(multiShareButton)
        multiShareButton.snp.makeConstraints { make in
            make.trailing.equalTo(-10)
            make.centerY.equalTo(backBtn.snp.centerY)
            make.height.equalTo(36)
        }
        
        collectionView.frame = CGRect(
            x: -ZLPhotoPreviewController.colItemSpacing / 2,
            y: 0,
            width: view.zl.width + ZLPhotoPreviewController.colItemSpacing,
            height: view.zl.height
        )
        //增加一个infobutton 用来读取照片exif data
       // view.addSubview(infoButton)
        buildBottomView()
//        infoButton.snp.makeConstraints { make in
//            make.trailing.equalToSuperview().offset(-60)
//            make.bottom.equalTo(bottomCollectionView.snp.top).offset(-20)
//            make.width.height.equalTo(44)
//        }
//        
        reloadBottomView()
    }
    
    @objc func backBtnClick() {
        if isFromTimeprint {
            navigationController?.popViewController(animated: true)
        } else {
            dismiss(animated: true)
        }
    }
    
    func checkShowRedPoint() {
        if !AlbumViewController.hasShowMultiRedPoint {
            multiShareButton.showRedDot(isShow: true, point: .init(x: multiShareButton.width - 10, y: 5))
        } else {
            multiShareButton.showRedDot(isShow: false)
        }
    }
    
    func buildBottomView() {
        let countryCode = GPCountryManager.geoCountryCode
        bottomCollectionView = AlbumBottomView(config: XHPhotoPreviewOrderModel.buildItem(with: countryCode), isMultiChoose: false)
        view.addSubview(bottomCollectionView)
        bottomCollectionView.snp.makeConstraints { (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(83 + GPApp.tabBarBottomHeight)
        }
        bottomCollectionView.onSelect = {[weak self] itemType, shareType in
            guard let self else { return }
                                    
            switch itemType {
            case .zip:
                zipBtnClick()
            case .delete:
                deleteBtnClick()
            case .more:
//                toCustomShare(shareType: .system)
                GPPhotoShowShareView.showDefault(in: view, fromPlace: "") { [weak self] shareType in
                    GPShareManager.photoShowShareTypeCacheKey = shareType.rawValue
                    self?.toCustomShare(shareType: shareType)
                    self?.reloadCollectionView()
                    self?.reloadBottomView()
                }
            case .directShare:
                toCustomShare(shareType: shareType ?? .system)
                break
                
//                guard let shareType else { return }
//                ShareGuideLocationAlert.checkShow(hasLocationOnPhoto: hasLocationOnCurrentCell()) { hasSet in
//                    self.toCustomShare(shareType: shareType)
//                }
            case .toMultiPhoto:
            
//                toMultiPhotoVC()
//                // 埋点
//                Report.photo_preview_click(clickItem: "viaKMZ", fromPage: fromPage)
                break
            case .edit:
                editBtnClick()
            case .email:
                break
            }
        }
    }
    
    func createButton(imgWidth: CGFloat, iconType: IconFontType, text: String) -> GPButton {
        let img = GPButton.createImage(size: .init(width: imgWidth, height: imgWidth), iconType: iconType)
        let btn = GPButton(frame: .init(x: 0, y: 0, width: 80, height: 60), style: .imageTopTextBottom(10, img, .init(title: text, font: UIFont.systemFont(ofSize: 16), titleColor: .white)))
        btn.titleLabel?.adjustsFontSizeToFitWidth = true
        btn.titleLabel?.minimumScaleFactor = 0.6
        return btn
    }
    
    func reloadBottomView() {
        let photoPreviewOrderModel = XHPhotoPreviewOrderModel.buildInDefaultData()
        bottomCollectionView.reload(with: photoPreviewOrderModel)
    }
    
}

// 加载数据
extension AlbumViewController {
    
    func loadDatas() {
        let status = PHPhotoLibrary.zl.authStatus(for: .readWrite)
        if status == .restricted || status == .denied {
            showNoAuthorityAlert()
        } else if status == .notDetermined {
            PHPhotoLibrary.requestAuthorization { status in
                ZLMainAsync {
                    if status == .denied {
                        self.showNoAuthorityAlert()
                    } else if status == .authorized {
                        self.loadPhotos()
                    }
                }
            }
        } else {
            loadPhotos()
        }
    }
    
    private func loadPhotos(_ animate: Bool = true) {
        let config = ZLPhotoConfiguration.default()
        let uiConfig = ZLPhotoUIConfiguration.default()
        
        var hud: ZLProgressHUD?
        if animate {
            hud = ZLProgressHUD.show()
        }
        // 顺序
        ZLPhotoUIConfiguration.default().sortAscending = false
    
        ZLPhotoManager.getCameraRollAlbum( albumTitle:isFromTimeprint ? "Timeprint":"default", allowSelectImage: config.allowSelectImage, allowSelectVideo: config.allowSelectVideo,searchText: isFromTimeprint ?searchText: "",date: createDate) { [weak self] cameraRoll in
            defer {
                hud?.hide()
            }
            
            guard let `self` = self else {
                return
            }
           // fetchOptions.predicate = NSPredicate(format: "title = %@", "Timeprint")
           // print("cameraRoll.result=== \(cameraRoll.result.count)")
            
       

            
            self.arrDataSources = ZLPhotoManager.fetchPhoto(
                in: cameraRoll.result,
                ascending: uiConfig.sortAscending,
                allowSelectImage: config.allowSelectImage,
                allowSelectVideo: config.allowSelectVideo
            )
            self.reloadCollectionView()
            // 如果是从Timeprint相册来的 且 firstIndex 大于0 ，跳转到firstIndex
            if self.isFromTimeprint && self.firstIndex > 0 && self.firstIndex < self.arrDataSources.count {
                let indexPath = IndexPath(item: self.firstIndex, section: 0)
                if let rect = self.collectionView.layoutAttributesForItem(at:indexPath)?.frame {
                    self.collectionView.scrollRectToVisible(rect.offsetBy(dx: -self.collectionView.x, dy: -GPApp.tabBarBottomHeight), animated: false)
                }
            }
        }
    }
 
    private func showNoAuthorityAlert() {
        if let customAlertWhenNoAuthority = ZLPhotoConfiguration.default().customAlertWhenNoAuthority {
            customAlertWhenNoAuthority(.library)
            return
        }
        
        let action = ZLCustomAlertAction(title: localLanguageTextValue(.ok), style: .default) { _ in
            // 引导开启权限
            GPApp.gotoSetting()
        }
        
        showAlertController(title: nil, message: String(format: localLanguageTextValue(.noPhotoLibratyAuthority), getAppName()), style: .alert, actions: [action], sender: self)
    }
    
    func reloadCollectionView() {
        let canClick = !arrDataSources.isEmpty
        self.bottomCollectionView.isHidden = !canClick
        // hidden share btn when empty
        self.multiShareButton.isHidden = !canClick
//        self.watermarkBtn?.isEnabled = canClick
//        self.editBtn?.isEnabled = canClick
//        self.deleteBtn?.isEnabled = canClick
//      self.shareBtn?.isEnabled = canClick
        self.collectionView.reloadData()
    }
    
}

extension AlbumViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return ZLPhotoPreviewController.colItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return ZLPhotoPreviewController.colItemSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: ZLPhotoPreviewController.colItemSpacing / 2, bottom: 0, right: ZLPhotoPreviewController.colItemSpacing / 2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: view.zl.width, height: view.zl.height)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return arrDataSources.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let config = ZLPhotoConfiguration.default()
        let model = arrDataSources[indexPath.row]
        
        let baseCell: ZLPreviewBaseCell
        
        if config.allowSelectGif, model.type == .gif {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLGifPreviewCell.zl.identifier, for: indexPath) as! ZLGifPreviewCell
            
            cell.singleTapBlock = { [weak self] in
                self?.tapPreviewCell()
            }
            
            cell.model = model
            
            baseCell = cell
        } else if config.allowSelectLivePhoto, model.type == .livePhoto {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLLivePhotoPreviewCell.zl.identifier, for: indexPath) as! ZLLivePhotoPreviewCell
            
            cell.model = model
            
            baseCell = cell
        } else if config.allowSelectVideo, model.type == .video {
//            print("Video Model Info:")
//            print("- Asset: \(model.asset)")
//            print("- Duration: \(model.duration)")
//            print("- Type: \(model.type)")
//            print("- Available: \(model.isAvailable)")
//            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLVideoPreviewCell.zl.identifier, for: indexPath) as! ZLVideoPreviewCell
            
            cell.model = model
            
            baseCell = cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ZLPhotoPreviewCell.zl.identifier, for: indexPath) as! ZLPhotoPreviewCell
            
            cell.singleTapBlock = { [weak self] in
                self?.tapPreviewCell()
            }
            
            cell.model = model
            
            baseCell = cell
        }
        
        baseCell.singleTapBlock = { [weak self] in
            self?.tapPreviewCell()
        }
        
        return baseCell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? ZLPreviewBaseCell)?.willDisplay()
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        (cell as? ZLPreviewBaseCell)?.didEndDisplaying()
    }
}

// MARK: scroll view delegate

extension AlbumViewController {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView == collectionView else {
            return
        }
        
        NotificationCenter.default.post(name: ZLPhotoPreviewController.previewVCScrollNotification, object: nil)
        let offset = scrollView.contentOffset
        var page = Int(round(offset.x / (view.bounds.width + ZLPhotoPreviewController.colItemSpacing)))
        page = max(0, min(page, arrDataSources.count - 1))
        if page == currentIndex {
            return
        }
        currentIndex = page
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let cell = collectionView.cellForItem(at: IndexPath(row: currentIndex, section: 0))
        if let cell = cell as? ZLGifPreviewCell {
            cell.loadGifWhenCellDisplaying()
        } else if let cell = cell as? ZLLivePhotoPreviewCell {
            cell.loadLivePhotoData()
        }
    }
}

extension AlbumViewController: PHPhotoLibraryChangeObserver {
    public func photoLibraryDidChange(_ changeInstance: PHChange) {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
        ZLMainAsync {
            self.loadPhotos(false)
        }
    }
}
