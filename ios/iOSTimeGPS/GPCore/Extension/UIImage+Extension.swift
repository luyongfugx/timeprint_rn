//
//  UIImage.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/6.
//

import Foundation
import UIKit

extension UIImage {
        
    // 调整比例，也变相压缩图片
    class func resizeImage(image: UIImage, targetSize: CGSize = .init(width: 200, height: 200)) -> UIImage? {
        let size = image.size

        let widthRatio  = targetSize.width  / size.width
        let heightRatio = targetSize.height / size.height

        // 根据较小的比率调整图像大小，以保持纵横比
        let newSize = CGSize(width: size.width * min(widthRatio, heightRatio),
                             height: size.height * min(widthRatio, heightRatio))

        // 创建一个位图图形上下文，并在其中绘制调整大小后的图像
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1)
        image.draw(in: CGRect(origin: .zero, size: newSize))

        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return newImage
    }
    
    // 通过多个色值生成一张渐变的图片
    class func imageWithGradientColors(
        colors: [UIColor],
        size: CGSize,
        startPoint: CGPoint = .init(x: 0.5, y: 0),
        endPoint: CGPoint = .init(x: 0.5, y: 0.8),
        locations: [NSNumber]? = nil
    ) -> UIImage? {
        var cgColors: [CGColor] = []
        for currentColor in colors {
            cgColors.append(currentColor.cgColor)
        }
        
        let view = UIView(frame: .init(x: 0, y: 0, width: size.width, height: size.height))
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        
        gradientLayer.colors = cgColors
        gradientLayer.locations = locations
        
        gradientLayer.frame = CGRect.init(x: 0, y: 0, width: size.width, height: size.height)
        
        view.layer.addSublayer(gradientLayer)
        
        let image = UIImage.imageWithView(view, compressionQuality: 1.0)
        return image
    }
    
    class func imageWithView(_ view : UIView, compressionQuality : CGFloat) -> UIImage? {
        
        UIGraphicsBeginImageContext(view.bounds.size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        view.layer.render(in: context)
        
        if let image = UIGraphicsGetImageFromCurrentImageContext(){
            UIGraphicsEndImageContext()
            if compressionQuality == 1 {
                return image
            } else {
                if let data = image.jpegData(compressionQuality: compressionQuality){
                    let tempImage = UIImage.init(data: data)
                    return tempImage
                }else{
                    return nil
                }
            }
        }else{
            return nil
        }
    }
}

extension UIImage {
    func tint(with color: UIColor) -> UIImage {
        var image = withRenderingMode(.alwaysTemplate)
        UIGraphicsBeginImageContextWithOptions(size.nonzeroSize, false, scale)
        color.set()

        image.draw(in: CGRect(origin: .zero, size: size))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
}

extension UIImage {
    func resize(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
