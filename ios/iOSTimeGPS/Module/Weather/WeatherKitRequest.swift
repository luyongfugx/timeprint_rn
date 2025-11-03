//
//  WeatherKitRequest.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/9/18.
//

import Foundation
import WeatherKit
import SwiftUI
import CoreLocation
import Solar

@available(iOS 16.0, *)
@MainActor class WeatherKitRequest: ObservableObject {
    
    @Published var weather: Weather?
    var location: CLLocation?
        
    func getWeather(location: CLLocation) async {
        do {
            self.location = location
            weather = try await Task.detached(priority: .userInitiated) {
                return try await WeatherService.shared.weather(for: .init(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude))
            }.value
            var weatherInfo = GPWeatherInfo()
            weatherInfo.temperature = temp
            weatherInfo.cloudDes = lookslikemoji
            GPSGeoManager.wartermarkGPSInfo.weather = weatherInfo
            GPSGeoManager.weatherCachTimestamp = TimeManager.shared.getRealTime().timeIntervalSince1970
            GPSGeoManager.weatherCach = showWeather
            GPFirebaseManager.weatherSucccess()
        } catch {
            LogDebug("\(error)")
            GPFirebaseManager.weatherFail()
            let errorText = "weather_fail, \(String(describing: error.localizedDescription)), systemInfo:  \(GPApp.getDeviceInfoStr())"
            GPErrorUploadManager.uploadError(fileName:#file,lineNumber :#line,functionName :#function,errorText: errorText)
        }
    }
    
    enum WeatherEmoji: String, Codable {
        case blowingDust = "blowingDust"
        case clear = "clear"
        case cloudy = "cloudy"
        case foggy = "foggy"
        case haze = "haze"
        case mostlyClear = "mostlyClear"
        case mostlyCloudy = "mostlyCloudy"
        case partlyCloudy = "partlyCloudy"
        case smokey = "smokey"
        case breezy = "breezy"
        case windy = "windy"
        case drizzle = "drizzle"
        case heavyRain = "heavyRain"
        case isolatedThunderstorms = "isolatedThunderstorms"
        case rain = "rain"
        case sunShowers = "sunShowers"
        case scatteredThunderstorms = "scatteredThunderstorms"
        case strongStorms = "strongStorms"
        case thunderstorms = "thunderstorms"
        case frigid = "frigid"
        case hail = "hail"
        case hot = "hot"
        case flurries = "flurries"
        case sleet = "sleet"
        case snow = "snow"
        case sunFlurries = "sunFlurries"
        case wintryMix = "wintryMix"
        case blizzard = "blizzard"
        case blowingSnow  = "blowingSnow"
        case freezingDrizzle = "freezingDrizzle"
        case freezingRain = "freezingRain"
        case heavySnow = "heavySnow"
        case hurricane = "hurricane"
        case tropicalStorm = "tropicalStorm"
        
        
    }
    
    var emojiweather: String {
        guard let condition = weather?.currentWeather.condition else { return "☀️" }
        
        var isDaytime = true
        if let location = location {
            let solar = Solar(for: TimeManager.shared.getRealTime(), coordinate: location.coordinate)
            isDaytime = solar?.isDaytime ?? true
        }
        
        switch condition {
        case .clear:
            return isDaytime ? "☀️" : "🌙"
        case .blowingDust:
            return "💨"
        case .cloudy:
            return "☁️"
        case .foggy:
            return "🌫️"
        case .haze:
            return "😶‍🌫️"
        case .mostlyClear:
            return "🌤️"
        case .mostlyCloudy:
            return "🌥️"
        case .partlyCloudy:
            return "⛅️"
        case .smoky:
            return "😶‍🌫️"
        case .breezy:
            return "💨"
        case .windy:
            return "🍃"
        case .drizzle:
            return "☔️"
        case .heavyRain:
            return "🌧️"
        case .isolatedThunderstorms:
            return "⚡️"
        case .rain:
            return "🌧️"
        case .sunShowers:
            return "🌤️"
        case .scatteredThunderstorms:
            return "⚡️"
        case .strongStorms:
            return "⛈️"
        case .thunderstorms:
            return "⛈️"
        case .frigid:
            return "🧣"
        case .hail:
            return "❄️"
        case .hot:
            return "🔥"
        case .flurries:
            return "💨"
        case .sleet:
            return "🌨️"
        case .snow:
            return "☃️"
        case .sunFlurries:
            return "🌤️"
        case .wintryMix:
            return "🧣"
        case .blizzard:
            return "🌨️"
        case .blowingSnow:
            return "🌨️"
        case .freezingDrizzle:
            return "🥶"
        case .freezingRain:
            return "🌧️"
        case .heavySnow:
            return "🌨️"
        case .hurricane:
            return "🌪️"
        case .tropicalStorm:
            return "🌪️"
        @unknown default:
            return "☀️"
        }
    }
    
    var lookslikemoji: String {
        let myemoji = "\(WeatherEmoji.self)"
        return "\(myemoji)"
    }
    
    var symbol: String {
        weather?.currentWeather.symbolName ?? "xmark"
    }
    
    var temp: String {
        let temp = weather?.currentWeather.temperature
        
        let convert = temp?.converted(to: .celsius).formatted(.measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
        return convert ?? "Loading Weather Data"
        
    }
    
    var feelslike: String {
        
        let feelslike = weather?.currentWeather.apparentTemperature
        
        let convert = feelslike?.converted(to: .celsius).formatted(.measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .number.precision(.fractionLength(0))))
        return convert ?? "Loading Weather Data"
        
    }
    
    var showWeather: String {
        guard let current = weather?.currentWeather else { return "" }
        let tUnit = current.temperature.unit.symbol
        let temText =  "\(current.temperature.value.formatted(.number.precision(.fractionLength(1))))\(tUnit)"
        return temText + " \(emojiweather)"
    }
    
}
