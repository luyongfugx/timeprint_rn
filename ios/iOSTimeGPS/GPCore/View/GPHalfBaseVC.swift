//
//  GPHalfBaseVC.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/1.
//

import Foundation
import UIKit

class GPHalfBaseVC: GPBaseVC {
    
    var bgColor: UIColor = .black.withAlphaComponent(0.5)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navBar.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
            make.top.equalTo(6)
        }
    }
    
}

extension GPHalfBaseVC: GPPresentationControllerTransitioning {
    
    func preferredDimmingViewBackgroundColor(for presentationController: UIPresentationController) -> UIColor? {
        bgColor
    }
    
}
