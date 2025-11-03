//
//  UIViewController+XHTransition.swift
//  XCamera
//
//  Created byBatMan on 2021/12/1.
//  Copyright © 2021 xhey. All rights reserved.
//

import UIKit

extension UIViewController {

    func customPresent(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let presentationController = GPPresentationController(presentedViewController: viewController, presenting: self)
        viewController.transitioningDelegate = presentationController
        present(viewController, animated: animated, completion: completion)
    }

    func customPopPresent(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let presentationController = GPPopPresentationController(presentedViewController: viewController, presenting: self)
        viewController.transitioningDelegate = presentationController
        present(viewController, animated: animated, completion: completion)
    }
}

extension UIViewController {
    /// 弹出一个只有一个按钮的 Alert
    static func show45ButtonAlert(
        title: String?,
        message: String?,
        buttonTitle: String = "OK",
        onTap: (() -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: .default) { _ in
            onTap?()
        })
        DispatchQueue.main.async {
            GPApp.topViewController?.present(alert, animated: true)
        }
    }
}
