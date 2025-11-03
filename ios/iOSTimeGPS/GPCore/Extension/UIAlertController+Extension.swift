//
//  UIAlertController+Extension.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/12/12.
//

import Foundation
import UIKit

public typealias BCAlertDidSelectHandler = (_ index: Int, _ controller:UIAlertController?) -> Void
public typealias BCAlertInputHandler = (_ inputField: UITextField) -> Void

public extension UIAlertController {
    
    /// alert弹框
    /// - Parameter title: 标题
    /// - Parameter message: 副标题
    /// - Parameter buttonTitles: 按钮名称的数组
    /// - Parameter viewController: present的控制器
    /// - Parameter onSelect: 点击回调
    class func showAlert(title:String?, message:String?, buttonTitles: [String], viewController: UIViewController?, styles: [UIAlertAction.Style] = [], onSelect:BCAlertDidSelectHandler?, isCenter: Bool = false) {
        
        DispatchQueue.main.async {
            if buttonTitles.count == 0 {
                return
            }
            
            // V2.9.345: 是否强制居中显示UIAlertController
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            for index in 0..<buttonTitles.count {
                var currentStyle: UIAlertAction.Style = .default
                if index < styles.count {
                    currentStyle = styles[index]
                }
                
                let action = UIAlertAction(title: buttonTitles[index], style: currentStyle) { [weak alertController] (alertAction) in
                    DispatchQueue.main.async {
                        if let handler = onSelect {
                            handler(index, alertController)
                        }
                    }
                }
                alertController.addAction(action)
            }
            
            if let vc = getCurrentPresentingVC(defaultVC: viewController) {
                self.willShowAlert(vc: vc, alertController: alertController)
            }
        }
    }

    /// alert弹框
    /// - Parameter title: 标题
    /// - Parameter message: 副标题
    /// - Parameter buttonTitles: 按钮名称的数组
    /// - Parameter viewController: present的控制器
    /// - Parameter buttonColors: 按钮颜色
    /// - Parameter onSelect: 点击回调
    class func showAlert(title:String?, message:String?, buttonTitles: [String], viewController: UIViewController?, buttonColors: [UIColor], onSelect:BCAlertDidSelectHandler?) {

        DispatchQueue.main.async {
            if buttonTitles.count == 0 {
                return
            }

            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            for index in 0..<buttonTitles.count {
                let action = UIAlertAction(title: buttonTitles[index], style: .default) { [weak alertController] (alertAction) in
                    DispatchQueue.main.async {
                        if let handler = onSelect {
                            handler(index, alertController)
                        }
                    }
                }

                if index < buttonColors.count {
                    action.setValue(buttonColors[index], forKey: "titleTextColor")
                }

                alertController.addAction(action)
            }

            if let vc = getCurrentPresentingVC(defaultVC: viewController) {
                self.willShowAlert(vc: vc, alertController: alertController)
            }
        }
    }
    
    @discardableResult
    class func alertOrActionSheet(title: String?, message: String?, buttonTitles:  [String], viewController: UIViewController?, styles: [UIAlertAction.Style] = [], onSelect: BCAlertDidSelectHandler?) ->  UIAlertController? {
        
        if buttonTitles.count == 0 {
            return nil
        }
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for index in 0..<buttonTitles.count {
            var currentStyle: UIAlertAction.Style = .default
            if index < styles.count {
                currentStyle = styles[index]
            }
            
            let action = UIAlertAction(title: buttonTitles[index], style: currentStyle) { [weak alertController] (alertAction) in
                DispatchQueue.main.async {
                    if let handler = onSelect {
                        handler(index, alertController)
                    }
                }
            }
            alertController.addAction(action)
        }
        
        if let vc = getCurrentPresentingVC(defaultVC: viewController) {
            willShowAlert(vc: vc, alertController: alertController)
        }
        return alertController
    }
    
    /// ActionSheet弹框
    /// - Parameter title: 标题
    /// - Parameter message: 副标题
    /// - Parameter buttonTitles: 按钮名称的数组
    /// - Parameter viewController: present的控制器
    /// - Parameter onSelect: 点击回调
    class func showActionSheet(title:String?, message:String?, buttonTitles:[String], viewController:UIViewController?, styles: [UIAlertAction.Style] = [], onSelect:BCAlertDidSelectHandler?) {
        
        DispatchQueue.main.async {
            if buttonTitles.count == 0 {
                return
            }
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
            for index in 0..<buttonTitles.count {
                var currentStyle: UIAlertAction.Style = .default
                if index == buttonTitles.count - 1 {
                    currentStyle = .cancel
                } else {
                    if index < styles.count {
                        currentStyle = styles[index]
                    }
                }
                
                let action = UIAlertAction(title: buttonTitles[index], style: currentStyle) { [weak alertController] (alertAction) in
                    DispatchQueue.main.async {
                        if let handler = onSelect {
                            handler(index, alertController)
                        }
                    }
                }
                alertController.addAction(action)
            }
            
            if let vc = getCurrentPresentingVC(defaultVC: viewController) {
                willShowAlert(vc: vc, alertController: alertController)
            }
        }
    }
    
    /// 带输入框的alert弹框
    /// - Parameter title: 标题
    /// - Parameter message: 副标题
    /// - Parameter buttonTitles: 按钮名称的数组
    /// - Parameter viewController: present的控制器
    /// - Parameter onSelect: 点击回调
    class func showInputAlert(title:String?, message:String?, buttonTitles:[String], viewController:UIViewController?, onSelect:BCAlertDidSelectHandler?, inputHandler: BCAlertInputHandler?) {
        
        DispatchQueue.main.async {
            if buttonTitles.count == 0 {
                return
            }
            
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            for index in 0..<buttonTitles.count {
                let action = UIAlertAction(title: buttonTitles[index], style: .default) { [weak alertController] (alertAction) in
                    DispatchQueue.main.async {
                        if let handler = onSelect {
                            handler(index, alertController)
                        }
                    }
                }
                alertController.addAction(action)
            }
            
            //添加textField输入框
            alertController.addTextField { (textField) in
                if let handler = inputHandler {
                    handler(textField)
                }
            }
            
            if let vc = getCurrentPresentingVC(defaultVC: viewController) {
                willShowAlert(vc: vc, alertController: alertController)
            }
        }
    }
    
    // 获取当前的presentingViewController
    private class func getCurrentPresentingVC(defaultVC: UIViewController?) -> UIViewController? {
        
        // 1、如果透传过来的VC能用，使用透传过来的
        if let vc = defaultVC {
            return vc
        }
        
        // 2、使用最上面的vc
        if let vc = GPApp.topViewController {
            return vc
        }
        
        // 3、使用rootViewController
        if let rootVC = UIApplication.shared.keyWindow?.rootViewController {
            return rootVC
        }
        return nil
    }
    
    // 2.9.228:尝试解决iPad上崩溃的bug
    private class func willShowAlert(vc: UIViewController, alertController: UIAlertController) {
        // 适配ipad，2.9.228版本尝试解决在iPad上崩溃的bug
        if let presentController = alertController.popoverPresentationController, alertController.preferredStyle == .actionSheet {
            presentController.sourceView = vc.view
            presentController.sourceRect = CGRect(x:GPApp.screenWidth/2, y: vc.view.height/2, width: 0, height: 0)
            presentController.permittedArrowDirections = .any
        }
        
        vc.present(alertController, animated: true, completion: nil)
    }
    
    // 2.9.305版本：尝试解决iOS12横屏播放崩溃的问题
    override var shouldAutorotate: Bool {
        return false
    }
}
