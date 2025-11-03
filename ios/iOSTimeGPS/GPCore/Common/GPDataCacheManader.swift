//
//  GPDataCacheManader.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/13.
//

import UIKit
import Kingfisher

enum DataCacheType: String {
    
    // 网络层
    case GPApi = "Api"
    
    // 本地业务数据
    case GPLocalBusinessData = "GPLocalBusinessData"

    case Logo = "Logo"
    case Cover = "Cover"
    case Video = "Video"
}

class GPDataCacheManager: NSObject {
  
    
    static let shared = GPDataCacheManager()
    // 缓存的文件夹路径
    let cacheFolderPath = GPSandbox.shared.libraryDirectory + "/" + "GPAppCache"
    
    let cacheTypes: [DataCacheType] = [.GPApi, .GPLocalBusinessData]
    
    var cachLogoDic: [String: UIImage] = [:]
    var cachCoverDic: [String: UIImage] = [:]
    
    let lock = NSLock()

    // 禁止外部调用init初始化方法
    private override init() {
        super.init()
        
        GPFileManager.checkDirectory(at: cacheFolderPath)
        for type in self.cacheTypes {
            let folderPath = self.cacheFolderPath + "/" + type.rawValue
            GPFileManager.checkDirectory(at: folderPath)
        }
    }
    

    /// 获取缓存文件路径
    /// - Parameters:
    ///   - cacheKey: 缓存的key
    ///   - subPath: 子路径
    /// - Returns: 全路径
    func getCacheFilePath(cacheKey: String, cacheType: DataCacheType) -> String {
        
        // 文件夹的路径
        let folderPath = self.cacheFolderPath + "/" + cacheType.rawValue
                
        // 检查目录
        GPFileManager.checkDirectory(at: folderPath)
        
        // 全路径
        let fullPath = folderPath + "/" + cacheKey
        return fullPath
    }
    
}

// MARK: - 保存缓存数据
extension GPDataCacheManager {
    
    /// 使用model缓存数据
    /// - Parameters:
    ///   - model: 缓存的model
    ///   - cacheKey: 缓存的key
    ///   - cacheType: 缓存类型，具体那个文件夹
    /// - Returns: 是否成功
    @discardableResult
    func cacheModelData<T>(_ model: T, cacheKey: String, cacheType: DataCacheType) -> Bool where T: Encodable {
        
        guard let obj = GPModelUtil.modelToAnyObject(model) else {
            LogDebug("[cache debug] - cacheData - model转换成json失败")
            return false
        }
        
        let isSuccess = self.cacheData(jsonObject: obj, cacheKey: cacheKey, cacheType: cacheType)
        return isSuccess
    }
    
    /// 使用model异步缓存数据
    /// - Parameters:
    ///   - model: 缓存的model
    ///   - cacheKey: 缓存的key
    ///   - cacheType: 缓存类型，具体那个文件夹
    ///   - complete: 回调
    func asyncCacheModelData<T>(_ model: T, cacheKey: String, cacheType: DataCacheType, complete: ((_ isSuccess: Bool) -> Void)?) where T: Encodable {
        
        guard let obj = GPModelUtil.modelToAnyObject(model) else {
            LogDebug("[cache debug] - asyncCacheData - model转换成json失败")
            complete?(false)
            return
        }
        
        self.asyncSaveCache(obj, cacheKey: cacheKey, cacheType: cacheType) { isSuccess in
            
            complete?(isSuccess)
        }
    }
    
    /// 删除缓存数据
    /// - Parameters:
    ///   - cacheKey: 缓存的key
    ///   - cacheType: 缓存类型，具体那个文件夹
    ///   - completeHandler: 主线程回调
    func asyncDelCache(cacheKey: String, cacheType: DataCacheType, complete: ((_ isSuccess: Bool) -> Void)?) {
        
        DispatchQueue.global().async { [weak self] in
            
            let result = self?.syncDelCache( cacheKey: cacheKey, cacheType: cacheType)
            DispatchQueue.main.async {
                complete?(result ?? false)
            }
        }
    }
    
    /// 异步写入缓存数据
    /// - Parameters:
    ///   - jsonObject: 要写入的数据(JSON)
    ///   - cacheKey: 缓存的key
    ///   - cacheType: 缓存类型，具体那个文件夹
    ///   - completeHandler: 主线程回调
    func asyncSaveCache(_ jsonObject: AnyObject, cacheKey: String, cacheType: DataCacheType, complete: ((_ isSuccess: Bool) -> Void)?) {
        
        DispatchQueue.global().async { [weak self] in
            
            let result = self?.cacheData(jsonObject: jsonObject, cacheKey: cacheKey, cacheType: cacheType)
            DispatchQueue.main.async {
                complete?(result ?? false)
            }
        }
    }
    
