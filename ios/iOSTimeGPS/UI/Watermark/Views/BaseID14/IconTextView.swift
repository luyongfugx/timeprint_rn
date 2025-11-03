//
//  IconTextView.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/4/4.
//

import Foundation
import UIKit

class IconTextView: GPView {
    
    static let btnWidth = 32.0
    static let logoBtnHeight = 26.0

    lazy var iconImageV: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.image = UIImage(named: "basic_list_cell_rightArrow")
        return imgView
    }()
    
    lazy var label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white
        label.text = "i_feedback".localized()
        label.lineBreakMode = .byWordWrapping
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.2
        label.numberOfLines = 1
        return label
    }()
            
    override func buildUI() {
        addSubview(iconImageV)
        iconImageV.snp.makeConstraints { make in
            make.left.equalTo(0)
            make.width.height.equalTo(24)
        }
        addSubview(label)
        label.snp.makeConstraints { make in
            make.left.equalTo(iconImageV.snp.right).offset(4)
            make.centerY.equalTo(iconImageV.snp.centerY)
            make.right.equalTo(-4)
        }
    }
    
}
