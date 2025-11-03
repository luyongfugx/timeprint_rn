//
//  BaseWatermark.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/17.
//

import Foundation
import UIKit

protocol BaseWatermarkDelegate: AnyObject {
    func beginEditWatermark()
    func endEditWatermark()
    func gotoEditCurrentWatermark() -> EditWatermarkVC?
}

class BaseWatermark: GPContentView {
    
    var watermarkModel: BaseWatermarkModel?
    var isPreviewMode: Bool = false
    var isCover: Bool = false

    var isEditPage: Bool = false
    var orientation: GPOrientation = .portraitDirection
    weak var delegate: BaseWatermarkDelegate?
    weak var editLogoVC: GPEditLogoVC?
    
    var selectedView: UIView?
    var lastLocation: CGPoint = .zero
    let minSpacing: CGFloat = 6 // 视图间最小间距
    var positionModel: AllWatermarkViewPosition?

    var animationView: WMAnimationView = {
        let view = WMAnimationView(frame: CGRect.zero)
        view.tag = excludeTag
        return view
    }()
    
    var scaleContentView: GPContentView = {
        let view = GPContentView(frame: CGRect.zero)
        return view
    }()
    
    var mapView: GPMapView = {
        return GPMapView.init(frame: .init(x: 0, y: 0, width: MapWidth, height: MapWidth))
    }()
    
    var offcialLogoView: OffcialLogoView = {
        let view = OffcialLogoView(frame: .zero)
        view.tag = OffcialLogoViewTag
        view.isHidden = true
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }()
    
    // 脱离水印的logo
    var outLogoView: GPOutLogoView = {
        let outLogoView = GPOutLogoView(frame: .zero)
        outLogoView.layerCornerRadius = 4
        outLogoView.isHidden = true
        return outLogoView
    }()
        
    // logo
    var logoImageView: UIImageView = {
        let imgV = UIImageView()
        imgV.layerCornerRadius = 4
        return imgV
    }()
    var logoWidth: CGFloat = 0  // logo的宽度
    var logoHeight: CGFloat = 0 // logo的高度
    var outLogoPadding: CGFloat = 12
    
    var loopSender: GPTimerLoopSender?
    
    var subsribeLocationID: String = ""
    var subsribeAddressID: String = ""
    
    // 大小的缩放
    var sizeScale: CGFloat = 1
    // 字体的缩放
    var fontScale:CGFloat = 1

    static func generateWatermarkView(watermarkModel: BaseWatermarkModel, preview: Bool = false, isCover: Bool = false, frame: CGRect) -> BaseWatermark {
        switch watermarkModel.baseID {
        case .ID1:
            return WatermarkID1View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID2:
            return WatermarkID2View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID3:
            return WatermarkID3View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID4:
            return WatermarkID4View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID5:
            return WatermarkID5View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID6:
            return WatermarkID6View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID7:
            return WatermarkID7View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID8:
            return WatermarkID8View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID9:
            return WatermarkID9View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID10:
            return WatermarkID10View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID11:
            return WatermarkID11View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID12:
            return WatermarkID12View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID13:
            return WatermarkID13View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID14:
            return WatermarkID14View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID15:
            return WatermarkID15View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        case .ID16:
            return WatermarkID16View(isPreviewMode: preview, isCover: isCover, watermarkModel: watermarkModel, frame: frame)
        }
    }
    
    // 使用纯代码布局的会走这个
    init(isPreviewMode: Bool, isCover: Bool = false, watermarkModel: BaseWatermarkModel?, frame: CGRect) {
        super.init(frame: frame)
        self.isPreviewMode = isPreviewMode
        self.isCover = isCover
        self.watermarkModel = watermarkModel
        buildViews()
        
        guard !isCover else { return }
        
        addGesture()
        
        // 监听时间
        configureLoopSender()
        // 添加定位和地址监听
        monitorGPS()
        // 监听其它通知
        addNotification()
    }
    
