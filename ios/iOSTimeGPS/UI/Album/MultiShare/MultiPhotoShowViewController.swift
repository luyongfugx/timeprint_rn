
import Foundation
import Photos
import UIKit
import MessageUI

protocol MultiPhotoSelectProtocol: AnyObject {
    func shouldSelectPhoto() -> Bool
    func selectedPhotosReachMaxCount()
}

class MultiPhotoShowViewController: GPBaseVC {
    var isFromTimeprint: Bool = false //如果是timeprint相册
    let photoManager = MultiPhotoManager()
    var groupedPhotos = [Date: [PHAsset]]()
    var sortedDates = [Date]()
    var pagination = Pagination()
    let maxCountOfPhotos = 200
    var selectedPhotos = [PHAsset]()
    var isSelectVideo: Bool {
        selectedPhotos.contains { $0.mediaType == .video }
    }
    var onlySelectVideo: Bool {
        selectedPhotos.allSatisfy { $0.mediaType == .video }
    }
    
    let defaultAsset: PHAsset?
    var defaultAssetLocated = false
    
    let collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.minimumLineSpacing = 4
        flowLayout.minimumInteritemSpacing = 4
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.registerCell(MultiPhotoCell.self)
        collectionView.registerHeader(MultiPhotoSectionHeader.self)
        collectionView.registerFooter(UICollectionReusableView.self)
        return collectionView
    }()
    
    let footerLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.regular(13)
        label.textColor = .text_ultrastrong
        label.numberOfLines = 1
        label.text = "1 \("i_photo_selected".localized())"
        return label
    }()
    
    let bottomView = AlbumBottomView(config: nil, isMultiChoose: true)
    
    init(asset: PHAsset?, defaultAssetLocated: Bool) {
        self.defaultAsset = asset
        self.defaultAsset?.xhSelected = true
        self.defaultAssetLocated = defaultAssetLocated
        super.init(nibName: nil, bundle: nil)
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        buildBottomView()
        setupUI()
        loadData()
        
        if GPCheetManager.isCheetMode {
            footerLabel.isHidden = true
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        .lightContent
    }

    private func setupUI() {
        view.backgroundColor = .black
        setupNaviBar()
        setupCollectionView()
        
        let footBGView = UIView(frame: .zero)
        footBGView.backgroundColor = .black
        view.addSubview(footBGView)
        footBGView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(collectionView.snp.bottom).offset(8)
            make.height.equalTo(30)
        }
        
        footBGView.addSubview(footerLabel)
        footerLabel.snp.makeConstraints { make in
            make.centerX.centerY.equalToSuperview()
        }
        view.addSubview(bottomView)
        bottomView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo((GPApp.isIPhoneX ? 0 : -7) - GPApp.tabBarBottomHeight)
            make.top.equalTo(footBGView.snp.bottom)
        }
    }

    private func setupNaviBar() {
        vcTitle = "i_multi_share".localized()
        navBar.backBtn.setTitleColor(.white, for: .normal)
        navBar.titleLabel.textColor = .white
        navBar.backgroundColor = .black
        navBar.lineView.backgroundColor = .clear
    }

    private func setupCollectionView() {
        collectionView.dataSource = self
        collectionView.delegate = self
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
            make.bottom.equalTo((GPApp.isIPhoneX ? -98 : -105) - GPApp.tabBarBottomHeight)
        }
        let bottomLine = UIView(backgroundColor: .icon_ultraweak)
        view.addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(collectionView.snp.bottom)
            make.height.equalTo(0.5)
        }
    }

    private func loadData() {
        // 根据 isFromTimeprint 设置不同的相册
        if self.isFromTimeprint {
            self.photoManager.albumTitle = "Timeprint"
        } else {
            self.photoManager.albumTitle = "default"
        }
        photoManager.prepareFetchResult { [weak self] isAuthorized in
            guard let self else { return }
            guard isAuthorized else {
                GPToast.text("i_photo_access_limited".localized())
                return
            }
            loadNextBatch()
        }
    }

    private func loadNextBatch() {
        guard pagination.hasMore else { return }

        photoManager.fetchPhotosBatch(pagination: &pagination) { [weak self] assets in
            guard let self else { return }
            groupAssetsByDate(assets: assets)
            collectionView.reloadData()
            updateFooterLabel()
            locateDefaultAsset()
        }
    }

    private func groupAssetsByDate(assets: [PHAsset]) {
        let calendar = Calendar.current
        for asset in assets {
            if let creationDate = asset.creationDate {
                let startOfDay = calendar.startOfDay(for: creationDate)
                if var existingGroup = groupedPhotos[startOfDay] {
                    existingGroup.append(asset)
                    groupedPhotos[startOfDay] = existingGroup
                } else {
                    groupedPhotos[startOfDay] = [asset]
                }
            }
        }
        sortedDates = groupedPhotos.keys.sorted(by: >)
    }
    
    private func locateDefaultAsset() {
        guard !defaultAssetLocated, let defaultAsset else { return }
        
        defaultAssetLocated = true
        for (sectionIndex, date) in sortedDates.enumerated() {
            if let assets = groupedPhotos[date],
               let rowIndex = assets.firstIndex(of: defaultAsset) {
                let asset = assets[rowIndex]
                asset.xhSelected = true
                selectedPhotos.append(asset)
                let indexPath = IndexPath(row: rowIndex, section: sectionIndex)
                DispatchQueue.main.async {
                    self.collectionView.reloadItems(at: [indexPath])
                    self.collectionView.scrollToItem(at: indexPath, at: .centeredVertically, animated: false)
                }
                break
            }
        }
    }

    private func updateFooterLabel() {
        let suffix = selectedPhotos.count > 1 ? "i_photos_selected".localized() : "i_photo_selected".localized()
        let textColor = selectedPhotos.isEmpty ? UIColor.text_error : UIColor.white
        let text = "\(selectedPhotos.count) \(suffix)"
        footerLabel.textColor = textColor
        footerLabel.text = text
    }
    
    private func updateHeader(asset: PHAsset) {
        guard let date = findDate(for: asset),
              let section = sortedDates.firstIndex(of: date),
              let photos = groupedPhotos[date],
              let header = collectionView.supplementaryView(
                  forElementKind: UICollectionView.elementKindSectionHeader,
                  at: IndexPath(item: 0, section: section)
              ) as? MultiPhotoSectionHeader else { return }

        header.isSelectAll = photos.allSatisfy { $0.xhSelected }
    }
    
    private func findDate(for targetAsset: PHAsset) -> Date? {
        for (date, assets) in groupedPhotos {
            if assets.contains(targetAsset) {
                return date
            }
        }
        return nil
    }
}

