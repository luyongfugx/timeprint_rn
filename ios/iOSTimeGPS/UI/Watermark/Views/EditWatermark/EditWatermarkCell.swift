//
//  EditWatermarkCell.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/10.
//

import Foundation
import UIKit
import CoreLocation

class EditWatermarkCell: GPTableviewCell {
    
    static let maxContentWidth = GPApp.screenWidth - 80 - 16 - 20 - 6
    
    var swichBlock: GPBoolBlock?
    var clickOptionBlock: GPVoidBlock?

    private static let rightArrorItems: [WatermarkItemID] = [WatermarkItemID.logo, WatermarkItemID.note, WatermarkItemID.watermarkTitle, WatermarkItemID.watermarkSubtitle, WatermarkItemID.weather, WatermarkItemID.map, WatermarkItemID.time, WatermarkItemID.address, WatermarkItemID.wm7_area, WatermarkItemID.wm7_project, WatermarkItemID.wm7_operator, WatermarkItemID.wm7_developer,
       WatermarkItemID.phoneNumber1, WatermarkItemID.phoneNumber2, WatermarkItemID.serviceDetail1, WatermarkItemID.serviceDetail2, WatermarkItemID.serviceDetail3,
       WatermarkItemID.wm7_inspection, WatermarkItemID.wm7_inspectior, WatermarkItemID.wm7_description, WatermarkItemID.customItem]
    
    lazy var topContentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    lazy var switchBtn: UISwitch = {
        let switchBtn = UISwitch()
        switchBtn.translatesAutoresizingMaskIntoConstraints = false
        switchBtn.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
        return switchBtn
    }()
    
    lazy var switchBGView: UIView = {
        return UIView(frame: .zero)
    }()
    
    var contentLabel: GPQStickerLabel = {
        let label = GPQStickerLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    var nextLabel: UILabel = {
        var iconType: IconFontType = isRTL() ? .btn_back : .btn_next
        let label = UILabel.iconLabel(fontSize: 20, labelWidth: 20, iconType: iconType)
        label.textColor = .text_black_color
        return label
    }()
    
    var weatherLabel: UILabel = {
        let label = UILabel()
        label.isHidden = true
        label.font = .systemFont(ofSize: 10)
        label.text = " Apple Weather"
        label.textColor = .text_weak
        return label
    }()
    
    var addLogoLabel: UILabel = {
        let label = UILabel.iconLabel(fontSize: 24, labelWidth: 24, iconType: .btn_add_logo)
        label.textColor = .text_black_color
        return label
    }()
    
    private lazy var logoImgView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.clipsToBounds = true
        return imgView
    }()
    
    var quickOptionView: QuickOptionListView?
    var itemModel: WatermarkItem?
    var baseID: WatermarkModelBaseID?
    
    override func buildUI() {
        super.buildUI()
             
        contentView.addSubview(topContentView)
        topContentView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        topContentView.addSubview(switchBtn)
        switchBtn.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.centerY.equalToSuperview()
        }
        switchBtn.transform = .init(scaleX: 0.8, y: 0.8)
        
        topContentView.insertSubview(switchBGView, belowSubview: switchBtn)
        switchBGView.addTapGestureRecognizer(target: self, action: #selector(clickSwithBG))
        switchBGView.isUserInteractionEnabled = true
        switchBGView.snp.makeConstraints { make in
            make.leading.equalTo(0)
            make.trailing.equalTo(switchBtn.snp.trailing).offset(12)
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        topContentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.leading.equalTo(80)
            make.trailing.equalTo(-16 - 20 - 6)
            make.centerY.equalToSuperview()
        }
        
        topContentView.addSubview(nextLabel)
        nextLabel.snp.makeConstraints { make in
            make.trailing.equalTo(-16)
            make.centerY.equalToSuperview()
        }
        
        topContentView.addSubview(weatherLabel)
        weatherLabel.snp.makeConstraints { make in
            make.trailing.equalTo(nextLabel.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
        }
        
        topContentView.addSubview(addLogoLabel)
        addLogoLabel.snp.makeConstraints { make in
            make.trailing.equalTo(-16 - 20 - 12)
            make.centerY.equalToSuperview()
        }
        
        topContentView.addSubview(logoImgView)
        logoImgView.isHidden = true
        logoImgView.snp.makeConstraints { make in
            make.trailing.equalTo(-16 - 20 - 12)
            make.width.equalTo(28)
            make.top.equalTo(2)
            make.bottom.equalTo(-2)
        }
        
    }
    
    func configModel(baseID: WatermarkModelBaseID?, item: WatermarkItem, block: GPBoolBlock?, clickOptionBlock: GPVoidBlock?) {
        self.swichBlock = block
        self.clickOptionBlock = clickOptionBlock
        self.baseID = baseID
        if item.isOpen == true {
            switchBtn.isOn = true
            contentLabel.textColor = UIColor.text_black_color
        } else {
            switchBtn.isOn = false
            contentLabel.textColor = UIColor.text_grey_color
        }
        let itemContent = item.getShowText(baseID: baseID)
        contentLabel.text = itemContent
        
        // Logo
        addLogoLabel.isHidden = true
        logoImgView.isHidden = true
        if item.idType == .logo {
            var logoImg = item.getLogo()
            if baseID == .ID7 {
                logoImg = item.extraLogoListInfo.getFirstImg()
            }
            if let logoImg {
                addLogoLabel.isHidden = true
                logoImgView.isHidden = false
                logoImgView.image = logoImg
            } else {
                addLogoLabel.isHidden = false
                logoImgView.isHidden = true
                logoImgView.image = nil
            }
        }
        
        // 是否可编辑条目
        if item.idType == .time {
            switchBtn.isOn = true
            switchBtn.isEnabled = false
        } else {
            switchBtn.isEnabled = true
        }
        
        if [.ID13, .ID14].contains(baseID) {
            if [WatermarkItemID.time, WatermarkItemID.address, WatermarkItemID.map, WatermarkItemID.coordinate].contains(item.idType) {
                switchBtn.isOn = true
                switchBtn.isEnabled = false
            }
        }
        
        weatherLabel.isHidden = item.idType != .weather
        
        // 右边箭头
        nextLabel.isHidden = !EditWatermarkCell.rightArrorItems.contains(item.idType)
        if item.idType == .address {
            nextLabel.isHidden = !GPSGeoManager.wartermarkGPSInfo.canEditAddress
        }
        if let _quickOptionView = quickOptionView {
            _quickOptionView.removeFromSuperview()
            quickOptionView = nil
        }
        let favoriteTexts = item.getItemContentFavoriteHistory()
        if !favoriteTexts.isEmpty {
            let calHeight = QuickOptionListView.calculateHeight(items: favoriteTexts, maxWidth2: EditWatermarkCell.maxContentWidth)
            let _quickOptionView = QuickOptionListView(maxWidth: Self.maxContentWidth, items: favoriteTexts, selectedItem: item.content) { [weak self] chooseText in
                item.content = chooseText
                self?.contentLabel.text = itemContent
                self?.clickOptionBlock?()
            }
            quickOptionView = _quickOptionView
            contentView.addSubview(_quickOptionView)
            _quickOptionView.snp.makeConstraints { make in
                make.leading.equalTo(contentLabel.snp.leading)
                make.trailing.equalTo(contentLabel.snp.trailing)
                make.top.equalTo(50)
                make.height.equalTo(calHeight)
            }
        }
                
    }
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        swichBlock?(sender.isOn)
    }
    
    @objc
    func clickSwithBG() {
        
    }
}
