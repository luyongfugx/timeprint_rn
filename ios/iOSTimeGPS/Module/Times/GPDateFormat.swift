//
//  GPDateFormat.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/18.
//

import Foundation

enum GPDateStyle: Int {
    // yy/mm/dd
    case yearMonthDateSpecialCountry = 0
    // dd/mm/yy
    case dayMonthYear = 1
    // mm/dd/yy
    case monthDayYear = 2
    
    func getDateFmt() -> String {
        var dateFmt = "dd/MM/yyyy"
        switch self {
        case .dayMonthYear:
            dateFmt = "dd/MM/yyyy"
        case .monthDayYear:
            dateFmt = "MM/dd/yyyy"
        case .yearMonthDateSpecialCountry:
            dateFmt = "yyyy/MM/dd"
        }
        return dateFmt
    }
}

enum GPID9DateStyle: Int {
    // yy/mm/dd
    case yearMonthDate = 0
    // dd/mm/yy
    case dayMonthYear = 1
    // mm/dd/yy
    case monthDayYear = 2
}

enum GPDateExtenstionStyle: Int {
    case weak = 0
    case hour = 1
    case timezone = 2
}

struct GPDateCommpent {
    
    var year: String
    var month: String
    var shortMonth: String
    var day: String
    var week: String
    var hh: String
    var mm: String
    // add ss for 秒
    var ss: String
    var ampm: String
    // 18/08/2024
    var date: String
}

class GPDateFormat {
    
    static func deviceLocalIsTh() -> Bool {
        GPLanguageManager.contryISOCode() == "TH"
    }
    
    static func localizedDateString(_ date: Date, style: GPDateStyle, is12Hours: Bool?, isShowWeek: Bool?, isShowTimezone: Bool?, baseID: WatermarkModelBaseID? = nil,needSecond:Bool = false,onlyYearMonthDay:Bool = false) -> String? {
        
        let isTh = deviceLocalIsTh()
        
        switch style {
        case .yearMonthDateSpecialCountry: do {
            return localDateString(date, isShowWeek: isShowWeek ?? false, is12Hours: is12Hours, isShowTimeZone: isShowTimezone, isUseBuddhist: isTh, dateStyle: style, baseID: baseID,needSecond: needSecond,onlyYearMonthDay:onlyYearMonthDay)
        }
        case .dayMonthYear, .monthDayYear: do {
            
            let com = dateCommpent(with: date, is12Hours: is12Hours, isUseBuddhist: isTh, dateStyle: style)
            
            let year = com.year
            let month = com.month
            //let shortMonth = com.shortMonth
            let day = com.day
            let week = com.week
            let hh = com.hh
            let mm = com.mm
            // second
            let ss = com.ss
            let ampm = com.ampm
            let timezone: String = TimeManager.shared.getGlobalTimeZone().abbreviation() ?? ""

            let hhmm = "\(hh):\(mm)\(is12Hours == true ? " \(ampm)" : "")\(isShowTimezone == true ? " \(timezone)" : "")"
            let hhmmss = "\(hh):\(mm):\(ss)\(is12Hours == true ? " \(ampm)" : "")\(isShowTimezone == true ? " \(timezone)" : "")"
            let weekString = isShowWeek == true ? "\(week), " : ""
            
            if style == .dayMonthYear {
                
                // "dd/MM/yyyy HH:mm" or  "dd/MM/yyyy HH:mm:ss"
                let result = "\(weekString)\(day)/\(month)/\(year)"
                
                //                switch templateType {
                //                case .ID43:
                //                    return "\(is12Hours == true ? " \(ampm) " : "")" + "\(weekString)\(day)/\(month)/\(year)"
                //                default:
                //                    return "\(result) \(hhmm)"
                //                }
                // add needSecond
                return "\(result) \(needSecond ? hhmmss : hhmm)"
            } else {
                
                // MM/dd/yyyy HH:mm  or MM/dd/yyyy HH:mm:ss
                let result = "\(weekString)\(month)/\(day)/\(year)"
                
                //                switch templateType {
                //                case .ID43:
                //                    return "\(is12Hours == true ? " \(ampm) " : "")" + "\(weekString)\(month)/\(day)/\(year)"
                //                default:
                //                    return "\(result) \(hhmm)"
                //                }
                
                return "\(result) \(needSecond ? hhmmss : hhmm)"
            }
        }
        }
    }
    
