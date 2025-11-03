//
//  ChooseFormatCell.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/1.
//

import Foundation
import UIKit

class ChooseFormatCell: GPTableviewCell {
    
    var chooseBlock: GPVoidBlock?

    private(set) lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textColor = .text_black_color
        label.font = .systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    
    private(set) lazy var selectIndicator: UILabel = {
        return UILabel.chooseIconLabel(fontSize: 22, labelWidth: 22)
    }()
    
    override func buildUI() {
        super.buildUI()
        contentView.addSubview(contentLabel)
        contentView.addSubview(selectIndicator)
        contentView.addTapGestureRecognizer(target: self, action: #selector(tapCell))
        selectIndicator.isHidden = true
        
        contentLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-52)
        }
        
        selectIndicator.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }
    }
    
    func configData(isSelect: Bool, text: String) {
        contentLabel.text = text
        contentLabel.textColor = isSelect ? .systemBlue: .text_black_color
        selectIndicator.isHidden = !isSelect
    }
    
    static func getCellHeight(_ text: String) -> CGFloat {
        let size = text.size(WithFont: .systemFont(ofSize: 16), ConstrainedToWidth: GPApp.screenWidth - 16 - 52)
        return size.height + 36
    }
    
    @objc
    func tapCell() {
        chooseBlock?()
    }
}
