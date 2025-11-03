//
//  WatermarkID16BottomCell.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2025/6/24.
//

//
//  WatermarkID1BottomCell.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/29.
//

import Foundation
import UIKit

class WatermarkID16BottomCell: GPTableviewCell {
    
    var contentLabel: GPQStickerLabel = {
        let label = GPQStickerLabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 14)
        label.textColor = .white
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()
    var circularCharacterView = CircularCharacterView()
    let iconSize = 20;
    var iconView: UIImageView = {
         let originalImage = UIImage(named: "phone") // Using an SF Symbol for demonstration
         let templateImage = originalImage?.withRenderingMode(.alwaysTemplate)
         let imageView = UIImageView(image: templateImage)
       // imageView.frame
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
        circularCharacterView.backgroundColor = .clear
        contentView.addSubview(circularCharacterView)
        contentView.addSubview(contentLabel)
        contentLabel.setLabShadow()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.bounds == .zero {
            return
        }
        let iconY = Int((Int(contentView.bounds.height)-iconSize)/2)
        iconView.frame = CGRect(x: 0, y: iconY, width: iconSize, height: iconSize)
        if(itemModel?.idType == .phoneNumber1 || itemModel?.idType == .phoneNumber2){
            circularCharacterView.frame = CGRect.init(x: 25, y: 0, width: contentView.bounds.width, height: contentView.bounds.height)
            circularCharacterView.isHidden = false
            contentLabel.isHidden = true
        }
        
        else {
            contentLabel.frame = CGRect.init(x: 25, y: 0, width: contentView.bounds.width+25, height: contentView.bounds.height)
            circularCharacterView.isHidden = true
            contentLabel.isHidden = false
        }
       
    }
//    override func layoutSubviews() {
//        super.layoutSubviews()
//        print("contentLabel contentView.bounds \(contentView.bounds)")
//        let contentHeightNew = contentView.height - 6
//        let maxWidth = contentView.width - 32
//        let iconY = Int((Int(contentHeightNew)-iconSize)/2)
//        //time 往下一点
////        if(itemModel?.idType == .time){
////            iconY = iconY+3
////        }
//        iconView.frame = CGRect(x: 0, y: iconY, width: iconSize, height: iconSize)
//        contentLabel.frame = CGRect.init(x: 25, y: 3, width: maxWidth, height: contentHeightNew)
//    }
    
    func configModel(text: String, textColor: UIColor, isBold: Bool,item:WatermarkItem?,templateColor: UIColor) {
        itemModel = item
        let textFont: UIFont = isBold ? UIFont.boldSystemFont(ofSize: 16) : UIFont.systemFont(ofSize: 14)
        contentLabel.font = textFont
        
        let attri_string = NSMutableAttributedString(string: text)
        let shadow = NSShadow.init()
        shadow.shadowColor = UIColor.fromHex("#000000", alpha: 0.4)
        shadow.shadowOffset = CGSize(width: 0.4, height: 0.5)//设置阴影大小
        shadow.shadowBlurRadius = 2
        attri_string.addAttribute(NSAttributedString.Key.shadow, value: shadow, range: NSMakeRange(0, attri_string.length))
        contentLabel.attributedText = attri_string
        
        contentLabel.textColor = textColor
        circularCharacterView.setText(text)
        circularCharacterView.setTextColor(textColor)
        circularCharacterView.setCharacterBackgroundColor(templateColor)
        circularCharacterView.setTextSize(sp: 12)
        
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
            case .phoneNumber1: iconName = "phone"
            case .phoneNumber2: iconName = "phone"
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

extension WatermarkID16BottomCell {
    //MARK: -计算cell高度
    class func getCellHeight(text: String, maxWidth: CGFloat, isBold: Bool,item:WatermarkItem?) -> (CGSize, CGFloat) {
        if text.isEmpty {
            return (CGSize.zero, 0)
        }
        let textFont: UIFont = isBold ? UIFont.boldSystemFont(ofSize: 16) : UIFont.systemFont(ofSize: 14)
        var contentSize = text.getStringSizeByLabel(WithFont: textFont, ConstrainedToWidth: maxWidth-12+20)

        if(item?.idType == .phoneNumber1 || item?.idType == .phoneNumber2){
            let circularCharacterView = CircularCharacterView()
            circularCharacterView.setText(text)
            circularCharacterView.setTextSize(sp: 12)
            contentSize =   CGSize(width: circularCharacterView.calculateDesiredWidth()+20,  height: circularCharacterView.calculateDesiredHeight())
        }
    
        let cell_h: CGFloat = 4.0 + contentSize.height + 4.0
        return (contentSize, cell_h)
    }
    
//    class func getCellHeight(text: String?, maxWidth: CGFloat, isBold: Bool) -> (CGSize, CGFloat) {
//        guard let text = text else { return (CGSize.zero, 0)}
//        let currentMaxW = maxWidth - 32
//        let textFont: UIFont = isBold ? UIFont.boldSystemFont(ofSize: 16) : UIFont.systemFont(ofSize: 14)
//        let sizeNew = text.getStringSizeByLabel(WithFont: textFont, ConstrainedToWidth: currentMaxW)
//        //return sizeNew.height + 8
//        return (sizeNew,sizeNew.height + 8)
//    }
}
