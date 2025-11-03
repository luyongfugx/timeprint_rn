//
//  WatermarkID1View.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/17.
//

import Foundation
import UIKit

class WatermarkID1View: BaseWatermark {

    var yearLB: GPQStickerLabel = {
        return GPQStickerLabel.init(text: "2024", textColor: .white, textFont: UIFont.systemFont(ofSize: 14), numberLines: 0)
    }()
    
    var dateLB: GPQStickerLabel = {
        return GPQStickerLabel.init(text: "18/08/2024", textColor: .white, textFont: UIFont.systemFont(ofSize: 14), numberLines: 1)
    }()
    
    var timeLB: GPQStickerLabel = {
        return GPQStickerLabel.init(text: "sun", textColor: .white, textFont: .bigShouldersMedium(45), numberLines: 1)
    }()
    
    var ampmLabel: GPQStickerLabel = {
        return GPQStickerLabel.init(text: "AM", textColor: .white, textFont: .systemFont(ofSize: 14), textAlignment: .right, numberLines: 1)
    }()
    
    var timeZoneLabel: GPQStickerLabel = {
        return GPQStickerLabel.init(text: "GMT+8", textColor: .white, textFont: .systemFont(ofSize: 14), textAlignment: .right, numberLines: 1)
    }()
    
    var locationLB: GPQStickerLabel = {
        return GPQStickerLabel.init(text: "", textColor: .white, textFont: .systemFont(ofSize: 14), textAlignment: .left, numberLines: 0, lineBreakMode: .byWordWrapping)
    }()
    
    //animation_View的宽度
    var currentAnimationViewWidth: CGFloat {
        let defaultWidth = GPApp.screenWidth - 100
        return sizeScale*defaultWidth
    }
    
    var bottomTableView: WatermarkID1BottomView = {
        let tableView = WatermarkID1BottomView(frame: .zero)
        return tableView
    }()
    
    var is12Hours = false
    var isTimeZone = false
    var showWeak = false
    var lastTimeText = ""
    
    override func buildViews() {
        super.buildViews()
        // 时间
        timeLB.frame = CGRect(x: 10, y: 4, width: 82, height: 38)
        timeLB.strokeWidth = 1
        timeLB.isStroke = true
        timeLB.strokeColor = UIColor.black.withAlphaComponent(0.5)
        animationView.addSubview(timeLB)
        timeLB.setLabShadow()
        if GPCheetManager.isCheetMode {
            timeLB.font = UIFont.boldSystemFont(ofSize: 50)
        }

        animationView.addSubview(yearLB)
        yearLB.setLabShadow()
        
        animationView.addSubview(dateLB)
        dateLB.setLabShadow()
        
        // 上下午
        animationView.addSubview(ampmLabel)
        ampmLabel.setLabShadow()
        
        // 时区
        animationView.addSubview(timeZoneLabel)
        timeZoneLabel.setLabShadow()
        
//        animationView.addSubview(lineView)
        
        // 地址
        animationView.addSubview(locationLB)
        locationLB.setLabShadow()
         
        // 底部tableview
        animationView.addSubview(bottomTableView)
        
    }
    
    override func updateUI() {
        super.updateUI()
                
        // 时间
        reloadTimes()
        
        if let addressItem = watermarkModel?.items?.first(where: { $0.idType == .address }), addressItem.isOpen == true {
            locationLB.isHidden = false
            locationLB.text = GPSGeoManager.wartermarkGPSInfo.address?.getShowAddress(addressItem.extraAddress.addressStyle, isForCover: isCover)
        } else {
            locationLB.isHidden = true
        }
        
        let templateColor = watermarkModel?.templateColor ?? UIColor.white
        let textColor = watermarkModel?.textColor ?? .white
        
        bottomTableView.configDatas(items: watermarkModel?.allBottomOpenItem ?? [], maxWidth: GPApp.screenWidth - 100, templateColor: textColor)
        for item in scaleContentView.subviews {
            if let label = item as? UILabel {
                label.textColor = textColor
            }
        }
        //顶部文字改成背景色，避免抄袭嫌疑
        for item in animationView.subviews {
            if let label = item as? UILabel {
                label.textColor = textColor
            }
        }
        
        bottomTableView.backgroundColor = templateColor.withAlphaComponent(0.1)
        refreshTimeTextColor()
        setNeedsLayout()
    }
    
