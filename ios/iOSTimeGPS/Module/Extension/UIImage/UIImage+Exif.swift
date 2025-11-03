// UI image extension

import UIKit
import CoreLocation

// MARK: - Creating Images with Metadata
extension UIImage {
    
    /// Returns a jpg data representation of the receiver containing the given image
    /// metadata or `nil` if the creation fails.
    /// Metadata is merged into any existing metadata in the receiver.
    /// - Note: https://developer.apple.com/library/archive/qa/qa1895/_index.html
    func getJpgImageData(metadata: CGImageMetadata, quality: CGFloat) -> Data? {
        
        guard let imageSourceData = self.jpegData(compressionQuality: quality)  else {
            return nil
        }
        
        let newData = UIImage.getJpgImageData(metadata: metadata, imageSourceData: imageSourceData)
        return newData
    }
    
    static func getJpgImageData(metadata: CGImageMetadata, imageSourceData: Data) -> Data? {
        let imageOutputData = NSMutableData()
        
        guard
            let imageSource = CGImageSourceCreateWithData(imageSourceData as CFData, nil),
            let uti = CGImageSourceGetType(imageSource),
            let imageDestination = CGImageDestinationCreateWithData(imageOutputData as CFMutableData, uti, 1, nil)
        else {
            return nil
        }
        
        var metadataOptions: [CFString: Any]
        
        // 解决iOS14.2崩溃的问题
        if #available(iOS 15.0, *) {
            metadataOptions = [
                kCGImageDestinationMetadata: metadata,
                kCGImageDestinationMergeMetadata: kCFBooleanTrue
            ]
        } else if #available(iOS 14.2, *) {
            metadataOptions = [
                kCGImageDestinationMetadata: metadata
            ]
        } else {
            metadataOptions = [
                kCGImageDestinationMetadata: metadata,
                kCGImageDestinationMergeMetadata: kCFBooleanTrue
            ]
        }
        
        
        let ok = CGImageDestinationCopyImageSource(imageDestination, imageSource, metadataOptions as CFDictionary, nil)
        
        return ok ? (imageOutputData as Data) : nil
    }
}

// MARK: - Creating Metadata

extension CGImageMetadata {
    
    private static func exifFormatter() -> DateFormatter {
        let formatter = DateFormatter.dateFormat_xh()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        return formatter
    }
    
