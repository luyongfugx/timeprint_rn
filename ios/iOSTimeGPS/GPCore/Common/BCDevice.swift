//
//  BCDevice.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/12/30.
//

import Foundation

import DeviceKit

open class BCDevice: NSObject {
    private var deviceIdentifier = ""
    private var deviceModel = ""
    
    public static let shared: BCDevice = {
        let instance = BCDevice()
        return instance
    }()
    
    override private init() {
        super.init()
        deviceIdentifier = Device.identifier
        deviceModel = Device.current.description
    }
    
    /// 获取设备型号处理后的
    /// - Returns: 手机型号名称, switch case后的
    open func getDeviceModel() -> String {
        return deviceModel
    }
    
    /// 获取设备型号处理前的
    /// - Returns: 手机型号名称, switch case前的
    open func getDeviceIdentifier() -> String {
        return deviceIdentifier
    }
    
    // MARK: - 设备的剩余空间大小MB

    open func getDiskFreeSpace() -> Int {
        var totalFreeSpace = 0
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let pathStr = paths.last {
            do {
                let dictionary = try FileManager.default.attributesOfFileSystem(forPath: pathStr)
                if let freeFileSystemSizeInBytes = dictionary[.systemFreeSize] as? Double {
                    totalFreeSpace = Int(freeFileSystemSizeInBytes / 1024 / 1024)
                }
            } catch {
                print("fail。。。")
            }
        }
        
        return totalFreeSpace
    }
    
    // 获取磁盘的总大小MB
    open func getTotalDiskSpace() -> Int {
        var totalFreeSpace = 0
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        if let pathStr = paths.last {
            do {
                let dictionary = try FileManager.default.attributesOfFileSystem(forPath: pathStr)
                if let freeFileSystemSizeInBytes = dictionary[.systemSize] as? Double {
                    totalFreeSpace = Int(freeFileSystemSizeInBytes / 1024 / 1024)
                }
            } catch {
                print("fail。。。")
            }
        }
        
        return totalFreeSpace
    }
    
    open func getMemoryUsage() -> (used: UInt64, total: UInt64) {
        var taskInfo = task_vm_info_data_t()
        var count = mach_msg_type_number_t(MemoryLayout<task_vm_info>.size) / 4
        let result: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        
        var used: UInt64 = 0
        if result == KERN_SUCCESS {
            used = UInt64(taskInfo.phys_footprint)
        }
        
        let total = ProcessInfo.processInfo.physicalMemory
        return (used, total)
    }
}
