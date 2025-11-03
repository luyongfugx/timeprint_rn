//
//  WatermarkLogoListItem.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/3.
//

import Foundation

// Logo补充信息
class WatermarkLogoListItem: NSObject, GPCodable {
    var logoList: [WatermarkLogoOneItem]?
    
    func checkInit() {
        if logoList == nil {
            logoList?.append(WatermarkLogoOneItem(isOpen: false, logoPath: nil, logoIndex: 0))
            logoList?.append(WatermarkLogoOneItem(isOpen: false, logoPath: nil, logoIndex: 1))
            logoList?.append(WatermarkLogoOneItem(isOpen: false, logoPath: nil, logoIndex: 0))
        }
    }
    
    func getFirstImg() -> UIImage? {
        for item in logoList ?? [] {
            if let img = item.getLogoImage() {
                return img
            }
        }
        return nil
    }
}

// Logo补充信息
class WatermarkLogoOneItem: NSObject, GPCodable {
    var isOpen: Bool?
    var logoPath: String?
    var logoUrl: String?
    var logoIndex: Int?
    
    init(isOpen: Bool? = nil, logoPath: String? = nil, logoIndex: Int? = nil) {
        self.isOpen = isOpen
        self.logoPath = logoPath
        self.logoIndex = logoIndex
    }

    func getLogoImage() -> UIImage? {
        // 只判断本地path
        guard let logoPath = self.logoPath else {
            return nil
        }
        
        if let img = UIImage(named: logoPath) {
            return img
        } else {
            return GPDataCacheManager.shared.getCachLogo(fileName: logoPath)
        }
        
    }
    
    func addLogo(_ img: UIImage) {
        // 将图片保存到本地沙盒
        let fileName = NSUUID().uuidString + ".png"
        GPDataCacheManager.shared.cachLogo(logoImg: img, fileName: fileName)
        self.logoPath = fileName
    }
}
