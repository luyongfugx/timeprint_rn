//
//  WatermarkID10View.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/12/18.
//

import Foundation



import Foundation
import UIKit
/**
 icon 类型的 水印都可以继承 BaseIconWatermarkView
 */
class WatermarkID10View: BaseIconWatermarkView{
    override var markNameKey: String {
          return "i_watermark_clean"
      }
    
    override var imageName : String  {
        return "clean"
    }
    
    override var textColor: UIColor {
        return UIColor.white
    }
    // 主题色
    override var themeColor: UIColor {
        return UIColor.systemBlue
    }
    //背景色
    override var bgColor: UIColor {
        return .gray.withAlphaComponent(0.9)
    }
    
}
    
   
