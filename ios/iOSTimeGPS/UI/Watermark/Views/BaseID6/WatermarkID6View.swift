//
//  WatermarkID6View.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/28.
//

import Foundation
import UIKit

class WatermarkID6View: BaseWatermark{
 
    var tableView: WatermarkID6TableView = {
        WatermarkID6TableView()
    }()
    
    var tableWidth: CGFloat = 0
    var tableHeight: CGFloat = 0
    
    var themeColor: UIColor {
        return UIColor.fromHex("#642a95")
    }
    
    override func buildViews() {
        super.buildViews()
        animationView.addSubview(tableView)
        outLogoPadding = 6
    }
    
    override func updateUI() {
        super.updateUI()
        
        var watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
        let watermarkTextColor = watermarkModel?.textColor ?? .white
        //watermarkThemeColor = UIColor.fromHex("#0733d4")
        // 时间
        reloadTimes()
        
        tableView.configDatas(baseID: watermarkModel?.baseID, items: watermarkModel?.allTopOpenItem ?? [], titleItem: watermarkModel?.items?.first(where: { $0.idType == .watermarkTitle }), textColor: watermarkTextColor, themeColor: watermarkThemeColor, isCover: isCover)
        
        let table_h = WatermarkID6TableView.getTableHeight(baseID: watermarkModel?.baseID, items: tableView.items, titleText: tableView.titleItem?.content).table_h

        tableWidth = ID100WatermarkUILayoutParams().table_width
        tableHeight = table_h
                        
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
        
        setNeedsLayout()
        
    }
    
    override func reloadTimes() {
        super.reloadTimes()
        // 刷新时间条目
        self.tableView.reloadDatas()
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        resetLogoFrame()
        var startY = 0.0
        if logoHeight > 0 && logoImageView.image != nil {
            startY = logoHeight + 12
        }
        
        tableView.frame = CGRect(x: 0, y: startY, width: tableWidth, height: tableHeight)
        
        if animationView.bottom == 0 {
            animationView.bottom = self.viewFrameHeight
        }
        let animationView_w: CGFloat = tableWidth
        let animationView_h: CGFloat = startY + tableHeight
        animationView.frame = CGRect(x: animationView.left, y: animationView.bottom - animationView_h, width: animationView_w, height: animationView_h)
        
        if sizeScale != 1 {
            makeChangSizeUI(animationView_w: animationView_w, content_y: animationView_h)
        } else {
            scaleContentView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        resetFrame()
    }
}
