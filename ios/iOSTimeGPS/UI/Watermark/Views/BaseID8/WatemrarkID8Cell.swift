//
//  WatemrarkID8Cell.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/12/14.
//

import Foundation

import UIKit

class WatemrarkID8Cell: GPTableviewCell {
    
    let placeHolder = " "
    var redBlock: UIView = {
        let view = UIView(backgroundColor: .red)
        view.alpha = 0.9
        return view
    }()
    var contentLabel: UILabel = {
        return WatemrarkID8Cell.buildContentLabel()
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
        let contentHeightNew = contentView.height - 6
        let maxWidth = contentView.width - 21
//        print("contentView.width \(contentView.width) maxWidth:\(maxWidth)")
        contentLabel.frame = CGRect.init(x: 11, y: 3, width: maxWidth, height: contentHeightNew)
    }
}

extension WatemrarkID8Cell {
    
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
        return sizeNew.height + 6
    }
}
