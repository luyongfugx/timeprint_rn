//
//  GPOrientationMamager.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/3.
//

import UIKit
import CoreMotion
import GPCam

protocol GPOrientationMamagerDelegate: class {
    func GPOrientationMamagerOrientationChange(currentOrientation: GPOrientation, oldOrientation: GPOrientation)
}

class GPOrientationManager: NSObject {
    let sensitive = 0.7
    let smoothX : BMWLinearSmoothFilter = BMWLinearSmoothFilter()
    let smoothY : BMWLinearSmoothFilter = BMWLinearSmoothFilter()
    static let shared = GPOrientationManager()
    
    private override init(){}
    
    private var monitor = CMMotionManager()
    weak var delegate: GPOrientationMamagerDelegate?
    private var oldOrientation = GPOrientation.unknownDirection
    private(set) var lastOrientation = GPOrientation.unknownDirection
    
    // MARK: - 屏幕方向 1:横屏  2:竖屏
    var screenType: Int {
//        if XHWartermarkDirectionType.getCurrentType() == .heri {
//            return 1
//        } else if XHWartermarkDirectionType.getCurrentType() == .verti {
//            return 2
//        }
        var orientation = self.getOrientation()
        if orientation == .unknownDirection {
            orientation = self.lastOrientation
        }
        
        if orientation == .unknownDirection{
            orientation = .portraitDirection
        }
        
        // 1:横屏  2:竖屏
        var type = 0
        if orientation == .portraitDirection || orientation == .downDirection {
            type = 2
        }else{
            type = 1
        }
        return type
    }
    
    /*
     func getOrientation()->GPOrientation{
         
         if let myMotion = monitor.deviceMotion{
             return deviceMotion(myMotion)
         }
         return .portraitDirection
     }
     */
    
    // MARK: - 获取当前的方向 V2.9.82使用这个，尝试解决用户水印乱跳的问题
    func getOrientation() -> GPOrientation {
        
//        if XHWartermarkDirectionType.getCurrentType() == .heri {
//            return .leftDirection
//        }
//        if XHWartermarkDirectionType.getCurrentType() == .verti {
//            return .portraitDirection
//        }
        if self.lastOrientation != .unknownDirection {
            return self.lastOrientation
        }
        return .portraitDirection
    }
    
    // 开始监测
    func startMonitor(){
        // 被动启动不启动sensor
        if BMWALifeCycleHelper.sharedInstance().launchedPassively {
            return
        }
//        if XHWartermarkDirectionType.getCurrentType() == .heri || XHWartermarkDirectionType.getCurrentType() == .verti {
//            return
//        }
        smoothX.factor = 0.5
        smoothY.factor = 0.5
        //检测时间间隔,1/10.0刷新频率太高了
        monitor.accelerometerUpdateInterval = 1/10.0 // V2.9.82版本改为1/10.0
        if(monitor.isAccelerometerAvailable){
            
            monitor.startAccelerometerUpdates(to: .main, withHandler: { [weak self] (motion, error) in
                
                if error == nil, let myMotion = motion, let currentOrientation = self?.deviceMotion(myMotion), let oldOrientation = self?.oldOrientation,
                    currentOrientation != oldOrientation {
                    
//                    XHLogInfo("[屏幕方向调试] - 更新水印方向")
                    self?.delegate?.GPOrientationMamagerOrientationChange(currentOrientation: currentOrientation, oldOrientation: oldOrientation)
                    self?.oldOrientation = currentOrientation
                    if currentOrientation != .unknownDirection {
                        self?.lastOrientation = currentOrientation
                    }
                }
            })
        }
    }
    
    // MARK: - 停止陀螺仪
    func stopMonitor(){
        monitor.stopAccelerometerUpdates()
        smoothX.reset()
        smoothY.reset()
//        XHLogInfo("[屏幕方向调试] - 停止陀螺仪")
    }
    
    // 更新屏幕方向
    
    private func deviceMotion(_ motion: CMAccelerometerData) -> GPOrientation {
        let x_ = motion.acceleration.x
        let y_ = motion.acceleration.y
        let x = smoothX.smoothFilter(x_)
        let y = smoothY.smoothFilter(y_)
        
        let tolerance = 0.3 // 允许的模糊区间

        if y < 0 {
            if fabs(y) > sensitive {
                return .portraitDirection
            } else if fabs(y) > (sensitive - tolerance) && (lastOrientation == .portraitDirection || lastOrientation == .unknownDirection) {
                return .portraitDirection
            }
        } else {
            if y > sensitive {
                return .downDirection
            } else if y > (sensitive - tolerance) && (lastOrientation == .downDirection || lastOrientation == .unknownDirection) {
                return .downDirection
            }
        }

        if x < 0 {
            if fabs(x) > sensitive {
                return .leftDirection
            } else if fabs(x) > (sensitive - tolerance) && (lastOrientation == .leftDirection || lastOrientation == .unknownDirection) {
                return .leftDirection
            }
        } else {
            if x > sensitive {
                return .rightDirection
            } else if x > (sensitive - tolerance) && (lastOrientation == .rightDirection || lastOrientation == .unknownDirection) {
                return .rightDirection
            }
        }

        // 如果都不是，保留之前方向，避免闪回 unknown
        return lastOrientation != .unknownDirection ? lastOrientation : .portraitDirection
    }

}