    /// Metadata with Exif, TIFF and GPS tags for date and location.
    /// The returned success flag is `false` if at least one tag failed to be set.
    static func `for`(date: Date,modifyDate:Date, location: CLLocation?,userComment:String,artist:String = "Timeprint") -> (ok: Bool, metadata: CGImageMetadata) {
        let metadata = CGImageMetadataCreateMutable()
        let dateString = exifFormatter().string(from: date)
        let modifyDateString = exifFormatter().string(from: modifyDate)

        var results = [Bool]()
        //EXif信息字典
        let result1 = metadata.setTags([
            (kCGImagePropertyExifDictionary, kCGImagePropertyExifDateTimeOriginal, dateString as CFString),
            (kCGImagePropertyExifDictionary, kCGImagePropertyExifDateTimeDigitized, dateString as CFString),
            (kCGImagePropertyExifDictionary, kCGImagePropertyExifUserComment, userComment as CFString)//UserComment
        ])
        results.append(result1)

//        if isAppStore != true{
//            assert(result1 == true, "info写入失败")
//        }
        
        //TIFF信息字典
        /*
         * kCGImagePropertyTIFFDateTime:对应"Modify Date",修改时间
         * kCGImagePropertyTIFFArtist:图片作者
         */
        let result2 = metadata.setTags([
            (kCGImagePropertyTIFFDictionary, kCGImagePropertyTIFFDateTime, modifyDateString as CFString),
            (kCGImagePropertyTIFFDictionary, kCGImagePropertyTIFFArtist, artist as CFString)//artist
        ])
        results.append(result2)

        //PNG信息字典
        let result3 = metadata.setTags([
            (kCGImagePropertyPNGDictionary, kCGImagePropertyPNGModificationTime, modifyDateString as CFString),
            (kCGImagePropertyPNGDictionary, kCGImagePropertyPNGCreationTime, dateString as CFString)
        ])
       results.append(result3)

        //IPTC信息字典
//        metadata.setTag((kCGImagePropertyIPTCDictionary, kCGImagePropertyIPTCReleaseDate, dateString as CFString))
//        metadata.setTag((kCGImagePropertyIPTCDictionary, kCGImagePropertyIPTCReleaseTime, dateString as CFString))
//        metadata.setTag((kCGImagePropertyIPTCDictionary, kCGImagePropertyIPTCExpirationDate, dateString as CFString))
//        metadata.setTag((kCGImagePropertyIPTCDictionary, kCGImagePropertyIPTCExpirationTime, dateString as CFString))
//        metadata.setTag((kCGImagePropertyIPTCDictionary, kCGImagePropertyIPTCExpirationDate, dateString as CFString))

        //GPS信息字典
        if let location = location {
            let coordinate = location.coordinate
            let result4 = metadata.setTags([
                (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSTimeStamp, dateString as CFString),
                (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSLatitude, "\(abs(coordinate.latitude))" as CFString),
                (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSLatitudeRef, (coordinate.latitude >= 0 ? "N" : "S") as CFString),
                (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSLongitude, "\(abs(coordinate.longitude))" as CFString),
                (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSLongitudeRef, (coordinate.longitude >= 0 ? "E" : "W") as CFString),
                (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSAltitude, Int(abs(location.altitude)) as CFTypeRef),
                (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSAltitudeRef, Int(location.altitude < 0.0 ? 1 : 0) as CFTypeRef),
                (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSHPositioningError, "\(location.horizontalAccuracy)" as CFString)
            ])
            results.append(result4)
        }
//        //方位角
//        if let gpsImgDirection = gpsImgDirection{
//            // (M or T)
//            let result5 = metadata.setTags([
//                (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSImgDirectionRef, "T" as CFString),
//                (kCGImagePropertyGPSDictionary, kCGImagePropertyGPSImgDirection,gpsImgDirection as AnyObject),
//            ])
//            results.append(result5)
//        }
//        
        
        return (!results.contains(false), metadata)
    }
}

// As an alternative to `CGImageMetadataSetValueMatchingImageProperty` see the more
// complex `CGImageMetadataSetTagWithPath` with `CGImageMetadataTagCreate`.

extension CGMutableImageMetadata {

    typealias Tag = (dictionary: CFString, property: CFString, value: CFTypeRef)

    @discardableResult
    func setTag(_ tag: Tag) -> Bool {
        return CGImageMetadataSetValueMatchingImageProperty(self, tag.dictionary, tag.property, tag.value)
    }

    @discardableResult
    func setTags(_ tags: [Tag]) -> Bool {
        return !tags.map(setTag).contains(false)
    }
}

extension CGImageSource {
    
    /// https://github.com/dbelford/Folder-Diff-App/blob/a93e936cf5168d0c5b61fc803acac07f8b434f5c/Folder-Diff/CGImageSource%2BAdditions.swift
    
    /// image 属性
    func properties() -> [String : Any]? {
      guard let properties = CGImageSourceCopyPropertiesAtIndex(self, 0, nil) as? [String: Any] else {
        return nil
      }
      return properties
    }
    /// gps 信息
    func gpsDic()->[String:Any]?{
        let gps = properties()?[kCGImagePropertyGPSDictionary as String]
        return gps as? [String:Any]
    }
    /// exif 信息
    func exifDic()->[String:Any]?{
        let exif = properties()?[kCGImagePropertyExifDictionary as String]
        return exif as? [String:Any]
    }
    
    /// tiff 信息
    func tiffDic() -> [String:Any]? {
        let tiff = properties()?[kCGImagePropertyTIFFDictionary as String]
        return tiff as? [String: Any]
    }
    
    /// 图片大小
    func sizeOfImage() -> CGSize? {
        let propertiesOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let properties = CGImageSourceCopyPropertiesAtIndex(self, 0, propertiesOptions) as? [CFString: Any] else {
            return nil
        }
        if let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
            let height = properties[kCGImagePropertyPixelHeight] as? CGFloat{
            return CGSize(width: width, height: height)
        } else {
            return nil
        }
    }
}