    private static func localDateString(_ date: Date, isShowWeek: Bool, is12Hours: Bool?, isShowTimeZone: Bool?, isUseBuddhist: Bool, dateStyle: GPDateStyle, baseID: WatermarkModelBaseID? = nil,needSecond:Bool = false,onlyYearMonthDay:Bool = false) -> String {
        
        let com = dateCommpent(with: date, is12Hours: is12Hours, isUseBuddhist: isUseBuddhist, dateStyle: dateStyle)
        
        let year = com.year
        let month = com.month
        let shortMonth = com.shortMonth
        let day = com.day
        let week = com.week
        let hh = com.hh
        let mm = com.mm
        let ss = com.ss
        let ampm = com.ampm
        let timezone: String = TimeManager.shared.getGlobalTimeZone().abbreviation() ?? ""
        
        let hhmm = "\(hh):\(mm)\(is12Hours == true ? " \(ampm)" : "")\(isShowTimeZone == true ? " \(timezone)" : "")"
        let hhmmss = "\(hh):\(mm):\(ss)\(is12Hours == true ? " \(ampm)" : "")\(isShowTimeZone == true ? " \(timezone)" : "")"
        
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
        
        let languageType = GPLanguageManager.localLanguageType()
        
        switch languageType {
        case .chinese, .hanguoyu, .riyu: do {
            
            /* 优化历史遗留问题
             日语,韩语,中文时, 星期是排在后面, 其他语言星期都是在前面, 80水印的历史逻辑会给截断了, 星期几会截没
             技术优化方案:
             1.  星期放在前面   可以跟2.0.60 版本
             2.  针对80特殊水印特殊定制兼容,  预计能跟2.0.65 版本.
             
             old
             let result = "\(year)\(localYear)\(month)\(localMonth)\(day)\(localDay)\(isShowWeek ? ", \(week)" : "")"
             */
            
            let result = "\(year)\(localYear)\(month)\(localMonth)\(day)\(localDay)\(isShowWeek ? ", \(week)" : "")"
            //只显示年月日
            if(onlyYearMonthDay){
                return "\(year)\(localYear)\(month)\(localMonth)\(day)\(localDay)"
            }
            
            //            switch templateType {
            //            //V2.0.65 针对80特殊水印特殊定制兼容处理完成, 此处特殊处理不需要了.
            //            // case .ID1080:
            //                //return "\(isShowWeek ? "\(week), " : "")\(year)\(localYear)\(month)\(localMonth)\(day)\(localDay)"
            //            case .ID43:
            //                return "\(is12Hours == true ? " \(ampm) " : "")" + "\(isShowWeek ? "\(week), " : "")\(year)\(localYear)\(month)\(localMonth)\(day)\(localDay)"
            //            default:
            //                return "\(result) \(hhmm)"
            //            }
            return "\(result) \(needSecond ? hhmmss : hhmm)"
        }
        case .english(let type): do {
            switch type{
            case .USA, .MY, .PH:
                let result = "\(isShowWeek ? "\(week), " : "")\(shortMonth) \(day), \(year)"
                
                //只显示年月日
                if(onlyYearMonthDay){
                    return "\(shortMonth) \(day), \(year)"
                }
                
                //                switch templateType {
                //                case .ID43:
                //                    return "\(is12Hours == true ? " \(ampm) " : "")" + "\(isShowWeek ? "\(week), " : "")\(shortMonth) \(day), \(year)"
                //                default:
                //                    return "\(result) \(hhmm)"
                //                }
                return "\(result) \(needSecond ? hhmmss : hhmm)"
            case .Other:
                
                let result = "\(isShowWeek ? "\(week), " : "")\(day) \(shortMonth) \(year)"
                
                //                switch templateType {
                //                case .ID43:
                //                    return "\(is12Hours == true ? " \(ampm) " : "")" + "\(isShowWeek ? "\(week), " : "")\(day) \(shortMonth) \(year)"
                //                default:
                //                    return "\(result) \(hhmm)"
                //                }
                return "\(result) \(needSecond ? hhmmss : hhmm)"
            }
        }
        case .yinniyu, .xibanyayu, .yindiyu, .taiyu, .malaiyu, .putaoyayu, .eyu, .amuhalayu, .fayu, .tuerqiyu, .yidaliyu, .siwaxiliyu: do {
            let result = "\(isShowWeek ? "\(week), " : "")\(day) \(shortMonth) \(year)"
            
            //            switch templateType {
            //            case .ID43:
            //                return "\(is12Hours == true ? " \(ampm) " : "")" + "\(isShowWeek ? "\(week), " : "")\(day) \(shortMonth) \(year)"
            //            default:
            //                return "\(result) \(hhmm)"
            //            }
            //只显示年月日
            if(onlyYearMonthDay){
                return "\(day) \(shortMonth) \(year)"
            }
            return "\(result) \(needSecond ? hhmmss : hhmm)"
        }
        case .yuenanyu: do {
            
            let weekDescr = isShowWeek ? "\(week), " : ""
            let result = "\(weekDescr)\(day) \(shortMonth), \(year)"
            
            //            switch templateType {
            //            case .ID43:
            //                return "\(is12Hours == true ? " \(ampm) " : "")" + "\(weekDescr)\(day) \(shortMonth), \(year)"
            //            default:
            //                return "\(result) \(hhmm)"
            //            }
            //只显示年月日
            if(onlyYearMonthDay){
                return "\(day) \(shortMonth), \(year)"
            }
            return "\(result) \(needSecond ? hhmmss : hhmm)"
        }
        case .mengjialayu: break //当前版本不用处理
        case .deyu: do {
            
            let result = "\(isShowWeek ? "\(week). " : "")\(day) .\(shortMonth). \(year)"
            
            //            switch templateType {
            //            case .ID43:
            //                return "\(is12Hours == true ? " \(ampm) " : "")" + "\(isShowWeek ? "\(week). " : "")\(day) .\(shortMonth). \(year)"
            //            default:
            //                return "\(result) \(hhmm)"
            //            }
            if(onlyYearMonthDay){
                return "\(day) .\(shortMonth). \(year)"
            }
            return "\(result) \(needSecond ? hhmmss : hhmm)"
        }
        case .other:
            let result = "\(isShowWeek ? "\(week), " : "")\(shortMonth) \(day), \(year)"
            
            //            switch templateType {
            //            case .ID43:
            //                return "\(is12Hours == true ? " \(ampm) " : "")" + "\(isShowWeek ? "\(week), " : "")\(shortMonth) \(day), \(year)"
            //            default:
            //                return "\(result) \(hhmm)"
            //            }
            if(onlyYearMonthDay){
                return "\(shortMonth) \(day), \(year)"
            }
            return "\(result) \(needSecond ? hhmmss : hhmm)"
        }
        
        let result = "\(isShowWeek ? "\(week), " : "")\(day) \(shortMonth) \(year)"
        if(onlyYearMonthDay){
            return "\(day) \(shortMonth) \(year)"
        }
        
        //        switch templateType {
        //        case .ID43:
        //            return "\(is12Hours == true ? " \(ampm) " : "")" + "\(isShowWeek ? "\(week), " : "")\(day) \(shortMonth) \(year)"
        //        default:
        //            return "\(result) \(hhmm)"
        //        }
        return "\(result) \(needSecond ? hhmmss : hhmm)"
    }
    
