//
//  OSSUploadManager+Watermark.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/4/6.
//

import Foundation
import QCloudCOSXML

extension OSSUploadManager {
    
    func putWatermarkWithQCloud(image: UIImage, wmID: String?, baseID: String?, finishHandler: @escaping(_ error: Error?) -> Void) {
        
        let resultModel = UIImage.resizeResolutionAndFileSize(sourceImage: image, level: .none)
        guard let data = resultModel.compressedData, let wmID, let baseID else {
            return
        }
        
        let appLan = GPLanguageManager.xhSpecialLocaleIdentifier()
        
        let fileName = "wm_cover/\(appLan)/\(baseID)_\(wmID)_\(Int(image.size.width))_\(Int(image.size.height))"  + ".png"
        
        let request = QCloudCOSXMLUploadObjectRequest<AnyObject>()
        request.body = data as AnyObject
        request.bucket = Watermark_BUCKET_TENCENT
        request.object = fileName
        request.sendProcessBlock = { bytesSent, totalBytesSent, totalBytesExpectedToSend in
            LogDebug("bytesSent:\(bytesSent),totalBytesSent:\(totalBytesSent),totalBytesExpectedToSend:\(totalBytesExpectedToSend)")
        }
        request.setFinish { _, error in
            if let error {
                LogDebug("上传水印失败：\(String(describing: error))")
            } else {
                LogDebug("上传水印成功：\(fileName)")
            }
            finishHandler(error)
        }
        QCloudCOSTransferMangerService.defaultCOSTransferManager().uploadObject(request)
    }
        
}
