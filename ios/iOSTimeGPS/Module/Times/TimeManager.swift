//
//  TimeManager.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/18.
//

import Foundation

// 服务器的时间戳key
private let gpServiceTimeStampKey = "GPTimeManager_service_time_stamp"
// 本地的系统时间戳key
private let gpLocalTimeStampKey = "GPTimeManager_local_time_stamp"
// 手机开机时间戳key
private let gpBootTimeStampKey = "GPTimeManager_boot_time_stamp"
// 2.9.255:系统的运行时间
private let gpSystemUptimeKey = "GPTimeManager_system_uptime"

private let gpServerTimeModelKey = "GPTimeManager_global_server_time_model_key"

class TimeManager: NSObject {
    
    static let shared = TimeManager()
    var hasRequestApi: Bool = false
    var timeZone = TimeZone.current
    var currentDate = Date()
    // 最大误差300秒
    // let timeLimitSeconds: Int = 300
    // V2.9.173版本，最大误差改为60秒
    let timeLimitSeconds: Int = 60
    
    // 内存中的服务器时间，如果存在说明在运行中请求时间接口成功过，下面三个字段是成套出现和保存的
    var memoryServerTime: Int?
    // 内存中本地系统时间
    var memoryLocalTime: Int?
    // 内存中手机启动时间
    var memoryBootTime: Int?
    
    // 同步时间的时候的服务器时间：上一次请求服务器时间成功的时候，保存到数据库的服务器时间
    var dbServiceTime: Int = 0
    // 同步时间的时候的本地系统时间：上一次请求服务器时间成功的时候，保存到数据库的设备系统时间
    var dbLocalTime: Int = 0
    // 同步时间的时候的手机开机时间：上一次请求服务器时间成功的时候，保存到数据库的设备开机时间
    var dbBootTime: Int = 0
    
    /*
     * 2.9.255:手机是不是重启了，如果是true：一定是重启了；如果是false：只能说以现有的条件无法判断出用户重启了手机
     * 2.9.295: 这里的重启是指：用户重启手机后，如果一直不连接网络，isPhoneRestarted一直是true，
     * 这样能保证重启手机后，只要用户不连接网络水印上就不显示时间
     */
    var isPhoneRestarted: Bool = false
    
    // 2.9.285: 是否已经弹出过重启手机后提示弹框，true：已经弹出过；false：还没有弹出过
    var isShowedRestartAlert: Bool = false
    
    // 2.9.295:是否保存系统的运行时间，用于计算用户是否重启
    var isSaveSystemUptime: Bool = false
    
    // 全球化适配：服务器时间的model
    var globalTimeModel: GPRealTimeModel?
    
    func getGlobalTimeZone() -> TimeZone {
        
        var timeZone = TimeZone.current
        
        if let timezoneID = self.globalTimeModel?.timeZone, timezoneID.count > 0, let zone = TimeZone(identifier: timezoneID) {
            // 通过ID获取时区信息
            timeZone = zone
        }
        
        // XHLogError("[时间校准调试] - 获取全球化版本的时区 - timeZone:[\(timeZone.identifier)]")
        return timeZone
    }
    
    func getRealTime() -> Date {
        return getRealTimeData().currentDate
    }

    // MARK: - V2.0.15: 全球化适配：获取全球化版本的时区缩写
    func getGlobalTimeZoneAbbreviation() -> String? {
        let timeZone = getGlobalTimeZone()
        if timeZone.identifier == "Asia/Kolkata" {
            // V2.0.65: 印度地区特殊判断
            return "IST"
        } else {
            return timeZone.abbreviation()
        }
    }
    

    
    /* iOS客户端不用处理夏令时，原因如下：
     * 1、时间戳：描述了距离某一时刻经过的时间跨度，是一个绝对值，和时区，冬(夏)令时这些没有关系。所以在地球上的同一时间点，对于同一参照点，获取到的时间戳都是完全一致的。
     * 2、客户端是根据服务端提供的时间戳和本地时间的时间戳的差值判断是否需要校正时间的；
     * 3、转成显示的时间是调用系统的API，系统帮我们做了这个处理，所以客户端不用处理夏令时的问题；
     */
    
