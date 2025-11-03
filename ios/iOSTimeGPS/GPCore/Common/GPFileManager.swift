//
//  GPFileManager.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/13.
//

import UIKit

open class GPFileManager: NSObject {
    
    /// 移动文件到目标位置
    @discardableResult
    open class func moveFile(sourcePath: String, targetPath: String) -> Bool {
        
        if FileManager.default.fileExists(atPath: sourcePath) == false {
            LogDebug("[文件操作调试] - 移动文件到目标位置，源文件不存在 - sourcePath:[\(sourcePath)]")
            return false
        }
        
        do{
            try FileManager.default.moveItem(atPath: sourcePath, toPath: targetPath)
            LogDebug("[文件操作调试] - 移动文件到目标位置成功")
            return true
        }catch{
            LogDebug("[文件操作调试] - 移动文件到目标位置失败 - error:[\(error)]")
            return false
        }
    }
    
    /// 移动文件到目标位置
    @discardableResult
    open class func moveFile(sourceUrl: URL, targetUrl: URL) -> Bool {
        do{
            try FileManager.default.moveItem(at: sourceUrl, to: targetUrl)
            LogDebug("[文件操作调试] - 移动文件到目标位置成功")
            return true
        }catch{
            LogDebug("[文件操作调试] - 移动文件到目标位置失败 - error:[\(error)]")
            return false
        }
    }
    
    /// 复制一个文件，到目标位置
    @discardableResult
    open class func copyFile(sourcePath: String, targetPath: String) -> Bool {
        
        if FileManager.default.fileExists(atPath: sourcePath) == false {
            LogDebug("[文件操作调试] - 复制一个文件，到目标位置失败，源文件不存在 - sourcePath:[\(sourcePath)]")
            return false
        }
        
        do{
            try FileManager.default.copyItem(atPath: sourcePath, toPath: targetPath)
            LogDebug("[文件操作调试] - 复制一个文件，到目标位置成功")
            return true
        }catch{
            LogDebug("[文件操作调试] - 复制一个文件，到目标位置失败 - error:[\(error)]")
            return false
        }
    }
    
    /// 复制一个文件，到目标位置
    @discardableResult
    open class func copyFile(sourceUrl: URL, targetUrl: URL) -> Bool {
        
        do{
            try FileManager.default.copyItem(at: sourceUrl, to: targetUrl)
            LogDebug("[文件操作调试] - 复制一个文件，到目标位置成功")
            return true
        }catch{
            LogDebug("[文件操作调试] - 复制一个文件，到目标位置失败 - error:[\(error)]")
            return false
        }
    }
    
    // MARK: - 删除单个文件
    ///删除单个文件
    @discardableResult
    open class func removeFile(at path: String) -> Bool {
        
        if FileManager.default.fileExists(atPath: path) == false {
            LogDebug("[文件操作调试] - 删除文件失败，文件不存在 - path:[\(path)]")
            return false
        }
        
        do {
            try FileManager.default.removeItem(atPath: path)
            LogDebug("[文件操作调试] - 删除文件成功 - path:[\(path)]")
            return true
        } catch {
            LogDebug("[文件操作调试] - 删除文件失败 - path:[\(path)] - error - [\(error)]")
            return false
        }
    }
    
    // MARK: - 删除单个文件
    /// 删除单个文件
    @discardableResult
    open class func removeFile(url: URL) -> Bool {
        
        do {
            try FileManager.default.removeItem(at: url)
            LogDebug("[文件操作调试] - 删除文件成功 - path:[\(url)]")
            return true
        } catch {
            LogDebug("[文件操作调试] - 删除文件失败 - path:[\(url)] - error - [\(error)]")
            return false
        }
    }
    
    // MARK: - 删除文件夹
    ///删除文件夹
    open class func removeFolder(_ folderPath: String) {
        
        if FileManager.default.fileExists(atPath: folderPath) == false {
            LogDebug("[文件操作调试] - 删除文件夹失败，文件不存在 - folderPath:[\(folderPath)]")
            return
        }
        
        if let subpaths = FileManager.default.subpaths(atPath: folderPath), subpaths.count > 0 {
            for singlePath in subpaths {
                let fileAbsoluePath = folderPath + "/" + singlePath
                do {
                    try FileManager.default.removeItem(atPath: fileAbsoluePath)
                    LogDebug("[文件操作调试] - 删除文件夹中的子文件成功 - path:[\(fileAbsoluePath)]")
                } catch {
                    LogDebug("[文件操作调试] - 删除文件夹中的子文件失败 - path:[\(fileAbsoluePath)] - error - [\(error)]")
                }
            }
        }
    }
    