    static func getDateFormatString(with date: Date, sytle: GPDateStyle, needWeek: Bool, needShowAll: Bool = false) -> String {
        let dateStr = getFormatterDate(date, dateFormat: sytle.getDateFmt())
        if needWeek {
            let dateComponent = dateCommpent(with: date, is12Hours: false, dateStyle: sytle)
            
            if needShowAll {
                // 添加星期显示
                switch sytle {
                case .dayMonthYear:
                    return "\(dateStr), \(dateComponent.week)"
                case .monthDayYear:
                    return "\(dateStr), \(dateComponent.week)"
                case .yearMonthDateSpecialCountry:
                    return "\(dateComponent.week), \(dateStr)"
                }
            } else {
                // 添加星期显示
                switch sytle {
                case .dayMonthYear:
                    return "\(dateStr), \(dateComponent.week)"
                case .monthDayYear:
                    return "\(dateStr), \(dateComponent.week)"
                case .yearMonthDateSpecialCountry:
                    return "\(dateComponent.week), \(dateStr)"
                }
            }
        } else {
            return dateStr
        }
    }
    
    // isUseBuddhist: 是否使用泰国的佛历年格式化, 泰国佛历年为当前年份+543
    static func dateCommpent(with date: Date, is12Hours: Bool?, isUseBuddhist: Bool = false, dateStyle: GPDateStyle) -> GPDateCommpent {
        
        let fmt = "yyyy-MM-dd-EEEE-HH-mm-ss"
        var formatterString = ""
        let dateFmt = dateStyle.getDateFmt()
        var dateFormatterString = ""
        
        // 是否用佛历年, 仅全球版特有国家化日期样式支持
        if isUseBuddhist {
            dateFormatterString = getFormatterDate_th_buddhist(date, dateFormat: dateFmt)
            formatterString = getFormatterDate_th_buddhist(date, dateFormat: fmt)
        } else {
            dateFormatterString = getFormatterDate(date, dateFormat: dateFmt)
            formatterString = getFormatterDate(date, dateFormat: fmt)
        }
        
        let ymde = formatterString.components(separatedBy: "-")
        
        let year = ymde[safe: 0] ?? "-"
        let month = ymde[safe: 1] ?? "-"
        let shortMonth = shortMonthLocal(with: month)
        let day = ymde[safe: 2] ?? "-"
        var hh = ymde[safe: 4] ?? "-"
        let mm = ymde[safe: 5] ?? "-"
        //秒
        let ss = ymde[safe: 6] ?? "-"
        
        var week = ymde[safe: 3] ?? "-"
        
        var weekIndex: Int?
        
        // 是否用佛历年
        if isUseBuddhist {
            
            weekIndex = DateFormatter.dateFormatCalendar_th_buddhist().component(.weekday, from: date)
        } else {
            
            weekIndex = DateFormatter.dateFormatCalendar().component(.weekday, from: date)
        }
        
        if let weekIndex = weekIndex, let localWeek = weekLocal(with: weekIndex - 1) {
            week = localWeek
        }
        
        var ampm = "AM"
        if is12Hours == true, var hhInt = Int(hh) {
            
            if hhInt >= 12 {
                
                if hhInt >= 13 {
                    
                    hhInt -= 12
                }
                
                hh = "\(hhInt)"
                ampm = "PM"
            }
        }
        
        return GPDateCommpent(year: year, month: month, shortMonth: shortMonth, day: day, week: week, hh: hh, mm: mm, ss:ss,ampm: ampm, date: dateFormatterString)
    }
    
