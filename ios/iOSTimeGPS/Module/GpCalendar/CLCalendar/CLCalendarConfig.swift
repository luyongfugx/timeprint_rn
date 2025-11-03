//
//  CLCalendarConfig.swift
//  Created by waynelu on 2024/12/16.
//
import DateToolsSwift
import UIKit

struct CLCalendarConfig {
    enum CLSelectType {
        case single
        case area
    }
   // UIColor.fromHex("#000000").cgColor
    struct CLColor {
        var background = UIColor.fromHex("#000000")
        var topToolBackground = UIColor.fromHex("#000000")
        var topToolText = UIColor.fromHex("#ffffff")
        var topToolTextWeekend = UIColor.fromHex("#ffffff")
        var sectionBackgroundText = UIColor.fromHex("f2f2f2")
        var selectStartBackground = UIColor.fromHex("#000000")
        var selectBackground = UIColor.fromHex("#000000")
        var selectEndBackground = UIColor.fromHex("#000000")
        var todayText = UIColor.fromHex("#facc15")
        var titleText = UIColor.fromHex("#404040")
        var headerTextColor = UIColor.fromHex("#353A55")
        var subtitleText = UIColor.fromHex("#555555")
        var selectTodayText = UIColor.fromHex("#32cd32")
        var selectTitleText = UIColor.fromHex("#ffffff")
        var selectSubtitleText = UIColor.fromHex("#ffffff")
        var failureTitleText = UIColor.fromHex("#a9a9a9")
        var failureSubtitleText = UIColor.fromHex("#a9a9a9")
        var failureBackground = UIColor.fromHex("#dcdcdc32")
    }

    var color = CLColor()
    var selectBegin: Date?
    var selectEnd: Date?
    var beginDate = Date() - 12.months
    var endDate = Date()
    var position = Date()
    var selectType = CLSelectType.single
    var limitBegin: Date?
    var limitEnd: Date?
    var isShowLunarCalendar = true
    var insetsLayoutMarginsFromSafeArea = true
    var layoutMargins = UIEdgeInsets.zero
    var headerHight = 50.0
}
