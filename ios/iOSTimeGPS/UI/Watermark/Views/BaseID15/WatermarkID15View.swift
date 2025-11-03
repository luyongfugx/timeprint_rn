//
//  WatermarkID15View.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/4/27.
//

import Foundation
import UIKit

class WatermarkID15View: BaseWatermark {

    let topClockView = ClockInView(frame: .zero)
        
    var themeColor: UIColor {
        return UIColor.fromHex("#37aaec")
    }
    
    var gradientColors: [UIColor] {
        return [UIColor.UIColorFromRGBA(55, g: 170, b: 212, a: 0.80), UIColor.UIColorFromRGBA(55, g: 170, b: 242, a: 0.90)]
    }
        
    //animation_View的宽度
    var currentAnimationViewWidth: CGFloat {
        let defaultWidth = GPApp.screenWidth - 100
        return sizeScale*defaultWidth
    }
        
    var topTableView: WatermarkTopLineTableView = {
        let tableView = WatermarkTopLineTableView(frame: .zero)
        return tableView
    }()
    
    var bottomTableView: WatermarkID1BottomView = {
        let tableView = WatermarkID1BottomView(frame: .zero)
        return tableView
    }()
    
    var verifyView: GPWatermarkPhotoCodeView = {
        return GPWatermarkPhotoCodeView(frame: .zero)
    }()
    
    var is12Hours = false
    var isTimeZone = false
    var showWeak = false
    var topTableWidth: CGFloat = 0
    var topTableHeight: CGFloat = 0
    var bottomTableWidth: CGFloat = 0
    var bottomTableHeight: CGFloat = 0
    var lastTimeText = ""
    
    override func buildViews() {
        super.buildViews()
        
        // 顶部tableview
        animationView.addSubview(topClockView)
        
        // 顶部tableview
        animationView.addSubview(topTableView)

        // 底部tableview
        animationView.addSubview(bottomTableView)
        
        animationView.addSubview(verifyView)
        
        outLogoPadding = ID2WatermarkLeftSpace
    }
    
    override func updateUI() {
        super.updateUI()
                
        // 强制刷新时间
        lastTimeText = "-1"
        reloadTimes()
                        
        let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
        let watermarkTextColor = watermarkModel?.textColor ?? .white
        
        bottomTableView.configDatas(items: watermarkModel?.allBottomOpenItem ?? [], maxWidth: GPApp.screenWidth - 100 - ID2WatermarkLeftSpace, templateColor: watermarkTextColor)
        bottomTableWidth = bottomTableView.width
        bottomTableHeight = bottomTableView.height
        
        topTableView.configDatas(baseID: watermarkModel?.baseID, items: watermarkModel?.allTopOpenItem ?? [], maxWidth: GPApp.screenWidth - 100 - ID2WatermarkLeftSpace, textColor: watermarkTextColor, themeColor: watermarkThemeColor)
        topTableWidth = topTableView.width
        topTableHeight = topTableView.height
        
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
        
        // 验证保障提示
        verifyView.reloadData(photoCode: nil)
        
        forceRefresh()
    }
    
    override func reloadTimes() {
        super.reloadTimes()
        // 获取时间
        guard let timeItem = watermarkModel?.items?.first(where: { $0.idType == .time }) else { return }
        let timeItemModel = timeItem.extraTime
        
        var titleText: String?
        if let titleItem = watermarkModel?.items?.first(where: { $0.idType == .watermarkTitle }), let content = titleItem.content, content.count > 0, titleItem.isOpen == true {
            titleText = content
        }
        is12Hours = timeItemModel.is12Hour ?? false
        isTimeZone = timeItemModel.showTimeZone ?? false
        showWeak = timeItemModel.showWeak ?? true
        
        let dateInfo = GPDateFormat.dateCommpent(with: TimeManager.shared.getRealTime(), is12Hours: is12Hours, dateStyle: timeItemModel.dateStyleEnum)
        let timeText = "\(dateInfo.hh):\(dateInfo.mm)"
        let ampmText = is12Hours ? dateInfo.ampm : ""
        let timeZoneText = isTimeZone ? TimeManager.shared.getGlobalTimeZone().abbreviation() : ""
        
        // 内嵌logo
        let logo: UIImage? = logoImageView.image
        logoImageView.isHidden = true
        let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
        
        if lastTimeText != timeText {
            topClockView.updateData(bgColor: watermarkThemeColor, clockTitle: titleText, timeStr: timeText, amStr: ampmText, timezoneStr: timeZoneText, logo: logo)
            forceRefresh()
        }
        lastTimeText = timeText
    }
    
    override func didUpdateLogo() {
        super.didUpdateLogo()
        // 强制刷新时间
        lastTimeText = "-2"
        reloadTimes()
    }
        
    override func layoutSubviews() {
        super.layoutSubviews()
                
        var content_y: CGFloat = ID2WatermarkLeftSpace
        var viewTotalH: CGFloat = ID2WatermarkLeftSpace

        resetLogoFrame()
        
        var contentCurrentMaxW: CGFloat = 168

        topClockView.left = ID2WatermarkLeftSpace
        topClockView.top = content_y
        contentCurrentMaxW = max(topClockView.right, contentCurrentMaxW)
        viewTotalH = topClockView.bottom + 8

        topTableView.frame = CGRect(x: ID2WatermarkLeftSpace, y: viewTotalH - 6, width: topTableWidth, height: topTableHeight)
        if topTableHeight > 0 {
            viewTotalH = (topTableHeight + viewTotalH - 6)
            contentCurrentMaxW = max(contentCurrentMaxW, ID2WatermarkLeftSpace + topTableWidth)
        }
        
        bottomTableView.frame = CGRect(x: ID2WatermarkLeftSpace, y: viewTotalH + 2, width: bottomTableWidth, height: bottomTableHeight)
        if bottomTableHeight > 0 {
            viewTotalH = bottomTableHeight + viewTotalH + 10
            contentCurrentMaxW = max(contentCurrentMaxW, ID2WatermarkLeftSpace + bottomTableWidth)
        }
        
        // 验证保障
        verifyView.frame = CGRect(x: ID2WatermarkLeftSpace, y: viewTotalH - 10, width: verifyView.width, height: verifyView.height)
        contentCurrentMaxW = max(contentCurrentMaxW, ID2WatermarkLeftSpace + verifyView.width)

        viewTotalH = verifyView.bottom
       // LogDebug("currentWatermarkView id12: \(viewTotalH) \(animationView.bottom)  \(animationView.bottom - viewTotalH)")
        animationView.frame = .init(x: animationView.left, y: animationView.bottom - viewTotalH, width: contentCurrentMaxW, height: viewTotalH)
        if sizeScale != 1 {
            makeChangSizeUI(animationView_w: contentCurrentMaxW, content_y: viewTotalH)
        } else {
            scaleContentView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        resetFrame()
    }
    
    func timeFont(for isInline: Bool) -> UIFont {
        .bebasDaka(isInline ? 32 : 27)
    }

    func ampmTimeZoneFont(for isInline: Bool) -> UIFont {
        .robotoCondensedMedium(isInline ? 10 : 9)
    }

    func isInlineStyle() -> Bool {
        false
    }
}


