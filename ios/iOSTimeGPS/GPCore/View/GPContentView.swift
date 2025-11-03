//
//  GPContentView.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/18.
//

import Foundation
import UIKit

let excludeTag: Int = 999

class GPContentView: GPView {

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event);
        if view?.tag == excludeTag {
            return view
        }
        if (view == self) {
            return nil
        }
        
        return view
    }

    
}
