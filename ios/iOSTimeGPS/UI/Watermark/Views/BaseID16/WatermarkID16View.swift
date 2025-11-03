//
//  WatermarkID16View.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2025/6/24.
//

import Foundation


import Foundation
import UIKit

class WatermarkID16View: BaseWatermark {
    var themeColor: UIColor {
        return UIColor.fromHex("#FFC233")
    }
        
    lazy var customTextLabel: GPQStickerLabel = {
        return GPQStickerLabel.init(text: "k_title".localized(), textColor: themeColor, textFont: .robotoCondensedRegular(17), textAlignment: .left, backgroundColor: .clear, cornerRadius: 2)
    }()
    

    // 左侧主题色条
    lazy var verArrow: UIView = {
        return .init(backgroundColor: themeColor, cornerRadius: 0.5)
    }()
    
    //animation_View的宽度
    var currentAnimationViewWidth: CGFloat {
        let defaultWidth = GPApp.screenWidth - 100
        return sizeScale*defaultWidth
    }
        
    var topTableView: WatermarkID16TopLineTableView = {
        let tableView = WatermarkID16TopLineTableView(frame: .zero)
        return tableView
    }()
    
    var bottomTableView: WatermarkID16BottomView = {
        let tableView = WatermarkID16BottomView(frame: .zero)
        return tableView
    }()
    
    var is12Hours = false
    var isTimeZone = false
    var showWeak = false
    var customTextWidth: CGFloat = 0
    var customTextHeight: CGFloat = 0
    var topTableWidth: CGFloat = 0
    var topTableHeight: CGFloat = 0
    var bottomTableWidth: CGFloat = 0
    var bottomTableHeight: CGFloat = 0
    
    override func buildViews() {
        super.buildViews()
        
        animationView.addSubview(customTextLabel)
        customTextLabel.setLabShadow()
        
        animationView.addSubview(verArrow)
        
        // 顶部tableview
        animationView.addSubview(topTableView)

        // 底部tableview
        animationView.addSubview(bottomTableView)
        
    }
    
    override func updateUI() {
        super.updateUI()
                
        // 时间
        reloadTimes()
                        
        let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
//        watermarkThemeColor = UIColor.fromHex("#FFC233")
        verArrow.backgroundColor = watermarkThemeColor
        let watermarkTextColor = watermarkModel?.textColor ?? .white
        //watermarkTextColor = UIColor.fromHex("#FFFFFF")
        // 自定义标题
        if let customItem = watermarkModel?.items?.first(where: { $0.idType == .watermarkTitle }) {
            setupCustomText(customItem,templateColor: watermarkThemeColor)
        }

        bottomTableView.configDatas(items: watermarkModel?.allBottomOpenItem ?? [], maxWidth: GPApp.screenWidth - 100, templateColor: watermarkThemeColor,textColor:watermarkTextColor)
        bottomTableWidth = bottomTableView.width
        bottomTableHeight = bottomTableView.height
        
        topTableView.configDatas(baseID: watermarkModel?.baseID, items: watermarkModel?.allTopOpenItem ?? [], canShowLine: false, maxWidth: GPApp.screenWidth - 100, textColor: watermarkTextColor, themeColor: watermarkThemeColor)
        
  
        topTableWidth = topTableView.width
        topTableHeight = topTableView.height
        
        verArrow.backgroundColor = watermarkThemeColor
        
        for item in scaleContentView.subviews {
            if let label = item as? UILabel {
                label.textColor = watermarkTextColor
            }
        }
        
        for item in animationView.subviews {
            if let label = item as? UILabel {
                label.textColor = watermarkTextColor
            }
        }
        //给title 增加一个圆角矩形背景
       // customTextLabel.textColor = watermarkThemeColor

  
        setNeedsLayout()
        
    }
    
    // 设置自定义文字
    func setupCustomText(_ item: WatermarkItem, templateColor: UIColor) {
        //标题字体改成20，区别抄袭
        let font = UIFont.robotoCondensedBold(20)
        customTextLabel.font = font
        let titleLabelWidth = (currentAnimationViewWidth-20)
        
        let customText = item.content ?? ""
        
        let isOpen = item.isOpen ?? false
        if isOpen && customText.count > 0 {
            let customSize = customText.getStringSizeByLabel(WithFont: font, ConstrainedToWidth: titleLabelWidth)
            let text_h = customSize.height
            let label_h: CGFloat = 4.0 + text_h + 4.0
            customTextWidth = customSize.width+20
            customTextHeight = label_h
            customTextLabel.text = customText
            customTextLabel.isHidden = false
            customTextLabel.backgroundColor = templateColor.withAlphaComponent(0.8)
            // customTextLabel.backgroundColor = .blue
            customTextLabel.layer.cornerRadius = 5
            customTextLabel.textAlignment = .center
            customTextLabel.layer.masksToBounds = true
        } else {
            customTextLabel.text = ""
            customTextLabel.isHidden = true
            customTextWidth = 0
            customTextHeight = 0
        }
    }
    
    override func reloadTimes() {
        super.reloadTimes()
        // 刷新时间条目
        self.topTableView.tableView?.reloadData()
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        var content_y: CGFloat = 12
        var viewTotalH: CGFloat = 12

        resetLogoFrame()
        
        // 计算跟随水印logo位置
        if logoHeight > 0 && logoImageView.image != nil {
            content_y = (logoImageView.bottom) + 4
            viewTotalH = content_y
        }
        var contentCurrentMaxW: CGFloat = 168
        let contentLeftSpace: CGFloat = 24

        self.customTextLabel.frame = CGRect(x: 10, y: viewTotalH, width: customTextWidth, height: customTextHeight)
        viewTotalH += (customTextHeight > 0) ? customTextHeight+1 : 0
        
        contentCurrentMaxW = max(contentCurrentMaxW, customTextWidth + 10)

        let line_top = viewTotalH + ((topTableHeight > 0) ? 2 : 0) + 2
        
        topTableView.frame = CGRect(x: 12, y: viewTotalH , width: topTableWidth, height: topTableHeight)
        if topTableHeight > 0 {
            viewTotalH = (topTableHeight + viewTotalH - 6)
            contentCurrentMaxW = max(contentCurrentMaxW, 12 + topTableWidth)
        }
        
        var line_h = viewTotalH + bottomTableHeight - line_top - ((bottomTableHeight == 0) ? 9 : 0) + 2
        if topTableHeight == 0 && bottomTableHeight == 0 {
            line_h = 0.0
        }
        
        // 背景视图宽度
        var animationViewW = contentCurrentMaxW + contentLeftSpace

        bottomTableView.frame = CGRect(x: 22, y: viewTotalH + 2, width: bottomTableWidth, height: bottomTableHeight)
        if bottomTableHeight > 0 {
            viewTotalH = bottomTableHeight + viewTotalH + 8
            animationViewW = max(animationViewW, 22 + bottomTableWidth)
        }
        
        // 竖直线条
        verArrow.frame = CGRect(x: 12, y: line_top, width: 2, height: line_h)
        
        viewTotalH = verArrow.bottom + 8
        
        animationView.frame = .init(x: animationView.left, y: animationView.bottom - viewTotalH, width: animationViewW, height: viewTotalH)
        if sizeScale != 1 {
            makeChangSizeUI(animationView_w: animationViewW, content_y: viewTotalH)
        } else {
            scaleContentView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        resetFrame()
    }
    
}