    func refreshTimeTextColor() {
        let textColor = watermarkModel?.textColor ?? .white
        timeLB.textGradient(
            colors: generateBalancedGradient(baseColor: textColor),
            start: .init(x: 0, y: 0.5),
            end: .init(x: 1.0, y: 0.5),
            locations: [0, 0.25, 0.5, 0.75, 1]
        )
    }
    
    func generateBalancedGradient(
            baseColor: UIColor,
            hueSpread: CGFloat = 0.05,
            satVariation: CGFloat = 0.1,
            brightVariation: CGFloat = 0.1
        ) -> [UIColor] {
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        
        // 获取主色的HSBA值
        guard baseColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) else {
            return Array(repeating: baseColor, count: 5)
        }
        
        // 计算5个色相点（包含主色）
        let hueSteps: [CGFloat] = [
            hue - 2 * hueSpread, // 最左色
            hue - hueSpread,     // 左色
            hue,                 // 主色
            hue + hueSpread,     // 右色
            hue + 2 * hueSpread  // 最右色
        ]
        
        return hueSteps.map { step in
            // 规范化色相（确保在0~1之间）
            let normalizedHue = (step.truncatingRemainder(dividingBy: 1) + 1).truncatingRemainder(dividingBy: 1)
            
            // 动态调整饱和度和亮度（中间高，两侧低）
            let position = (step - hue) / (2 * hueSpread) + 0.5 // -0.5~1.5 → 0~1
            let satAdjustment = satVariation * (1 - 2 * abs(position - 0.5))
            let brightAdjustment = brightVariation * (1 - 2 * abs(position - 0.5))
            
            return UIColor(
                hue: normalizedHue,
                saturation: min(max(saturation + satAdjustment, 0), 1),
                brightness: min(max(brightness + brightAdjustment, 0), 1),
                alpha: alpha
            )
        }
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
        let currentTimeText = "\(dateInfo.hh):\(dateInfo.mm)"
        timeLB.text = currentTimeText
        timeLB.sizeToFit()
        timeLB.width = timeLB.width + 2
        dateLB.text = dateInfo.date
        yearLB.text = dateInfo.week
        ampmLabel.text = dateInfo.ampm
        timeZoneLabel.text = TimeManager.shared.getGlobalTimeZone().abbreviation()
        
        ampmLabel.isHidden = !is12Hours
        yearLB.isHidden = !showWeak
        timeZoneLabel.isHidden = !isTimeZone
        
        if lastTimeText != currentTimeText {
            setNeedsLayout()
            layoutIfNeeded()
            refreshTimeTextColor()
        }
        lastTimeText = currentTimeText
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        var content_y: CGFloat = 12
        var totalH: CGFloat = -2
        
        resetLogoFrame()
        
        // 计算跟随水印logo位置
        if logoHeight > 0 && logoImageView.image != nil {
            content_y = (logoImageView.bottom) + 8
            totalH = content_y
        }
        var contentCurrentMaxW: CGFloat = 168
        let animateViewMaxW = self.currentAnimationViewWidth
        let locLeftSpace:CGFloat = 14
        let contentTextMaxW = animateViewMaxW - locLeftSpace - 18
        
        // 顶部view底部的位置
        var topViewBottom = totalH
        var topViewLeft = 10.0
        
        let timeLBTop: CGFloat = content_y - 2
        timeLB.frame = CGRect(x: 10, y: timeLBTop, width: timeLB.width, height: 55)
        
        var lineViewLeft: CGFloat = timeLB.right
        let ampmY = timeLBTop + 5
        let timeZoneY = timeLB.bottom - 7 - 17
        
