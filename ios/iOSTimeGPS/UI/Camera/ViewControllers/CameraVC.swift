//
//  CameraVC.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/12.
//

import UIKit
import GPCam
import MediaPlayer

// 相机模式
enum CameraMode: Int {
    case photo = 0
    case video = 1
    case report = 2
}

enum DelayTakePhotoType : Int{
    case none = 0
    case five = 1
    case ten = 2
}

class CameraVC: UIViewController {

    var glView: BMWGLView!
    var camera: BMWCamera?
    var watermImagView: UIImageView!
    var appstoreImagView: UIImageView?

    var watermarkContentView: GPContentView!
    var currentWatermarkView: BaseWatermark?
    var bottomView: CameraBottomView!
    var topView: CameraTopView!
    var focusView: GPFocusView!
    var cameraAccessView: CameracAccessView?
    let bottomHeight = GPApp.tabBarBottomHeight + 162
    
    var tmpVideoFileName: String?
    // 是否正在录制视频
    var isRecording = false {
        didSet {
            currentWatermarkView?.isUserInteractionEnabled = !isRecording
            if canShowOfficial() {
                currentWatermarkView?.offcialLogoView.isHidden = !isRecording
            } else {
                currentWatermarkView?.offcialLogoView.isHidden = true
            }
        }
    }
    var isCurrentVC = false
    var lastLPStartLocation: CGPoint?
    var gestureController: GPCameraGesture?
    var gestureView: UIView!
    weak var wideAngleListView: GPWideAngleListView?
    weak var wideAngleValueTipView: GPWideAngleTipView?
    var isSupportWideAngle: Bool = true
    var enableShowWideAngleValueTipView: Bool = true
    var isCameraBackPosition:Bool{
        return camera?.cameraEntry.devicePosition == .back
    }
    // 音量
    var volumeView: MPVolumeView?
    var firstChangedVolume: Bool = true
    weak var volumeSlider: UISlider?
    var minVolume: Float = 0.01
    var maxVolume: Float = 0.99
    var volumeKeyActionTag = -100
    // 上架图唯一设置入口
    static let isAppStoreMode: Bool = false