    //  2.0.40 : 泰国佛历年格式化，获取日期字符串
    static func getFormatterDate_th_buddhist(_ date: Date, dateFormat: String) -> String {
        return date.toString_th_buddhist(format: dateFormat)
    }
    
    // 2.9.250版本统一修改，获取日期字符串
    static func getFormatterDate(_ date: Date, dateFormat: String) -> String {
        return date.toString_xh(format: dateFormat)
    }
    
    private static func shortMonthLocal(with month: String) -> String {
        
        let local = ["k_date_jan",
                     "k_date_feb",
                     "k_date_mar",
                     "k_date_apr",
                     "k_date_may",
                     "k_date_jun",
                     "k_date_jul",
                     "k_date_aug",
                     "k_date_sep",
                     "k_date_oct",
                     "k_date_nov",
                     "k_date_dec"]
        
        if let index = Int.init(month), let localString = local[safe: index - 1] {
            
            return localString.localized()
        }
        
        return month
    }
    //日历的hearder,只需要一个字
    public static func calendarWeekLocal(with weekdDay: Int) -> String? {
        
        if weekdDay < 0 || weekdDay > 6 {
            return nil
        }
        
        let local = ["k_calendar_sun",
                     "k_calendar_mon",
                     "k_calendar_tues",
                     "k_calendar_wed",
                     "k_calendar_thur",
                     "k_calendar_fri",
                     "k_calendar_sat",
        ]
        let defaultLocal = ["S",
                     "M",
                     "T",
                     "W",
                     "T",
                     "F",
                     "S",
        ]
        
        guard let localKey = local[safe: weekdDay] else {
            return nil
        }
        
        let localString = localKey.localized()
        
        if localString == localKey {
            return defaultLocal[safe: weekdDay]
        }
        
        return localString
    }
    public static func weekLocal(with weekdDay: Int) -> String? {
        
        if weekdDay < 0 {
            return nil
        }
        
        let local = ["k_date_sun",
                     "k_date_mon",
                     "k_date_tues",
                     "k_date_wed",
                     "k_date_thur",
                     "k_date_fri",
                     "k_date_sat",
        ]
        
        guard let localKey = local[safe: weekdDay] else {
            return nil
        }
        
        let localString = localKey.localized()
        
        if localString == localKey {
            return nil
        }
        
        return localString
    }
}

