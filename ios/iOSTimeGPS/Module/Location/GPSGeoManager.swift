//
//  GPSGeoManager.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/18.
//

import Foundation
import SwiftLocation
import CoreLocation

class GPSGeoManager {
    
    static let shared = GPSGeoManager()
    
    @GPPersistance(key: "com.gpscamera.key.weathercach", defaultValue: "")
    static var weatherCach: String
    @GPPersistance(key: "com.gpscamera.key.weathercachTime", defaultValue: 0)
    static var weatherCachTimestamp: Double
    
    // 水印上的GPS和地址信息
    static var wartermarkGPSInfo = {
        var info = GPWatermarkGpsGeoInfo()
        // 默认使用经纬度缓存
        info.location = SwiftLocation.lastKnownGPSLocation
        return info
    }()
    
    var isFirstRequest = true

    func startMonitor() {
        
        // 如果没有定位权限，直接退出
//        guard CLLocationManager.authorizationStatus().hasAuthorized else { return }
                
        GPLocationManager.shared.monitorLocation { isSuccess, location, error in
            
            if CameraVC.isAppStoreMode , let location {
                let latitude: Double = Double("k_appstore_latitude".localized()) ?? 21.1159769;
                let longitude: Double = Double("k_appstore_longitude".localized()) ?? 105.7476808;
                // 上架经纬度
                let appStoreLocation = CLLocation.init(latitude: latitude, longitude: longitude);
                    GPSGeoManager.wartermarkGPSInfo.location = appStoreLocation
                    // 定位成功，默认会逆地理请求水印上的逆地理地址（还是使用当前地址，不然出不来）
                    self.regeoSystemAddress(wgs84Lat: location.coordinate.latitude, wgs84Lng: location.coordinate.longitude)
                    // 刷新天气
                    WeatherManger.shared.requstWeather()
                    TimeManager.shared.requestTimeApi(lat: appStoreLocation.coordinate.latitude, lon: appStoreLocation.coordinate.longitude)
               
            }
            else {
                if isSuccess, let location {
                    GPSGeoManager.wartermarkGPSInfo.location = location
                    // 定位成功，默认会逆地理请求水印上的逆地理地址
                    self.regeoSystemAddress(wgs84Lat: location.coordinate.latitude, wgs84Lng: location.coordinate.longitude)
                    // 刷新天气
                    self.requestWeather()
                    TimeManager.shared.requestTimeApi(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                } else {
                    if self.isFirstRequest {
                        // 首次定位，需要展示定位失败弹窗
                    }
                }
            }
      
        }
            
    }
    
    
    
    func requestWeather() {
        // 1、检查选中水印的天气条目是否已经开启
        // 2、缓存时间是否到期
        if let item = WatermarkManager.shared.getSelectWatermarkModel().items?.first(where: { $0.idType == .weather && $0.isOpen == true }) {
            WeatherManger.shared.requstWeather()
        }
    }
    
    func regeoSystemAddress(wgs84Lat: Double, wgs84Lng: Double) {
        GPAddressManager.shared.regeoSystemAddress(wgs84Lat: wgs84Lat, wgs84Lng: wgs84Lng) { [weak self] isSuccess, address, error in
            if isSuccess, let address {
                GPSGeoManager.wartermarkGPSInfo.address = address
                GPCountryManager.geoCountryCode = address.clPlacemark?.isoCountryCode ?? ""
            } else {
                if self?.isFirstRequest == true {
                    // 首次请求失败 3秒后重试
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        // delay
                        self?.regeoSystemAddress(wgs84Lat: wgs84Lat, wgs84Lng: wgs84Lng)
                    }
                }
            }
            self?.isFirstRequest = false
        }
    }
    
    func checkAuthAndMonitor() {
//        // 检测定位权限并开始监听
//        if CLLocationManager.locationServicesEnabled() {
//
//        }
//        startAppCheckLocationStatus()
//
        // 没权限时，做相应的提示
        if CLLocationManager.locationServicesEnabled() {
            let status = CLLocationManager.authorizationStatus()
            if status == .authorizedAlways || status == .authorizedWhenInUse || status == .notDetermined{
                self.startMonitor()
            }
        }
    }
}

extension CLAuthorizationStatus {
    
    var hasAuthorized: Bool {
        switch self {
        case .authorizedAlways, .authorizedWhenInUse:
            return true
        default:
            return false
        }
    }

    var isRejected: Bool {
        switch self {
        case .denied, .restricted:
            return true
        default:
            return false
        }
    }
    
}