// MARK: BottomView

extension MultiPhotoShowViewController {
    // 构造底部View
    func buildBottomView() {
        let model = buildOrderModel()
        bottomView.reload(with: model)
        bottomView.onSelect = {[weak self] itemType, shareType in
            guard let self else { return }
            switch itemType {
            case .zip:
                onClickZip()
            case .email:
                onEmailTapped()
            case .more:
                if GPCheetManager.isCheetMode {
                    Task {
                        let result = try await self.photoManager.fetchMediaFromAssets(self.selectedPhotos)
                        await MainActor.run {
                            GPShareManager.shareMultiMedias(result, type: .system)
                        }
                    }
                } else {
                    showMoreShareView()
                }
            case .directShare:
                guard let shareType else { return }
                toCustomShare(shareType: shareType)
            default:
                break
            }
        }
    }
    
    @objc private func onEmailTapped() {
        let assets = selectedPhotos
        guard !assets.isEmpty else {
            UIViewController.show45ButtonAlert(
                title: "i8_key_tips".localized(),
                message: "i8_key_please_select_photos_first".localized(),
                buttonTitle: "i8_key_ok".localized()
            )
            return
        }

        let hud = ZLProgressHUD.show()
        hud.changeTitle("i8_key_exporting".localized())

        GPZipTool.gp_exportAssetsToTemp(assets, progress: { p in
            hud.changeTitle("\("i8_key_exporting".localized()) \(Int(p * 100))%")
        }) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let e):
                hud.hide()
                UIViewController.show45ButtonAlert(
                    title: "i8_key_failed".localized(),
                    message: e.localizedDescription,
                    buttonTitle: "i8_key_ok".localized()
                )

            case .success(let urls):
                // 仅保留图片和视频类附件（邮件多附件体验更好）
                let allowedExt: Set<String> = ["jpg", "jpeg", "png", "heic", "tif", "tiff", "gif", "mov", "mp4", "m4v", "avi", "hevc"]
                let mediaURLs = urls.filter { allowedExt.contains($0.pathExtension.lowercased()) }

