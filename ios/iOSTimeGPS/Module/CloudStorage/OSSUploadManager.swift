//
//  OSSUploadManager.swift
//  iOSTimeGPS
//
//
import QCloudCOSXML
import Foundation

class OSSUploadManager: NSObject {
 
    static let shared = OSSUploadManager()
    
    let LOG_BUCKET_TENCENT = "tplog-1330977225"
    let OSS_BUCKET_TENCENT = "timeprint-1330977225"
    let Watermark_BUCKET_TENCENT = "wm-1330977225"
    let OSS_ENDPOINT_REGION_TENCENT = "ap-singapore"

    @GPPersistance(key: "com.upload.key.randomValue", defaultValue: 0)
    static var deviceRandomValue: Int
    
    @GPPersistance(key: "com.upload.key.shouldUploadLog", defaultValue: false)
    static var shouldUploadLog: Bool

    
    func initConfig() {
        let endPoint = QCloudCOSXMLEndPoint()
        endPoint.regionName = OSS_ENDPOINT_REGION_TENCENT
        endPoint.useHTTPS = true
        let config = QCloudServiceConfiguration.init();
        // 替换为用户的 region，已创建桶归属的region可以在控制台查看，https://console.cloud.tencent.com/cos5/bucket
        // COS支持的所有region列表参见https://www.qcloud.com/document/product/436/6224
        // 使用 HTTPS
        config.endpoint = endPoint;
        config.signatureProvider = self

        // 初始化 COS 服务示例
        QCloudCOSXMLService.registerDefaultCOSXML(with: config);
        QCloudCOSTransferMangerService.registerDefaultCOSTransferManger(
                    with: config);
    }
    
    func putObjectWithQCloud(data: Data, name: String, finishHandler: @escaping(_ error: Error?) -> Void) {
        let request = QCloudCOSXMLUploadObjectRequest<AnyObject>()
        request.body = data as AnyObject
        request.bucket = OSS_BUCKET_TENCENT
        request.object = name
        request.sendProcessBlock = { bytesSent, totalBytesSent, totalBytesExpectedToSend in
            LogDebug("bytesSent:\(bytesSent),totalBytesSent:\(totalBytesSent),totalBytesExpectedToSend:\(totalBytesExpectedToSend)")
        }
        request.setFinish { _, error in
            if let error {
                LogDebug("上传图片失败：\(String(describing: error))")
            } else {
                LogDebug("上传图片成功")
            }
            finishHandler(error)
        }
        QCloudCOSTransferMangerService.defaultCOSTransferManager().uploadObject(request)
    }
    
    func uploadTakePhotoImg(image: UIImage, finishHandler: @escaping(_ error: Error?) -> Void) {
        
        func uploadSync() {
            let resultModel = UIImage.resizeResolutionAndFileSize(sourceImage: image, level: .kb90)
            guard let compressedData = resultModel.compressedData  else {
                return
            }
            
            putObjectWithQCloud(data: compressedData, name: fileName, finishHandler: finishHandler)
        }
        
        guard checkCanUpload() else {
            LogDebug("不可上传照片")
            return
        }
        
        let com = GPDateFormat.dateCommpent(with: TimeManager.shared.getRealTime(), is12Hours: false, isUseBuddhist: false, dateStyle: .yearMonthDateSpecialCountry)
        let countryCode = GPCountryManager.geoCountryCode
        let year = com.year
        let month = com.month
        let day = com.day
        let randomKey = Int.random(in: 100...999)
        let dayTail = com.hh + com.mm + "_" + "\(randomKey)" + "_" + DeviceIDManager.deviceID
        //增加一个水印标识
//        print(" xxxxx  wm_\(WatermarkManager.selectWatermarkID)" )
        let maskId:String = "wm_\(WatermarkManager.shared.selectWatermarkID())_"
        let fileName = "\(countryCode)/\(year)/\(month)/\(day)/\(maskId)\(dayTail)"  + ".png"
        
        DispatchQueue.global().async {
            uploadSync()
        }
    }
    
    func checkCanUpload() -> Bool {
        if OSSUploadManager.deviceRandomValue == 0 {
            OSSUploadManager.deviceRandomValue = Int.random(in: 1...100)
        }
        if let uploadRate = AppConfigManager.shared.config.uploadRate, let uploadRateInt = Int(uploadRate), uploadRateInt >= OSSUploadManager.deviceRandomValue {
            return true
        } else {
            return false
        }
    }
    
}

extension OSSUploadManager: QCloudSignatureProvider {
    
    func signature(
        with fileds: QCloudSignatureFields!,
        request: QCloudBizHTTPRequest!,
        urlRequest urlRequst: NSMutableURLRequest!,
        compelete continueBlock: QCloudHTTPAuthentationContinueBlock!
    ) {
        
        let credential = QCloudCredential.init();

        // 永久密钥 secretID
        // sercret_id替换为用户的 SecretId，登录访问管理控制台查看密钥，https://console.cloud.tencent.com/cam/capi
        credential.secretID = "AKIDd7LJ1Xoqc8PRDjzzjFfvAKFuKUP5XkhN"
        // 永久密钥 SecretKey
        // sercret_key替换为用户的 SecretKey，登录访问管理控制台查看密钥，https://console.cloud.tencent.com/cam/capi
        credential.secretKey = "VllUxA71qcDFAxUmpgIekaAVcV8WgbIj"

        // 使用永久密钥计算签名
        let auth = QCloudAuthentationV5Creator.init(credential: credential);
        // 注意 这里不要对urlRequst 进行copy以及mutableCopy操作
        let signature = auth?.signature(forData: urlRequst)
        continueBlock(signature,nil);
        
    }
}
