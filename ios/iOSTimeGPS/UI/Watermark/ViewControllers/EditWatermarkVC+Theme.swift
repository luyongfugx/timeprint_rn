//
//  EditWatermarkVC+Theme.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/9/28.
//

import Foundation
import UIKit

extension EditWatermarkVC {
    
    func showEditTheme() {
        guard let watermarkModel = watermarkModel else { return }
        if editThemeView == nil {
            let _editThemeView = EditThemeView(frame: .init(x: 0, y: GPApp.screenHeight, width: GPApp.screenWidth, height: editViewHeight), model: watermarkModel)
            _editThemeView.delegate = self
            editThemeView = _editThemeView
            view.addSubview(_editThemeView)
        }
        guard let editThemeView else { return }
        
        UIView.animate(withDuration: 0.3) {
            editThemeView.bottom = GPApp.screenHeight
        } completion: { finish in
            //
        }
        
        editThemeView.flashScrollIndicators()
    }
    
}

extension EditWatermarkVC: EditThemeViewDelegate {
    
    func updateWatermarkColor(themeColorStr: String?, textColorStr: String?) {
        watermarkModel?.templateColorStr = themeColorStr
        watermarkModel?.textColorStr = textColorStr
        refreshCurrentWatermark()
    }
    
    func updateWatermarkScale(scale: CGFloat) {
        watermarkModel?.templateScale = scale
        refreshCurrentWatermark()
    }
    
    func updateLogoScale(scale: CGFloat) {
        //
    }
    
}
