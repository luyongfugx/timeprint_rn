//
//  EditWatermarkVC+WatermarkList.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/4/6.
//

extension EditWatermarkVC: WatermarkListViewDelegate {
    
    func buildWatermarkListView() {
        if wmListView.superview == nil {
            wmListView.delegate = self
            watermarkListContentView.addSubview(wmListView)
            wmListView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            // 后台加载水印列表封面
            WatermarkPreloader.shared.preload()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // delay
            self.wmListView.flashScrollIndicators()
        }
    }
    
    func chooseWatermark(model: BaseWatermarkModel) {
        
        // logo迁移（非logo url默认配置的）
        if let lastSelectModel = watermarkModel {
            if let logoItem = lastSelectModel.logoItem(), logoItem.isOpen == true, logoItem.extraLogo.selectLogoPath != nil, logoItem.extraLogo.logoUrl == nil {
                if !isNotEmpty(model.logoItem()?.extraLogo.selectLogoPath) && (model.logoItem()?.extraLogo.logoUrl == nil) {
                    if let destinationIndex = model.items?.firstIndex(where: { $0.idType == .logo }) {
                        model.items?[destinationIndex] = logoItem.deepCopy()
                    } else {
                        model.items?.append(logoItem.deepCopy())
                    }
                    WatermarkManager.shared.saveWatermarkModel(model)
                }
            }
        }
        
        watermarkModel = model
        reChooseWatermark()
    }
    
    func clickEdit() {
        clickEditStamp()
    }
}
