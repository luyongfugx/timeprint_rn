//
//  GPBaseVC.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/1.
//

import Foundation
import UIKit

class GPBaseVC: UIViewController {
    
    lazy var navBar: GPNavigateBar = {
        let bar = GPNavigateBar()
        bar.delegate = self
        return bar
    }()
    
    var vcTitle: String = "" {
        didSet {
            navBar.titleLabel.text = vcTitle
        }
    }
    
    deinit {
        LogDebug("GPBaseVC--deinit")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.isHidden = true
        view.backgroundColor = .white
        view.addSubview(navBar)
        navBar.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
            make.top.equalTo(GPApp.statusBarHeight)
        }
    }
    
}

extension GPBaseVC: GPNavigateBarDelegate {
    func clickBack() {
        popOrDismissVC()
    }
}

extension UIViewController {
    
    // MARK: - 向后返回方法
    func popOrDismissVC(animated: Bool = true, completion: (() -> Void)? = nil) {
        
        if let nav = self.navigationController {
            if nav.viewControllers.count == 1 && nav.viewControllers.first == self, nav.presentingViewController != nil {
                nav.dismiss(animated: animated, completion: completion)
            } else {
                nav.popViewController(animated: animated)
                completion?()
            }
        } else {
            self.dismiss(animated: animated, completion: completion)
        }
    }
    
}
