//
//  GPToast+noticeBar.swift
//  GPToast
//
//  Created by Mccc on 2020/6/24.
//

import Foundation
import UIKit

extension UIResponder {
    
    /// 在状态栏栏显示一个toast
    /// - Parameters:
    ///   - text: 显示的文字内容
    ///   - duration: 显示的时长（秒）
    ///   - font: 文字字体
    ///   - backgroundColor: 背景颜色
    ///   - callback: 隐藏的回调
    @discardableResult
    public func showStatusBar( _ text: String,
                              duration: CGFloat = GPToastConfig.shared.duration,
                              font: UIFont = GPToastConfig.shared.text.font,
                              backgroundColor: UIColor? = nil,
                              callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
        return GPToast.statusBar(text, duration: duration, font: font, backgroundColor: backgroundColor, callback: callback)
    }
}


extension GPToast {
    
    /// 在状态栏栏显示一个toast
    /// - Parameters:
    ///   - text: 显示的文字内容
    ///   - duration: 显示的时长（秒）
    ///   - font: 文字字体
    ///   - backgroundColor: 背景颜色
    ///   - callback: 隐藏的回调
    @discardableResult
    public static func statusBar(
        _ text: String,
        duration: CGFloat = GPToastConfig.shared.duration,
        font: UIFont = GPToastConfig.shared.text.font,
        backgroundColor: UIColor? = nil,
        callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
            return GPToast.noticeOnStatusBar(text, duration: duration, backgroundColor: backgroundColor, font: font, callback: callback)
        }
}



// MARK: - 在状态栏上显示提示框
extension GPToast {
    
    
    @discardableResult
    internal static func noticeOnStatusBar(
        _ text: String,
        duration: CGFloat,
        backgroundColor: UIColor?,
        font: UIFont,
        callback: GPToast.GPToastCallback? = nil) -> UIWindow? {
            
            
            
            func createWindow() -> UIWindow {
                clearAllToast()
                
                let labelHeight: CGFloat = text.getHeight(font: font, width: kScreenWidth) + 10
                
                
                let topSafeAreaHeight: CGFloat = UIDevice.topSafeAreaHeight
                let height = topSafeAreaHeight + labelHeight
                
                let frame = CGRect(x: 0, y: 0, width: kScreenWidth, height: height)
                
                let window = UIWindow()
                window.backgroundColor = UIColor.clear
                
                let view = UIView()
                
                if let color = backgroundColor {
                    view.backgroundColor = color
                } else {
                    let red: CGFloat = 0x6a/0x100
                    let green: CGFloat = 0xb4/0x100
                    let blue: CGFloat = 0x9f/0x100
                    view.backgroundColor = UIColor(red: red, green: green, blue: blue, alpha: 1)
                }
                
                let label = UILabel()
                label.frame = CGRect.init(x: 0, y: topSafeAreaHeight, width: frame.width, height: labelHeight)
                label.textAlignment = NSTextAlignment.center
                label.font = font
                label.textColor = UIColor.white
                label.text = text
                view.addSubview(label)
                
                window.frame = frame
                view.frame = frame
                
                
                window.windowLevel = UIWindow.Level(9999999)
                window.isHidden = false
                window.addSubview(view)
                windows.append(window)
                
                var origPoint = view.frame.origin
                origPoint.y = -(view.frame.size.height)
                let destPoint = view.frame.origin
                view.tag = sn_topBar
                
                view.frame = CGRect(origin: origPoint, size: view.frame.size)
                UIView.animate(withDuration: 0.3, animations: {
                    view.frame = CGRect(origin: destPoint, size: view.frame.size)
                }, completion: { b in
                    GPToast.autoRemove(window: window, duration: duration, callback: callback)
                })
                return window
            }
            
            
            if text.isEmpty {
                return nil
            }
            
            var temp: UIWindow?
            DispatchQueue.main.safeSync {
                temp = createWindow()
            }
            return temp
        }
}