struct GPWatermarkGpsGeoInfo {
    var location: CLLocation?
    var address: GPWatermarkAddressInfo?
    var weather: GPWeatherInfo?
    var canEditAddress: Bool {
        get {
            return isNotEmpty(address?.addressDic?.keys)
        }
    }
}

// 地址样式
enum GPAddressStyle: Int, CaseIterable {
    case formatAddress = 0
    case formatAddress1
    case formatAddress2
    case formatAddress3
    case addressDouhao
    case name
    case nameStreet
    case nameRegion
    case nameCity
    case street
    case streetRegion
    case streetCity
    case streetCityCountry
    case cityCountry
}

struct GPWatermarkAddressInfo {
    var formataddress: String?
    var clPlacemark: CLPlacemark?
    var addressDic: [GPAddressStyle: [String?]]?
    
    mutating func generatePlaceDic(_ placeMark: CLPlacemark) {
        clPlacemark = placeMark
        addressDic = [:]
        for item in GPAddressStyle.allCases {
            var componentList: [String?] = []
            switch item {
            case .formatAddress:
                componentList.append(placeMark.getValiedFormattedAddress().0)
            case .addressDouhao:
                componentList.append(placeMark.formattedAddressDouhao)
            case .formatAddress1:
                componentList.append(placeMark.formattedAddress)
            case .formatAddress2:
                componentList.append(placeMark.formattedAddress2)
            case .formatAddress3:
                componentList.append(placeMark.formattedAddress3)
            case .name:
                componentList.append(placeMark.name)
            case .nameStreet:
                componentList.append(placeMark.name)
                componentList.append(placeMark.thoroughfare)
            case .nameRegion:
                componentList.append(placeMark.name)
                componentList.append(placeMark.subLocality)
            case .nameCity:
                componentList.append(placeMark.name)
                componentList.append(placeMark.locality)
            case .street:
                componentList.append(placeMark.thoroughfare)
            case .streetRegion:
                componentList.append(placeMark.thoroughfare)
                componentList.append(placeMark.subLocality)
            case .streetCity:
                componentList.append(placeMark.thoroughfare)
                componentList.append(placeMark.locality)
            case .streetCityCountry:
                componentList.append(placeMark.thoroughfare)
                componentList.append(placeMark.locality)
                componentList.append(placeMark.country)
            case .cityCountry:
                componentList.append(placeMark.locality)
                componentList.append(placeMark.country)
            }
            addressDic?[item] = componentList
        }
    }
    
    func getShowAddress(_ addressStyle: GPAddressStyle, isForCover: Bool) -> String? {
        
        if CameraVC.isAppStoreMode {
            // 上架图地址
            return "k_appstore_address".localized()
        }
        
        // 通过非formatAddress类型，返回地址
        if addressStyle != .formatAddress, addressDic?.keys.contains(addressStyle) == true {
            if let componentList = addressDic?[addressStyle], let address = getComponetMerge(componentList) {
//                LogDebug("通过非formatAddress类型：\(addressStyle)，得出地址：\(address)")
                return address
            }
        }
        
        // 通过formatAddress类型，返回地址
        if let formataddressList = addressDic?[.formatAddress], let address = getComponetMerge(formataddressList) {
//            LogDebug("通过formatAddress类型：\(addressStyle)，得出地址：\(address)")
            return address
        }
        
        if isForCover, formataddress?.isEmpty == true {
            return "k_appstore_address".localized()
        }
        
//        LogDebug("通过外部设置的formatAddress地址返回：\(String(describing: formataddress))")
        return formataddress
    }
    
    private func getComponetMerge(_ list: [String?]) -> String? {
        if clPlacemark?.isoCountryCode == "CN" {
            // 中国正着拼接
            if let li = list.filter({ isNotEmpty($0) }) as? [String]{
                let str = li.reversed().joined(separator: "")
                return str
            }
        } else {
            // 其它国家反拼接
            if let li = list.filter({ isNotEmpty($0) }) as? [String]{
                let str = li.joined(separator: ", ")
                return str
            }
        }
        return nil
    }
    
    func getAddressByStyle(_ style: GPAddressStyle) -> String? {
        if let addressList = addressDic?[style], let address = getComponetMerge(addressList) {
            return address
        } else {
            return nil
        }
    }
}

struct GPWeatherInfo {
    var temperature: String? // 温度
    var cloudDes: String? // 天气描述
   
}