        if is12Hours || isTimeZone {
            
            // 上下午
            if is12Hours {
                
                let ampmWidth = (ampmLabel.sizeThatFits(CGSize(width: 100, height: 23)).width) + 1
                ampmLabel.frame = CGRect(x: timeLB.right + 4, y: ampmY, width: ampmWidth, height: 17)
                lineViewLeft = max(lineViewLeft, ampmLabel.right)
            } else {
                ampmLabel.frame = .zero
            }
            
            // 时区
            if isTimeZone {
                
                let timeZoneWidth = (timeZoneLabel.sizeThatFits(CGSize(width: 200, height: 23)).width) + 1
                timeZoneLabel.frame = CGRect(x: timeLB.right + 4, y: timeZoneY, width: timeZoneWidth, height: 17)
                lineViewLeft = max(lineViewLeft, timeZoneLabel.right)
            } else {
                timeZoneLabel.frame = .zero
            }
            
            lineViewLeft = lineViewLeft + 8
        } else {
            lineViewLeft = timeLB.right + 8
        }
        
        dateLB.frame = CGRect(x: 10, y: ampmY, width: 2, height: 17)
        yearLB.frame = .init(x: 10, y: timeZoneY, width: 32, height: 17)
        
        // 日期
        if (dateLB.text?.replacingOccurrences(of: " ", with: "").count ?? 0) > 0 {
            let dateSize = dateLB.text?.size(WithFont: dateLB.font ?? UIFont.systemFont(ofSize: 12), ConstrainedToWidth: contentTextMaxW) ?? .zero
            let maxW = lineViewLeft + 7 + dateSize.width + 1
            contentCurrentMaxW = max(contentCurrentMaxW, maxW)
            dateLB.width = dateSize.width + 1
            dateLB.left = lineViewLeft - 1
        } else {
            dateLB.frame = .zero
        }
        // 年
        if (yearLB.text?.replacingOccurrences(of: " ", with: "").count ?? 0) > 0 {
            let dateSize = yearLB.text?.size(WithFont: yearLB.font ?? UIFont.systemFont(ofSize: 12), ConstrainedToWidth: contentTextMaxW) ?? .zero
            let maxW = lineViewLeft + 7 + dateSize.width + 1
            contentCurrentMaxW = max(contentCurrentMaxW, maxW)
            yearLB.width = dateSize.width + 4
            yearLB.left = lineViewLeft - 1
        } else {
            yearLB.frame = .zero
        }
        
        // 顶部view的底部位置
        topViewBottom = timeLB.bottom

        // 定位
        if locationLB.isHidden == false, let text = locationLB.text, text.count > 0 {
            
            let locationSize = locationLB.text?.getStringSizeByLabel(WithFont: locationLB.font ?? UIFont.systemFont(ofSize: 14), ConstrainedToWidth: contentTextMaxW, lineBreakMode: locationLB.lineBreakMode) ?? .zero
            locationLB.frame = .init(x: topViewLeft, y: topViewBottom, width: locationSize.width + 1, height: locationSize.height + 1)

            contentCurrentMaxW = max(contentCurrentMaxW, locationSize.width + 1)
            topViewBottom = locationLB.bottom + 8
        } else {
            locationLB.frame = .zero
        }
        
        topViewLeft = 10
        
        // 底部tableview
        bottomTableView.frame = .init(x: topViewLeft, y: topViewBottom, width: bottomTableView.width, height: bottomTableView.height)
        contentCurrentMaxW = max(contentCurrentMaxW, bottomTableView.width + 1)
        topViewBottom = bottomTableView.bottom
        if bottomTableView.height == 0 {
            topViewBottom -= 8
        }
        
        if animationView.bottom == 0 {
            animationView.bottom = height
        }
        
        let animationViewH = topViewBottom + 10
        let animationViewW = contentCurrentMaxW + locLeftSpace + 18
                
        animationView.frame = .init(x: animationView.left, y: animationView.bottom - animationViewH, width: animationViewW, height: animationViewH)
        
        if sizeScale != 1 {
            makeChangSizeUI(animationView_w: animationViewW, content_y: animationViewH)
        } else {
            scaleContentView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        
        resetFrame()
        // TODO:
//        animationView.backgroundColor =  .red.withAlphaComponent(0.2)
    }
    
}
