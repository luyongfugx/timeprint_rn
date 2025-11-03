//
//  GPGoogleSearchLogoCell.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/17.
//

import Foundation
import UIKit

class GPGoogleSearchLogoCell: UICollectionViewCell {
    
    var logoImageView: UIImageView?
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buildUI() {
        contentView.layerCornerRadius = 4.0
        contentView.backgroundColor = UIColor.black.withAlphaComponent(0.05)

        logoImageView = UIImageView(frame: .zero)
        logoImageView?.contentMode = .scaleAspectFit
        contentView.addSubview(logoImageView!)
        logoImageView?.layerCornerRadius = 4.0
        logoImageView?.snp.makeConstraints { make in
            make.left.top.equalTo(4)
            make.right.bottom.equalTo(-4)
        }        
    }
    
}
