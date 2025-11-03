//
//  GPTableviewCell.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/29.
//

import Foundation
import UIKit

class GPTableviewCell: UITableViewCell {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        buildUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func buildUI() {
        self.selectionStyle = .none
        backgroundColor = UIColor.white
        contentView.backgroundColor = UIColor.clear
    }
}