    // 全球化适配: 是否在指定日期使用夏令时
    func isDaylightSavingTime() -> Bool {
        
        let timeZone = getGlobalTimeZone()
        // 是否在指定日期使用夏令时
        let isDST = timeZone.isDaylightSavingTime()
        LogDebug("[时间校准调试] - 是否在指定日期使用夏令时:[\(isDST)]")
        return isDST
    }
    
    // 全球化适配: 获取指定日期的夏令时偏移量，单位：秒
    func getDaylightSavingTimeOffset() -> Int {
        
        let timeZone = getGlobalTimeZone()
        let offset = Int(timeZone.daylightSavingTimeOffset())
        LogDebug("[时间校准调试] - 获取指定日期的夏令时偏移量:[\(offset)]")
        return offset
    }
}

extension TimeManager {
    
    func requestTimeApi(lat: Double, lon: Double) {
        
        if hasRequestApi {
            return
        }
        
        let startRequestTime = Date()
        networkAPI.realtime(lat: lat, lon: lon) { [weak self] error, message in
            if let message, error == nil {
                self?.hasRequestApi = true
                let endRequestTime = Date()
                let requestTotalTime = endRequestTime.timeIntervalSince(startRequestTime)
                // 超过2分钟直接抛弃
                if requestTotalTime > 120 {
                    GPFirebaseManager.time_api_timeout()
                    return
                }
                GPFirebaseManager.time_api_success(Int(requestTotalTime))
                // 修改本地时间
                if let timezoneID = message.timeZone, let globalTimeZone = TimeZone(identifier: timezoneID) {
                    self?.timeZone = globalTimeZone
                    if let timeStr = message.time, let glbalDate = Date.getDateFromString(timezone: globalTimeZone, dateString: timeStr, formatterString: "YYYY-MM-dd HH:mm:ss") {
                        self?.currentDate = glbalDate
                        
                        let serviceTimeStamp = Int(glbalDate.timeIntervalSince1970)
                        let serverTimeModel = message.deepCopy()
                        serverTimeModel.timestamp = serviceTimeStamp
                        
                        TimeManager.shared.updateServiceTime(serviceTime: serviceTimeStamp, model: serverTimeModel)
                        // 发送服务器时间刷新成功通知
                        NotificationCenter.default.post(name: GPNotification.realTimeNotification, object: nil)
                    }
                }
            } else {
                GPFirebaseManager.time_api_fail(errorMsg: "\(String(describing: error))")
            }
        }
    }
    
}

extension TimeManager {
    
    // 从数据获取服务器时间
    func getServiceTimeFromDB() {
        
        // 1、从数据库获取serviceTime
        func getServiceTime() {
            var serviceTime: Int = 0
            if UserDefaults.standard.value(forKey: gpServiceTimeStampKey) != nil {
                serviceTime =  UserDefaults.standard.integer(forKey: gpServiceTimeStampKey)
                // LogDebug("[时间校准调试] - [数据库缓存] - getServiceTimeFromDB - 从UserDefaults获取serviceTime:[\(serviceTime)]")
            } else {
                // 2.9.255:钥匙串取值
                if let keychainStr = GPKeychainManager.shared.string(forKey: gpServiceTimeStampKey), keychainStr.count > 0, let keychainTime = Int(keychainStr) {
                    
                    serviceTime = keychainTime
                    // LogDebug("[时间校准调试] - [数据库缓存] - getServiceTimeFromDB - 从钥匙串获取serviceTime:[\(serviceTime)]")
                } else {
                    // LogDebug("[时间校准调试] - [数据库缓存] - getServiceTimeFromDB - 从钥匙串获取serviceTime - 没有取到值")
                }
            }
            self.dbServiceTime = serviceTime
        }
        
        // 2、从数据库获取localTime
        func getLocalTime() {
            var localTime: Int = 0
            if UserDefaults.standard.value(forKey: gpLocalTimeStampKey) != nil {
                localTime =  UserDefaults.standard.integer(forKey: gpLocalTimeStampKey)
                // LogDebug("[时间校准调试] - [数据库缓存] - getServiceTimeFromDB - 从UserDefaults获取localTime:[\(localTime)]")
            } else {
                // 2.9.255:钥匙串取值
                if let keychainStr = GPKeychainManager.shared.string(forKey: gpLocalTimeStampKey), keychainStr.count > 0, let keychainTime = Int(keychainStr) {
                    
                    localTime = keychainTime
                    // LogDebug("[时间校准调试] - [数据库缓存] - getServiceTimeFromDB - 从钥匙串获取localTime:[\(localTime)]")
                } else {
                    // LogDebug("[时间校准调试] - [数据库缓存] - getServiceTimeFromDB - 从钥匙串获取localTime - 没有取到值")
                }
            }
            self.dbLocalTime = localTime
        }
        
        // 3、从数据库获取bootTime
        func getBootTime() {
            var bootTime: Int = 0
            if UserDefaults.standard.value(forKey: gpBootTimeStampKey) != nil {
                bootTime =  UserDefaults.standard.integer(forKey: gpBootTimeStampKey)
                // LogDebug("[时间校准调试] - [数据库缓存] - getServiceTimeFromDB - 从UserDefaults获取bootTime:[\(bootTime)]")
            } else {
                // 2.9.255:钥匙串取值
                if let keychainStr = GPKeychainManager.shared.string(forKey: gpBootTimeStampKey), keychainStr.count > 0, let keychainTime = Int(keychainStr) {
                    
                    bootTime = keychainTime
                   // LogDebug("[时间校准调试] - [数据库缓存] - getServiceTimeFromDB - 从钥匙串获取bootTime:[\(bootTime)]")
                } else {
                   // LogDebug("[时间校准调试] - [数据库缓存] - getServiceTimeFromDB - 从钥匙串获取bootTime - 没有取到值")
                }
            }
            self.dbBootTime = bootTime
        }
        
        // 开始调用
        getServiceTime()
        getLocalTime()
        getBootTime()
        
        // 全球化适配
        getGlobalServerTimeModelFromDB()
        
        LogDebug("[时间校准调试] - 从数据库获取服务器时间 - dbServiceTime:[\(dbServiceTime)] - dbLocalTime:[\(dbLocalTime)] - dbBootTime:[\(dbBootTime)]")
    }
    
