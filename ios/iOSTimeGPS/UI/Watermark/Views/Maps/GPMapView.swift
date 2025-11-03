//
//  GPMapView.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/18.
//

import Foundation
import UIKit
import MapKit

enum WatermarkMapStyle: Int {
    case standard = 0
    case satellite
    
    func getTitle() -> String {
        switch self {
        case .standard:
            return "k_map_standard".localized()
        case .satellite:
            return "k_map_satellite".localized()
        }
    }
}

let MapWidth = 98
class GPMapView: UIView {
    
    lazy var locationLabel: UILabel = {
        let label = UILabel.iconLabel(fontSize: 20, labelWidth: 20, iconType: .icon_location)
        label.textColor = .location_color
        return label
    }()
    
    var mapView: MKMapView = {
        let mapView = MKMapView(frame: CGRect.init(x: 0, y: -MapWidth, width: MapWidth, height: MapWidth))
        return mapView
    }()
    
    var imgView: UIImageView = {
        let imgV = UIImageView(frame: CGRect.init(x: 0, y: -MapWidth, width: MapWidth, height: MapWidth))
        return imgV
    }()
    
    var hasMapLoadSuccess: Bool?
    // 上次截图时间，两次之间不能小于0.5秒
    var lastSnapTim2e = 0
    
    var canShowMap: Bool = false {
        didSet {
            checkCanShowMap()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setBorder(color: .white, width: 1)
        addSubview(imgView)
        imgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.clipsToBounds = true
        addSubview(mapView)
        
        self.mapView.delegate = self
        self.mapView.mapType = MKMapType.standard
        self.mapView.userTrackingMode = MKUserTrackingMode.follow
        self.mapView.isScrollEnabled = false
        self.mapView.isZoomEnabled = false
        
        addSubview(locationLabel)
        locationLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateLocation(location: CLLocationCoordinate2D, mapStyle: WatermarkMapStyle) {
        var finalLocation = location
        if GPCountryManager.isChina {
            // 中国地区特殊处理，转成gcj02再请求
            let gcj02 = GPLocationConverter.wgs84(toGcj02: location)
            finalLocation.latitude = gcj02.latitude
            finalLocation.longitude = gcj02.longitude
        }
        self.mapView.mapType = (mapStyle == .standard) ? MKMapType.standard : .satellite
        let region = MKCoordinateRegion.init(center: finalLocation, latitudinalMeters:1000, longitudinalMeters: 1000)
        self.mapView.setRegion(region, animated: true)
    }
    
    private func showMapWhenLoadFinish(_ canShow: Bool) {
        hasMapLoadSuccess = canShow
        checkCanShowMap()
    }
    
    private func checkCanShowMap() {
        if hasMapLoadSuccess == true {
            self.isHidden = canShowMap ? false : true
        } else {
            self.isHidden = true
        }
    }
}

extension GPMapView {
    
    //截图
    func doSnap() {
        
        let currentTime = Int(ProcessInfo.processInfo.systemUptime * 1000)
        if currentTime - lastSnapTim2e > 500 {
            // 上次截图时间，两次之间不能小于0.5秒
            lastSnapTim2e = currentTime
            doSnapStart()
        }
    }
    
    @objc private func doSnapStart() {
        let options = MKMapSnapshotter.Options()
        options.region = self.mapView.region
        options.scale = UIScreen.main.scale
        options.size = self.mapView.frame.size
        options.mapType = self.mapView.mapType
        let shotter = MKMapSnapshotter(options: options)
        shotter.start {[weak self] snapshot, error in
            if let err = error {
                // 地图加载失败
                self?.finalLoadFail(error: err)
            } else {
                self?.finalLoadSuccess(img: snapshot?.image)
            }
        }
    }
}

extension GPMapView {
    // 统一的加载成功
    func finalLoadSuccess(img: UIImage?) {
        self.imgView.image = img
        // 加载成功回调
        showMapWhenLoadFinish(true)
    }
    
    // 统一的加载失败
    func finalLoadFail(error: Error?) {
        showMapWhenLoadFinish(false)
    }
}

// MARK: - MKMapViewDelegate
extension GPMapView: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
//        self.doSnap()
    }
  
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        
    }
    
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        // 地图加载完成
        self.doSnap()
    }
    
    func mapViewDidFailLoadingMap(_ mapView: MKMapView, withError error: Error) {
        // 地图加载失败
        showMapWhenLoadFinish(false)
    }
    
    func mapViewWillStartRenderingMap(_ mapView: MKMapView) {
    }

    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        self.doSnap()
    }
    func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
        // 添加地图完成
    }

}