    /// 同步删除缓存数据
    /// - Parameters:
    ///   - cacheKey: 缓存的key
    ///   - cacheType: 缓存类型，具体那个文件夹
    /// - Returns: 是否成功
    @discardableResult
    func syncDelCache(cacheKey: String, cacheType: DataCacheType) -> Bool {
        
        lock.lock()
        let atPath = getCacheFilePath(cacheKey: cacheKey, cacheType: cacheType)
        do {
            var isSuccess = try FileManager.default.removeItem(atPath: atPath)
            LogDebug("[cache debug] - delCacel - isSuccess:[\(isSuccess)]")
            return true
        } catch {
            // Handle the error here, e.g., log it or show an alert
            print("Error removing item at path \(atPath): \(error)")
        }
        lock.unlock()
        return false
    
    }
    /// 同步写入缓存数据
    /// - Parameters:
    ///   - jsonObject: 要写入的数据(JSON)
    ///   - cacheKey: 缓存的key
    ///   - cacheType: 缓存类型，具体那个文件夹
    /// - Returns: 是否成功
    @discardableResult
    func cacheData(jsonObject: AnyObject, cacheKey: String, cacheType: DataCacheType) -> Bool {
        
        lock.lock()
        let data = GPJson.jsonToData(jsonObject)
        let atPath = getCacheFilePath(cacheKey: cacheKey, cacheType: cacheType)
        
        let isSuccess = FileManager.default.createFile(atPath: atPath, contents: data, attributes: nil)
        lock.unlock()
        
        LogDebug("[cache debug] - saveCache - isSuccess:[\(isSuccess)]")
        return isSuccess
    }
}

// MARK: - 获取缓存数据
extension GPDataCacheManager {
    
    /// 获取缓存的对象
    /// - Parameters:
    ///   - cacheKey: 缓存的key
    ///   - cacheType: 缓存类型，具体那个文件夹
    /// - Returns: 返回AnyObject
    func getCacheObject(cacheKey: String, cacheType: DataCacheType) -> AnyObject? {
        
        lock.lock()
        var resultObject: AnyObject?
        
        // 文件路径
        let filePath = getCacheFilePath(cacheKey: cacheKey, cacheType: cacheType)
        
        if FileManager.default.fileExists(atPath: filePath),
           let data = FileManager.default.contents(atPath: filePath),
           let tempObject = GPJson.dataToJson(data) {
            
            resultObject = tempObject
        }
        lock.unlock()
        return resultObject
    }
    
    // 获取缓存的数据
    func getCachedModel<T: Codable>(type: T.Type, cacheKey: String, cacheType: DataCacheType) -> T? {
        
        guard let obj = getCacheObject(cacheKey: cacheKey, cacheType: cacheType) else {
            LogDebug("[cache debug] - getCachedData - 从沙盒获取json数据失败")
            return nil
        }
        
        if let model = GPModelUtil.anyToModel(type, param: obj) {
            return model
        }
        
        LogDebug("[cache debug] - getCachedData - json转换成model失败")
        return nil
    }
}

// MARK: - 清除缓存
extension GPDataCacheManager {
    
    func clearCache() {
//        // 1、清除工作圈数据缓存
//        self.clearCacheFolder(cacheType: .WorkgroupCache)
    }
    
    // 清除指定文件夹下的全部缓存
    func clearCacheFolder(cacheType: DataCacheType) {
        
        let folderPath: String = self.cacheFolderPath + "/" + cacheType.rawValue
        GPFileManager.removeFolder(folderPath)
        LogDebug("[cache debug] - 清除缓存")
    }
    
    // 删除指定文件
    @discardableResult
    func deleteFile(cacheKey: String, cacheType: DataCacheType) -> Bool {
        
        let filePath = self.getCacheFilePath(cacheKey: cacheKey, cacheType: cacheType)
        do {
            try FileManager.default.removeItem(atPath: filePath)
            LogDebug("[cache debug] - 删除文件成功")
            return true
        } catch let error as NSError {
            LogDebug("[cache debug] - 删除文件失败，error - [\(error)]")
            return false
        }
    }
    
    //获取缓存文件大小
    func getCacheSize() {
        let size = GPFileManager.getFolderSize(at: self.cacheFolderPath)
        let sizeStr = GPFileManager.getSizeString(KBSize: Int(size))
        LogDebug("[cache debug] - 获取缓存大小:[\(size)-\(sizeStr)]")
    }
}

