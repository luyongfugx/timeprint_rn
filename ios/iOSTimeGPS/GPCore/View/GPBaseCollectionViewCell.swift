//
//  GPBaseCollectionViewCell.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/2.
//

import Foundation
import UIKit

class GPBaseCollectionViewCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buildUI() {
        
    }
}
