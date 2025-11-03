//
//  WatermarkPreload.swift
//  XCamera_global
//
//  Copyright © 2025 xhey. All rights reserved.
//

// 水印预加载器
class WatermarkPreloader {
    
    static let shared = WatermarkPreloader()
    // MARK: - Properties
    private let fileManager = FileManager.default
    private let cacheDirectory: String
    private let serialQueue = DispatchQueue(label: "com.watermark.preloader.queue")
    private var currentIndex = 0
    private var watermarkUIModelList: [WatermarkCoverModel] = []
    static let prefixKey = "cover_key_"
    var hasLoad = false


    // MARK: - Initialization
    init() {
        self.cacheDirectory = GPSandbox.shared.libraryDirectory + "/" + "WatermarkPreviews6"
        
        GPFileManager.createDirectory(at: self.cacheDirectory)
        
        WatermarkManager.shared.watermarkCategoryList.forEach { category in
            watermarkUIModelList.append(contentsOf: category.list ?? [])
        }
        
    }
    
    func preload() {
        if hasLoad {
            return
        }
        hasLoad = true
        startPreloading()
    }
    
    // MARK: - Public Methods
    private func startPreloading() {
                
        guard currentIndex < watermarkUIModelList.count else {
            print("All watermarks preloaded")
            return
        }
        
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.preloadNextWatermark()
        }
    }
    
    // MARK: - Private Methods
    private func preloadNextWatermark() {
        guard currentIndex < watermarkUIModelList.count else { return }
        
        let index = currentIndex
        let watermarkUIModel = watermarkUIModelList[index]
        let watermarkClassID: String = watermarkUIModel.watermarkModel?.id ?? ""
        let filename = "/\(watermarkClassID).png"
        let filePath = cacheDirectory + filename
        
        // 检查是否已存在
        if fileManager.fileExists(atPath: filePath) {
            serialQueue.async {
                self.currentIndex += 1
                self.startPreloading()
            }
            return
        }
        
        guard let watermarkModel = watermarkUIModel.watermarkModel else {
            return
        }
                
        // 在主线程创建视图
        DispatchQueue.main.async {
            
            let currentWatermarkView = BaseWatermark.generateWatermarkView(watermarkModel: watermarkModel, isCover: true, frame: .init(x: 0, y: 0, width: GPApp.screenWidth, height: GPApp.screenWidth/0.75))
            currentWatermarkView.alpha = 0
            UIApplication.shared.windows.first?.addSubview(currentWatermarkView)
            currentWatermarkView.updateUI()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                WatermarkPreloader.saveWatermarkCoverRatio(ratio: currentWatermarkView.animationView.width/currentWatermarkView.animationView.height, wmID: watermarkClassID)
                self.captureAndSave(view: currentWatermarkView.animationView, filePath: URL(string: filePath)!, className: filename, wmID: watermarkClassID)
                currentWatermarkView.removeFromSuperview()
            }
                            
        }
                    
    }
    
    private func captureAndSave(view: UIView, filePath: URL, className: String, wmID: String) {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        let image = renderer.image { context in
            view.layer.render(in: context.cgContext)
        }
        
        DispatchQueue.global(qos: .utility).async {
            if let data = image.pngData() {
                do {
                    let isSuccess = FileManager.default.createFile(atPath: filePath.path, contents: data, attributes: nil)
                    print("水印预加载✅ Saved \(className) preview，filePath：\(filePath)")
                    ZLMainAsync {
                        NotificationCenter.default.post(name: GPNotification.loadCoverSuccessNotification, object: nil, userInfo: ["wmID": wmID])
                    }
                } catch {
                    print("水印预加载❌ Failed to save \(className): \(error)")
                }
            }
            
            self.serialQueue.async {
                self.currentIndex += 1
                self.startPreloading()
            }
        }
    }
    
    // MARK: - Utility Methods
    func getWatermarkImage(for wmID: String) -> UIImage? {
        let filename = "/\(wmID).png"
        let filePath = cacheDirectory + filename
        print("水印预加载 获取目录 filePath：\(filePath)")
        return UIImage(contentsOfFile: filePath)
    }
    
    static let wmCoverPrefixKey = "wmCoverPrefixKey_"
    
    static func saveWatermarkCoverRatio(ratio: CGFloat, wmID: String) {
        let key = WatermarkPreloader.wmCoverPrefixKey + wmID
        UserDefaults.standard.set(ratio, forKey: key)
    }
    
    static func watermarkCoverRatio(wmID: String) -> CGFloat {
        let key = WatermarkPreloader.wmCoverPrefixKey + wmID
        var value = UserDefaults.standard.double(forKey: key)
        if value == 0 {
            value = 2.4
        }
        return value
    }
    
}