    /// 遍历目标文件夹(获得文档目录下所有的内容，以及子文件夹下的内容)
    open class func listFolder(_ folderPath: String) -> [Any]? {
        
        if FileManager.default.fileExists(atPath: folderPath) == false {
            LogDebug("[文件操作调试] - 遍历目标文件夹，文件不存在 - folderPath:[\(folderPath)]")
            return nil
        }
        
        if let contents = FileManager.default.enumerator(atPath: folderPath) {
            let result = contents.allObjects
            LogDebug("遍历目标文件夹:[\(result)]")
            return result
        }
        LogDebug("遍历目标文件夹失败")
        return nil
    }
    
    //MARK: -  检查目录，如果文件夹不存在，就创建文件夹
    ///检查目录，如果文件夹不存在，就创建文件夹
    open class func checkDirectory(at path: String) {
        let fileManager: FileManager = FileManager.default
        
        var isDir = ObjCBool(false) //isDir判断是否为文件夹
        if !fileManager.fileExists(atPath: path, isDirectory: &isDir) {
            LogDebug("[文件操作调试] - 文件夹不存在，创建文件夹 - path:[\(path)]")
            self.createDirectory(at: path)
        } else {
            if !isDir.boolValue {
                do {
                    LogDebug("[文件操作调试] - 该路径下不是文件夹，首先删除这个文件然后创建文件夹 - path:[\(path)]")
                    try fileManager.removeItem(atPath: path)
                    self.createDirectory(at: path)
                } catch let error as NSError {
                    LogDebug("[文件操作调试] - 创建缓存文件夹失败，error - [\(error)] - path:[\(path)]")
                }
            }
        }
    }
    
    /// 创建文件夹
    open class func createDirectory(at path: String) {
        
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            LogDebug("[文件操作调试] - 创建文件夹成功 - path:[\(path)]")
        } catch {
            LogDebug("[文件操作调试] - 创建文件夹失败 - error[\(error)] - path:[\(path)]")
        }
    }
    
    /// 设置不备份
    /*
     如果我们的APP需要存放比较大的文件的时候，同时又不希望被系统清理掉，那么我们就需要把我们的资源保存在Documents目录下，但是我们又不希望他会被iCloud备份，因此就有了这个方法
     */
    open class func addDoNotBackupAttribute(_ path: String) {
        let url: URL = URL(fileURLWithPath: path)
        do {
            
            /*
             var u = URLResourceValues()
             u.isExcludedFromBackup = true
             try url.setResourceValues(u)
             */
            try (url as NSURL).setResourceValue(NSNumber(value: true as Bool), forKey: URLResourceKey.isExcludedFromBackupKey)
        }
        catch let error as NSError {
            LogDebug("[文件操作调试] - 设置不备份属性失败 - error[\(error)] - path:[\(path)]")
        }
    }
    
    open class func removeURLs(_ urls: [URL]) {
        urls.forEach { (url) in
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                LogDebug("BCFileManager removeURLs error:\(error)")
            }
        }
    }
    
    /// 计算单个文件的大小(KB)
    open class func getFileSize(at path: String) -> Double {
           let manager = FileManager.default
           var fileSize: Double = 0
           do {
               let attr = try manager.attributesOfItem(atPath: path)
               fileSize = Double(attr[FileAttributeKey.size] as! UInt64)
               let dict = attr as NSDictionary
               fileSize = Double(dict.fileSize())
           } catch {
               dump(error)
           }
           return fileSize/1024
       }
       
    /// 遍历所有子目录， 并计算文件大小(KB)
    open class func getFolderSize(at folderPath: String) -> Double {
           let manage = FileManager.default
           if !manage.fileExists(atPath: folderPath) {
               return 0
           }
           let childFilePath = manage.subpaths(atPath: folderPath)
           var fileSize:Double = 0
           for path in childFilePath! {
               let fileAbsoluePath = folderPath + "/" + path
               fileSize += getFileSize(at: fileAbsoluePath)
           }
           return fileSize
       }
       
    /// 单位换算(KB)
    open class func getSizeString(KBSize: Int) -> String {
           var resultStr = "\(KBSize)KB"
           if KBSize >= 1024 && KBSize < 1024*1024 {
               let MBSize = Double(KBSize) / Double(1024)
               resultStr = String(format: "%.1fMB", MBSize)
           } else if KBSize >= 1024*1024 {
               let GBSize = Double(KBSize) / Double(1024) / Double(1024)
               resultStr = String(format: "%.2fGB", GBSize)
           }
           return resultStr
       }
       
}
