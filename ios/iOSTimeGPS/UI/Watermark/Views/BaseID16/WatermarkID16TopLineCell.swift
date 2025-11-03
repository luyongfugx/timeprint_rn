//
//  WatermarkID16TopLineCell.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2025/6/24.
//



import Foundation
import UIKit

class WatermarkID16TopLineCell: GPTableviewCell {
    
    
    
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
    let iconSize = 20;
    
    var iconView: UIImageView = {
         let originalImage = UIImage(named: "phone") // Using an SF Symbol for demonstration
         let templateImage = originalImage?.withRenderingMode(.alwaysTemplate)
         let imageView = UIImageView(image: templateImage)
         imageView.contentMode = .scaleAspectFit
         imageView.tintColor = UIColor.fromHex("#FFEE5B")
        return imageView
    }()

    
    var itemModel: WatermarkItem?
    
    override func buildUI() {
        super.buildUI()
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        contentView.addSubview(iconView)
        contentView.addSubview(contentLabel)
        contentLabel.setLabShadow()
    }
    
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        
//        if self.bounds == .zero {
//            return
//        }
//        contentLabel.frame = contentView.bounds
//    }
    override func layoutSubviews() {
        super.layoutSubviews()
        let contentHeightNew = contentView.height - 6
        let maxWidth = contentView.width - 32
        var iconY = Int((Int(contentHeightNew)-iconSize)/2)
        //time 往下一点
        if(itemModel?.idType == .time){
            iconY = iconY+3
        }
        iconView.frame = CGRect(x: 0, y: iconY, width: iconSize, height: iconSize)
        // contentLabel.frame = contentView.bounds
        contentLabel.frame = CGRect.init(x: 25, y: 3, width: maxWidth, height: contentHeightNew)
    }
    
    func configModel(text: String, textColor: UIColor, needBold: Bool = false,item:WatermarkItem?) {
        itemModel = item
        let attri_string = NSMutableAttributedString(string: text)
        let shadow = NSShadow.init()
        shadow.shadowColor = UIColor.fromHex("#000000", alpha: 0.4)
        shadow.shadowOffset = CGSize(width: 0.4, height: 0.5)//设置阴影大小
        shadow.shadowBlurRadius = 2
        attri_string.addAttribute(NSAttributedString.Key.shadow, value: shadow, range: NSMakeRange(0, attri_string.length))
        contentLabel.attributedText = attri_string
        contentLabel.textColor = textColor
        contentLabel.font = needBold ? UIFont.robotoCondensedBold(14) : UIFont.robotoCondensedRegular(14)
        let iconName: String
        switch item?.idType {
            case .customItem: iconName = "note"
            case .logo: iconName = "people"
            case .time: iconName = "time"
            case .address: iconName = "clock_location_white"
            case .coordinate: iconName = "latlng"
            case .weather: iconName = "weather"
            case .altitude: iconName = "altitude"
            case .note: iconName = "note"
            default: iconName = "note"
        }
        
        if let image = UIImage(named: iconName)?.withRenderingMode(.alwaysTemplate) {
            iconView.image = image
        } else {
            iconView.image = UIImage(named: "note")?.withRenderingMode(.alwaysTemplate)
        }
        iconView.tintColor = textColor
    }
    
}

extension WatermarkID16TopLineCell {
    //MARK: -计算cell高度
//    class func getCellHeight(text: String, maxWidth: CGFloat) -> (CGSize, CGFloat) {
//        if text.isEmpty {
//            return (CGSize.zero, 0)
//        }
//        let textFont: UIFont = UIFont.robotoCondensedRegular(14)
//        let contentSize = text.getStringSizeByLabel(WithFont: textFont, ConstrainedToWidth: maxWidth-12)
//        let cell_h: CGFloat = 4.0 + contentSize.height + 4.0
//        return (contentSize, cell_h)
//    }
    class func getCellHeight(text: String?, maxWidth: CGFloat) -> (CGSize, CGFloat) {
        guard let text = text else { return (CGSize.zero, 0)}
        let currentMaxW = maxWidth - 32
        let sizeNew = text.getStringSizeByLabel(WithFont: UIFont.robotoCondensedRegular(14), ConstrainedToWidth: currentMaxW)
        //return sizeNew.height + 8
        return (sizeNew,sizeNew.height + 8)
    }
}