    /// 更新本地的服务器时间：inChina接口回调成功后，同时把：服务器时间、设备系统时间、设备开机时间保存到数据库
    func updateServiceTime(serviceTime: Int, model: GPRealTimeModel?) {
        
        if serviceTime <= 0 {
            LogDebug("[时间校准调试] - 接口成功更新服务器时间 - 服务器时间是0 - 直接返回")
            return
        }
        
        // 1、更新serviceTime
        UserDefaults.standard.set(serviceTime, forKey: gpServiceTimeStampKey)
        // 2.9.255:保存到钥匙串
        GPKeychainManager.shared.set("\(serviceTime)", forKey: gpServiceTimeStampKey)
        self.dbServiceTime = serviceTime
        self.memoryServerTime = serviceTime
        
        // 2、更新localTime
        let localTime = now()
        UserDefaults.standard.set(localTime, forKey: gpLocalTimeStampKey)
        // 2.9.255:保存到钥匙串
        GPKeychainManager.shared.set("\(localTime)", forKey: gpLocalTimeStampKey)
        self.dbLocalTime = localTime
        self.memoryLocalTime = localTime
        
        // 3、更新bootTime
        let bootTime = self.bootTime()
        UserDefaults.standard.set(bootTime, forKey: gpBootTimeStampKey)
        // 2.9.255:保存到钥匙串
        GPKeychainManager.shared.set("\(bootTime)", forKey: gpBootTimeStampKey)
        self.dbBootTime = bootTime
        self.memoryBootTime = bootTime
        
        // 1.0.95:
        self.saveGlobalServerTime(model: model)
        
        // 2.9.295:当获取到服务器时间的时候才更新设备的运行时间
        saveSystemUptime()
        
        LogDebug("[时间校准调试] - 接口成功更新服务器时间 - serviceTime:[\(serviceTime)] - localTime:[\(localTime)] - bootTime:[\(bootTime)]")
    }
    
