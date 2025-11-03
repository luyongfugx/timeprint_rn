//
//  WatermarkID2View.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/13.
//

import Foundation
import UIKit

let ID2WatermarkLeftSpace: CGFloat = 6

class WatermarkID2View: BaseWatermark {

    lazy var titleLab: UILabel = {
        return UILabel.init(text: "k_attendance_record".localized(), textColor: UIColor.white, textFont: .robotoCondensedBold(17), textAlignment: .center, backgroundColor: .clear)
    }()
    
    lazy var titleBgView: UIView = {
        let v = UIView(backgroundColor: .clear)
        v.clipsToBounds = true
        v.addSubview(titleLab)
        return v
    }()
    
    // 顶部时间
    let timeLB: UILabel = .init(
        text: "--:--",
        textColor: .black,
        textFont: .bigShouldersMedium(50),
        textAlignment: .center
    )
    // AM PM
    let ampmLabel: UILabel = .init(
        text: "--",
        textColor: .black,
        textFont: .robotoCondensedMedium(9),
        textAlignment: .left
    )
    // 时区
    let timeZoneLabel: UILabel = .init(
        text: "--",
        textColor: .black,
        textFont: .robotoCondensedMedium(9),
        textAlignment: .left
    )
    
    lazy var timeBgView: UIView = {
        let v = UIView(backgroundColor: .clear)
        v.clipsToBounds = true
        v.addSubview(timeLB)
        v.addSubview(ampmLabel)
        v.addSubview(timeZoneLabel)
        return v
    }()
    
//    // 底纹图
//    lazy var topBgImageView: UIImageView = {
//        let imgV = UIImageView(imageName: "cover_2_bg", cornerRadius: 0, backgroundColor: .clear, contentMode: .center, clipsToBounds: true)
//        return imgV
//    }()
    
    // 顶部view
    lazy var topView: UIView = {
        let topV = UIView(backgroundColor: UIColor.white, cornerRadius: 6)
//        topV.addSubview(topBgImageView)
        topV.addSubview(titleBgView)
        topV.addSubview(timeBgView)
        return topV
    }()
    
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
    
    override func buildViews() {
        super.buildViews()
        
        // 顶部tableview
        animationView.addSubview(topView)
        
        // 顶部tableview
        animationView.addSubview(topTableView)

        // 底部tableview
        animationView.addSubview(bottomTableView)
        
        animationView.addSubview(verifyView)
        
        outLogoPadding = ID2WatermarkLeftSpace
    }
    
    override func updateUI() {
        super.updateUI()
                
        // 时间
        reloadTimes()
        
        // 标题
        if let titleItem = watermarkModel?.items?.first(where: { $0.idType == .watermarkTitle }), let content = titleItem.content, content.count > 0, titleItem.isOpen == true {
            titleLab.text = content
        } else {
            titleLab.text = nil
        }
                
        var watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
        var watermarkTextColor = watermarkModel?.textColor ?? .white
//        watermarkThemeColor = UIColor.fromHex("#00B046")
//        watermarkTextColor = UIColor.fromHex("#ffffff")
        
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
        //设置为
        timeLB.textGradient(colors: [watermarkThemeColor, watermarkThemeColor])
//        titleBgView.addGradientLayer(
//            colors: [watermarkThemeColor.cgColor, watermarkThemeColor.cgColor],
//            locations: [0, 1],
//            layerframe: titleBgView.bounds,
//            startPoint: CGPoint(x: 0.5, y: 0),
//            endPoint: CGPoint(x: 0.5, y: 1)
//        )
        setNeedsLayout()
        
    }
    
