//
//  WatermarkTopLineCell.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/19.
//

import Foundation
import UIKit

class WatermarkTopLineCell: GPTableviewCell {
    
    
    
    var contentLabel: GPQStickerLabel = {
        let label = GPQStickerLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.robotoCondensedRegular(14)
        label.textColor = .white
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        label.adjustsFontSizeToFitWidth = true
        return label
    }()
    
    var itemModel: WatermarkItem?
    
    override func buildUI() {
        super.buildUI()
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        
        contentView.addSubview(contentLabel)
        contentLabel.setLabShadow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.bounds == .zero {
            return
        }
        contentLabel.frame = contentView.bounds
    }
    
    func configModel(text: String, textColor: UIColor, needBold: Bool = false) {
        
        let attri_string = NSMutableAttributedString(string: text)
        let shadow = NSShadow.init()
        shadow.shadowColor = UIColor.fromHex("#000000", alpha: 0.4)
        shadow.shadowOffset = CGSize(width: 0.4, height: 0.5)//设置阴影大小
        shadow.shadowBlurRadius = 2
        attri_string.addAttribute(NSAttributedString.Key.shadow, value: shadow, range: NSMakeRange(0, attri_string.length))
        contentLabel.attributedText = attri_string
        contentLabel.textColor = textColor
        contentLabel.font = needBold ? UIFont.robotoCondensedBold(14) : UIFont.robotoCondensedRegular(14)
    }
    
}

extension WatermarkTopLineCell {
    //MARK: -计算cell高度
    class func getCellHeight(text: String, maxWidth: CGFloat) -> (CGSize, CGFloat) {
        if text.isEmpty {
            return (CGSize.zero, 0)
        }
        let textFont: UIFont = UIFont.robotoCondensedRegular(14)
        let contentSize = text.getStringSizeByLabel(WithFont: textFont, ConstrainedToWidth: maxWidth-12)
        let cell_h: CGFloat = 4.0 + contentSize.height + 4.0
        return (contentSize, cell_h)
    }
}
