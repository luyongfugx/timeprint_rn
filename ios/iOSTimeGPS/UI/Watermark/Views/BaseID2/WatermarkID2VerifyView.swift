//
//  WatermarkID2VerifyView.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/20.
//

import UIKit

class GPWatermarkPhotoCodeView: GPContentView {
        
    var checkImageView: UIImageView = {
        let imgV = UIImageView(frame: .init(x: 10, y: 0, width: 12, height: 14))
        imgV.contentMode = .scaleAspectFit
        imgV.image = UIImage(named: "id2_verify")
        return imgV
    }()
    
    var photoCodeLabel: GPQStickerLabel = {
        return GPQStickerLabel.init(text: "k_verified_by_tp".localized(), textColor: UIColor.white.withAlphaComponent(0.6), textFont: UIFont.robotoCondensedRegular(12), numberLines: 1)
    }()
    
    override init(frame: CGRect) {
        super.init(frame: CGRect(x: 0, y: 0, width: GPApp.screenWidth, height: 32))
        buildUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        LogDebug("deinit - Timeprint WatermarkPhotoCodeView")
    }
    
    override func buildUI() {
                
        addSubview(checkImageView)
        checkImageView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.width.equalTo(12)
            make.height.equalTo(14)
            make.centerY.equalToSuperview()
        }
        
        addSubview(photoCodeLabel)
        photoCodeLabel.snp.makeConstraints { make in
            make.left.equalTo(checkImageView.snp.right).offset(4)
            make.centerY.equalToSuperview()
        }
        
    }
    
    func reloadData(photoCode: String?) {
        let verifyTimeStr = "k_verified_by_tp".localized()
        let decibelSize = verifyTimeStr.size(WithFont: UIFont.robotoCondensedRegular(12), ConstrainedToWidth: GPApp.screenWidth - 100)
        self.height = GPWatermarkPhotoCodeView.getViewHeight(canShowCode: false)
        self.width = decibelSize.width + 26 + 2
    }
    
    func generateHighlightText(hightlightText: String, originalText: String) -> NSMutableAttributedString {
        let attri_string = NSMutableAttributedString.init(string: originalText)
        if let range = attri_string.string.range(of: hightlightText), let searchNSRange = attri_string.string.nsRange(from: range) {
            let font = UIFont.robotoCondensedBold(12)
            attri_string.addAttribute(NSAttributedString.Key.font, value: font, range: searchNSRange)
        }
        return attri_string
    }
    
    static func getViewHeight(canShowCode: Bool) -> CGFloat {
        return canShowCode ? 36 : 32
    }
    
}
