//
//  WatermarkID9View.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/12/14.
//

import Foundation
import UIKit

class WatermarkID9View: BaseWatermark{
 
    //animation_View的最大宽度
    var currentAnimationViewWidth: CGFloat {
        let defaultWidth = GPApp.screenWidth - 100
        return sizeScale*defaultWidth
    }
    
    var timeContentView: UIView = {
        return UIView(backgroundColor: UIColor.clear)
    }()
    
    var timeBGImageView: UIImageView = {
        let imgV = UIImageView(image: UIImage(named: "clock_BG"))
        return imgV
    }()
    
    var dateView: ID9DateView = {
        return ID9DateView(frame: .zero)
    }()
    
    var timeView: ID9TimeView = {
        return ID9TimeView(frame: .zero)
    }()
    
    var clockLB: GPQStickerLabel = {
        return GPQStickerLabel.init(text: "k_clock_now".localized(), textColor: .white, textFont: UIFont.robotoCondensedBold(24), numberLines: 1, lineBreakMode: .byTruncatingTail)
    }()
    
    var locationIcon: UIImageView = {
        let imgV = UIImageView(image: UIImage(named: "clock_location_white"))
        imgV.contentMode = .scaleAspectFit
        imgV.isHidden = true
        return imgV
    }()
    
    var locationLB: GPQStickerLabel = {
        return GPQStickerLabel.init(text: "", textColor: .white, textFont: UIFont.robotoCondensedBold(20), textAlignment: .left, numberLines: 0, lineBreakMode: .byWordWrapping)
    }()
    
    var themeColor: UIColor {
        return UIColor.white
    }
    
    override func buildViews() {
        super.buildViews()
        timeContentView.frame = CGRect(x: 10, y: 10, width: 229, height: 83)
        timeContentView.clipsToBounds = true
        animationView.addSubview(timeContentView)
                
        timeBGImageView.frame = timeContentView.bounds
        timeContentView.addSubview(timeBGImageView)
        
        timeContentView.addSubview(dateView)
        timeContentView.addSubview(timeView)
        
        clockLB.setLabShadow()
        clockLB.isHidden = true
        animationView.addSubview(clockLB)
        
        locationIcon.frame = CGRect(x: 0, y: 0, width: 56.0/2.0, height: 63/2.0)
        locationIcon.isHidden = true
        animationView.addSubview(locationIcon)

        locationLB.setLabShadow()
        locationLB.isHidden = true
        animationView.addSubview(locationLB)
        
        outLogoPadding = 16
    }
    
    override func updateUI() {
        super.updateUI()
        
        let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
        let watermarkTextColor = watermarkModel?.textColor ?? .white
//
//        // 时间
        reloadTimes()
        
        // 设置定格这一刻
        if let noteItem = watermarkModel?.items?.first(where: { $0.idType == .note }), noteItem.isOpen == true {
            clockLB.text = noteItem.content ?? ""
            clockLB.textColor = watermarkTextColor
            clockLB.sizeToFit()
            let maxClockW = currentAnimationViewWidth - 10*2
            if clockLB.width > maxClockW {
                clockLB.width = maxClockW
            }
            clockLB.isHidden = false
        } else {
            clockLB.isHidden = true
        }
        
        locationIcon.image = locationIcon.image?.withTintColor(watermarkThemeColor)

        // 设置地址
        if let addressItem = watermarkModel?.items?.first(where: { $0.idType == .address }), addressItem.isOpen == true, let locationText = GPSGeoManager.wartermarkGPSInfo.address?.getShowAddress(addressItem.extraAddress.addressStyle, isForCover: isCover), !locationText.isEmpty {
            locationLB.isHidden = false
            locationIcon.isHidden = false
            locationLB.textColor = watermarkTextColor
            locationLB.text = locationText
        } else {
            locationLB.isHidden = true
            locationIcon.isHidden = true
        }
        
        setNeedsLayout()
        
    }
            
    override func reloadTimes() {
        super.reloadTimes()

        // 获取时间
        guard let timeItem = watermarkModel?.items?.first(where: { $0.idType == .time }) else { return }
        let timeItemModel = timeItem.extraTime
        
        let is12Hours = timeItemModel.is12Hour ?? false
        
        let (dateArr, timeArr) = GPDateFormat.getID9DateTimeString(TimeManager.shared.getRealTime(), style: timeItemModel.dateStyleEnum, is12Hours: is12Hours)
        dateView.updateDate(dataList: dateArr)
        timeView.updateDate(dataList: timeArr)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        reloadAnimationViewSize()
    }
    
    func reloadAnimationViewSize(shouldRelayout: Bool = true) {
        if shouldRelayout {
            layoutIfNeeded()
        }
                
        var content_y: CGFloat = 12
        var totalH: CGFloat = 10
        
        resetLogoFrame()
        
        // 计算跟随水印logo位置
        if logoHeight > 0 && logoImageView.image != nil {
            content_y = (logoImageView.bottom) + 8
            totalH = content_y
        }
        
        if animationView.bottom == 0 {
            animationView.bottom = height
        }
        
        timeContentView.y = totalH
        
        dateView.centerX = timeContentView.width/2.0
        dateView.y = 14
        
        timeView.centerX = timeContentView.width/2.0
        timeView.bottom = timeContentView.height - 14
        var startY = timeContentView.bottom
        var maxW = timeContentView.right
        
        // 设置定格这一刻
        if clockLB.isHidden == false {
            clockLB.frame = CGRect(x: 12, y: startY + 8, width: clockLB.width, height: clockLB.height)
            startY = clockLB.bottom + 6
            maxW = max(maxW, clockLB.right)
        }
                
        // 设置地址
        if locationLB.isHidden == false, let text = locationLB.text, text.count > 0 {
            
            let locationSize = locationLB.text?.getStringSizeByLabel(WithFont: locationLB.font ?? UIFont.systemFont(ofSize: 14), ConstrainedToWidth: currentAnimationViewWidth - 10*2 - 28, lineBreakMode: locationLB.lineBreakMode) ?? .zero
            locationLB.frame = .init(x: 10+28, y: startY+6+2, width: locationSize.width + 1, height: locationSize.height + 1)
            maxW = max(maxW, locationSize.width + 1)
            locationIcon.frame = .init(x: 10, y: startY+6, width: locationIcon.width, height: locationIcon.height)
            maxW = max(maxW, locationSize.width + 1)
            
            startY = locationLB.bottom
        } else {
            locationLB.frame = .zero
        }
        
        let animateViewHeight = startY + 10
        let animationView_w = maxW
        animationView.frame = CGRect.init(x: animationView.left, y: animationView.bottom - animateViewHeight, width: animationView_w, height: animateViewHeight)
        
        if sizeScale != 1 {
            makeChangSizeUI(animationView_w: animationView_w, content_y: animateViewHeight)
        } else {
            scaleContentView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        resetFrame()
    }

}

