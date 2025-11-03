//
//  GPView.swift
//  iOSTimeGPS
//
//

import Foundation
import UIKit
import SnapKit

open class GPView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
    }
    
    open func buildUI() { }
}