extension GPDateFormat {
    
    static func localizedID9DateString(_ date: Date, style: GPDateStyle, is12Hours: Bool?) -> String? {
                
        let com = dateCommpent(with: date, is12Hours: is12Hours, isUseBuddhist: false, dateStyle: style)
        
        let year = com.year
        let month = com.month
        //let shortMonth = com.shortMonth
        let day = com.day
        let week = com.week
        let hh = com.hh
        let mm = com.mm
        // second
        let ss = com.ss
        let ampm = com.ampm
        let timezone: String = TimeManager.shared.getGlobalTimeZone().abbreviation() ?? ""
        let hhmm = "\(hh):\(mm)"

        switch style {
        case .yearMonthDateSpecialCountry: do {
            let languageType = GPLanguageManager.localLanguageType()
            switch languageType {
            case .chinese, .hanguoyu, .riyu: do {
                let result = "\(year)/\(month)/\(day)"
                return "\(result) \(hhmm)"
            }
            case .english(let type): do {
                switch type{
                case .USA, .MY, .PH:
                    let result = "\(month)/\(day)/\(year)"
                    return "\(result) \(hhmm)"
                case .Other:
                    let result = "\(day)/\(month)/\(year)"
                    return "\(result) \(hhmm)"
                }
            }
            case .yinniyu, .xibanyayu, .yindiyu, .taiyu, .malaiyu, .putaoyayu, .eyu, .amuhalayu, .fayu, .tuerqiyu, .yidaliyu, .siwaxiliyu: do {
                let result = "\(day)/\(month)/\(year)"
                return "\(result) \(hhmm)"
            }
            case .yuenanyu: do {
                let result = "\(day)/\(month)/\(year)"
                return "\(result) \(hhmm)"
            }
            case .mengjialayu: break //当前版本不用处理
            case .deyu: do {
                let result = "\(day)/\(month)/\(year)"
                return "\(result) \(hhmm)"
            }
            case .other:
                let result = "\(month)/\(day)/\(year)"
                return "\(result) \(hhmm)"
            }
        }
        case .dayMonthYear:
            let result = "\(day)/\(month)/\(year)"
            return "\(result) \(hhmm)"
        case .monthDayYear:
            let result = "\(month)/\(day)/\(year)"
            return "\(result) \(hhmm)"
        }
        
        return nil
    }
    
