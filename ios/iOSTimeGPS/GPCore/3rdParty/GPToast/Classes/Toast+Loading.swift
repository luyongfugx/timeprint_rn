//
//  GPToast+Loading.swift
//  GPToast
//
//  Created by Mccc on 2020/6/24.
//


import UIKit

/**
 loading 里面新增
 
 1. 帧动画
 2. json动画
 3. 系统loading
 4. 是否需要文字提示
 5. 如何动态更新文字 （比如上传图片的数量的改动）
 6. 
 */

extension UIResponder {
    
    
    /// loading (菊花)
    /// - Parameters:
    ///   - text: 显示的内容
    ///   - duration: 持续时间
    ///   - respond: 交互方式
    ///   - callback: 隐藏回调
    @discardableResult
    public func showLoading(text: String = "正在加载中",
                           duration: CGFloat = 0,
                           respond: GPToast.GPToastRespond = GPToastConfig.shared.respond,
                           callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
        if text.isEmpty {
            return GPToast.loadingIcon(duration: duration, respond: respond)
        } else {
            return GPToast.loading(text: text, duration: duration, respond: respond, callback: callback)
        }
    }
}


extension GPToast {
    
    /// loading (菊花)
    ///
    /// - Parameters:
    ///   - text: 文字内容 默认为 "正在加载中"
    ///   - duration: 自动隐藏的时间
    ///   - font: 字体大小
    @discardableResult
    public static func showLoading(text: String = "正在加载中",
                                  duration: CGFloat = 0,
                                  respond: GPToast.GPToastRespond = GPToastConfig.shared.respond,
                                  callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
        
        if text.isEmpty {
            return GPToast.loadingIcon(duration: duration, respond: respond)
        } else {
            return GPToast.loading(text: text, duration: duration, respond: respond, callback: callback)
        }
    }
}




// MARK: - 网络等待 菊花转圈
extension GPToast {
    
    
    /// Loading （菊花）
    /// - Parameters:
    ///   - text: 文字内容
    ///   - animationSpeed: 动画帧速度
    ///   - duration: 持续时间
    ///   - respond: 交互类型
    ///   - callback: 隐藏的回调
    @discardableResult
    fileprivate static func loading(text: String,
                                    duration: CGFloat,
                                    respond: GPToast.GPToastRespond,
                                    callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
        
        
        func createLabel(iconFrame: CGRect) -> UILabel {
            let label = UILabel()
            label.font = GPToastConfig.shared.icon.font
            label.textColor = GPToastConfig.shared.icon.textColor
            
            if text.count == 0 {
                label.text = "正在加载中"
            } else {
                label.text = text
            }
            
            label.numberOfLines = 2
            label.lineBreakMode = .byCharWrapping
            label.textAlignment = NSTextAlignment.center
            
            
            let labelWidth = GPToastConfig.shared.icon.toastWidth - GPToastConfig.shared.icon.padding.left - GPToastConfig.shared.icon.padding.right
            let labelSize = label.sizeThatFits(CGSize(width: labelWidth, height: CGFloat.greatestFiniteMagnitude))
            label.frame = CGRect(x: GPToastConfig.shared.icon.padding.left, y: iconFrame.maxY + 12, width: labelWidth, height: labelSize.height)
            return label
        }
        
        func createActivity() -> UIActivityIndicatorView {
            let activity = UIActivityIndicatorView()
            activity.color = UIColor.white
            if #available(iOS 13.0, *) {
                activity.style = .large
            } else {
                activity.style = .whiteLarge
            }
            activity.startAnimating()
//            activity.transform = CGAffineTransform.init(scaleX: 1.5, y: 1.5)
            return activity
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
            
            let activity = createActivity()
            let iconFrame = getIconFrame()
            activity.frame = iconFrame
            
            
            let label = createLabel(iconFrame: iconFrame)
            
            
        
            let mainSize = getToastSize(labelFrame: label.frame)
            let window = GPToast.createWindow(respond: respond, size: mainSize, toastType: .icon)

            
            
            
            let mainView = GPToast.createMainView()
            mainView.frame = getMainViewFrame(mainViewSize: mainSize, windowFrame: window.frame)
            mainView.addSubview(activity)
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
    
    /// Loading （菊花）
    /// - Parameters:
    ///   - text: 文字内容
    ///   - animationSpeed: 动画帧速度
    ///   - duration: 持续时间
    ///   - respond: 交互类型
    ///   - callback: 隐藏的回调
    @discardableResult
    fileprivate static func loadingIcon(duration: CGFloat,
                                    respond: GPToast.GPToastRespond,
                                    callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
        var temp: UIWindow?
        DispatchQueue.main.safeSync {
            clearAllToast()
            temp = createWindow()
        }
        return temp
        
        func createActivity() -> UIActivityIndicatorView {
            let activity = UIActivityIndicatorView()
            if #available(iOS 13.0, *) {
                activity.style = .medium
            } else {
                activity.style = .gray
            }
            activity.tintColor = .gray
            activity.startAnimating()
            return activity
        }
        
        func getIconFrame() -> CGRect {
            let size = GPToastConfig.shared.icon.imageSize
            let x = (GPToastConfig.shared.icon.toastWidth - size.width) / 2
            var rect = CGRect.zero
            rect.size = size
            rect.origin = CGPoint(x: x, y: GPToastConfig.shared.icon.padding.top)
            return rect
        }
        
        func getToastSize(labelFrame: CGRect) -> CGSize {
            let width: CGFloat =  GPToastConfig.shared.icon.toastWidth
            let height: CGFloat = labelFrame.maxY + GPToastConfig.shared.icon.padding.bottom
            let frame = CGSize(width: width, height: height)
            return frame
        }
        
        func createWindow() -> UIWindow? {
            
            let activity = createActivity()
            let iconFrame = getIconFrame()
            
            let mainSize = iconFrame.size
            let window = GPToast.createWindow(respond: respond, size: mainSize, toastType: .icon)
            
            /// 始终显示在屏幕中心
            let iconSize = GPToastConfig.shared.icon.imageSize
            let x: CGFloat = (window.frame.width - iconSize.width) / 2
            let y: CGFloat = (window.frame.height - iconSize.height) / 2
            activity.frame = CGRect(x: x, y: y, width: iconSize.width, height: iconSize.height)
            
            window.addSubview(activity)
            
            windows.append(window)
            GPToast.autoRemove(window: window, duration: duration, callback: callback)

            return window
        }
    }
}
