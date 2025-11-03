//
//  AlbumBottomView.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/2.
//

import UIKit

class XHPhotoShowButtonCell: GPBaseCollectionViewCell {
    
    static let cellIdentifier = "XHPhotoShowButtonCell"
    
    private(set) var icon: UIImageView!
    private(set) var titleLabel: UILabel!
    
    override func buildUI() {
        clipsToBounds = false
        icon = UIImageView(frame: .zero).then({
            addSubview($0)
            $0.contentMode = .scaleAspectFit
            $0.clipsToBounds = false
            $0.snp.makeConstraints { make in
                make.top.centerX.equalToSuperview()
                make.size.equalTo(CGSize(width: 36, height: 36))
            }
        })
        
        titleLabel = UILabel(text: "", textColor: .white, textFont: UIFont.regular(12)).then({
            addSubview($0)
            $0.textAlignment = .center
            $0.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(icon.snp.bottom).offset(6)
            }
        })
    }
    
    func config(with model: XHPhotoPreviewOrderItemModel, isMultiChoose: Bool) {
        let type = PhotoShowBottomViewItemType.fromModel(model)
        if let iconFontType = model.iconFontType {
            icon.image = GPButton.createImage(size: .init(width: 24, height: 24), iconType: iconFontType, imgColor: .white)
            icon.snp.remakeConstraints { make in
                make.top.equalTo(3)
                make.centerX.equalToSuperview()
                make.size.equalTo(CGSize(width: 30, height: 30))
            }
        } else {
            let localIconName = type?.iconName ?? ""
            let iconName = model.icon.or(localIconName)
            icon.image = UIImage(named: iconName)
            icon.snp.remakeConstraints { make in
                make.top.centerX.equalToSuperview()
                make.size.equalTo(CGSize(width: 36, height: 36))
            }
        }
        
        titleLabel.text = model.name?.localized()
//        if type == .defaultShare && !isMultiChoose {
//            icon.showRedPoint(pointCenter: .init(x: 36, y: 0))
//        } else {
//            icon.hideRedPoint()
//        }
    }
}

enum PhotoShowBottomViewItemType: String {
    case more       // 通过分享弹窗XHPhotoShowShareView进行分享
    case delete             // 删除照片
    case directShare        // 直接通过对应shareType分享
    case toMultiPhoto       // 跳转多图预览
    case edit             // 编辑照片
    case zip               // zip 压缩
    case email
    
    // 兜底的图标名
    var iconName: String {
        switch self {
        case .more, .directShare:
            return "share"
        case .edit:
            return "edit_icon"
        case .delete:
            return "del"
        case .email:
            return "icon_share_email"
        case .zip:
            return "icon_zip"
        case .toMultiPhoto:
            return "logo_googlemap"
        }
    }
    
    static func fromModel(_ item: XHPhotoPreviewOrderItemModel) -> PhotoShowBottomViewItemType? {
        if let function = item.function {
            return PhotoShowBottomViewItemType(rawValue: function)
        }
        return nil
    }
}

class AlbumBottomView: GPView {
    var isVideo = false
    
    var onSelect: ((PhotoShowBottomViewItemType, XHPhotoShowShareType?) -> ())?

    var bottomCollection: UICollectionView!
    
    var isMultiChoose: Bool = false
    
    private(set) var bottomModel = Array<XHPhotoPreviewOrderItemModel>()
    
    convenience init(config model: XHPhotoPreviewOrderModel?, isMultiChoose: Bool) {
        self.init()
        self.backgroundColor = .black
        self.isMultiChoose = isMultiChoose
        self.reload(with: model)
    }
    
    func reload(with model: XHPhotoPreviewOrderModel?) {
        if let bottom = model?.bottom, !bottom.isEmpty {
            bottomModel = bottom
        }
        reloadCollectionView()
    }
    
    override func buildUI() {
        super.buildUI()

        bottomCollection = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout()).then({
            addSubview($0)
            $0.delegate = self
            $0.dataSource = self
            $0.clipsToBounds = false
            $0.backgroundColor = UIColor.black
            $0.register(XHPhotoShowButtonCell.self, forCellWithReuseIdentifier: XHPhotoShowButtonCell.cellIdentifier)
            $0.snp.makeConstraints { make in
                make.top.equalTo(8)
                make.left.right.equalToSuperview()
                make.height.equalTo(75)
            }
        })
        reloadCollectionView()
    }
    
    func updateUI(isVideo:Bool) {
        if self.isVideo == isVideo {
            return
        }
        self.isVideo = isVideo
        reloadCollectionView()
    }
    
    func reloadCollectionView() {
        bottomCollection.reloadData()
    }
}

extension AlbumBottomView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return bottomModel.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: XHPhotoShowButtonCell.cellIdentifier, for: indexPath) as? XHPhotoShowButtonCell,
           let model = bottomModel[safe: indexPath.item] {
            cell.config(with: model, isMultiChoose: isMultiChoose)
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets.zero
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = GPApp.screenWidth / CGFloat(bottomModel.count)
        return CGSize(width: width, height: 64)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let item = bottomModel[safe: indexPath.item] else {
            return
        }
            
        if let type = PhotoShowBottomViewItemType.fromModel(item) {
            if type == .more && !isMultiChoose {
                reloadCollectionView()
            }
            onSelect?(type, item.customShareType)
        }
    }
}