    func addNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(weatherRefresh), name: GPNotification.weatherNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(realTimeRefresh), name: GPNotification.realTimeNotification, object: nil)
    }
    
    @objc
    func weatherRefresh() {
        guard !isHidden else { return }
        GPSafeMainAsync {
            self.updateUI()
        }
    }
    
    @objc
    func realTimeRefresh() {
        guard !isHidden else { return }
        GPSafeMainAsync {
            self.reloadTimes()
        }
    }
    
    func monitorGPS() {
        subsribeLocationID = GPLocationManager.shared.subscribe(complete: { [weak self] isSuccess, location, error in
            if location != nil {
                self?.updateUI()
            }
        })
        
        subsribeAddressID = GPAddressManager.shared.subscribe(complete: { [weak self] isSuccess, address, error in
            if address != nil {
                self?.updateUI()
            }
        })
    }
    
    func configureLoopSender(){
        loopSender = GPTimerLoopSender.init(interval: 1)
        loopSender?.timerloopCallBack = { [weak self](count,interval) in
            guard let wself = self, !wself.isHidden else {return}
//            if wself.refreshTime > 0{
//                //refreshTime 单位秒
//                //30 个interval 的时间 0.033*30 = 1s
//                wself.timeReloadSticker()
//            }
            wself.reloadTimes()
            //0.033s 更新一次
        }
        loopSender?.start()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        LogDebug("BaseWatermark--deinit")
        GPLocationManager.shared.cancleSubscribe(identify: subsribeLocationID)
        GPAddressManager.shared.cancleSubscribe(identify: subsribeAddressID)
    }
    
    func reloadTimes() {
    }
    
    func buildViews() {
        self.isUserInteractionEnabled = true
        addSubview(offcialLogoView)
        //如果是中国,则隐藏offcialLogoView
        if GPCheetManager.isCheetMode{
            offcialLogoView.isHidden = true
        }
        else {
            //offcialLogoView.isHidden = true
            offcialLogoView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }

        // 外部显示Map
        addSubview(mapView)
        // 外部显示Logo
        addSubview(outLogoView)
        addSubview(animationView)
        animationView.addSubview(logoImageView)
    }
    
    func updateUI() {
        // 水印大小
        sizeScale = watermarkModel?.templateScale ?? 1
        
        // 设置logo
        updateLogo()
        
        // 设置地图
        if let mapModel = watermarkModel?.items?.first(where: { $0.idType == .map }), mapModel.isOpen == true, let location = GPSGeoManager.wartermarkGPSInfo.location?.coordinate {
            mapView.canShowMap = true
            mapView.updateLocation(location: location, mapStyle: mapModel.getMapStyle() ?? .standard)
        } else {
            mapView.canShowMap = false
        }
//        if hasSubviewInTopRightCorner(size: 100) {
//            offcialLogoView.moveToTopBottom(isTop: true)
//        } else {
//            offcialLogoView.moveToTopBottom(isTop: false)
//        }
        
        
        
    }
    /// 判断视图右上角指定大小的区域内是否有子视图。
    /// - Parameter size: 要检查的区域大小（正方形）。
    /// - Returns: 如果区域内有子视图，则返回 true；否则返回 false。
    func hasSubviewInTopRightCorner(size: CGFloat) -> Bool {
        // 1. 定义右上角区域的矩形
        let rectToCheck = CGRect(
            x: self.bounds.width - size,
            y: self.bounds.height - size,
            width: size,
            height: size
        )

        // 2. 遍历所有子视图
        for subview in subviews {
            // 3. 将子视图的 frame 转换到父视图的坐标系中
            let subviewFrameInParent = subview.frame

            // 4. 判断子视图的 frame 是否与定义的区域有交集
            if subviewFrameInParent.intersects(rectToCheck) {
                // 如果找到任何一个有交集的子视图，立即返回 true
                return true
            }
        }

        // 遍历完成，没有找到有交集的子视图
        return false
    }
    
    func resetFrame() {
        loadViewPositions()
        frameSizeChange(orientation: orientation)
    }
    
    //水印改大小重新布局
    func makeChangSizeUI(animationView_w: CGFloat, content_y: CGFloat) {
        let animationV = self.animationView
        let v = self.scaleContentView
        v.layer.anchorPoint = CGPoint(x: 0, y: 1)
        v.transform = CGAffineTransform.identity
        for obj in animationV.subviews {
            if obj != v {
                obj.removeFromSuperview()
                self.scaleContentView.addSubview(obj)
            }
        }
        
        animationV.addSubview(scaleContentView)
        scaleContentView.frame = CGRect(x: 0, y: 0, width: animationView_w, height: content_y)
        animationV.frame = CGRect.init(x: animationV.left, y: animationV.bottom - content_y*self.sizeScale, width: animationView_w*self.sizeScale, height: content_y*self.sizeScale)
        scaleContentView.transform = CGAffineTransform(scaleX: self.sizeScale, y: self.sizeScale)
        scaleContentView.left = 0
        scaleContentView.top = 0
    }
    
    func updateSubLabelColor(_ superV: UIView, _ watermarkTextColor: UIColor) {
        for item in superV.subviews {
            if item.subviews.count > 0 {
                updateSubLabelColor(item, watermarkTextColor)
            } else {
                if let label = item as? UILabel {
                    label.textColor = watermarkTextColor
                }
            }
        }
    }
    
    func getItem(title: String, content: String, open: Bool) -> WatermarkItem{
        let item = WatermarkItem()
        item.title = title
        item.content = content
        item.isOpen = open
        return item
    }
    
    func gotoAddLogo() {
        let editVC = gotoEdit()
        if let logoItem = watermarkModel?.items?.first(where: { $0.idType == .logo }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                editVC?.clickItem(logoItem)
            }
        }
    }
    
    func hasLogo() -> Bool {
        watermarkModel?.items?.first(where: { $0.idType == .logo })?.isOpen == true
    }
    
    func gotoEditMap() {
        let editVC = gotoEdit()
        if let mapItem = watermarkModel?.items?.first(where: { $0.idType == .map }) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                editVC?.clickItem(mapItem)
            }
        }
    }
    
    func cachAnimationViewToCover(async: Bool) {
        
        func cropSnap() {
            if let watermarkID = watermarkModel?.id {
                let img = animationView.screenshots()
                GPDataCacheManager.shared.cachWatermarkCover(coverImg: img, watermarkID: watermarkID)
            }
        }
        
        if async {
            DispatchQueue.global().asyncAfter(deadline: .now() + 0.1) {
                cropSnap()
            }
        } else {
            cropSnap()
        }
        
    }
    
    func didUpdateLogo() {
        
    }
    
    func addDotLineAnimation() {
        for subV in subviews {
            if subV.isHidden == false {
                subV.addInternalDashedBorderAnimation()
            }
        }
    }
    
    func removeDotLineAnimation() {
        for subV in subviews {
            subV.removeInternalDashedBorderAnimation()
        }
    }

}

class WMAnimationView: GPContentView {
    
}
