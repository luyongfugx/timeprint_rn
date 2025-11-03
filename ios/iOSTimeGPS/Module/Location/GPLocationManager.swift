//
//  GPLocationManager.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/18.
//

import Foundation
import SwiftLocation
import CoreLocation

typealias LocationCompletionHandler = (_ isSuccess: Bool, CLLocation?, Error?) -> ()

class GPLocationManager {
    
    static let shared = GPLocationManager()
    
    var lcationRequestID: String?
    
    var lastGPSLocation: CLLocation?
    
    private var subscribeCompletionList: [String: LocationCompletionHandler] = [:]
    
    private let operationQueue = DispatchQueue(label: "Operations.GPLocationManager")


    // 获取当前定位
    func monitorLocation(complete: LocationCompletionHandler?) {
        
//        guard lcationRequestID == nil else { return }
        
        // 不在后台刷新位置
        SwiftLocation.allowsBackgroundLocationUpdates = false
        
        lcationRequestID = SwiftLocation.gpsLocationWith {
            $0.subscription = .continous // 持续定位
            $0.accuracy = .block // 半径100米
            $0.precise = .fullAccuracy // 高精度
            $0.minDistance = 10 // 最少移动100米后更新经纬度
            $0.minTimeInterval = 10 // 最少间隔10秒更新
            $0.activityType = .fitness // 走动时更新
        }.then(queue: operationQueue) { [weak self] result in
            switch result {
            case .success(let newData):
                print("New location: \(newData)")
                if let latestLocation = SwiftLocation.lastKnownGPSLocation {
                    self?.lastGPSLocation = latestLocation
                    // 子线程回调首次监听
                    complete?(true, latestLocation, nil)
                    // 主线程回调外部所有订阅
                    self?.handleSubscribeCallback(true, latestLocation, nil)
                } else {
                    complete?(false, nil, NSError(domain: "没有最新经纬度位置", code: -2, userInfo: nil))
                    self?.handleSubscribeCallback(false, nil, NSError(domain: "没有最新经纬度位置", code: -2, userInfo: nil))
                }
                
            case .failure(let error):
                complete?(false, nil, error)
                self?.handleSubscribeCallback(false, nil, error)
            }
        }
        
    }
    
    private func handleSubscribeCallback(_ isSuccess: Bool, _ location: CLLocation?, _ error: Error?) {
        GPSafeMainAsync {
            for callback in self.subscribeCompletionList.values {
                callback(isSuccess, location, error)
            }
        }
    }
    
    func subscribe(complete: @escaping LocationCompletionHandler) -> String {
        let identify = NSUUID().uuidString
        subscribeCompletionList[identify] = complete
        return identify
    }
    
    func cancleSubscribe(identify: String) {
        subscribeCompletionList.removeValue(forKey: identify)
    }
}
