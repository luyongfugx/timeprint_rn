//
//  GPToast+Custom.swift
//  BTMaterial
//
//  Created by batman on 2022/12/8.
//

import Foundation
import UIKit
extension GPToast {
    
}
// MARK: - 展示各种状态Toast
extension GPToast {
        
    @discardableResult
    public static func showCustomView(_ customView: UIView,
                                  duration: CGFloat,
                                  bgColor: UIColor? = nil,
                                  respond: GPToast.GPToastRespond,
                                      isLandscape: Bool = false,
                                  callback: GPToast.GPToastCallback? = nil) -> UIWindow? {

        
        
        func createWindow() -> UIWindow? {
            
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
        
            let mainSize = customView.frame.size
            let window = GPToast.createWindow(respond: respond, isLandscape: isLandscape, size: mainSize, toastType: .icon)

            let mainView = GPToast.createMainView(bgColor: bgColor)
            mainView.addSubview(customView)
            mainView.frame = getMainViewFrame(mainViewSize: mainSize, windowFrame: window.frame)

            
            window.addSubview(mainView)

            
            windows.append(window)
            
            GPToast.autoRemove(window: window, duration: duration, callback: callback)

            return window
        }


        var temp: UIWindow?
        DispatchQueue.main.safeSync {
            clearAllToast()
            temp = createWindow()
        }
        return temp
    }
}

