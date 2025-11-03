//
//  Date+Extension.swift
//  XCamera
//
//  Created by batman on 2021/3/28.
//  Copyright © 2021 xhey. All rights reserved.
//

import Foundation

extension DateFormatter {
    
    /// 初始化DateFormatter，项目中统一使用，解决iOS15.4之后，12小时制显示“上午”、“下午”的问题
    /// 参考链接：https://www.jianshu.com/p/79465eb4e4c4
    /// - Parameter islocalization: 是否本地化，true：根据isGpsInChina设置timeZone和locale
    /// - Returns: DateFormatter
    class func dateFormat_xh(islocalization: Bool = true) -> DateFormatter {
        
        let dateFormater = DateFormatter()
        
            // 全球化适配
            dateFormater.timeZone = TimeManager.shared.getGlobalTimeZone() // TimeZone.current
            // 从苹果官方对NSDateFormatter的解释中可以看出，要想在任何时候输出固定格式的日期，需要设置.local，即设置：
            dateFormater.locale = NSLocale.system // Locale.current
        
        
        dateFormater.calendar = Calendar.init(identifier: .iso8601)
        return dateFormater
    }
    
    // 泰国佛历年formatter
    class func dateFormat_th_buddhist() -> DateFormatter {
        
        let dateFormater = dateFormat_xh()
        dateFormater.calendar = Calendar.init(identifier: Calendar.Identifier.buddhist)
        
        return dateFormater
    }

    
    class func dateFormatCalendar(islocalization: Bool = true) -> Calendar {
        
        dateFormat_xh(islocalization: islocalization).calendar
    }
    
    class func dateFormatCalendar_th_buddhist() -> Calendar {
        
        dateFormat_th_buddhist().calendar
    }

    
    /// 2.9.250：系统的日期格式
    class func systemDateFormat_xh() -> DateFormatter {
        
        let dateFormater = DateFormatter()
        dateFormater.timeZone = TimeZone.current
        dateFormater.locale = NSLocale.system // Locale.current
        dateFormater.calendar = Calendar.init(identifier: .iso8601)
        return dateFormater
    }
    
    /// 2.9.250：中国的日期格式
    class func chinaDateFormat_xh() -> DateFormatter {
        
        let dateFormater = DateFormatter()
        dateFormater.timeZone = TimeZone.init(identifier: "Asia/Shanghai")
        dateFormater.locale = Locale(identifier: "zh_CN")
        dateFormater.calendar = Calendar.init(identifier: .iso8601)
        return dateFormater
    }
}

extension Date {
    
    /// 2.9.250:日期是不是今天
    var isToday_xh: Bool {
        let result = NSCalendar.current.isDateInToday(self)
        return result
    }
    
    /// V2.9.240 新增：（为了解决`CVCalendar`的日期颜色bug新增）
    /// `year`：年份
    /// `month`：月份
    /// `weekOfMonth`：当前月份的第几周
    /// `weekDay`：`1` ~ `7` 星期天 ~ 星期六
    var info_xh: (year: Int?, month: Int?, weekOfMonth: Int?, weekDay: Int?, day: Int?) {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month, .weekOfMonth, .weekday, .day], from: self)
        return (comps.year, comps.month, comps.weekOfMonth, comps.weekday, comps.day)
    }
    
    var year_xh: Int? {
        return self.info_xh.year
    }
    
    var month_xh: Int? {
        return self.info_xh.month
    }
    
    var day_xh: Int? {
        return self.info_xh.day
    }
    
    /// 是否是同一天
    /// - Parameters:
    ///   - firstDate: 第一个日期
    ///   - secondDate: 第二个日期
    /// - Returns: 是同一天：true；不是同一天：false
    static func isSameDay_xh(firstDate: Date, secondDate: Date) -> Bool {
        
        if firstDate.year_xh == secondDate.year_xh, firstDate.month_xh == secondDate.month_xh, firstDate.day_xh == secondDate.day_xh {
            return true
        }
        return false
    }

    /// 计算指定日期之前/之后N天对应的日期字符串
    /// - Parameters:
    ///   - date: 指定日期
    ///   - beforeDays: 负数表示之前N天，正数表示之后N天
    ///   - dateFormat: 日期显示的格式
    /// - Returns: 返回对应日期的字符串
    func getSpecialDateString(beforeDays: TimeInterval, dateFormat: String = "yyyy.MM.dd") -> String {

        let pastDate = self.addingTimeInterval(60 * 60 * 24 * beforeDays)

        let dateFormater = DateFormatter.dateFormat_xh()
        dateFormater.dateFormat = dateFormat
        
        let resultStr = dateFormater.string(from: pastDate)
        return resultStr
    }
    
    /// 2.9.250版本从基础组件库移到这里：Date转换成String 默认："yyyy-MM-dd HH:mm:ss"
    func toString_xh(format: String = "yyyy-MM-dd HH:mm:ss", islocalization: Bool = true) -> String {
        
        let dateFormater = DateFormatter.dateFormat_xh(islocalization: islocalization)
        dateFormater.dateFormat = format
        
        let resultStr = dateFormater.string(from: self)
        return resultStr
    }
    
    /// 2.0.40 : 泰国佛历年格式化：Date转换成String 默认："yyyy-MM-dd HH:mm:ss"
    func toString_th_buddhist(format: String = "yyyy-MM-dd HH:mm:ss", islocalization: Bool = true) -> String {
        
        let dateFormater = DateFormatter.dateFormat_th_buddhist()
        dateFormater.dateFormat = format
        
        let resultStr = dateFormater.string(from: self)
        return resultStr
    }
    
    // 计算一个月有多少天 2.9.345：把XHDateTool中的方法挪到这里
    static func getDaysOfOneMonth(year: Int, month: Int) -> Int {
        
        let dateComponents = DateComponents(year: year, month: month)
        let calendar = Calendar.current
        
        if let date = calendar.date(from: dateComponents), let range = calendar.range(of: .day, in: .month, for: date) {
            return range.count
        }
        return 0
    }
    
    /*
     // 计算一个月有多少天
     static func getDaysOfOneMonth(year: Int, month: Int) -> Int {
         let dateComponents = DateComponents(year: year, month: month)
         let calendar = Calendar.current
         let date = calendar.date(from: dateComponents)!
         let range = calendar.range(of: .day, in: .month, for: date)!
         return range.count
     }
     */
    
    // 获取日期，固定格式如“2023-12-04”
    func getDateString() -> String {
        let df = DateFormatter.dateFormat_xh(islocalization: false)
        df.dateFormat = "yyyy-MM-dd"
        let string = df.string(from: self)
        return string
    }
    
    static func getDateFromString(dateString: String, formatterString: String) -> Date? {
        let dateFormater = DateFormatter.dateFormat_xh()
        dateFormater.dateFormat = formatterString
        let date = dateFormater.date(from: dateString)
        return date
    }
    
    static func getDateFromString(timezone:TimeZone, dateString: String, formatterString: String) -> Date? {
        let dateFormater = DateFormatter()
        dateFormater.timeZone = timezone // TimeZone.current
        // 从苹果官方对NSDateFormatter的解释中可以看出，要想在任何时候输出固定格式的日期，需要设置.local，即设置：
        dateFormater.locale = NSLocale.system // Locale.current
        dateFormater.calendar = Calendar.init(identifier: .iso8601)
        dateFormater.dateFormat = formatterString
        let date = dateFormater.date(from: dateString)
        return date
    }
    
}
