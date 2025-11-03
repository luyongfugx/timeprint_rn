//
//  CLCalendarModel.swift
//  Created by waynelu on 2024/12/16.
//

import UIKit
import Photos

struct CLCalendarDayModel {
    enum CLCalendarDayType {
        case empty
        case past
        case today
        case future
    }

    var title: String?
    var date: Date?
    var type: CLCalendarDayType = .empty
    var assets: [PHAsset]? //图片
}

struct CLCalendarMonthModel {
    var headerText = ""
    var month = ""
    
    var daysArray = [CLCalendarDayModel]()
}
