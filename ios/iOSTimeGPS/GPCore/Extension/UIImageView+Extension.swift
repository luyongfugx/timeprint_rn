//
//  UIImageView+Extension.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/17.
//

import Foundation
import UIKit
import Kingfisher

extension UIImageView {
    
    // 便捷构造方式
    convenience init(imageName: String?, cornerRadius: CGFloat = 0, backgroundColor: UIColor = UIColor.clear, contentMode: ContentMode = .scaleToFill, clipsToBounds: Bool = false) {
        
        // V2.9.220版本：处理报错：[framework] CUICatalog: Invalid asset name supplied: ''
        var currentImg: UIImage? = nil
        if let imgName = imageName, imgName.count > 0 {
            currentImg = UIImage(named: imgName)
        }
        
        self.init(image: currentImg)
        self.backgroundColor = backgroundColor
        if cornerRadius > 0 {
            self.layerCornerRadius = cornerRadius
        }
        
        self.contentMode = contentMode
        self.clipsToBounds = clipsToBounds
    }
    
    // 便捷构造方式
    convenience init(image: UIImage?, cornerRadius: CGFloat = 0, backgroundColor: UIColor = UIColor.clear, contentMode: ContentMode = .scaleToFill, clipsToBounds: Bool = false) {
        
        self.init(image: image)
        self.backgroundColor = backgroundColor
        if cornerRadius > 0 {
            self.layerCornerRadius = cornerRadius
        }
        
        self.contentMode = contentMode
        self.clipsToBounds = clipsToBounds
    }
    
    // 通过url设置图片
    func downloadAndSetImage(with urlStr: String?, defaultImage: UIImage? = nil, complete: ((UIImage?, URL?) -> ())? = nil) {
        
        if let tempImage = defaultImage {
            self.image = tempImage
        }
        
        if let urlString = urlStr, let url = URL(string: urlString) {
            
            KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: { (receivedSize, totalSize) in
//                XHLogDebug("[下载图片调试] - 已经下载的size:[\(receivedSize)] - 总大小:[\(totalSize)]")
            }) { (result) in
                
                switch result {
                case .success(let value):
                    self.image = value.image
                    complete?(value.image, value.source.url)
                case .failure( _):
                    complete?(nil, nil)
                }
            }
        }
    }
    
    // 通过url设置图片
    func setImage_xh(with urlStr: String?, defaultImage: Placeholder? = nil, complete: ((UIImage?, URL?) -> ())? = nil) {
        if let urlString = urlStr, let url = URL(string: urlString) {
            self.kf.setImage(with: url, placeholder: defaultImage, options: nil, progressBlock: { (receivedSize, totalSize) in
                // XHLogDebug("[下载图片调试] - 已经下载的size:[\(receivedSize)] - 总大小:[\(totalSize)]")
            }) { (result) in
                switch result {
                case .success(let value):
                    complete?(value.image, value.source.url)
                case .failure( _):
                    complete?(nil, nil)
                }
            }
        } else {
            complete?(nil, nil)
        }
    }
    
}
