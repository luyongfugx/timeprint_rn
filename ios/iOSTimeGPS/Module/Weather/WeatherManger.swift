//
//  WeatherManger.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/9/27.
//

import Foundation

class WeatherManger {
    
    static let shared = WeatherManger()
    var isRequsting: Bool = false
    
    func weatherCachValid() -> Bool {
        guard !GPSGeoManager.weatherCach.isEmpty else { return false }
        guard let cachHourStr = AppConfigManager.shared.config.weatherCachHour, let cachHour = Double(cachHourStr), cachHour > 0 else { return false }
        let cachSecond = cachHour * 60 * 60
        let nowTimestamp = TimeManager.shared.getRealTime().timeIntervalSince1970
        let cachValid = nowTimestamp < (cachSecond + GPSGeoManager.weatherCachTimestamp)
        LogDebug("天气是否符合缓存条件：\(cachValid), lasttime: \(GPSGeoManager.weatherCachTimestamp), config cachHour:\(cachHour)")
        return cachValid
    }
    
    func requstWeather() {
        guard !weatherCachValid() else { return }
        guard !isRequsting else { return }
        guard let location = GPSGeoManager.wartermarkGPSInfo.location else { return }
        isRequsting = true
        LogDebug("开始请求天气")

        Task {
            await handleWeather(location: location)
        }
        
    }
    
    private func handleWeather(location: CLLocation) async {
        if #available(iOS 16.0, *) {
            let weather = await WeatherKitRequest()
            await weather.getWeather(location: location)
            self.isRequsting = false
            // 发送天气刷新成功通知
            GPSafeMainAsync {
                LogDebug("天气请求结束，发送通知")
                NotificationCenter.default.post(name: GPNotification.weatherNotification, object: nil)
            }

        }
    }
}
