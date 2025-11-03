//
//  AddWatermarkCell.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/13.
//


import Foundation
import UIKit

class AddWatermarkCell: GPTableviewCell {
    
    var addIconLabel: UILabel = {
        let label = UILabel.iconLabel(fontSize: 20, labelWidth: 20, iconType: .btn_add_item)
        label.textColor = .button_blue
        return label
    }()
        
    var contentLabel: GPQStickerLabel = {
        let label = GPQStickerLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = .button_blue
        label.text = "k_custom_item".localized()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
        
    override func buildUI() {
        super.buildUI()
        contentView.addSubview(addIconLabel)
        addIconLabel.snp.makeConstraints { make in
            make.left.equalTo(30)
            make.centerY.equalToSuperview()
        }
        
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.left.equalTo(80)
            make.right.equalTo(-16 )
            make.centerY.equalToSuperview()
        }
        
    }
        
}
