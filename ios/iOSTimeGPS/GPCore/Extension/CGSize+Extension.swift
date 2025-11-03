//
//  CGSize+Extension.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/3.
//

import Foundation

extension CGSize {
    
    /*
     * 非零值 3.0.16：解决iOS17调用UIGraphicsBeginImageContext，由于size是0导致的崩溃
     * 3.0.108版本：处理isNaN的情况（NaN，是Not a Number的缩写），这种情况发生的场景是：0除以0
     */
    var nonzeroSize: CGSize {
        
        var w = self.width
        if w == 0 || w.isNaN {
            w = 1
        }
        
        var h = self.height
        if h == 0 || h.isNaN {
            h = 1
        }
        return CGSize(width: w, height: h)
    }
}
