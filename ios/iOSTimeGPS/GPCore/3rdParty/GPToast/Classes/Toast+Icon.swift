//
//  GPToast+Icon.swift
//  GPToast
//
//  Created by Mccc on 2020/6/24.
//
import UIKit

extension GPToast {
    /// Toast类型
    public enum IconType {
        /// 成功
        case success
        /// 失败
        case failure
        /// 警告
        case warning
        
        func getImage() -> UIImage? {
            var showImage: UIImage?
            switch self {
            case .success:
                if let trueImage = GPToastConfig.shared.icon.successImage {
                    showImage = trueImage
                } else {
                    showImage = GPToast.loadImage("toast_success")
                }
            case .failure:
                if let trueImage = GPToastConfig.shared.icon.failureImage {
                    showImage = trueImage
                } else {
                    showImage = GPToast.loadImage("toast_failure")
                }
            case .warning:
                if let trueImage = GPToastConfig.shared.icon.warningImage {
                    showImage = trueImage
                } else {
                    showImage = GPToast.loadImage("toast_warning")
                }
            }
            return showImage
        }
    }
}



extension UIResponder {
    
    /// 成功类型的Toast
    /// - Parameters:
    ///   - text: 文字内容
    ///   - duration: 展示时间（秒）
    ///   - respond: 交互类型
    ///   - callback: 隐藏的回调
    @discardableResult
    public func showSuccess(_ text:String,
                           duration: CGFloat = GPToastConfig.shared.duration,
                           respond: GPToast.GPToastRespond = GPToastConfig.shared.respond,
                           callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
        return GPToast.success(text, duration: duration, respond: respond, callback: callback)
    }
    
    
    /// 失败类型的Toast
    /// - Parameters:
    ///   - text: 文字内容
    ///   - duration: 展示时间（秒）
    ///   - respond: 交互类型
    ///   - callback: 隐藏的回调
    @discardableResult
    public func showFailure(_ text: String,
                           duration:CGFloat = GPToastConfig.shared.duration,
                           respond: GPToast.GPToastRespond = GPToastConfig.shared.respond,
                           callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
        return GPToast.failure(text, duration: duration, respond: respond, callback: callback)
    }
    
    
    /// 警告类型的Toast
    /// - Parameters:
    ///   - text: 文字内容
    ///   - duration: 展示时间（秒）
    ///   - respond: 交互类型
    ///   - callback: 隐藏的回调
    @discardableResult
    public func showWarning(_ text: String,
                           duration:CGFloat = GPToastConfig.shared.duration,
                           respond: GPToast.GPToastRespond = GPToastConfig.shared.respond,
                           callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
        return GPToast.warning(text, duration: duration, respond: respond, callback: callback)
    }
}



extension GPToast {
    
    /// 成功类型的Toast
    /// - Parameters:
    ///   - text: 文字内容
    ///   - duration: 展示时间（秒）
    ///   - respond: 交互类型
    ///   - callback: 隐藏的回调
    @discardableResult
    public static func success(_ text:String,
                                  duration: CGFloat = GPToastConfig.shared.duration,
                                  respond: GPToast.GPToastRespond = GPToastConfig.shared.respond,
                                  callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
        
        return GPToast.showStatus(text: text, iconImage: IconType.success.getImage(), duration: duration, respond: respond, callback: callback)
    }
    
    
    /// 失败类型的Toast
    /// - Parameters:
    ///   - text: 文字内容
    ///   - duration: 展示时间（秒）
    ///   - respond: 交互类型
    ///   - callback: 隐藏的回调
    @discardableResult
    public static func failure(_ text: String,
                                  duration:CGFloat = GPToastConfig.shared.duration,
                                  respond: GPToast.GPToastRespond = GPToastConfig.shared.respond,
                                  callback: GPToast.GPToastCallback? = nil) -> UIWindow?  {
        return GPToast.showStatus(text: text, iconImage: IconType.failure.getImage(), duration: duration, respond: respond, callback: callback)
    }
    
    
    /// 警告类型的Toast
    /// - Parameters:
    ///   - text: 文字内容
    ///   - duration: 展示时间（秒）
    ///   - respond: 交互类型
    ///   - callback: 隐藏的回调
    @discardableResult
    public static func warning(_ text: String,
                                  duration: CGFloat = GPToastConfig.shared.duration,
                                  respond: GPToast.GPToastRespond = GPToastConfig.shared.respond,
                                  callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
        return GPToast.showStatus(text: text, iconImage: IconType.warning.getImage(), duration: duration, respond: respond,callback: callback)
    }
}


