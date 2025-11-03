import Foundation
import MessageUI
import Photos
import UIKit
import Zip

class GPZipTool {
    
    // 存储当前正在处理的临时文件路径，用于清理
    private static var currentTempDirectories: Set<URL> = []
    private static var currentZipFiles: Set<URL> = []
    private static let fileManager = FileManager.default
    
    // 压缩PHAsset资源并创建ZIP文件
    static func gp_exportAssetsToZip(_ assets: [PHAsset],
                                   progress: @escaping (Double) -> Void,
                                   completion: @escaping (Result<URL, Error>) -> Void) {
        
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        do {
            try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
            currentTempDirectories.insert(tempDirectory)
        } catch {
            completion(.failure(error))
            return
        }
        
        var exportedURLs: [URL] = []
        var completedCount = 0
        let totalCount = assets.count
        
        guard totalCount > 0 else {
            completion(.failure(NSError(domain: "GPZipTool", code: -1, userInfo: [NSLocalizedDescriptionKey: "No assets to export"])))
            return
        }
        
        let dispatchGroup = DispatchGroup()
        let serialQueue = DispatchQueue(label: "com.gp.photo.export.serial")
        
        // 导出进度
        let exportProgress: (Double) -> Void = { exportProgressValue in
            let overallProgress = (Double(completedCount) + exportProgressValue) / Double(totalCount)
            DispatchQueue.main.async {
                progress(overallProgress)
            }
        }
        
        for (index, asset) in assets.enumerated() {
            dispatchGroup.enter()
            
            gp_exportAsset(asset, to: tempDirectory, index: index, progress: exportProgress) { result in
                serialQueue.async {
                    switch result {
                    case .success(let url):
                        exportedURLs.append(url)
                    case .failure(let error):
                        print("Export failed for asset \(index): \(error)")
                    }
                    
                    completedCount += 1
                    let currentProgress = Double(completedCount) / Double(totalCount)
                    DispatchQueue.main.async {
                        progress(currentProgress)
                    }
                    
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .global(qos: .userInitiated)) {
            // 所有资源导出完成后，创建ZIP文件
            gp_createZipFile(from: exportedURLs, in: tempDirectory) { zipResult in
                // 清理导出的原始文件
                gp_cleanupTempDirectory(tempDirectory)
                
                DispatchQueue.main.async {
                    switch zipResult {
                    case .success(let zipURL):
                        currentZipFiles.insert(zipURL)
                        completion(.success(zipURL))
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
        }
    }
    
    // 导出资源到临时目录（用于邮件分享）
    static func gp_exportAssetsToTemp(_ assets: [PHAsset],
                                    progress: @escaping (Double) -> Void,
                                    completion: @escaping (Result<[URL], Error>) -> Void) {
        
        let tempDirectory = fileManager.temporaryDirectory.appendingPathComponent("email_export_\(UUID().uuidString)")
        
        do {
            try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
            currentTempDirectories.insert(tempDirectory)
        } catch {
            completion(.failure(error))
            return
        }
        
        var exportedURLs: [URL] = []
        var completedCount = 0
        let totalCount = assets.count
        
        guard totalCount > 0 else {
            completion(.failure(NSError(domain: "GPZipTool", code: -1, userInfo: [NSLocalizedDescriptionKey: "No assets to export"])))
            return
        }
        
        let dispatchGroup = DispatchGroup()
        let serialQueue = DispatchQueue(label: "com.gp.photo.email.export.serial")
        
        for (index, asset) in assets.enumerated() {
            dispatchGroup.enter()
            
            gp_exportAsset(asset, to: tempDirectory, index: index, progress: { progressValue in
                let overallProgress = (Double(completedCount) + progressValue) / Double(totalCount)
                DispatchQueue.main.async {
                    progress(overallProgress)
                }
            }) { result in
                serialQueue.async {
                    switch result {
                    case .success(let url):
                        exportedURLs.append(url)
                    case .failure(let error):
                        print("Export failed for asset \(index): \(error)")
                    }
                    
                    completedCount += 1
                    let currentProgress = Double(completedCount) / Double(totalCount)
                    DispatchQueue.main.async {
                        progress(currentProgress)
                    }
                    
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            completion(.success(exportedURLs))
        }
    }
    
    // 创建ZIP文件
    static func gp_makeZip(from urls: [URL]) throws -> URL {
        let tempDirectory = fileManager.temporaryDirectory
        
        // 生成多语言的ZIP文件名
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        
        let workReportPrefix = "i8_key_work_report".localized()
        let zipFileName = "\(workReportPrefix)-\(dateString).zip"
        let zipURL = tempDirectory.appendingPathComponent(zipFileName)
        
        // 如果ZIP文件已存在，先删除
        if fileManager.fileExists(atPath: zipURL.path) {
            try fileManager.removeItem(at: zipURL)
        }
        
        // 使用Zip库压缩文件
        try Zip.zipFiles(paths: urls, zipFilePath: zipURL, password: nil, progress: nil)
        
        // 记录ZIP文件
        currentZipFiles.insert(zipURL)
        return zipURL
    }
    
    // 导出单个资源
    private static func gp_exportAsset(_ asset: PHAsset,
                                     to directory: URL,
                                     index: Int,
                                     progress: @escaping (Double) -> Void,
                                     completion: @escaping (Result<URL, Error>) -> Void) {
        
        gp_getOriginalFileName(for: asset) { originalFileName in
            let fileName: String
            
            if let originalName = originalFileName, !originalName.isEmpty {
                fileName = originalName
            } else {
                let fileExtension = asset.mediaType == .image ? "jpg" : "mov"
                fileName = "\(asset.mediaType == .image ? "image" : "video")_\(index).\(fileExtension)"
            }
            
            let destinationURL = directory.appendingPathComponent(fileName)
            let finalDestinationURL = gp_generateUniqueFileURL(destinationURL)
            
            if asset.mediaType == .image {
                gp_exportImageAsset(asset, to: finalDestinationURL, progress: progress, completion: completion)
            } else if asset.mediaType == .video {
                gp_exportVideoAsset(asset, to: finalDestinationURL, progress: progress, completion: completion)
            } else {
                completion(.failure(NSError(domain: "GPZipTool", code: -2, userInfo: [NSLocalizedDescriptionKey: "Unsupported media type"])))
            }
        }
    }
    
    // 获取资源的原始文件名
    private static func gp_getOriginalFileName(for asset: PHAsset, completion: @escaping (String?) -> Void) {
        let resources = PHAssetResource.assetResources(for: asset)
        
        if let resource = resources.first {
            var originalFilename = resource.originalFilename
            
            if originalFilename.isEmpty {
                completion(nil)
                return
            }
            
            if !originalFilename.contains(".") {
                let fileExtension = asset.mediaType == .image ? "jpg" : "mov"
                originalFilename += ".\(fileExtension)"
            }
            
            completion(originalFilename)
        } else {
            completion(nil)
        }
    }
    
    // 生成唯一的文件URL，避免文件名冲突
    private static func gp_generateUniqueFileURL(_ url: URL) -> URL {
        var finalURL = url
        var counter = 1
        
        while fileManager.fileExists(atPath: finalURL.path) {
            let fileName = url.deletingPathExtension().lastPathComponent
            let fileExtension = url.pathExtension
            let newFileName = "\(fileName)_\(counter).\(fileExtension)"
            finalURL = url.deletingLastPathComponent().appendingPathComponent(newFileName)
            counter += 1
        }
        
        return finalURL
    }
    
    // 导出图片资源（保留EXIF信息）
    private static func gp_exportImageAsset(_ asset: PHAsset,
                                          to destinationURL: URL,
                                          progress: @escaping (Double) -> Void,
                                          completion: @escaping (Result<URL, Error>) -> Void) {
        
        let options = PHImageRequestOptions()
        options.version = .original
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progr, error, stop, info in
            if error == nil {
                progress(progr)
            }
        }
        
        PHImageManager.default().requestImageDataAndOrientation(for: asset, options: options) { imageData, dataUTI, orientation, info in
            guard let imageData = imageData else {
                let error = NSError(domain: "GPZipTool", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to get image data"])
                completion(.failure(error))
                return
            }
            
            do {
                try imageData.write(to: destinationURL)
                progress(1.0)
                completion(.success(destinationURL))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // 导出视频资源
    private static func gp_exportVideoAsset(_ asset: PHAsset,
                                          to destinationURL: URL,
                                          progress: @escaping (Double) -> Void,
                                          completion: @escaping (Result<URL, Error>) -> Void) {
        
        let options = PHVideoRequestOptions()
        options.version = .original
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        options.progressHandler = { progr, error, stop, info in
            if error == nil {
                progress(progr)
            }
        }
        
        PHImageManager.default().requestAVAsset(forVideo: asset, options: options) { avAsset, audioMix, info in
            guard let avAsset = avAsset as? AVURLAsset else {
                let error = NSError(domain: "GPZipTool", code: -6, userInfo: [NSLocalizedDescriptionKey: "Failed to get video asset"])
                completion(.failure(error))
                return
            }
            
            let sourceURL = avAsset.url
            
            do {
                if FileManager.default.fileExists(atPath: destinationURL.path) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
                progress(1.0)
                completion(.success(destinationURL))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // 使用Zip库创建ZIP文件
    private static func gp_createZipFile(from urls: [URL],
                                       in directory: URL,
                                       completion: @escaping (Result<URL, Error>) -> Void) {
        do {
            let zipURL = try gp_makeZip(from: urls)
            completion(.success(zipURL))
        } catch {
            completion(.failure(error))
        }
    }
    
    // 清理临时ZIP文件
    static func gp_cleanupTempZipFile(_ zipURL: URL) {
        do {
            if fileManager.fileExists(atPath: zipURL.path) {
                try fileManager.removeItem(at: zipURL)
                currentZipFiles.remove(zipURL)
                print("Cleaned up temporary zip file: \(zipURL.lastPathComponent)")
            }
        } catch {
            print("Failed to cleanup zip file: \(error)")
        }
    }
    
    // 清理临时目录
    static func gp_cleanupTempDirectory(_ directory: URL) {
        do {
            if fileManager.fileExists(atPath: directory.path) {
                try fileManager.removeItem(at: directory)
                currentTempDirectories.remove(directory)
                print("Cleaned up temporary directory: \(directory.lastPathComponent)")
            }
        } catch {
            print("Failed to cleanup temporary directory: \(error)")
        }
    }
    
    // 获取文件大小（字节）
    static func gp_getFileSizeInBytes(_ url: URL) -> Int64? {
        do {
            let attributes = try fileManager.attributesOfItem(atPath: url.path)
            return attributes[.size] as? Int64
        } catch {
            print("Failed to get file size: \(error)")
            return nil
        }
    }
    
    // 清理所有临时文件
    static func gp_cleanupAllTempFiles() {
        print("Cleaning up all temporary files...")
        
        for directory in currentTempDirectories {
            gp_cleanupTempDirectory(directory)
        }
        
        for zipFile in currentZipFiles {
            gp_cleanupTempZipFile(zipFile)
        }
        
        cleanupOrphanedZipFiles()
    }
    
    // 清理孤立的ZIP文件
    private static func cleanupOrphanedZipFiles() {
        let tempDirectory = fileManager.temporaryDirectory
        
        do {
            let contents = try fileManager.contentsOfDirectory(at: tempDirectory, includingPropertiesForKeys: nil)
            let zipFiles = contents.filter { $0.pathExtension == "zip" }
            
            for zipFile in zipFiles {
                if !currentZipFiles.contains(zipFile) {
                    try? fileManager.removeItem(at: zipFile)
                    print("Cleaned up orphaned zip file: \(zipFile.lastPathComponent)")
                }
            }
        } catch {
            print("Failed to list temporary directory: \(error)")
        }
    }
}