                // 估算大小并决定是否压缩
                let hasVideo = mediaURLs.contains { ["mov", "mp4", "m4v", "avi", "hevc"].contains($0.pathExtension.lowercased()) }
                let totalBytes = mediaURLs.reduce(0) { $0 + (GPZipTool.gp_getFileSizeInBytes($1) ?? 0) }
                let shouldZip = hasVideo || mediaURLs.count > 15 || totalBytes > 18 * 1024 * 1024

                if shouldZip {
                    hud.changeTitle("i8_key_compressing".localized())
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.gp_exportZipFilesToEmail(urls: mediaURLs, hud: hud)
                    }
                } else {
                    hud.hide()
                    self.gp_presentMail(with: mediaURLs, subject: "\("i8_key_work_report".localized()) (\(mediaURLs.count))", body: "")
                }
            }
        }
    }

    private func gp_exportZipFilesToEmail(urls: [URL], hud: ZLProgressHUD) {
        do {
            let zipURL = try GPZipTool.gp_makeZip(from: urls)
            DispatchQueue.main.async {
                hud.hide()
                self.gp_presentMail(with: [zipURL], subject: "\("i8_key_work_report".localized()) (\(urls.count))", body: "")
            }
        } catch {
            DispatchQueue.main.async {
                hud.hide()
                UIViewController.show45ButtonAlert(
                    title: "i8_key_failed".localized(),
                    message: error.localizedDescription,
                    buttonTitle: "i8_key_ok".localized()
                )
            }
        }
    }

    private func gp_presentMail(with fileURLs: [URL], subject: String, body: String) {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setSubject(subject)
            mail.setMessageBody(body, isHTML: false)

            for url in fileURLs {
                guard let data = try? Data(contentsOf: url) else { continue }
                let ext = url.pathExtension.lowercased()
                let mime: String
                switch ext {
                case "jpg", "jpeg": mime = "image/jpeg"
                case "png": mime = "image/png"
                case "heic": mime = "image/heic"
                case "tif", "tiff": mime = "image/tiff"
                case "gif": mime = "image/gif"
                case "zip": mime = "application/zip"
                case "mov", "m4v": mime = "video/quicktime"
                case "mp4": mime = "video/mp4"
                case "avi": mime = "video/x-msvideo"
                case "hevc": mime = "video/mp4"
                default: mime = "application/octet-stream"
                }
                mail.addAttachmentData(data, mimeType: mime, fileName: url.lastPathComponent)
            }
            present(mail, animated: true)
        } else {
            // 未配置系统邮箱 → 用系统分享面板（支持 Gmail/企业邮箱 App）
            let activityVC = UIActivityViewController(activityItems: fileURLs, applicationActivities: nil)
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = self.view
                popover.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.maxY - 80, width: 1, height: 1)
            }
            present(activityVC, animated: true)
        }
    }
    
    func onClickZip() {
        let assets = selectedPhotos
        guard !assets.isEmpty else {
            UIViewController.show45ButtonAlert(
                title: "i8_key_tips".localized(),
                message: "i8_key_please_select_photos_first".localized(),
                buttonTitle: "i8_key_ok".localized()
            )
            return
        }

        let hud = ZLProgressHUD.show()
        hud.changeTitle("i8_key_exporting_assets".localized())

        GPZipTool.gp_exportAssetsToZip(assets, progress: { p in
            let progressPercent = Int(p * 100)
            if p < 1.0 {
                let progressText = String(format: "i8_key_exporting".localized(), progressPercent)
                hud.changeTitle(progressText)
            } else {
                hud.changeTitle("i8_key_compressing".localized())
            }
        }, completion: { [weak self] result in
            guard let self = self else { return }
            hud.hide()
            
            switch result {
            case .success(let zipURL):
                GPToast.text("i8_key_zip_complete".localized())
                self.gp_shareZipFile(zipURL)
                
            case .failure(let error):
                UIViewController.show45ButtonAlert(
                    title: "i8_key_failed".localized(),
                    message: error.localizedDescription,
                    buttonTitle: "i8_key_ok".localized()
                )
            }
        })
    }
    
    // 修改分享完成回调，确保分享后也清理文件
    private func gp_shareZipFile(_ zipURL: URL) {
        let activityVC = UIActivityViewController(activityItems: [zipURL], applicationActivities: nil)
        
        activityVC.completionWithItemsHandler = { [weak self] (activityType, completed, returnedItems, error) in
            // 分享完成后清理临时文件
            GPZipTool.gp_cleanupTempZipFile(zipURL)
            
            if completed {
                GPToast.text("i8_key_share_success".localized())
            } else if let error = error {
                print("Share failed: \(error)")
            }
            
            // 额外调用一次全面清理，确保没有遗漏
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                GPZipTool.gp_cleanupAllTempFiles()
            }
        }
        
        // 在iPad上需要设置popoverPresentationController
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        present(activityVC, animated: true)
    }
    
    func buildOrderModel() -> XHPhotoPreviewOrderModel {
        let model = XHPhotoPreviewOrderModel()
        var items: [XHPhotoPreviewOrderItemModel] = []

        func getShareTypeModel(_ type: XHPhotoShowShareType) -> XHPhotoPreviewOrderItemModel {
            let info = type.info
            var shareModel = XHPhotoPreviewOrderModel.createPhotoPreviewOrderItem(
                function: .directShare,
                icon: info.imageName,
                name: "i_share",
                customShareType: type
            )
            if type == .system {
                shareModel = XHPhotoPreviewOrderModel.createPhotoPreviewOrderItem(
                    function: .directShare,
                    name: "i_share",
                    iconFontType: .album_share,
                    customShareType: type
                )
            }
            return shareModel
        }

        func appendShareItem(
            function: PhotoShowBottomViewItemType,
            icon: String,
            name: String,
            shareType: XHPhotoShowShareType? = nil
        ) {
            let item = XHPhotoPreviewOrderModel.createPhotoPreviewOrderItem(
                function: function,
                icon: icon,
                name: name,
                customShareType: shareType
            )
            items.append(item)
        }

        // 第一个分享位
        let countryCode = GPCountryManager.geoCountryCode
        if let country = PhotoShowShareSpecialCountry(rawValue: countryCode),
           let shareType = country.shareTypes.first,
           PhotoShowShareSpecialCountry.supportedCountry().contains(countryCode) {
            appendShareItem(
                function: .directShare,
                icon: shareType.info.imageName,
                name: "i_share",
                shareType: shareType
            )
        } else {
            if let type = XHPhotoShowShareType(rawValue: GPShareManager.photoShowShareTypeCacheKey),
               type.supportInfo().isSupport {
                items.append(getShareTypeModel(type))
            } else {
                items.append(getShareTypeModel(XHPhotoShowShareType.whatsApp))
            }
        }

        // kmz、pdf
        let additionalShareTypes: [XHPhotoShowShareType] = []
        additionalShareTypes.forEach { type in
            let item = XHPhotoPreviewOrderModel.createCustomShareItem(type: type)
            items.append(item)
        }
        
        appendShareItem(function: .email, icon: "icon_share_email", name: "i_email")
        appendShareItem(function: .zip, icon: "icon_zip", name: "k_zip")

        // more
        appendShareItem(function: .more, icon: "edit_tool_border_more", name: "i_share_more")
        
        model.bottom = items
        return model
    }
    
    func showMoreShareView() {
        let supportTypes = GPShareManager.getSupportShareTypes()

        if supportTypes.count <= 1 {
            shareAssets(for: .system, fromMore: true)
            return
        }

        GPPhotoShowShareView.showDefault(in: view, fromPlace: "multiShare") { [weak self] shareType in
            guard let self else { return }

            let supportInfo = shareType.supportInfo()
            guard supportInfo.isSupport else {
                GPToast.text(supportInfo.notSupportToast)
                return
            }
            shareAssets(for: shareType, fromMore: true)
        }

    }

    func toCustomShare(shareType: XHPhotoShowShareType) {
        let supportInfo = shareType.supportInfo()
        guard supportInfo.isSupport else {
            GPToast.text(supportInfo.notSupportToast)
            return
        }
        shareAssets(for: shareType, fromMore: false)
    }
    
    func shareAssets(for shareType: XHPhotoShowShareType, fromMore: Bool) {
        guard !selectedPhotos.isEmpty else {
            GPToast.text("i_select_at_least_1".localized())
            return
        }
        
        Task {
            let result = try await photoManager.fetchMediaFromAssets(selectedPhotos)
            await MainActor.run {
                GPShareManager.shareMultiMedias(result, type: shareType)
            }
        }

    }
    
}

