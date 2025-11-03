//
//  PHAsset+Extension.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/3.
//

import Foundation
import Photos

private var XHAssetSelectKey = "XHAssetSelectKey"

extension PHAsset {
    var xhSelected: Bool! {
        set {
            objc_setAssociatedObject(self, &XHAssetSelectKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_ASSIGN)
        }
        get {
            return (objc_getAssociatedObject(self, &XHAssetSelectKey) as? Bool) ?? false
        }
    }
}