    lazy var watermarkBtn: GPButton = {
        let button = GPButton.init(frame: .init(x: 0, y: 0, width: 44, height: 44), fontSize: 20, iconType: .btn_template)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(watermarkAction), for: .touchUpInside)
        return button
    }()
    
    lazy var quickEditBtn: GPButton = {
        let button = GPButton.init(frame: .init(x: 0, y: 0, width: 44, height: 44), fontSize: 20, iconType: .btn_quick_edit)
        button.setTitleColor(.white, for: .normal)
        button.addTarget(self, action: #selector(quickEditAction), for: .touchUpInside)
        return button
    }()
    
    lazy var takePhotoViewBG: UIView = {
        let view = UIView(frame: .init(x: 0, y: 0, width: GPApp.screenWidth, height: GPApp.screenHeight))
        view.backgroundColor = UIColor.fromRGBA(39, g: 31, b: 28).withAlphaComponent(0.9)
        view.isUserInteractionEnabled = false
        view.alpha = 0
        return view
    }()
    
    // 倒计时相关属性
    var countdownTimer: Timer?
    var remainingSeconds: Int = 0
    var isCountdownActive: Bool = false
    
    // 倒计时标签
    var countdownLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .white
        label.font = UIFont.boldSystemFont(ofSize: 80)
        label.layerCornerRadius = 10
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
    }()
    
    // 取消按钮（原来是暂停按钮）
    var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "camera_stop_icon"), for: .normal)
        button.isHidden = true
        button.layer.masksToBounds = true
        return button
    }()
        
    // 画幅比例
    @GPPersistance(key: "com.gpscamera.key.PhotoRatioType", defaultValue: 0)
    static var photoRatioInt: Int
    var photoRatio: PhotoRatioType {
        set {
            CameraVC.photoRatioInt = newValue.rawValue
            changeCameraModeAndFrame()
        }
        get {
            return PhotoRatioType(rawValue: CameraVC.photoRatioInt) ?? .ratio3x4
        }
    }
    
    // 倒计时
    @GPPersistance(key: "com.gpscamera.key.delaytakephoto", defaultValue: 0)
    static var delaytakephotoInt: Int
    var delayTakephotoType: DelayTakePhotoType {
        set {
            CameraVC.delaytakephotoInt = newValue.rawValue
            updateDelayTakePhotoUI()
        }
        get {
            return DelayTakePhotoType(rawValue: CameraVC.delaytakephotoInt) ?? .none
        }
    }
    
    // 相机模式
    @GPPersistance(key: "com.gpscamera.key.CameraMode", defaultValue: 0)
    static var cameraModeInt: Int
    var cameraMode: CameraMode {
        set {
            CameraVC.cameraModeInt = newValue.rawValue
            switch newValue {
            case .photo:
                topView.ratioButton.isHidden = false
                bottomView.takePhotoButton.updateState(state: .photoNormal)
            case .video:
                topView.ratioButton.isHidden = true
                bottomView.takePhotoButton.updateState(state: .videoNormal)
                break
            case .report:
                break
            }
            changeCameraModeAndFrame()
        }
        get {
            return CameraMode(rawValue: CameraVC.cameraModeInt) ?? .photo
        }
    }
    
    var cameraKitMode: BMWCameraKitMode {
        get {
            if cameraMode == .video {
                return .video
            } else {
                switch photoRatio {
                case .ratio1x1:
                    return .photo1x1
                case .ratio3x4:
                    return .photo4x3
                case .ratio9x16:
                    return .photo16x9
                case .ratioFull:
                    return .photoFull
                }
            }
        }
    }
    
    // 后置摄像头
    @GPPersistance(key: "com.gpscamera.key.CameraBack", defaultValue: true)
    var isCameraBack: Bool {
        didSet {
            swiftCameraBack()
        }
    }
    
    // 闪光灯模式
    @GPPersistance(key: "com.gpscamera.key.FlashlightMode", defaultValue: 0)
    static var flashlightModeInt: Int
    var flashlightMode: GPFlashMode {
        set {
            CameraVC.flashlightModeInt = newValue.rawValue
            updateFlashLight()
        }
        get {
            return GPFlashMode(rawValue: CameraVC.flashlightModeInt) ?? .off
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        isCurrentVC = true
        updateLatestPhoto()
        tryRestartCamera()
        observeSystemVolum(.add)
        startMonitorOrientation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isCurrentVC = false
        closeCamera()
        observeSystemVolum(.remove)
        stopMonitorOrientation()
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // oss启动配置
        OSSUploadManager.shared.initConfig()

        // 优先处理防作弊模式
        GPCheetManager.handleChineseMode()
        
        GPToViewManager.shared.cameraVC = self
        // 优先检测定位+地址
        GPSGeoManager.shared.startMonitor()
//        // 测试代码，移除数据
//        GPDataCacheManager.shared.clearCacheFolder(cacheType: .GPLocalBusinessData)
        initViews()
        initXHFilterController()
        
        //如果非appstore模式，才显示
        if !CameraVC.isAppStoreMode{
            buildWideAngle()
        }
        
        // 添加倒计时标签和取消按钮
        setupCountdownUI()

        //声音配置
        configureVolume()
        // 初始化相机参数
        cameraMode = cameraMode
        updateFlashLight()
        bottomView.tabBarView.selectMode(cameraMode)
        // 监听通知
        addObserver()
        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
//            self.firstAutoFocusP()
//        }
        
        GPRealTimeAlert.cehckShowSuccessAlert(superView: view, viewController: self, complete: nil)
            
        DispatchQueue.main.asyncAfter(deadline: .now() + 2 ) {
            // 初始化启动配置
            AppConfigManager.shared.fetchConfig()
            // 检测是否需要上传日志
            if OSSUploadManager.shouldUploadLog {
                // 一次冷启动只上传一次日志
                OSSUploadManager.shouldUploadLog = false
                GPLogManager.uploadLogs(isFromFeedback: false)
            }
        }
        
        if LaunchManager.launchTimeCount == 1 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
                // 首次启动检测权限
                self.checkCameraPermission()
                self.checkLocationPermission()
                //add 增加音频权限
               // self.checkRecordPermission()
            }
        }
        
        checkGoToNewApp()
    }
            
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if CameraVC.isAppStoreMode {
            appStoreImage()
        }
        checkCameraPermission()
        checkLocationPermission()
        checkLogoOrShare()
        //add 增加音频权限
       // checkRecordPermission()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.currentWatermarkView?.removeDotLineAnimation()
    }
        
    func initXHFilterController(){

        let location: AVCaptureDevice.Position =  isCameraBack ? .back : .front
        camera = BMWCamera.init(builder: { [weak self] settingProfile in
            guard let self = self else { return }
            settingProfile.containView = self.glView
            settingProfile.position = location
            settingProfile.cameraMode = self.cameraKitMode
            settingProfile.useYUV = true
            settingProfile.cameraInitCompleteBlock = { error, totalTimecost, cameraTimecost in
                // 初始化成功
                LogDebug("camera init succ")
                ZLMainAsync {
                    NotificationCenter.default.post(name: GPNotification.launchFinishNotification, object: nil)
                }
            }
        })
        if camera == nil {
            return
        }

        glView.setInputImageSize(CGSize.init(width: 1000, height: 1000));
        glView.fillMode = .xhImageFillModePreserveAspectRatioAndFill
        glView.setRenderBackingColorWithRed(0, green: 0, blue: 0, alpha: 1)
        
        // 设置当前的分辨率
//        let quality: BMWImageResolutionQuality = XHImageResolutionManager.getCurrentImageResolutionQuality()
        camera?.setImageResolutionQuality(CameraConfig.photoQuolityType)
        camera?.startCapture()

        
        if camera?.cameraEntry.devicePosition == .back {
            camera?.cameraEntry.setStabilitizationMode()
        }
        
//        XHAzimuthInfoManager.shared.backDirection = camera?.cameraEntry.devicePosition == .back
        //防抖
        updateDeviceFormat(isLowLight: false)
        //设置产品水印
//        setProductWatermarkInfo(codeDataModel: nil, isSupportSecurityCode: true) { [weak self](waterInfo) in
//            self?.camera?.configureProductWatermarkInfo(waterInfo)
//        }
    }
    
    func updateDeviceFormat(isLowLight: Bool) {
        if camera?.cameraEntry.devicePosition == .back {
            camera?.cameraEntry.setStabilitizationMode()
        }
    }
    
    // 更新相机模式和frame
    func changeCameraModeAndFrame() {
        camera?.change(cameraKitMode)
        updateBGColor()
        updateWatermarkContentViewFrame()
        topView.updatePhotoRatio(ratio: photoRatio, cameraMode: cameraMode)
        takePhotoViewBG.frame = glView.frame
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "hidden"{
            
//            DispatchQueue.main.async {[weak self] in
//                self?.wideAngleListView?.isHidden = !(self?.widgeSliderView?.isHidden ?? false)
//            }
        }else if keyPath == "currZoomFactor"{
            
            DispatchQueue.main.async {[weak self] in
                self?.wideAngleListView?.updateScale(self?.camera?.cameraEntry.currZoomFactor)
//                self?.widgeSliderView?.updateScale(self?.camera?.cameraEntry.currZoomFactor)
                
                if self?.enableShowWideAngleValueTipView == true {
                    self?.wideAngleValueTipView?.updateScale(self?.camera?.cameraEntry.currZoomFactor)
                } else {
                    self?.wideAngleValueTipView?.isHidden = true
                }
            }
        }
    }
    
}

