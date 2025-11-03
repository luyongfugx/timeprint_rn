//
//  WatermarkCoverModel.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/9/16.
//

import Foundation

class WatermarkCoverModel: NSObject, GPCodable {
    
    var isSelect: Bool?
    // 水印名称
    var name: String?
    var cover: String?
    var aspectRatio: CGFloat?// 水印封面宽高比
    var watermark: String?
    var watermarkModel: BaseWatermarkModel? {
        get {
            if let _watermarkModel {
                return _watermarkModel
            } else {
                _watermarkModel = SpeedyModel.anyToModel(BaseWatermarkModel.self, param: watermark ?? "")
                return _watermarkModel
            }
        } set {
            _watermarkModel = newValue
        }
    }
    private var _watermarkModel: BaseWatermarkModel?
}
