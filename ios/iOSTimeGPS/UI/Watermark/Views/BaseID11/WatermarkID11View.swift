//
//  WatermarkID11View.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/12/19.
//

import Foundation
class WatermarkID11View: BaseIconWatermarkView{
    //override var markNameKey:String = "i_watermark_receipt"
    override var markNameKey: String {
            return "i_watermark_receipt"
        }
    
    override var themeColor: UIColor {
        return UIColor.systemGreen
    }
    
    override var imageName : String  {
        return "receipt"
    }
    
    override var textColor: UIColor {
        return UIColor.white
    }

    //背景色
    override var bgColor: UIColor {
        return .gray.withAlphaComponent(0.9)
    }
    
}
    
