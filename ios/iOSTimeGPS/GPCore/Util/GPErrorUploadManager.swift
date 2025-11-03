//
//  GPErrorUploadManager.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/12/11.
//

import Foundation

import UIKit
import GPCam
import Photos
import AVFoundation
/**
 s上报错误
 */
class GPErrorUploadManager {
    
    static  func getStorageInfo() -> String {
        let totalSpace = getTotalSpace()
        let freeSpace = getFreeSpace()
        let totalSpaceMB = totalSpace / (1024 * 1024)
        let freeSpaceMB = freeSpace / (1024 * 1024)
//        print("Total Storage: \(totalSpace) bytes")
//        print("Free Storage: \(freeSpace) bytes")
        return "Total Storage: \(totalSpaceMB) mb, Free Storage: \(freeSpaceMB) mb"
    }

    static  func getTotalSpace() -> Int64 {
        let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        if let totalSize = attributes?[FileAttributeKey.systemSize] as? NSNumber {
            return totalSize.int64Value
        }
        return 0
    }

    static  func getFreeSpace() -> Int64 {
        let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
        if let freeSize = attributes?[FileAttributeKey.systemFreeSize] as? NSNumber {
            return freeSize.int64Value
        }
        return 0
    }
    

    
    static private var ErrorFileName: String = "error_log"
    static func uploadError(fileName:String,lineNumber:Int ,functionName:String, errorText:String) {
        // 只有上报错误日志时，才会在下次冷启动再上报
        OSSUploadManager.shouldUploadLog = true
        OSSUploadManager.shared.uploadErrorApi(apiName: ErrorFileName, logText: "fileName：\(fileName), lineNumber：\(lineNumber), functionName：\(functionName) error :\(errorText)"  ) { error in
        }
    }
}
