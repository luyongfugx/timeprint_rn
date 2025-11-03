//
//  GPToViewManager.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/7.
//

import Foundation

enum ToViewType {
    case editLogo
    case editMap
}

class GPToViewManager {
    
    static let shared = GPToViewManager()
    weak var cameraVC: CameraVC?
    
    func goto(_ viewType: ToViewType) {
        switch viewType {
        case .editLogo:
            cameraVC?.gotoEditLogo()
        case .editMap:
            cameraVC?.gotoEditMap()
        }
    }
    
}
