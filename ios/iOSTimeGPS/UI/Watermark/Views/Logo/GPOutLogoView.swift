//
//  GPOutLogoView.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/6.
//

import Foundation
import UIKit

class GPOutLogoView: GPView {
    
    lazy var imgView: UIImageView = {
        let _imageView = UIImageView(frame: .zero)
        return _imageView
    }()
    
    override func buildUI() {
        super.buildUI()
        addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
}
