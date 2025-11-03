//
//  WatermarkId12Cell.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2025/2/26.
//

import Foundation

import UIKit

class WatermarkID12Cell: GPTableviewCell {
    
    let placeHolder = " "
    var redBlock: UIView = {
        let view = UIView(backgroundColor: .red)
        view.alpha = 0.9
        return view
    }()
    var contentLabel: UILabel = {
        return WatermarkID12Cell.buildContentLabel()
    }()
    
    var defaultFontSize: CGFloat = 0
    
    deinit {
        // XHLogDebug("[43号水印调试] - deinit - ID43WatermarkItemCell")
    }
    
    override func buildUI(){
        super.buildUI()
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        //contentView.addSubview(redBlock)
        contentView.addSubview(contentLabel)
    }
    
    func configModel(text: String, textColor: UIColor) {
        contentLabel.text = text
        contentLabel.textColor = textColor
        redBlock.frame = CGRect(x: 0, y: 7, width: 4, height: 8)
    }
    
    //MARK: -计算布局
    override func layoutSubviews() {
        super.layoutSubviews()
        
        redBlock.frame = CGRect(x: 0, y: 7, width: 4, height: 8)
        let contentHeightNew = contentView.height - 4
        let maxWidth = contentView.width - 16
//        print("contentView.width \(contentView.width) maxWidth:\(maxWidth)")
        contentLabel.frame = CGRect.init(x: 11, y: 2, width: maxWidth, height: contentHeightNew)
    }
}

extension WatermarkID12Cell {
    
    // 创建contentLabel
    private static func buildContentLabel() -> UILabel {
        
        let label = UILabel()
        label.lineBreakMode = .byCharWrapping
        label.font = UIFont.robotoCondensedRegular(14)
        label.numberOfLines = 0
        return label
    }
    
    // MARK: - 计算cell高度
    class func getCellHeight(text: String?, maxWidth: CGFloat) -> CGFloat{
        guard let text = text else { return 0 }
        let currentMaxW = maxWidth - 21
        let sizeNew = text.getStringSizeByLabel(WithFont: UIFont.robotoCondensedRegular(14), ConstrainedToWidth: currentMaxW)
        return sizeNew.height + 4
    }
}
