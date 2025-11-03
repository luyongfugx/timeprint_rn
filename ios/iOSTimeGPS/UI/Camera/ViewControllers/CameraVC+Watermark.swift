//
//  CameraVC+Watermark.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/4.
//

import Foundation

extension CameraVC: BaseWatermarkDelegate {
    
    func beginEditWatermark() {
        self.topView.isHidden = true
        self.wideAngleListView?.isHidden = true
        self.currentWatermarkView?.isHidden = false
    }
    
    func endEditWatermark() {
        self.topView.isHidden = false
        self.wideAngleListView?.isHidden = false
        self.currentWatermarkView?.isHidden = false
    }
    
    func gotoEditCurrentWatermark() -> EditWatermarkVC? {
        return handleWatermarkAction(.edit)
    }
}

extension CameraVC {
    
    @discardableResult
    func handleWatermarkAction(_ type: EditWatermarkType) -> EditWatermarkVC? {
        guard let watermarkModel = currentWatermarkView?.watermarkModel, let wmView = self.currentWatermarkView else { return nil }

        if type == .list {
            CameraConfig.showWatermarBtnRed = true
            watermarkBtn.showRedDot(isShow: false)
        }
        
        var editType = type
        if watermarkModel.baseID == .ID14 && type == .quickEdit {
            editType = .edit
        }
        
        beginEditWatermark()
        return EditWatermarkVC.showEditVC(editType: editType, model: watermarkModel, wmView: wmView) { [weak self] resultModel, isModify, wmView in
            guard let self = self else { return }
            WatermarkManager.shared.saveWatermarkModel(resultModel)
            
            currentWatermarkView = wmView
            watermarkContentView.addSubview(wmView)
            currentWatermarkView?.delegate = self
            currentWatermarkView?.updateUI()
            wmView.isPreviewMode = false
            wmView.isCover = false
            wmView.isEditPage = false
            wmView.addGesture()
            photoRatio = photoRatio
            endEditWatermark()
            checkLogoOrShare()
//            self?.currentWatermarkView?.cachAnimationViewToCover(async: true)
        }
    }
    
}
