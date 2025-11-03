//
//  GPDateFormat+ID5.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/26.
//

import Foundation

extension GPDateFormat {
    
    static func watermarkUICommpentForID5(with timeItem: WatermarkTimeItem, date: Date = TimeManager.shared.getRealTime()) -> (topExtraDateString: String, bottomDateString: String, hhmm: String) {
        
        var styleType = timeItem.dateStyleEnum
        
        let is12Hours = timeItem.is12Hour ?? false
        let isShowWeek = timeItem.showWeak ?? false
        let isTimeZone = timeItem.showTimeZone ?? false
        
        // 2.9.295:水印上不显示时间
        if TimeManager.shared.isShowTimeOnWatermark() == false {
            
            return (topExtraDateString: "--", bottomDateString: "--", hhmm: "--")
        }
        
        var isUseBuddhist = false
        
        // 国际化日期样式的时候, 而且是泰国才展示佛历年
        if styleType == .yearMonthDateSpecialCountry, deviceLocalIsTh() {
            
            isUseBuddhist = true
        }
        
        let com = dateCommpent(with: date, is12Hours: is12Hours, isUseBuddhist: isUseBuddhist, dateStyle: styleType)
        
        let year = com.year
        let month = com.month
        let shortMonth = com.shortMonth
        let day = com.day
        let week = com.week
        let hh = com.hh
        let mm = com.mm
        let ampm = com.ampm
        
        let hhmm = "\(hh):\(mm)"
        
        var localYear = "i_date_year".localized()
        var localMonth = "i_date_month".localized()
        var localDay = "i_date_day".localized()
        
        if localYear == "i_date_year" {
            localYear = "年"
        }
        
        if localMonth == "i_date_month" {
            localMonth = "月"
        }
        
        if localDay == "i_date_day" {
            localDay = "日"
        }
        
        var bottomDateString = "\(day) \(shortMonth) \(year)"
        switch styleType {
        case .yearMonthDateSpecialCountry: do {
            
            let languageType = GPLanguageManager.localLanguageType()
            
            let shortMonth = com.shortMonth
            var localYear = "i_date_year".localized()
            var localMonth = "i_date_month".localized()
            var localDay = "i_date_day".localized()
            
            if localYear == "i_date_year" {
                localYear = "年"
            }
            
            if localMonth == "i_date_month" {
                localMonth = "月"
            }
            
            if localDay == "i_date_day" {
                localDay = "日"
            }
            
            switch languageType {
            case .chinese, .hanguoyu, .riyu:
                bottomDateString = "\(year)\(localYear)\(month)\(localMonth)\(day)\(localDay)"
            case .english(let type): do {
                switch type{
                case .USA, .MY, .PH:
                    bottomDateString = "\(shortMonth) \(day), \(year)"
                case .Other:
                    bottomDateString = "\(day) \(shortMonth) \(year)"
                }
            }
            case .yinniyu, .xibanyayu, .yindiyu, .taiyu, .malaiyu, .putaoyayu, .eyu, .amuhalayu, .fayu, .tuerqiyu, .yidaliyu, .siwaxiliyu:
                bottomDateString = "\(day) \(shortMonth) \(year)"
            case .yuenanyu:
                bottomDateString = "\(day) \(shortMonth), \(year)"
            case .deyu:
                bottomDateString = "\(day) .\(shortMonth). \(year)"
            default:
                bottomDateString = "\(day) \(shortMonth) \(year)"
            }
        }
        case .monthDayYear:
            bottomDateString = "\(month)/\(day)/\(year)"
        case .dayMonthYear:
            bottomDateString = "\(day)/\(month)/\(year)"
        default:
            bottomDateString = "\(month)/\(day)/\(year)"
        }
        
        var topExtraDateString = ""
        
        if is12Hours == true {
            topExtraDateString.append("\(ampm) ")
        }
        
        if isTimeZone, let abbreviation = TimeManager.shared.getGlobalTimeZoneAbbreviation() {
            
            topExtraDateString.append("\(abbreviation) ")
        }
        
        if isShowWeek {
            topExtraDateString.append(week)
        }
        
        return (topExtraDateString: topExtraDateString, bottomDateString: bottomDateString, hhmm: hhmm)
    }
}
