//
//  UIImage+Compress.swift
//  iOSTimeGPS
//
//

import GPCam

// 压缩图片结果的model
struct GPCompressPhotoResultModel {
    /// 生成的新图片, 没有压缩
    var uncompressedImage: UIImage
    /// 压缩后的data
    var compressedData: Data?
    /// 分辨率
    var resolution: CGSize = .init(width: 0, height: 0)
    /// 压缩系数
    var compressionQuality: CGFloat = 1.0
}

// 压缩等级
enum GPCompressPhotoLevel {
    case `default`
    case kb90
    case mb1
    case mb1_4
    case mb2_4
    case mb3
    case mb25
    case none
    
    var fileSize: Double {
        switch self {
        case .none:
            return -1
        case .default:
            return Double(GPCamConfigurator.sharedInstance().jpegFileSizeForUpload)
        case .kb90:
            return 90*1024
        case .mb1:
            return 1024*1024
        case .mb1_4:
            return 1.4*1024*1024
        case .mb2_4:
            return 2.4*1024*1024
        case .mb3:
            return 3*1024*1024
        case .mb25:
            return 25*1024*1024
        }
    }
}

extension UIImage {
    
    // V2.9.95版本：调整策略，调整图片分辨率和size的大小
    static func resizeResolutionAndFileSize(
        sourceImage: UIImage,
        level: GPCompressPhotoLevel = .default
    ) -> GPCompressPhotoResultModel {
        
        if level == .none {
            let imageData = sourceImage.pngData()
            let model = GPCompressPhotoResultModel(uncompressedImage: sourceImage, compressedData: imageData, resolution: .init(width: sourceImage.size.width, height: sourceImage.size.height), compressionQuality: 1.0)

            return model
        }
        
        let tuples = getResolutionAndMaxFileSize(sourceImage: sourceImage, level: level)
        let newSize = tuples.resolution
        let maxFileSize = tuples.maxFileSize
        
        UIGraphicsBeginImageContext(newSize.nonzeroSize)
        sourceImage.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
            let model = GPCompressPhotoResultModel(uncompressedImage: sourceImage, compressedData: nil, resolution: newSize, compressionQuality: 1.0)
            return model
        }
        UIGraphicsEndImageContext()
        
        guard var imageData = newImage.jpegData(compressionQuality: 1.0) else {
            let model = GPCompressPhotoResultModel(uncompressedImage: newImage, compressedData: nil, resolution: newSize, compressionQuality: 1.0)
            return model
        }
        
        var imageStorageByte = Double(imageData.count)
        
        // 调整大小
        let begin = CACurrentMediaTime()
        var quality: CGFloat = 0.9
        while imageStorageByte > maxFileSize && quality > 0.1 {
            if let tempData = newImage.xhm_jpegData(quality) as? Data {
                imageData = tempData
                imageStorageByte = Double(imageData.count)
                quality -= 0.1
            } else {
                break
            }
        }
        let end = CACurrentMediaTime()
        LogDebug("[JPEG Compress]resizeImage_resolution_fileSize compress timeCost: \((end - begin)*1000)ms, quality: \(quality), byte: \(imageData.count)")
    
        let model = GPCompressPhotoResultModel(uncompressedImage: newImage, compressedData: imageData, resolution: newSize, compressionQuality: quality)
        return model
    }
    
    // MARK: - 获取新图片的分辨率和最大的文件大小

    static func getResolutionAndMaxFileSize(
        sourceImage: UIImage,
        level: GPCompressPhotoLevel = .default
    ) -> (resolution: CGSize, maxFileSize: Double) {
        let image_w: CGFloat = sourceImage.size.width // 原图片的宽度
        let image_h: CGFloat = sourceImage.size.height // 原图片的高度
        
        var maxFileSize: Double = GPCompressPhotoLevel.mb25.fileSize // 存储的大小（byte）
        var newSize = CGSize(width: image_w, height: image_h)
        if image_w > image_h {
            let rate: CGFloat = image_w / image_h
            if rate <= 3 {
                maxFileSize = level.fileSize
                if image_h > 1280 {
                    newSize = CGSize(width: 1280*rate, height: 1280)
                }
            } else if rate > 3, rate <= 15 {
                maxFileSize = GPCompressPhotoLevel.mb1.fileSize
                if image_h > 720 {
                    newSize = CGSize(width: 720*rate, height: 720)
                }
            } else if rate > 15 {
                maxFileSize = GPCompressPhotoLevel.mb1_4.fileSize
                if image_h > 540 {
                    newSize = CGSize(width: 540*rate, height: 540)
                }
            }
        } else {
            let rate: CGFloat = image_h / image_w
            if rate <= 3 {
                maxFileSize = level.fileSize
                if image_w > 1280 {
                    newSize = CGSize(width: 1280, height: 1280*rate)
                }
            } else if rate > 3, rate <= 15 {
                maxFileSize = GPCompressPhotoLevel.mb1.fileSize
                if image_h > 720 {
                    newSize = CGSize(width: 720, height: 720*rate)
                }
            } else if rate > 15 {
                maxFileSize = GPCompressPhotoLevel.mb1_4.fileSize
                if image_h > 540 {
                    newSize = CGSize(width: 540, height: 540*rate)
                }
            }
        }
        return (newSize, maxFileSize)
    }
    
}