// MARK: - 展示各种状态Toast
extension GPToast {
    
    /// 加载图片资源
    static func loadImage(_ name: String) -> UIImage? {
        let image = BundleImage.loadImage(named: name)
        return image
    }
    
    @discardableResult
    public static func showStatus(text: String,
                                  iconImage: UIImage?,
                                  duration: CGFloat,
                                  respond: GPToast.GPToastRespond,
                                  callback: GPToast.GPToastCallback? = nil) -> UIWindow? {

        
        func createLabel(iconFrame: CGRect) -> UILabel {
            let label = UILabel()
            label.font = GPToastConfig.shared.icon.font
            label.textColor = GPToastConfig.shared.icon.textColor
            label.text = text
            label.numberOfLines = 2
            label.lineBreakMode = .byCharWrapping
            label.textAlignment = NSTextAlignment.center
            
            
            let labelWidth = GPToastConfig.shared.icon.toastWidth - GPToastConfig.shared.icon.padding.horizontal
            let labelSize = label.sizeThatFits(CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude))
            label.frame = CGRect(x: GPToastConfig.shared.icon.padding.left, y: iconFrame.maxY + 12, width: labelWidth, height: labelSize.height)
            return label
        }
        
        func createIcon() -> UIImageView {
            let icon = UIImageView(image: iconImage)
            return icon
        }
        
        
        func getIconFrame() -> CGRect {
            let size = GPToastConfig.shared.icon.imageSize
            let x = (GPToastConfig.shared.icon.toastWidth - size.width) / 2
            var rect = CGRect.zero
            rect.size = size
            rect.origin = CGPoint(x: x, y: GPToastConfig.shared.icon.padding.top)
            return rect
        }
        
        func getMainViewFrame(mainViewSize: CGSize, windowFrame: CGRect) -> CGRect {
            
            /// 始终显示在屏幕中心
            let x: CGFloat = (windowFrame.width - mainViewSize.width) / 2
            var y: CGFloat = (windowFrame.height - mainViewSize.height) / 2
            if respond == .allowNav {
                guard let vc = UIViewController.current() else {
                    return CGRect(x: x, y: y, width: mainViewSize.width, height: mainViewSize.height)
                }

                let rectNav = vc.navigationController?.navigationBar.frame
                let maxY = rectNav?.maxY ?? 0
                y -= maxY / 2
            }
            return CGRect(x: x, y: y, width: mainViewSize.width, height: mainViewSize.height)
        }
        
        func getToastSize(labelFrame: CGRect) -> CGSize {
            let width: CGFloat =  GPToastConfig.shared.icon.toastWidth
            let height: CGFloat = labelFrame.maxY + GPToastConfig.shared.icon.padding.bottom
            let frame = CGSize(width: width, height: height)
            return frame
        }
        

        
        
        func createWindow() -> UIWindow? {
            
            let icon = createIcon()
            let iconFrame = getIconFrame()
            icon.frame = iconFrame
            
            
            let label = createLabel(iconFrame: iconFrame)
            
            
        
            let mainSize = getToastSize(labelFrame: label.frame)
            let window = GPToast.createWindow(respond: respond, size: mainSize, toastType: .icon)

            
            
            
            let mainView = GPToast.createMainView()
            mainView.frame = getMainViewFrame(mainViewSize: mainSize, windowFrame: window.frame)
            mainView.addSubview(icon)
            mainView.addSubview(label)
            window.addSubview(mainView)
            


            
            windows.append(window)
            
            GPToast.autoRemove(window: window, duration: duration, callback: callback)

            return window
        }

        if text.isEmpty {
            return nil
        }
        var temp: UIWindow?
        DispatchQueue.main.safeSync {
            clearAllToast()
            temp = createWindow()
        }
        return temp
    }
}




