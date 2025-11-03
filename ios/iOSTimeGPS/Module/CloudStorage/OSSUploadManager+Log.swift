//
//  OSSUploadManager+Log.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/21.
//

import Foundation
import QCloudCOSXML

extension OSSUploadManager {
    
    private func putLogWithQCloud(data: Data, name: String, finishHandler: @escaping(_ error: Error?) -> Void) {
        let request = QCloudCOSXMLUploadObjectRequest<AnyObject>()
        request.body = data as AnyObject
        request.bucket = LOG_BUCKET_TENCENT
        request.object = name
        request.sendProcessBlock = { bytesSent, totalBytesSent, totalBytesExpectedToSend in
//            LogDebug("bytesSent:\(bytesSent),totalBytesSent:\(totalBytesSent),totalBytesExpectedToSend:\(totalBytesExpectedToSend)")
        }
        request.setFinish { _, error in
            if let error {
                LogDebug("上传Log失败：\(String(describing: error))")
            } else {
                LogDebug("上传Log成功")
            }
            finishHandler(error)
        }
        QCloudCOSTransferMangerService.defaultCOSTransferManager().uploadObject(request)
    }
    
    func uploadErrorApi(apiName: String, logText: String, finishHandler: @escaping(_ error: Error?) -> Void) {
        
        LogDebug("error api log upload:\(apiName)，logtext：\(logText)")

//
//        func uploadSync() {
//            guard let data = logText.data(using: .utf8) else {
//                return
//            }
//            
//            putLogWithQCloud(data: data, name: fileName, finishHandler: finishHandler)
//        }
//        
//        guard checkCanUploadLog() else {
//            LogDebug("不可上传Log")
//            return
//        }
//        
//        LogDebug("error api log upload:\(apiName)，logtext：\()")
//        
//        let com = GPDateFormat.dateCommpent(with: TimeManager.shared.getRealTime(), is12Hours: false, isUseBuddhist: false, dateStyle: .yearMonthDateSpecialCountry)
//        let countryCode = GPCountryManager.geoCountryCode
//        let version = GPApp.version
//        let year = com.year
//        let month = com.month
//        let day = com.day
//        let randomKey = Int.random(in: 100...999)
//        let dayTail = com.hh + com.mm + "_" + "\(randomKey)" + "_" + DeviceIDManager.deviceID
//        
//        let fileName = "\(apiName)/\(year)/\(month)/\(day)/\(version)_\(countryCode)_\(dayTail)"  + ".txt"
//        
//        DispatchQueue.global().async {
//            uploadSync()
//        }
    }
    
    func uploadErrorLog(isFromFeedback: Bool, localpath: String, finishHandler: @escaping(_ error: Error?) -> Void) {
        
        func uploadSync() {
            
            do {
                // 直接通过 URL 读取 Data
                let fileURL = URL(fileURLWithPath: localpath)
                let data = try Data(contentsOf: fileURL)
                print("成功读取数据，字节数: \(data.count)")
                putLogWithQCloud(data: data, name: fileName, finishHandler: finishHandler)

            } catch {
                print("读取文件失败: \(error.localizedDescription)")
            }
                        
        }
        
        guard checkCanUploadLog() else {
            LogDebug("不可上传Log")
            return
        }
                
        let com = GPDateFormat.dateCommpent(with: TimeManager.shared.getRealTime(), is12Hours: false, isUseBuddhist: false, dateStyle: .yearMonthDateSpecialCountry)
        let countryCode = GPCountryManager.geoCountryCode
        let version = GPApp.version
        let year = com.year
        let month = com.month
        let day = com.day
        let randomKey = Int.random(in: 100...999)
        let dayTail = com.hh + com.mm + "_" + "\(randomKey)" + "_" + DeviceIDManager.deviceID
        let superFolder = isFromFeedback ? "feedbackLog" : "newErrorLog"
        let fileName = "\(superFolder)/\(year)/\(month)/\(day)/\(version)_\(countryCode)_\(dayTail)"  + ".txt"
        
        DispatchQueue.global().async {
            uploadSync()
        }
    }
    
    func checkCanUploadLog() -> Bool {
        if OSSUploadManager.deviceRandomValue == 0 {
            OSSUploadManager.deviceRandomValue = Int.random(in: 1...100)
        }
        if let uploadRate = AppConfigManager.shared.config.logRate {
            if let uploadRateInt = Int(uploadRate), uploadRateInt >= OSSUploadManager.deviceRandomValue {
                return true
            } else {
                return false
            }
        } else {
            return true
        }
    }
    
}
