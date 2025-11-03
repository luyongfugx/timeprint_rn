//
//  GPLogManager.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/13.
//

import Foundation
import UIKit
import CocoaLumberjack

func LogDebug(_ message: String,
                file: StaticString = #file,
                function: StaticString = #function,
                line: UInt = #line) {
    DDLogDebug(message, file: file, function: function, line: line)
    print(message)
}

class GPLogManager {
    // 配置日志信息
    static func configDDLog() {
        // 1.自定义Log格式
        let consoleLogFormatter = GPConsoleLogFormatter()
        
        // 2.DDASLLogger，日志语句发送到苹果文件系统、日志状态发送到Console.app
        //        DDOSLogger.sharedInstance.logFormatter = consoleLogFormatter
        //        DDLog.add(DDOSLogger.sharedInstance)
        
        //3.DDFileLogger，日志语句写入到文件中（默认路径：Library/Caches/Logs/目录下，文件名为bundleid+空格+日期.log）
        let path = GPSandbox.shared.cachesDirectory + "/TPCamera.log"
        let logFileManager = DDLogFileManagerDefault.init(logsDirectory: path)
        let fileLogger = DDFileLogger.init(logFileManager: logFileManager)
        // 每24小时创建一个新文件
        fileLogger.rollingFrequency = 60*60*24
        // 最多允许创建10个文件
        fileLogger.logFileManager.maximumNumberOfLogFiles = 10
        // 最大文件大小5MB
        fileLogger.maximumFileSize = 1024 * 1024 * 5
        fileLogger.logFormatter = GPFileLogFormatter()
        DDLog.add(fileLogger)
        
        // 4.DDTTYLogger，日志语句发送到Xcode
        if let sharedInstance = DDTTYLogger.sharedInstance{
            sharedInstance.logFormatter = consoleLogFormatter
            DDLog.add(sharedInstance)
        }
    }
    
    //上传日志到oss
    static func uploadLogs(isFromFeedback: Bool) {
        let path = GPSandbox.shared.cachesDirectory + "/TPCamera.log"
        let enumerator = FileManager.default.enumerator(atPath: path)
        while let element = enumerator?.nextObject() as? String {
            if element.hasSuffix("log") { // checks the extension
                let filePath = path + "/" + element
                uploadLog(isFromFeedback: isFromFeedback, filePath: filePath, fileName: element)
            }
        }
    }
    
    static func uploadLog(isFromFeedback: Bool, filePath: String, fileName: String) {
        
        guard OSSUploadManager.shared.checkCanUploadLog() else {
            LogDebug("不可上传Log")
            return
        }
                
        OSSUploadManager.shared.uploadErrorLog(isFromFeedback: isFromFeedback, localpath: filePath) { error in
            //
            LogDebug("上传日志结果：\(String(describing: error))")
        }
        
//        XHUploadManager.shared.upload(objectKey: objectKey, fileLocalPath: filePath, fileData: nil, needFailureToUseXheyServer: true, uploadProgress: nil, successHandler: nil, failure: nil)
    }
}

class GPConsoleLogFormatter: DDAbstractLogger, DDLogFormatter {
    
    func format(message logMessage: DDLogMessage) -> String? {
        
        var loglevelStr = ""
        switch logMessage.flag {
        case .error:
            loglevelStr = "[ERROR]"
        case .warning:
            loglevelStr = "[WARN]"
        case .info:
            loglevelStr = "[INFO]"
        case .debug:
            loglevelStr = "[DEBUG]"
        case .verbose:
            loglevelStr = "[VBOSE]"
        default:
            loglevelStr = ""
        }
        
        let dateNow = logMessage.timestamp
        // 2.9.250:使用toString_xh有卡死的风险，当这个方法还没有走完，就打印log的时候
        let dateFormater = DateFormatter()
        dateFormater.timeZone = TimeZone.init(identifier: "Asia/Shanghai")
        dateFormater.locale = Locale(identifier: "zh_CN")
        dateFormater.calendar = Calendar.init(identifier: .iso8601)
        
        dateFormater.dateFormat = "YYYY-MM-dd HH:mm:ss.SSS Z"
        let currentTimeStr = dateFormater.string(from: dateNow)
        
        // 1.0.95
        // let resultStr = "[\(currentTimeStr)] \(loglevelStr) \(logMessage.message),  (\(logMessage.fileName):\(logMessage.line) \(logMessage.function ?? ""))"
        let resultStr = "[\(currentTimeStr)] \(loglevelStr) \(logMessage.message)"
        return resultStr
    }
}

class GPFileLogFormatter: DDAbstractLogger, DDLogFormatter {
    func format(message logMessage: DDLogMessage) -> String? {
        
        var loglevelStr = ""
        switch logMessage.flag {
        case .error:
            loglevelStr = "[ERROR]"
        case .warning:
            loglevelStr = "[WARN]"
        case .info:
            loglevelStr = "[INFO]"
        case .debug:
            loglevelStr = "[DEBUG]"
        case .verbose:
            loglevelStr = "[VBOSE]"
        default:
            loglevelStr = ""
        }
        
        let dateNow = logMessage.timestamp
        // 2.9.250:使用toString_xh有卡死的风险，当这个方法还没有走完，就打印log的时候
        let dateFormater = DateFormatter()
        dateFormater.timeZone = TimeZone.init(identifier: "Asia/Shanghai")
        dateFormater.locale = Locale(identifier: "zh_CN")
        dateFormater.calendar = Calendar.init(identifier: .iso8601)
        
        dateFormater.dateFormat = "YYYY-MM-dd HH:mm:ss.SSS Z"
        let currentTimeStr = dateFormater.string(from: dateNow)
        
        // 1.0.95
        // let resultStr = "[\(currentTimeStr)] \(loglevelStr) \(logMessage.message),  (\(logMessage.fileName):\(logMessage.line) \(logMessage.function ?? ""))"
        let resultStr = "[\(currentTimeStr)] \(loglevelStr) \(logMessage.message)"
        return resultStr
    }
    
}
