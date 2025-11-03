//
//  GpImageManager.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/11/30.
//

import Foundation
import UIKit

// gen a new image and add some exif info
enum GpImageManager {
    /// 生成一张压缩的新图片
    /// - Parameters:
    ///   - originalImage: 原始图片
    ///   - quality: 压缩比例，默认1
    ///   - userCommentStr: 用户信息
    ///   - createDate: 图片的创建时间
    ///   - modifyDate: 图片的修改时间
    ///   - location: 图片的位置信息
    ///   - gpsImgDirection: 方位角
    ///   - gpsImgDirectionRef: 方位角单位
    ///   - artist: 作者，默认Timeprint
    ///   - completeHandler: 回调
    static func generateNewImage(originalImage: UIImage,
                                 quality: CGFloat = 1,
                                 userCommentStr: String?,
                                 createDate: Date,
                                 modifyDate: Date,
                                 location: CLLocation?,
//                                 gpsImgDirection: Double?,
//                                 gpsImgDirectionRef: String = "M",
                                 artist:String = "Timeprint",
                                 completeHandler: @escaping ((Data?) -> ())) {
        
        DispatchQueue.global().async {
            autoreleasepool {
                //若果有user commment
                var finalStr = "";
               // print("before write userCommentStr \(userCommentStr)");
                if let tempStr = userCommentStr {
                    finalStr = tempStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? tempStr
                }
                //print("before write finalStr \(finalStr)");
                //加密
                finalStr = GPSecurityManager.shared.encryptAES(str: finalStr)
                //print("after write finalStr ===  \(finalStr)");
                let (_, metadata) = CGImageMetadata.for(date: createDate,
                                                        modifyDate: modifyDate,
                                                        location: location,
                                                        userComment: finalStr,
                                                        artist: artist
                                                        )
                
                let imageData = originalImage.getJpgImageData(metadata: metadata, quality: quality)
                DispatchQueue.main.async {
                    completeHandler(imageData)
                }
            }
        }
    }
    
    // MARK: 生成一张压缩的新图片
    /// 生成一张压缩的新图片
    /// - Parameters:
    ///   - imageData: 图片的data
    ///   - userCommentStr: userComment str
    ///   - createDate: 图片的创建时间
    ///   - modifyDate: 图片的修改时间
    ///   - location: 图片的位置信息
    ///   - gpsImgDirection: 方位角
    ///   - gpsImgDirectionRef: 方位角单位
    ///   - artist: 作者，默认Timeprint
    ///   - completeHandler: 回调
    static func generateNewImage(imageData: Data,
                                 userCommentStr: String?,
                                 createDate: Date,
                                 modifyDate: Date,
                                 location: CLLocation?,
                      
                                 artist:String = "Timeprint",
                                 completeHandler: @escaping ((Data?) -> ())) {
        
        DispatchQueue.global().async {
            autoreleasepool {
                var finalStr = "";
                if let tempStr = userCommentStr {
                    finalStr = tempStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? tempStr
                }
                
                let (_, metadata) = CGImageMetadata.for(date: createDate,
                                                        modifyDate: modifyDate,
                                                        location: location,
                                                        userComment: finalStr,
                                                        artist: artist
                                                        )
                
                let imageData =  UIImage.getJpgImageData(metadata: metadata, imageSourceData: imageData)
                
                DispatchQueue.main.async {
                    completeHandler(imageData)
                }
            }
        }
    }
}