    // 时刻水印，返回日期和时间数组
    static func getID9DateTimeString(_ date: Date, style: GPDateStyle, is12Hours: Bool?) -> ([Int], [Int]) {
                
        let com = dateCommpent(with: date, is12Hours: is12Hours, isUseBuddhist: false, dateStyle: style)
        
        let year = com.year
        let month = com.month
        //let shortMonth = com.shortMonth
        let day = com.day
        let week = com.week
        var hh = com.hh
        let mm = com.mm
        // second
        let ss = com.ss
        
        if is12Hours == true {
            if hh.count == 1 {
                hh = "0\(hh)"
            }
        }
    
        var id9Style: GPID9DateStyle = .monthDayYear
        switch style {
        case .yearMonthDateSpecialCountry: do {
            let languageType = GPLanguageManager.localLanguageType()
            switch languageType {
            case .chinese, .hanguoyu, .riyu: do {
                id9Style = .yearMonthDate
            }
            case .english(let type): do {
                switch type{
                case .USA, .MY, .PH:
                    id9Style = .monthDayYear
                case .Other:
                    id9Style = .dayMonthYear
                }
            }
            case .yinniyu, .xibanyayu, .yindiyu, .taiyu, .malaiyu, .putaoyayu, .eyu, .amuhalayu, .fayu, .tuerqiyu, .yidaliyu, .siwaxiliyu: do {
                id9Style = .dayMonthYear
            }
            case .yuenanyu: do {
                id9Style = .dayMonthYear

            }
            case .mengjialayu: break //当前版本不用处理
            case .deyu: do {
                id9Style = .dayMonthYear
            }
            case .other:
                id9Style = .monthDayYear
            }
        }
        case .dayMonthYear:
            id9Style = .dayMonthYear
        case .monthDayYear:
            id9Style = .monthDayYear
        }
        
        var dateArr = [Int]()
        switch id9Style {
        case .yearMonthDate:
            dateArr.append(contentsOf: GPDateFormat.getTimeIntArr(year))
            dateArr.append(-1)
            dateArr.append(contentsOf: GPDateFormat.getTimeIntArr(month))
            dateArr.append(-1)
            dateArr.append(contentsOf: GPDateFormat.getTimeIntArr(day))
        case .dayMonthYear:
            dateArr.append(contentsOf: GPDateFormat.getTimeIntArr(day))
            dateArr.append(-1)
            dateArr.append(contentsOf: GPDateFormat.getTimeIntArr(month))
            dateArr.append(-1)
            dateArr.append(contentsOf: GPDateFormat.getTimeIntArr(year))
        case .monthDayYear:
            dateArr.append(contentsOf: GPDateFormat.getTimeIntArr(month))
            dateArr.append(-1)
            dateArr.append(contentsOf: GPDateFormat.getTimeIntArr(day))
            dateArr.append(-1)
            dateArr.append(contentsOf: GPDateFormat.getTimeIntArr(year))
        }
        
        var timeArr = [Int]()
        timeArr.append(contentsOf: GPDateFormat.getTimeIntArr(hh))
        timeArr.append(-1)
        timeArr.append(contentsOf: GPDateFormat.getTimeIntArr(mm))
        timeArr.append(-1)
        timeArr.append(contentsOf: GPDateFormat.getTimeIntArr(ss))
        
        return (dateArr, timeArr)
    }
    
    static func getTimeIntArr(_ timeStr: String) -> [Int] {
        return timeStr.compactMap { Int(String($0)) }
    }
    
    // 会议水印，返回时间数组
    static func getID8TimeString(_ date: Date, style: GPDateStyle, is12Hours: Bool?) -> [Int] {
                
        let com = dateCommpent(with: date, is12Hours: is12Hours, isUseBuddhist: false, dateStyle: style)
        
        let year = com.year
        let month = com.month
        //let shortMonth = com.shortMonth
        let day = com.day
        let week = com.week
        var hh = com.hh
        let mm = com.mm
        // second
        let ss = com.ss
        
        if is12Hours == true {
            if hh.count == 1 {
                hh = "0\(hh)"
            }
        }
        
        var timeArr = [Int]()
        timeArr.append(contentsOf: GPDateFormat.getTimeIntArr(hh))
        timeArr.append(-1)
        timeArr.append(contentsOf: GPDateFormat.getTimeIntArr(mm))
        
        return timeArr
    }
}
