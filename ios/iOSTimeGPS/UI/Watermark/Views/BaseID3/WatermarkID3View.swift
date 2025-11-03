//
//  WatermarkID3View.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/20.
//

import Foundation
class WatermarkID3View: WatermarkID2View {
    
    override var themeColor: UIColor {
        return UIColor.fromHex("#0075FF")
    }
    
    override func buildUI() {
        super.buildUI()
        titleLab.text = "k_clock_out".localized()
    }
    
    override var gradientColors: [UIColor] {
        return [.fromHex("#0075FF"), .fromHex("#0059C1")]
    }
}