// MARK: CollectionView

extension MultiPhotoShowViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in _: UICollectionView) -> Int {
        sortedDates.count
    }

    func collectionView(_: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let date = sortedDates[section]
        return groupedPhotos[date]?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueCell(MultiPhotoCell.self, for: indexPath)
        cell.delegate = self
        cell.selectHandler = { [weak self] asset in
            guard let self else { return }
            if asset.xhSelected {
                selectedPhotos.append(asset)
            } else if let index = selectedPhotos.firstIndex(of: asset) {
                selectedPhotos.remove(at: index)
            }
            updateFooterLabel()
            updateHeader(asset: asset)
        }
        
        let date = sortedDates[indexPath.section]
        if let asset = groupedPhotos[date]?[indexPath.row] {
            cell.configAsset(asset)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, sizeForItemAt _: IndexPath) -> CGSize {
        let numberOfColumns: CGFloat = 3
        let spacing: CGFloat = 4
        let totalSpacing = (numberOfColumns - 1) * spacing
        let width = (collectionView.bounds.width - totalSpacing) / numberOfColumns
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, layout _: UICollectionViewLayout, referenceSizeForHeaderInSection _: Int) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 52)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        CGSize(width: collectionView.bounds.width, height: 12)
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueHeader(MultiPhotoSectionHeader.self, for: indexPath)
            header.selectAllHandler = { [weak self] in
                guard let self else { return false }
                let date = sortedDates[indexPath.section]
                guard let photos = groupedPhotos[date] else { return false }
                // 检查是否存在未选择的照片
                let hasUnselected = photos.contains { !$0.xhSelected }
                if !hasUnselected {
                    for photo in photos {
                        self.selectedPhotos.removeAll { $0 == photo }
                        photo.xhSelected = false
                    }
                } else {
                    for photo in photos {
                        if shouldSelectPhoto() {
                            if !photo.xhSelected {
                                self.selectedPhotos.append(photo)
                            }
                            photo.xhSelected = true
                        } else {
                            if photos.contains(where: { !$0.xhSelected }) {
                                selectedPhotosReachMaxCount()
                            }
                            break
                        }
                    }
                }
                updateFooterLabel()
                UIView.performWithoutAnimation {
                    self.collectionView.reloadSections(IndexSet(integer: indexPath.section))
                }
                return photos.allSatisfy { $0.xhSelected }
            }
            let date = sortedDates[indexPath.section]
            if let assets = groupedPhotos[date] {
                header.setTitle("\(date.photoDateFormattedString()) (\(assets.count))")
                header.isSelectAll = assets.allSatisfy { $0.xhSelected }
            }
            return header
        } else if kind == UICollectionView.elementKindSectionFooter {
            return collectionView.dequeueFooter(UICollectionReusableView.self, for: indexPath)
        }
        return collectionView.dequeueFooter(UICollectionReusableView.self, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let date = sortedDates[indexPath.section]
        if let cell = collectionView.cellForItem(at: indexPath) as? MultiPhotoCell {
            cell.selectIconViewTapped()
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let threshold: CGFloat = 100.0 // 距离底部多少时加载下一页
        let contentHeight = scrollView.contentSize.height
        let contentOffset = scrollView.contentOffset.y
        let frameHeight = scrollView.frame.size.height

        if contentOffset + frameHeight + threshold > contentHeight {
            loadNextBatch()
        }
    }
}

extension MultiPhotoShowViewController: MultiPhotoSelectProtocol {
    func shouldSelectPhoto() -> Bool {
        selectedPhotos.count < maxCountOfPhotos
    }
    
    func selectedPhotosReachMaxCount() {
        GPToast.text("k_share_200_only".localized())
    }
}

// MFMailComposeViewControllerDelegate
extension MultiPhotoShowViewController: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        controller.dismiss(animated: true) {
            // 邮件发送完成后清理临时文件
            GPZipTool.gp_cleanupAllTempFiles()
            
            switch result {
            case .sent:
                GPToast.text("i8_key_send_email_suc".localized())
            case .saved:
                GPToast.text("i8_key_email_save_draft".localized())
            case .failed:
                if let error = error {
                    GPToast.text("Failed to send email: \(error.localizedDescription)")
                }
            case .cancelled:
                print("Email cancelled")
            @unknown default:
                break
            }
        }
    }
}
