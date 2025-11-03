//
//  CalendarPhotoCell.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/12/16.
//

import Foundation

import Foundation
import Photos

class CalendarPhotoCell: UICollectionViewCell {
    let unselectedIcon = UIImage(named: "multiphoto_unselected")
    let selectedIcon = UIImage(named: "multiphoto_selected")
    
    let photoManager = MultiPhotoManager()
    var asset: PHAsset?
    var selectHandler: ((PHAsset) -> Void)?
    weak var delegate: MultiPhotoSelectProtocol?
    
    let photoView: UIImageView = {
        let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.contentMode = .scaleAspectFill
        imgView.layer.masksToBounds = true
        return imgView
    }()
    
    let iconBgView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
//    let selectIconView: UIImageView = {
//        let imgView = UIImageView()
//        imgView.translatesAutoresizingMaskIntoConstraints = false
//        imgView.contentMode = .scaleAspectFit
//        imgView.image = UIImage(named: "multiphoto_unselected")
//        return imgView
//    }()
    
    let videoIconView: UIImageView = {
        let imgView = UIImageView()
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.contentMode = .scaleAspectFit
        imgView.image = UIImage(named: "edit_album_video")
        return imgView
    }()
    
    let videoDurationLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 14)
        label.textColor = .white
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(photoView)
        contentView.addSubview(iconBgView)
        //iconBgView.addSubview(selectIconView)
        contentView.addSubview(videoIconView)
        contentView.addSubview(videoDurationLabel)
        photoView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        iconBgView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.size.equalTo(40)
        }
//        selectIconView.snp.makeConstraints { make in
//            make.leading.bottom.equalToSuperview()
//            make.size.equalTo(28)
//        }
        iconBgView.addTapGestureRecognizer(target: self, action: #selector(selectIconViewTapped))
        videoIconView.snp.makeConstraints { make in
            make.leading.equalTo(8)
            make.bottom.equalTo(-7)
            make.size.equalTo(CGSize(width: 20, height: 14))
        }
        videoDurationLabel.snp.makeConstraints { make in
            make.centerY.equalTo(videoIconView.snp.centerY)
            make.leading.equalTo(videoIconView.snp.trailing).offset(8)
        }
    }
    
    func configAsset(_ asset: PHAsset) {
        self.asset = asset

        videoIconView.isHidden = (asset.mediaType == .image)
        videoDurationLabel.isHidden = (asset.mediaType == .image)
        if asset.mediaType == .video {
            videoDurationLabel.text = getVideoDuration(asset: asset)
        }
        
        let currentAsset = asset
        let targetSize = CGSize(width: 100 * UIScreen.main.scale, height: 100 * UIScreen.main.scale)
        photoManager.requestImage(for: asset, targetSize: targetSize) { image in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if self.asset == currentAsset {
                    self.photoView.image = image
                }
            }
        }
        
       // selectIconView.image = asset.xhSelected ? selectedIcon : unselectedIcon
    }
    
    private func getVideoDuration(asset: PHAsset) -> String? {
        let durationInSeconds = asset.duration

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.minute, .second]
        formatter.zeroFormattingBehavior = .pad
        formatter.unitsStyle = .positional
        
        return formatter.string(from: durationInSeconds)
    }

    @objc
    func selectIconViewTapped() {
        guard let asset, let delegate else { return }

        let shouldSelect = !asset.xhSelected && delegate.shouldSelectPhoto()

//        if shouldSelect || asset.xhSelected {
//            asset.xhSelected.toggle()
//            selectIconView.image = asset.xhSelected ? selectedIcon : unselectedIcon
//            selectHandler?(asset)
//        } else {
//            delegate.selectedPhotosReachMaxCount()
//        }
    }
}


class EmptyPhotoCell: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let imageView = UIImageView()
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(pointSize: 50, weight: .light)
            imageView.image = UIImage(systemName: "photo.on.rectangle.angled", withConfiguration: config)
            imageView.tintColor = .gray
        }
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        let label = UILabel()
        label.text = "k_empty_folder".localized()
        label.textColor = .gray
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16)
        label.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(label)

        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(100)
            make.height.equalTo(100)
        }
        label.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(10)
        }
        
    }

}