    // MARK: - 获取真实时间
    func getRealTimeData() -> (currentDate: Date, isNeedCorrectTime: Bool, canMakeSureRealTime: Bool, deltaTime: Int?) {
        
        // 2、内存中有服务器时间，一切以服务器的时间为准，说明请求inChina成功过, 运行内存中有服务器时间，能确保用户没有重启手机，所以能确保是真实时间
        if let memoryServerTime = self.memoryServerTime, let memoryLocalTime = self.memoryLocalTime, let memoryBootTime = self.memoryBootTime {
            
            // XHLogDebug("[时间校准调试] - getRealTime - 内存中有服务器时间，一切以服务器的时间为准，说明请求inChina成功过")
            let realTime = calculateRealTime(point_serviceTime: memoryServerTime, point_localTime: memoryLocalTime, point_bootTime: memoryBootTime)
            let nowTime = self.now()
            let deltaTime = abs(realTime - nowTime)
            
            if deltaTime > self.timeLimitSeconds {
                // 2.1、内存中有服务器时间，计算出来的时间和本地时间超出误差范围，使用计算出来的时间, 需要校正时间，保证是真实时间
                let realDate = Date.init(timeIntervalSince1970: TimeInterval(realTime))
                let nowDate = Date.init(timeIntervalSince1970: TimeInterval(nowTime))
                LogDebug("[时间校准调试] - [计算时间] - ByMemory - 2.1、内存中有服务器时间，计算出来的时间和本地时间超出误差范围 - 使用计算出来的时间 - 需要校正时间 - 保证是真实时间 - 计算出的时间:[\(realDate.toString_xh())] - 设备时间:[\(nowDate.toString_xh())]")
                return (realDate, true, true, deltaTime)
            } else {
                // 2.2、内存中有服务器时间，计算出来的时间和本地时间在误差范围内，使用系统时间，不需要校正时间，保证是真实时间
                // XHLogDebug("[时间校准调试] - ByMemory - 2.2、内存中有服务器时间，计算出来的时间和本地时间在误差范围内 - 使用系统时间 - 不需要校正时间 - 保证是真实时间")
                return (Date(), false, true, deltaTime)
            }
        } else {
            // 3、内存中没有服务器时间，使用上次请求inChina成功时，保存到数据库中的数据，不知道用户有没有重启手机
            // 3.1、内存中无服务器时间，本地数据库中不存在服务器时间，使用系统时间，不校正时间，没有参照时间，所以不能确保是真实时间
            if self.dbServiceTime == 0 {
//                LogDebug("[时间校准调试] - [计算时间] - 3.1、内存中无服务器时间，本地数据库中不存在服务器时间 - 使用系统时间 - 不校正时间 - 不能确保是真实时间")
                return (Date(), false, false, nil)
            }
            
            let nowLocalTime = self.now()
            let realTime = calculateRealTime(point_serviceTime: self.dbServiceTime, point_localTime: self.dbLocalTime, point_bootTime: self.dbBootTime)
            let deltaTime = abs(realTime - nowLocalTime)
            if deltaTime > self.timeLimitSeconds {
                // 3.2、使用数据库中的服务器时间，计算出来的时间和本地时间超过误差范围，使用计算出来的时间，需要校正时间，不能确保是真实时间
                let realDate = Date.init(timeIntervalSince1970: TimeInterval(realTime))
                let localDate = Date.init(timeIntervalSince1970: TimeInterval(nowLocalTime))
                LogDebug("[时间校准调试] - [计算时间] - 3.2、使用数据库中的服务器时间，计算出来的时间和本地时间超过误差范围 - 使用计算出来的时间 - 需要校正时间 - 不能确保是真实时间 - 计算出的日期:[\(realDate.toString_xh())] - 设备日期:[\(localDate.toString_xh())]")
                return (realDate, true, false, deltaTime)
            } else {
                // 3.3、使用数据库中的服务器时间，计算出来的时间和本地时间在误差范围内，认为用户没有修改时间，使用系统时间，不需要校正时间，保证是真实时间
                // XHLogDebug("[时间校准调试] - [计算时间] - 3.4、使用数据库中的服务器时间，计算出来的时间和本地时间在误差范围内 - 使用系统时间 - 不需要校正时间 - 保证是真实时间")
                return (Date(), false, true, deltaTime)
            }
        }
    }
}

// MARK: - 通用方法
extension TimeManager {
    
    /// 2.9.233:计算真实时间
    /// - Parameters:
    ///   - point_serviceTime: 某一时刻获取的服务时间
    ///   - point_localTime: 获取服务器时间的时候的本地系统时间
    ///   - point_bootTime: 获取服务器时间的时候的开机时间
    /// - Returns: 真实时间（秒）
    private func calculateRealTime(point_serviceTime: Int, point_localTime: Int, point_bootTime: Int) -> Int {
        
        // 获取服务器时间那一刻运行时间（运行时间指距离上次开机的运行时间）
        let runTime0 = point_localTime - point_bootTime
        // 此时此刻的运行时间（运行时间指距离上次开机的运行时间）
        let runTime1 = self.uptime()
        // 计算出来的现在的时间戳
        let realTime = point_serviceTime + (runTime1 - runTime0)
        return realTime
    }
    
