//
//  CLCalendarCell.swift
//  Created by waynelu on 2024/12/16.
//

import SnapKit
import UIKit
import Photos


class CLCalendarCell: UICollectionViewCell {
    static let reuseIdentifier = "CLCalendarCell"

    private lazy var mainStackView: UIView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.distribution = .fill
        view.alignment = .center

        view.insetsLayoutMarginsFromSafeArea = false
        view.isLayoutMarginsRelativeArrangement = true
        let margin: CGFloat = 10
        view.layoutMargins = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
        return view
    }()
    let imageView = UIImageView()
    let bgColorView = UIView()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.textAlignment = .center
        return view
    }()


    override init(frame: CGRect) {
        super.init(frame: frame)
        configUI()
        makeConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension CLCalendarCell {
    func configUI() {
        backgroundColor = .clear
        clipsToBounds = true
        contentView.addSubview(mainStackView)
       
   
        mainStackView.addSubview(imageView)
        mainStackView.addSubview(bgColorView)
        bgColorView.layer.cornerRadius = 5
        mainStackView.addSubview(titleLabel)
    }

    func makeConstraints() {
        mainStackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

extension CLCalendarCell {
    func refreshData(_ model: CLCalendarDayModel, config: CLCalendarConfig, startDate: Date?, endDate: Date?,itemSize : CGSize) {
        isUserInteractionEnabled = {
            guard let date = model.date else { return false }
            if let limitBegin = config.limitBegin,
               date.isEarlier(than: limitBegin)
            {
                return false
            } else if let limitEnd = config.limitEnd,
                      date.isLater(than: limitEnd)
            {
                return false
            }
            return true
        }()
        backgroundColor = (model.type == .empty || isUserInteractionEnabled) ? .clear : config.color.failureBackground
        self.bgColorView.layer.cornerRadius = 5
        self.bgColorView.layer.borderWidth = 2
        self.bgColorView.layer.borderColor = UIColor.clear.cgColor
        let bgWidth = itemSize.width-10
        let bgHeight = itemSize.height-10
        if(model.type != .empty ){
            self.bgColorView.frame = .init(x: 0-(bgWidth/2), y:  0-(bgHeight/2), width: bgWidth, height: bgHeight)
            self.bgColorView.backgroundColor =  UIColor.fromHex("#101010")
        }
        else {
            self.bgColorView.frame = .init(x: 0-(bgWidth/2), y:  0-(bgHeight/2), width: bgWidth, height: bgHeight)
            self.bgColorView.backgroundColor = .clear
        }

        titleLabel.text = model.title
        titleLabel.textColor = config.color.titleText

   
        
        imageView.image = nil
        if let assets = model.assets, !assets.isEmpty {
            let firstAsset = assets[0] // Get the first asset
            let imageManager = PHImageManager.default()
            let requestOptions = PHImageRequestOptions()
            requestOptions.isSynchronous = true // Synchronous request for simplicity
            imageManager.requestImage(for: firstAsset, targetSize: imageView.bounds.size, contentMode: .aspectFill, options: requestOptions) { [weak self] (image, _) in
                // Set the image to the imageView
                self?.imageView.image = image
                let imageWidth = itemSize.width-10
                let imageHeight = itemSize.height-10
                self?.bgColorView.backgroundColor = .clear
                self?.imageView.frame = .init(x: 0-(imageWidth/2), y:  0-(imageHeight/2), width: imageWidth, height: imageHeight)
                self?.imageView.contentMode = .scaleAspectFill // Ensure the image fills the view while maintaining aspect ratio
                self?.imageView.clipsToBounds = true // Clip any excess image
                self?.imageView.backgroundColor = .clear
                self?.imageView.layer.cornerRadius = 3
            }
        }
      
        guard model.type != .empty else {
            return
        }
        if model.date == startDate || model.date == endDate {
            titleLabel.textColor = config.color.selectTitleText
            backgroundColor = model.date == startDate ? config.color.selectStartBackground : config.color.selectEndBackground
            layer.cornerRadius = 5
            self.bgColorView.layer.borderColor = UIColor.white.cgColor
            let isAllCorners = config.selectType == .single

            layer.maskedCorners = isAllCorners ? [.layerMinXMinYCorner, .layerMinXMaxYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner] : (model.date == startDate ? [.layerMinXMinYCorner, .layerMinXMaxYCorner] : [.layerMaxXMinYCorner, .layerMaxXMaxYCorner])
        } else if let date = model.date,
                  let start = startDate,
                  let end = endDate,
                  date > start,
                  date < end
        {
 
            titleLabel.textColor = isUserInteractionEnabled ? config.color.titleText : config.color.failureTitleText
            backgroundColor = isUserInteractionEnabled ? config.color.selectBackground : config.color.failureBackground
        }
    }
}
