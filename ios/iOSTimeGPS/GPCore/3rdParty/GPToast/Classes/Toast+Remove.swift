//
//  GPToast+Remove.swift
//  GPToast
//
//  Created by Mccc on 2020/6/24.
//

import Foundation
import UIKit

extension UIResponder {
    
    /// 移除toast
    /// - Parameter callback: 移除成功的回调
    public func removeToast(callback: GPToast.GPToastCallback? = nil) {
        GPToast.clearAllToast(callback: callback)
    }
}


extension GPToast {
    /// 移除toast
    /// - Parameter callback: 移除成功的回调
    public static func remove(callback: GPToast.GPToastCallback? = nil) {
        GPToast.clearAllToast(callback: callback)
    }
}


internal extension Selector {
    static let hideNotice = #selector(GPToast.hideNotice(_:))
}

extension GPToast {
    
    /// 隐藏
    @objc static func hideNotice(_ sender: AnyObject) {
        if let window = sender as? UIWindow {
            
            if let v = window.subviews.first {
                UIView.animate(withDuration: 0.2, animations: {
                    
                    if v.tag == sn_topBar {
                        v.frame = CGRect(x: 0, y: -v.frame.height, width: v.frame.width, height: v.frame.height)
                    }
                    v.alpha = 0
                }, completion: { b in
                    
                    if let index = windows.firstIndex(where: { (item) -> Bool in
                        return item == window
                    }) {
                        windows.remove(at: index)
                    }
                })
            }
        }
    }
    
    
    /// 清空
    static func clearAllToast(callback: GPToastCallback? = nil) {
        
        DispatchQueue.main.safeSync {
            self.cancelPreviousPerformRequests(withTarget: self)
            windows.removeAll(keepingCapacity: false)
        }
        callback?()
    }
}


extension GPToast {
    
    /// 自动隐藏
    static func autoRemove(window: UIWindow, duration: CGFloat, callback: GPToastCallback?) {
        let autoClear : Bool = duration > 0 ? true : false
        if autoClear {
            self.perform(.hideNotice, with: window, afterDelay: TimeInterval(duration))
             
            let time = DispatchTime.now() + .milliseconds(Int(duration * 1000))
            DispatchQueue.main.asyncAfter(deadline: time) {
                callback?()
            }
        }
    }
}