    // 获取当前 Unix Time：(获取设备当前时间 Now，该值受系统时间影响，用户如果修改时间，值也会随着变化；)
    func now() -> Int {
        var now = timeval()
        var tz = timezone()
        gettimeofday(&now, &tz)
        return now.tv_sec
    }
    
    // 设备开机时间：获取设备上次重启的 Unix Time：(获取设备上次重启的时间 BootTime，该值受系统时间影响，用户如果修改时间，值也会随着变化)
    func bootTime() -> Int {
        
        var mid = [CTL_KERN, KERN_BOOTTIME]
        var boottime = timeval()
        var size = MemoryLayout.size(ofValue: boottime)
        
        if sysctl(&mid, 2, &boottime, &size, nil, 0) != -1 {
            return boottime.tv_sec
        }
        return 0
    }
    
    // 运行时间 = now() - bootTime()：此刻距离上次开机的时间差
    private func uptime() -> Int {
        var boottime = timeval()
        var mid = [CTL_KERN, KERN_BOOTTIME]
        var size = MemoryLayout.size(ofValue: boottime)
        
        var now: time_t = 0
        var uptime: time_t = -1
        time(&now)
        
        if sysctl(&mid, 2, &boottime, &size, nil, 0) != -1 && boottime.tv_sec != 0 {
            uptime = now - boottime.tv_sec
            return uptime
        }
        return 0
    }
}

extension TimeManager {
    
    func saveGlobalServerTime(model: GPRealTimeModel?) {
        
        guard let timeModel = model,
              let timestampInt = timeModel.timestamp, timestampInt > 0,
              let modelStr = timeModel.toCompactJSONString(), modelStr.count > 0 else {
            return
        }
        
        // 1、更新内存中的值
        self.globalTimeModel = timeModel
        
        // 2、保存到UserDefaults
        UserDefaults.standard.set(modelStr, forKey: gpServerTimeModelKey)
        
        // 3、保存到钥匙串
        GPKeychainManager.shared.set("\(modelStr)", forKey: gpServerTimeModelKey)
        
       // LogDebug("[时间校准调试] - 接口请求成功 - 保存全球化版本服务器时间model:[\(modelStr)]")
    }
    
    // 从数据获取全球化服务器时间
    func getGlobalServerTimeModelFromDB() {
        
        var modelStr: String?
        if UserDefaults.standard.value(forKey: gpServerTimeModelKey) != nil {
            
            modelStr = UserDefaults.standard.string(forKey: gpServerTimeModelKey)
        } else if let keychainStr = GPKeychainManager.shared.string(forKey: gpServerTimeModelKey), keychainStr.count > 0 {
            
            modelStr = keychainStr
        }
        
        if let str = modelStr, str.count > 0, let model = SpeedyModel.anyToModel(GPRealTimeModel.self, param: str) {
            self.globalTimeModel = model
        } else {
            LogDebug("[时间校准调试] - 从本地获取globalTimeModel失败")
        }
    }
}

// MARK: - 2.9.255:判断手机是否重启过
extension TimeManager {
    
    /*
     * 2.9.255：保存系统自上次重启后的运行时间
     * 2.9.295：当获取到服务器时间的时候才更新设备的运行时间，
     * 这样会出现如果用户重启手机后断网打开app，不显示时间，然后杀掉app后，重新打开app还是不显示时间
     */
    private func saveSystemUptime() {
        
        if isSaveSystemUptime == true {
            return
        }
        isSaveSystemUptime = true
        
        // The amount of time the system has been awake since the last time it was restarted.
        // 通过NSProcessInfo获取系统重启后的运行时间不受系统控制，只受设备重启和休眠行为影响
        let systemUptime1: Int = Int(ProcessInfo.processInfo.systemUptime)
        
        // 运行时间 = now() - bootTime()：此刻距离上次开机的时间差，只受设备重启的影响
        let systemUptime2 = self.uptime()
        
        let valueStr = "\(systemUptime1)" + "_" + "\(systemUptime2)"
        
        UserDefaults.standard.set(valueStr, forKey: gpSystemUptimeKey)
        // 2.9.255:保存到钥匙串
        GPKeychainManager.shared.set(valueStr, forKey: gpSystemUptimeKey)
        
        // LogDebug("[时间校准调试] - [是否重启] - saveSystemUptime - 保存系统自上次重启后的运行时间:[\(valueStr)]")
    }
    
