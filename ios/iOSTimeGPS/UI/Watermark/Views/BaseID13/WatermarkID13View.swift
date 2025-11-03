//
//  WatermarkID13View.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/3/31.
//

import Foundation
import UIKit

class WatermarkID13View: BaseWatermark {
    
    let inMapWidth = 110.0
    let padding = 6.0
    let logoViewHeight = 24.0
    
    var themeColor: UIColor {
        return UIColor.black
    }
    
    lazy var bgView: UIView = {
        let view = UIView.init(backgroundColor: themeColor.withAlphaComponent(0.3), cornerRadius: 0)
        return view
    }()
    
    lazy var logoView: UIView = {
        let view = UIView.init(backgroundColor: themeColor.withAlphaComponent(0.3), cornerRadius: 0)
        
        let logoImgV = UIImageView(frame: .init(x: 4, y: 4, width: 16, height: 16))
        logoImgV.layerCornerRadius = 2
        logoImgV.image = UIImage(named: "icon80-removebg")
        view.addSubview(logoImgV)
        
        let titleLabel = UILabel(frame: .zero).then {
            view.addSubview($0)
            $0.font = UIFont.regular(8)
            $0.textColor = UIColor.white
            $0.lineBreakMode = .byTruncatingTail
            $0.text = "Timeprint"
            $0.sizeToFit()
        }
        
        titleLabel.left = logoImgV.right + 4
        titleLabel.centerY = logoImgV.centerY
        
        view.frame = .init(x: 0, y: 0, width: titleLabel.right + 4, height: logoViewHeight)
        
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

    
    var bottomTableView: WatermarkID1BottomView = {
        let tableView = WatermarkID1BottomView(frame: .zero)
        return tableView
    }()
    
    var bottomTableWidth: CGFloat = 0
    var bottomTableHeight: CGFloat = 0
    
    override func buildViews() {
        super.buildViews()
        
        animationView.addSubview(bgView)
        animationView.addSubview(logoView)
        if(isCover){ //如果是生成cover的，则使用coverMapView
            bgView.addSubview(coverMapView)
        }
        else {
            bgView.addSubview(inMapView)
        }

        // 底部tableview
        bgView.addSubview(bottomTableView)
        
    }
    
    override func updateUI() {
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
                        
        let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
        bgView.backgroundColor = watermarkThemeColor.withAlphaComponent(0.3)
        logoView.backgroundColor = watermarkThemeColor.withAlphaComponent(0.3)

        let watermarkTextColor = watermarkModel?.textColor ?? .white
        bottomTableView.configDatas(baseID: .ID13, items: watermarkModel?.allBottomOpenItem ?? [], maxWidth: GPApp.screenWidth - inMapWidth - padding*4, templateColor: watermarkTextColor)
        bottomTableView.backgroundColor = .clear
        bottomTableWidth = bottomTableView.width
        bottomTableHeight = bottomTableView.height - 6
          
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
        self.bottomTableView.tableView?.reloadData()
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
            content_y = (logoImageView.bottom) + padding
            viewTotalH = content_y
        }
        
        let animationViewW = self.width
        logoView.right = animationViewW - padding
        logoView.top = content_y
        
        let bgWidth = animationViewW - padding*2
        let bgHeight = max(bottomTableHeight, inMapView.bottom + padding)
        bgView.frame = CGRect(x: padding, y: logoView.bottom, width: bgWidth, height: bgHeight)

        bottomTableView.frame = CGRect(x: inMapView.right + padding, y: 0, width: bottomTableWidth, height: bottomTableHeight)
                
        viewTotalH = max(bgView.bottom + padding, inMapView.bottom + padding)
       // LogDebug("currentWatermarkView: id13 \(viewTotalH) \(animationView.bottom)  \(animationView.bottom - viewTotalH)")
        
        animationView.frame = .init(x: animationView.left, y: animationView.bottom - viewTotalH, width: animationViewW, height: viewTotalH)
        if sizeScale != 1 {
            makeChangSizeUI(animationView_w: animationViewW, content_y: viewTotalH)
        } else {
            scaleContentView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        resetFrame()
    }
    
}

