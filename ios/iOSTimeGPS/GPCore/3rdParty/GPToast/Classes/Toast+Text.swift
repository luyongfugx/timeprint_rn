//
//  GPToast+Text.swift
//  GPToast
//
//  Created by Mccc on 2020/6/24.
//
import UIKit

extension UIResponder {
    
    /// 展示文字toast
    /// - Parameters:
    ///   - text: 文字内容
    ///   - offset: toast底部距离屏幕底部距离
    ///   - duration: 显示的时间（秒）
    ///   - respond: 交互类型
    ///   - callback: 隐藏的回调
    @discardableResult
    public func showText(_ text: String,
                        offset: CGFloat = GPToastConfig.shared.text.offset,
                        duration: CGFloat = GPToastConfig.shared.duration,
                        respond: GPToast.GPToastRespond = GPToastConfig.shared.respond,
                        callback: GPToast.GPToastCallback? = nil) -> UIWindow?  {
        return GPToast.text(text, offset: offset, duration: duration, respond: respond, callback: callback)
    }
}


extension GPToast {
    
    
    /// 展示文字toast
    /// - Parameters:
    ///   - text: 文字内容
    ///   - offset: toast底部距离屏幕底部距离
    ///   - duration: 显示的时间（秒）
    ///   - respond: 交互类型
    ///   - callback: 隐藏的回调
    @discardableResult
    public static func text(_ text: String,
                               offset: CGFloat = GPApp.screenHeight/2.0,
                               duration: CGFloat = GPToastConfig.shared.duration,
                               respond: GPToast.GPToastRespond = GPToastConfig.shared.respond,
                               callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
        return GPToast.showText(text, offset: offset, duration: duration, respond: respond, callback: callback)
        
    }
    
}


// MARK: - 显示纯文字
extension GPToast {
    
    
    /// 展示文字toast
    /// - Parameters:
    ///   - text: 文字内容
    ///   - offset: toast底部距离屏幕底部距离
    ///   - duration: 显示的时间（秒）
    ///   - respond: 交互类型
    ///   - callback: 隐藏的回调
    @discardableResult
    internal static func showText(_ text: String,
                                  offset: CGFloat = GPToastConfig.shared.text.offset,
                                  duration: CGFloat,
                                  respond: GPToast.GPToastRespond,
                                  callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
        
        func createLabel() -> UILabel {
            let label = UILabel()
            label.text = text
            label.numberOfLines = 0
            label.font = GPToastConfig.shared.text.font
            label.textAlignment = .center
            label.textColor = GPToastConfig.shared.text.textColor
            let labelMaxWidth = GPToastConfig.shared.text.maxWidth
            var size = label.sizeThatFits(CGSize(width: labelMaxWidth, height: CGFloat.greatestFiniteMagnitude))
            size.width = max(size.width, GPToastConfig.shared.text.minWidth)
            label.frame = CGRect(x: GPToastConfig.shared.text.padding.left, y: GPToastConfig.shared.text.padding.top, width: size.width, height: size.height)
            return label
        }
        
        func getMainViewFrame(mainViewSize: CGSize, windowFrame: CGRect) -> CGRect {
            switch respond {
            case .allow:
                return CGRect(x: 0, y: 0, width: mainViewSize.width, height: mainViewSize.height)
            case .allowNav, .forbid:
                let x: CGFloat = (windowFrame.width - mainViewSize.width) / 2
                let allowY: CGFloat = windowFrame.height - mainViewSize.height - offset
                return CGRect(x: x, y: allowY, width: mainViewSize.width, height: mainViewSize.height)
            }
        }
        
        func getToastSize(labelSize: CGSize) -> CGSize {
            let width: CGFloat = labelSize.width + GPToastConfig.shared.text.padding.horizontal
            let height: CGFloat = labelSize.height + GPToastConfig.shared.text.padding.vertical
            let frame = CGSize(width: width, height: height)
            return frame
        }
        
        func createWindow() -> UIWindow {
            /// 1. 获取label 和 label size
            let mainLabel = createLabel()
            
            /// 2. 获取toast Size
            let mainSize = getToastSize(labelSize: mainLabel.frame.size)
            
            /// 3. 生成window
            let window = GPToast.createWindow(respond: respond, size: mainSize, toastType: .text, offset: offset)

            /// 4. 生成mainView
            let mainView = GPToast.createMainView()
            
            
            /// 5. 根据window计算mainView的frame
            mainView.frame = getMainViewFrame(mainViewSize: mainSize, windowFrame: window.frame)
            
            /// 6. 添加到对应的父视图上
            mainView.addSubview(mainLabel)
            window.addSubview(mainView)
            windows.append(window)
            
            
            GPToast.autoRemove(window: window, duration: duration, callback: callback)
            
            return window
        }
        
        
        if text.isEmpty { return nil }
        
        var temp: UIWindow?
        DispatchQueue.main.safeSync {
            clearAllToast()
            temp = createWindow()
        }
        return temp
    }
}
