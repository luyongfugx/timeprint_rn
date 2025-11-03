//
//  LaunchManager.swift
//  iOSTimeGPS
//
//  Created by ganshiren on 2024/11/15.
//

import Foundation

class LaunchManager {
        
    @GPPersistance(key: "com.gpscamera.launch.launchTime", defaultValue: 0)
    static var launchTimeCount: Int
    
}