    /// 2.9.255：获取是否重启过手机
    func getIsPhoneRestarted() {
        
        var systemUptimeStr = ""
        if let str = UserDefaults.standard.string(forKey: gpSystemUptimeKey), str.count > 0 {
            systemUptimeStr = str
        } else {
            if let keychainStr = GPKeychainManager.shared.string(forKey: gpSystemUptimeKey), keychainStr.count > 0 {
                systemUptimeStr = keychainStr
            }
        }
        
        guard systemUptimeStr.contains("_") else {
            LogDebug("[时间校准调试] - 获取是否重启过手机 - 数据库不存在")
            return
        }
        
        let array = systemUptimeStr.split(separator: "_")
        guard array.count == 2, let firstStr = array.first, let firstInt = Int(firstStr), let lastStr = array.last, let lastInt = Int(lastStr) else {
         
            LogDebug("[时间校准调试] - 获取是否重启过手机 - 解析数据失败:[\(systemUptimeStr)]")
            return
        }
        
        let oldUptime1 = firstInt
        let oldUptime2 = lastInt
        
        // The amount of time the system has been awake since the last time it was restarted.
        // 通过NSProcessInfo获取系统重启后的运行时间不受系统控制，只受设备重启和休眠行为影响
        let newUptime1: Int = Int(ProcessInfo.processInfo.systemUptime)
        
        // 运行时间 = now() - bootTime()：此刻距离上次开机的时间差，只受设备重启的影响
        let newUptime2 = self.uptime()
        
        if newUptime1 <= oldUptime1 || newUptime2 <= oldUptime2 {
            isPhoneRestarted = true
            // Report.iOS_phoneRestarted_255(oldUptime1: oldUptime1, oldUptime2: oldUptime2, newUptime1: newUptime1, newUptime2: newUptime2)
        } else {
            isPhoneRestarted = false
        }
        
        LogDebug("[时间校准调试] - 获取是否重启过手机 - oldUptime1:[\(oldUptime1)] - oldUptime2:[\(oldUptime2)] - newUptime1:[\(newUptime1)] - newUptime2:[\(newUptime2)] - isPhoneRestarted:[\(isPhoneRestarted)]")
    }
    
    /// 获取当前设备的运行时间:通过NSProcessInfo获取系统重启后的运行时间不受系统控制，只受设备重启和休眠行为影响
    /// - Returns: 运行时间，单位：毫秒
    /// The amount of time the system has been awake since the last time it was restarted.
    static func getCurrentSystemUptime() -> Int {
        let uptime = Int(ProcessInfo.processInfo.systemUptime * 1000)
        // XHLogDebug("[运行时间调试] - 运行时间:[\(uptime)]")
        return uptime
    }
}


// 2.9.295：水印上是否显示时间
extension TimeManager {
    
    /// 2.9.295：水印上是否显示时间
    /// - Returns: true：显示；false：不显示
    func isShowTimeOnWatermark() -> Bool {
        
        var hasServerTime = false
        if let sTime = self.memoryServerTime, sTime > 0 {
            hasServerTime = true
        }
        
        /* 2、用户在国内的情况：
         * 满足三个条件水印上不显示时间
         * 1）、内存中不存在服务器时间
         * 2）、用户重启了手机
         * 3）、iOS_show_time_on_watermark配置为0，默认是0 2.9.343版本移除
         */
        // 2.9.343版本移除
        // let isOpen = XHAPPConfigureManager.shared.configureModel?.ios?.iOS_show_time_on_watermark ?? "0"
        // if self.isPhoneRestarted == true, hasServerTime == false, isOpen == "0" {
        if self.isPhoneRestarted == true, hasServerTime == false {
//            // 埋点和日志一次生命周期报一次
//            if isReportNotShowTime == false {
//                // Report.iOS_not_show_time_on_watermark_295()
//                XHLogError("[时间校准调试] - isShowTimeOnWatermark - 满足三个条件水印上不显示时间")
//            }
//            isReportNotShowTime = true
            return false
        }
        return true
    }
}

