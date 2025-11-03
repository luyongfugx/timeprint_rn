//
//  GPAddressManager.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/18.
//

import Foundation
import SwiftLocation

typealias AddressCompletionHandler = (_ isSuccess: Bool, GPWatermarkAddressInfo?, Error?) -> ()

class GPAddressManager {
    
    static let shared = GPAddressManager()
        
    var systemGeoRequestID: String?

    private let operationQueue = DispatchQueue(label: "Operations.GPAddressManager")
    
    private var subscribeCompletionList: [String: AddressCompletionHandler] = [:]

    func regeoSystemAddress(wgs84Lat: Double, wgs84Lng: Double, complete: AddressCompletionHandler?) {
        
        // 同一时间只请求一次逆地理
        cancleLastGeo()
        
        var latitude = wgs84Lat
        var longitude = wgs84Lng
        
        if GPCountryManager.isChina {
            // 中国地区特殊处理，转成gcj02再请求
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let gcj02 = GPLocationConverter.wgs84(toGcj02: coordinate)
            latitude = gcj02.latitude
            longitude = gcj02.longitude
        }
                        
        let service = Geocoder.Apple(coordinates: .init(latitude: latitude, longitude: longitude))
        systemGeoRequestID = SwiftLocation.geocodeWith(service).then { [weak self] result in
            switch result {
            case .success(let geoLocation):
                var addreeInfo = GPWatermarkAddressInfo()
                
                if let geo = geoLocation.first, let placeMark = geo.clPlacemark {
                    if let validAddress = geo.clPlacemark?.getValiedFormattedAddress().0 {
                        addreeInfo.generatePlaceDic(placeMark)
                        addreeInfo.formataddress = validAddress
                        complete?(true, addreeInfo, nil)
                        self?.handleSubscribeCallback(true, addreeInfo, nil)
                        LogDebug("geo succ，:\(validAddress)")
                        return
                    }
                } else {
                    LogDebug("geo fail，geoLocations is null")
                }
                self?.handleSubscribeCallback(false, nil, NSError(domain: "没有地址位置", code: -2, userInfo: nil))
                complete?(false, nil, NSError(domain: "没有地址位置", code: -2, userInfo: nil))

            case .failure(let error):
                LogDebug("geo fail：\(error)")
                self?.handleSubscribeCallback(false, nil, error)
                complete?(false, nil, NSError(domain: "geo fail：\(error)", code: -1, userInfo: nil))

            }

        }
    }
    
    private func handleSubscribeCallback(_ isSuccess: Bool, _ addressInfo: GPWatermarkAddressInfo?, _ error: Error?) {
        GPSafeMainAsync {
            for callback in self.subscribeCompletionList.values {
                callback(isSuccess, addressInfo, error)
            }
        }
    }
    
    func subscribe(complete: @escaping AddressCompletionHandler) -> String {
        let identify = NSUUID().uuidString
        subscribeCompletionList[identify] = complete
        return identify
    }
    
    func cancleSubscribe(identify: String) {
        subscribeCompletionList.removeValue(forKey: identify)
    }
    
    func cancleLastGeo() {
        guard let systemGeoRequestID = systemGeoRequestID else { return }
        SwiftLocation.cancel(subscription: systemGeoRequestID)
    }
    
}