    override func reloadTimes() {
        super.reloadTimes()
        // 获取时间
        guard let timeItem = watermarkModel?.items?.first(where: { $0.idType == .time }) else { return }
        let timeItemModel = timeItem.extraTime
        
        is12Hours = timeItemModel.is12Hour ?? false
        isTimeZone = timeItemModel.showTimeZone ?? false
        showWeak = timeItemModel.showWeak ?? true
        
        let dateInfo = GPDateFormat.dateCommpent(with: TimeManager.shared.getRealTime(), is12Hours: is12Hours, dateStyle: timeItemModel.dateStyleEnum)
        timeLB.text = "\(dateInfo.hh):\(dateInfo.mm)"
        ampmLabel.text = dateInfo.ampm
        timeZoneLabel.text = TimeManager.shared.getGlobalTimeZone().abbreviation()
        
        ampmLabel.isHidden = !is12Hours
        timeZoneLabel.isHidden = !isTimeZone
        
        setTimeBInfo(timeText: timeLB.text ?? "", ampmText: ampmLabel.text ?? "", timeZoneText: timeZoneLabel.text ?? "", isInline: false)
        timeLB.sizeToFit()
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        var content_y: CGFloat = ID2WatermarkLeftSpace
        var viewTotalH: CGFloat = ID2WatermarkLeftSpace

        resetLogoFrame()
        
        // 计算跟随水印logo位置
        if logoHeight > 0 && logoImageView.image != nil {
            content_y = (logoImageView.bottom) + 8
            viewTotalH = content_y
        }
        var contentCurrentMaxW: CGFloat = 168

        let miniPadding = 10.0
        let titleLabelSize =  titleLab.getOneLineSize()
        let timeLabelSize = timeLB.getOneLineSize()
        let ampmLabelSize = is12Hours ? ampmLabel.getOneLineSize() : .zero
        let timeZoneSize = isTimeZone ? timeZoneLabel.getOneLineSize() : .zero
        var timeBgWidth = timeLabelSize.width
        let timepadding = 6.0
        if is12Hours || isTimeZone {
            timeBgWidth = timeBgWidth + timepadding + max(ampmLabelSize.width, timeZoneSize.width)
        }
        var topWidth = max(titleLabelSize.width, timeBgWidth) + miniPadding*2
        if topWidth < 80 {
            topWidth = 80
        }
        let titleBgViewHeight = titleLabelSize.width == 0 ? 0 : (titleLabelSize.height + miniPadding*2)
        titleBgView.frame = .init(x: 0, y: 0, width: topWidth, height: titleBgViewHeight)
        titleLab.sizeToFit()
        titleLab.center = .init(x: titleBgView.width/2.0, y: titleBgView.height/2.0)
        
        timeLB.sizeToFit()
        timeLB.width = timeLabelSize.width + 4
        timeLB.frame.origin = .zero
        ampmLabel.sizeToFit()
        timeZoneLabel.sizeToFit()
        timeZoneLabel.width = timeZoneSize.width + 2
        ampmLabel.left = is12Hours ? (timeLB.right + timepadding) : 0
        ampmLabel.top = timeLB.top+5
        timeZoneLabel.left = isTimeZone ? (timeLB.right + timepadding) : 0
        timeZoneLabel.bottom = timeLB.bottom - 3
        timeBgView.width = max(timeLB.right, max(ampmLabel.right, timeZoneLabel.right))
        timeBgView.height = timeLB.height
        timeBgView.center = .init(x: titleBgView.width/2.0, y: titleBgView.height + timeBgView.height/2.0)
        
        topView.frame = .init(x: ID2WatermarkLeftSpace, y: content_y, width: topWidth, height: titleBgView.height + timeBgView.height)

        let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
        titleBgView.backgroundColor = watermarkThemeColor
        
        viewTotalH = (topView.bottom) + 8
//        topBgImageView.frame = CGRect(x: 0, y: titleBgView.bottom, width: topWidth, height: topView.height - titleBgView.bottom)
        
        contentCurrentMaxW = max(contentCurrentMaxW, topWidth + ID2WatermarkLeftSpace)

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
    
    func setTimeBInfo(timeText: String, ampmText: String, timeZoneText: String, isInline: Bool) {
        let timeFont = timeFont(for: isInline)
        let lineSpace: CGFloat = isInline ? 1 : 0.8

        // 时间
        timeLB.attributedText = NSAttributedString(
            string: timeText,
            attributes: [.kern: lineSpace, .font: timeFont]
        )
        // V3.0.20版本设计改字体了 , 字体稍微有些低 , 所以渐变到文字顶部的时候变成深色了, 原先第一个颜色为: #006CFF,找设计要了个浅色的: #0771FF
        //timeLB.textGradient(colors: [.fromHex("#00B046"), .fromHex("#008D38")])
       // timeLB.textGradient(colors: [self.themeColor, self.themeColor])
        // 上下午
        let ampmTimeZoneFont = ampmTimeZoneFont(for: isInline)
        ampmLabel.attributedText = NSAttributedString(
            string: ampmText,
            attributes: [.font: ampmTimeZoneFont]
        )
        // V3.0.20版本设计改字体了 , 字体稍微有些低 , 所以渐变到文字顶部的时候变成深色了, 原先第一个颜色为: #006CFF,找设计要了个浅色的: #0771FF
        ampmLabel.textGradient(colors: [.fromHex("#016AFA"), .fromHex("#013F94")])

        // 时区
        timeZoneLabel.attributedText = NSAttributedString(
            string: timeZoneText,
            attributes: [.font: ampmTimeZoneFont]
        )
        // V3.0.20版本设计改字体了 , 字体稍微有些低 , 所以渐变到文字顶部的时候变成深色了, 原先第一个颜色为: #006CFF,找设计要了个浅色的: #0771FF
        timeZoneLabel.textGradient(colors: [.fromHex("#023984"), .fromHex("#01132D")])
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


