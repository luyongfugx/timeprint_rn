//
//  WatermarkID14.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/4/4.
//

import Foundation
import UIKit

class WatermarkID14View: BaseWatermark {
    
    let inMapWidth = 92.0
    let padding = 6.0
    let edgePadding = 20.0

    var themeColor: UIColor {
        return UIColor.white
    }
    
    lazy var bgView: UIView = {
        let view = UIView.init(backgroundColor: themeColor.withAlphaComponent(0.3), cornerRadius: 0)
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    // 跟谁水印一起的地图
    lazy var inMapView: GPMapView = {
        let mapV = GPMapView.init(frame: .init(x: 0, y: 0, width: inMapWidth, height: inMapWidth))
        mapV.layerCornerRadius = 4
        return mapV
    }()

    //如果是生成coverview 的使用一个mapcover的imageivew
    lazy var coverMapView: UIView = {
        let view = UIImageView(frame: .init(x: 0, y: 0, width: inMapWidth, height: inMapWidth))
        view.layerCornerRadius = 4
        view.image = UIImage(named: "mapcover")
        return view
    }()
    
    
    private lazy var addressBtn: IconTextView = {
        let button = IconTextView(frame: .zero)
        button.iconImageV.image = .init(named: "position_id14")?.withTintColor(UIColor(red: 248/255.0, green: 57/255.0, blue: 49/255.0, alpha: 1))
        button.iconImageV.transform = .init(scaleX: 0.8, y: 0.8)
        return button
    }()
    
    private lazy var dateBtn: IconTextView = {
        let button = IconTextView(frame: .zero)
        button.iconImageV.image = .init(named: "icon_calendar")
        button.iconImageV.transform = .init(scaleX: 0.8, y: 0.8)
        return button
    }()
    
    private lazy var timeBtn: IconTextView = {
        let button = IconTextView(frame: .zero)
        button.iconImageV.image = .init(named: "id14icontimer")
        button.iconImageV.transform = .init(scaleX: 0.9, y: 0.9)
        return button
    }()
    
    private lazy var latitudeBtn: IconTextView = {
        let button = IconTextView(frame: .zero)
        button.iconImageV.image = .init(named: "icon_lat")?.withTintColor(UIColor(red: 248/255.0, green: 57/255.0, blue: 49/255.0, alpha: 1))
        button.iconImageV.transform = .init(scaleX: 0.7, y: 0.7)
        return button
    }()
    
    private lazy var longitudeBtn: IconTextView = {
        let button = IconTextView(frame: .zero)
        button.iconImageV.image = .init(named: "icon_lng")?.withTintColor(UIColor(red: 248/255.0, green: 57/255.0, blue: 49/255.0, alpha: 1))
        button.iconImageV.transform = .init(scaleX: 0.7, y: 0.7)
        return button
    }()
    
    override func buildViews() {
        super.buildViews()
        animationView.addSubview(bgView)
        if(isCover){ //如果是生成cover的，则使用coverMapView
            [coverMapView, addressBtn, dateBtn, timeBtn, latitudeBtn, longitudeBtn].forEach({ bgView.addSubview($0) })
        }
        else {
            [inMapView, addressBtn, dateBtn, timeBtn, latitudeBtn, longitudeBtn].forEach({ bgView.addSubview($0) })
        }
        
   
        outLogoPadding = edgePadding
    }
    
    override func updateUI() {
        LogDebug("watermarkModel frame currentWatermarkView updateUI ")
        super.updateUI()
                
        // 设置地图
        if let mapModel = watermarkModel?.items?.first(where: { $0.idType == .map }), mapModel.isOpen == true, let location = GPSGeoManager.wartermarkGPSInfo.location?.coordinate {
            inMapView.canShowMap = true
            inMapView.updateLocation(location: location, mapStyle: mapModel.getMapStyle() ?? .standard)
        } else {
            inMapView.canShowMap = false
        }
        
        
        mapView.canShowMap = false
        mapView.isHidden = true
        inMapView.isHidden = false
        
        // 时间
        reloadTimes()
 
//        if let address = GPSGeoManager.wartermarkGPSInfo.address?.getShowAddress(.formatAddress) {
        if let addressItem = watermarkModel?.items?.first(where: { $0.idType == .address }){
            addressBtn.label.text = addressItem.getShowContent()
        } else {
            addressBtn.label.text = "k_address".localized()
        }
        
        if let location = GPSGeoManager.wartermarkGPSInfo.location {
            let _latitude = String.init(format: "%.6f", abs(location.coordinate.latitude))
            let _longitude = String.init(format: "%.6f", abs(location.coordinate.longitude))
            latitudeBtn.label.text = _latitude
            longitudeBtn.label.text = _longitude
        }
                
        let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
        let watermarkTextColor = watermarkModel?.textColor ?? .white
        
        bgView.backgroundColor = watermarkThemeColor.withAlphaComponent(0.3)
        [addressBtn, dateBtn, timeBtn, latitudeBtn, longitudeBtn].forEach({
            $0.label.textColor = watermarkTextColor
        })
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
        // 获取时间
        guard let timeItem = watermarkModel?.items?.first(where: { $0.idType == .time }) else { return }
        let timeItemModel = timeItem.extraTime
        
        let is12Hours = timeItemModel.is12Hour ?? false
        let isTimeZone = timeItemModel.showTimeZone ?? false
        let showWeak = timeItemModel.showWeak ?? true
        
        let dateInfo = GPDateFormat.dateCommpent(with: TimeManager.shared.getRealTime(), is12Hours: is12Hours, dateStyle: timeItemModel.dateStyleEnum)
        
        var dateText = dateInfo.date
        if showWeak {
            dateText = dateInfo.week + ", " + dateInfo.date
        }
        dateBtn.label.text = dateText
        
        var timeText = "\(dateInfo.hh):\(dateInfo.mm)"
        if is12Hours {
            timeText = timeText + " " + dateInfo.ampm
        }
        if isTimeZone, let timezoneT = TimeManager.shared.getGlobalTimeZone().abbreviation() {
            timeText = timeText + ", " + timezoneT
        }
        timeBtn.label.text = timeText
        
        layoutIfNeeded()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        inMapView.left = padding
        inMapView.top = padding
        if(isCover){
            coverMapView.left = padding
            coverMapView.top = padding
        }
        var content_y: CGFloat = padding
        var viewTotalH: CGFloat = padding

        resetLogoFrame()
        
        // 计算跟随水印logo位置
        if logoHeight > 0 && logoImageView.image != nil {
            content_y = (logoImageView.bottom) + 4
            viewTotalH = content_y
        }
        
        let animationViewW = self.width
        let bgWidth = animationViewW - edgePadding*2
        let bgHeight = inMapWidth + padding*2
        bgView.frame = CGRect(x: edgePadding, y: content_y, width: bgWidth, height: bgHeight)

        var startX =  inMapView.right + padding
        //如果是cover
        if(isCover){
            startX =  coverMapView.right + padding
        }
        let addressWidth = bgWidth - startX - padding
        addressBtn.frame = .init(x: startX, y: padding+2, width: addressWidth, height: 16)
        
        addressBtn.label.font = UIFont.boldSystemFont(ofSize: 16)
        if addressBtn.label.getOneLineSize().width > addressWidth {
            addressBtn.label.font = UIFont.systemFont(ofSize: 12)
            addressBtn.label.numberOfLines = 2
        }
        dateBtn.frame = .init(x: startX, y: addressBtn.bottom + padding*2 + 4.0 , width: animationViewW - startX, height: 16)
        timeBtn.frame = .init(x: startX, y: dateBtn.bottom + padding*2 + 4.0 , width: animationViewW - startX, height: 16)
        
        let textW = max(dateBtn.label.getOneLineSize().width, timeBtn.label.getOneLineSize().width)
        let startX2 = startX + 26 + textW + padding*2
        latitudeBtn.frame = .init(x: startX2, y: dateBtn.y, width: animationViewW - startX - 100, height: 16)
        longitudeBtn.frame = .init(x: startX2, y: timeBtn.y, width: animationViewW - startX - 100, height: 16)
        
        viewTotalH = bgView.bottom + edgePadding
        
        animationView.frame = .init(x: animationView.left, y: animationView.bottom - viewTotalH, width: animationViewW, height: viewTotalH)
        if sizeScale != 1 {
            makeChangSizeUI(animationView_w: animationViewW, content_y: viewTotalH)
        } else {
            scaleContentView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        resetFrame()
    }
    
}
