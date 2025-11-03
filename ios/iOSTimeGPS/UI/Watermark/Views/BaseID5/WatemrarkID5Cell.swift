//
//  WatemrarkID5Cell.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/26.
//

import UIKit

class WatemrarkID5Cell: GPTableviewCell {
    
    let placeHolder = " "
    // var redBlock: UIView = {
    //     //把红色点改成跟横线一样的黄色，避免侵权问题
    //     let view = UIView(backgroundColor: UIColor.fromHex("#FFEE5B", alpha: 1.0))
    //     view.alpha = 0.9
    //     return view
    // }()
     //改成图片
    let iconSize = 20;
     var redBlock: UIImageView = {
         let originalImage = UIImage(named: "phone") // Using an SF Symbol for demonstration
         let templateImage = originalImage?.withRenderingMode(.alwaysTemplate)
         let imageView = UIImageView(image: templateImage)
         imageView.contentMode = .scaleAspectFit
         imageView.tintColor = UIColor.fromHex("#FFEE5B")
        return imageView
    }()

    var contentLabel: UILabel = {
        return WatemrarkID5Cell.buildContentLabel()
    }()
    
    var defaultFontSize: CGFloat = 0
    var waterMarkItem: WatermarkItem?
    deinit {
        // XHLogDebug("[43号水印调试] - deinit - ID43WatermarkItemCell")
    }
    
    override func buildUI(){
        super.buildUI()
        backgroundColor = UIColor.clear
        contentView.backgroundColor = UIColor.clear
        contentView.addSubview(redBlock)
        contentView.addSubview(contentLabel)
    }
    
    func configModel(text: String, textColor: UIColor,item:WatermarkItem?) {
        contentLabel.text = text
        contentLabel.textColor = textColor
        waterMarkItem = item
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
            redBlock.image = image
        } else {
            redBlock.image = UIImage(named: "note")?.withRenderingMode(.alwaysTemplate)
        }
        redBlock.tintColor = textColor
        redBlock.frame = CGRect(x: 0, y: 2, width: iconSize, height: iconSize)
   
    }
    
    //MARK: -计算布局
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //redBlock.frame = CGRect(x: 0, y: 7, width: 4, height: 8)
        
        let contentHeightNew = contentView.height - 6
        let maxWidth = contentView.width - 32
        let iconY = Int((Int(contentHeightNew)-iconSize)/2)
        redBlock.frame = CGRect(x: 0, y: iconY, width: iconSize, height: iconSize)
        
        contentLabel.frame = CGRect.init(x: 25, y: 3, width: maxWidth, height: contentHeightNew)
    }
}

extension WatemrarkID5Cell {
    
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
        let currentMaxW = maxWidth - 32
        let sizeNew = text.getStringSizeByLabel(WithFont: UIFont.robotoCondensedRegular(14), ConstrainedToWidth: currentMaxW)
        return sizeNew.height + 8
    }
}
