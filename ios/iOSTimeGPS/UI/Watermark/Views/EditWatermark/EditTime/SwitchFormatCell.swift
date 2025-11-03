//
//  SwitchFormatCell.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/1.
//

import Foundation
import UIKit

class SwitchFormatCell: GPTableviewCell {
    
    var swichBlock: GPBoolBlock?

    private(set) lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = .text_black_color
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 1
        return label
    }()
    
    lazy var switchBtn: UISwitch = {
        let switchBtn = UISwitch()
        switchBtn.translatesAutoresizingMaskIntoConstraints = false
        switchBtn.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
        return switchBtn
    }()
    
    override func buildUI() {
        super.buildUI()
        contentView.addSubview(contentLabel)
        contentView.addSubview(switchBtn)
                
        contentLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-52)
        }
        
        switchBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }
    }
    
    func configData(_ isOpen: Bool, _ text: String) {
        switchBtn.isOn = isOpen
        contentLabel.text = text
    }
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        swichBlock?(sender.isOn)
    }
}