// 缓存Logo
extension GPDataCacheManager {
    
    @discardableResult
    func cachLogo(logoImg: UIImage, fileName: String) -> Bool {
        cachLogoDic[fileName] = logoImg
        if let imgData = logoImg.pngData() {
            return cacheImage(imageData: imgData, fileName: fileName, cacheType: .Logo)
        }
        
        if let imgData = logoImg.jpegData(compressionQuality: 1) {
            return cacheImage(imageData: imgData, fileName: fileName, cacheType: .Logo)
        }
        return false
    }
    
    func getCachLogo(fileName: String) -> UIImage? {
        if fileName.count == 0 {
            return nil
        }
        
        if cachLogoDic.keys.contains(fileName), let img = cachLogoDic[fileName] {
            return img
        }
        
        // 1、按照fileName，从沙盒里查找
        let filePath = self.getFilePath(fileName, cacheType: .Logo)
        if FileManager.default.fileExists(atPath: filePath) == true, let image = UIImage(contentsOfFile: filePath) {
            cachLogoDic[fileName] = image
            return image
        }
        
        // 2、如果是url的话，取md5查找
        let newPath = self.getFilePath(fileName, cacheType: .Logo)
        if FileManager.default.fileExists(atPath: newPath) == true, let image = UIImage(contentsOfFile: newPath) {
            cachLogoDic[fileName] = image
            return image
        }
        
        // 3、从KingfisherManager的缓存中查找
        if let image = KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: fileName) {
            cachLogoDic[fileName] = image
            return image
        }
        return nil
    }
    
    /// 通过data缓存图片到沙盒
    /// - Parameters:
    ///   - imageData: 图片数据
    ///   - fileName: 图片的名称
    ///   - cacheType: 缓存的文件夹
    /// - Returns: 是否成功
    @discardableResult
    func cacheImage(imageData: Data, fileName: String, cacheType: DataCacheType) -> Bool {
        
        let filePath = self.getFilePath(fileName, cacheType: cacheType)
        if FileManager.default.fileExists(atPath: filePath) == true {
            GPFileManager.removeFile(at: filePath)
        }
        
        let isSuccess = FileManager.default.createFile(atPath: filePath, contents: imageData, attributes: nil)
        return isSuccess
    }
    
   
}

extension GPDataCacheManager {
    // 获取文件的缓存路径
    func getFilePath(_ fileName: String, cacheType: DataCacheType) -> String {
        
        let folderPath = self.getFolderPath(cacheType)
        let fullPath = folderPath + "/" + fileName
        return fullPath
    }
    
    // 获取文件夹缓存路径
    func getFolderPath(_ cacheType: DataCacheType) -> String {
        
        var folderPath = GPSandbox.shared.documentDirectory + "/" + cacheType.rawValue
        
        GPFileManager.checkDirectory(at: folderPath)
        return folderPath
    }
}

// MARK: - 缓存封面
extension GPDataCacheManager {
    
    

    
    private func getCoverFileName(_ watermarkID: String) -> String {
        return "coverID_\(watermarkID)"
    }
    
    @discardableResult
    func cachWatermarkCover(coverImg: UIImage, watermarkID: String) -> Bool {
        cachCoverDic[watermarkID] = coverImg
        let fileName = getCoverFileName(watermarkID)
        if let imgData = coverImg.pngData() {
            return cacheImage(imageData: imgData, fileName: fileName, cacheType: .Cover)
        }
        
        if let imgData = coverImg.jpegData(compressionQuality: 1) {
            return cacheImage(imageData: imgData, fileName: fileName, cacheType: .Cover)
        }
        return false
    }
    /**
        删除缓存图片
     */
    func delCacheWatermarkCover(_ watermarkID: String) {
        let fileName = getCoverFileName(watermarkID)
        let filePath = self.getFilePath(fileName, cacheType: .Cover)
        if FileManager.default.fileExists(atPath: filePath) == true {
            GPFileManager.removeFile(at: filePath)
        }
        cachCoverDic[fileName] = nil
    }
    
    func getCachWatermarkCover(_ watermarkID: String) -> UIImage? {
        
        let fileName = getCoverFileName(watermarkID)
        
        if cachCoverDic.keys.contains(fileName), let img = cachCoverDic[fileName] {
            return img
        }
        
        // 1、按照fileName，从沙盒里查找
        let filePath = self.getFilePath(fileName, cacheType: .Cover)
        if FileManager.default.fileExists(atPath: filePath) == true, let image = UIImage(contentsOfFile: filePath) {
            cachCoverDic[fileName] = image
            return image
        }
        
        return nil
    }
    
}
