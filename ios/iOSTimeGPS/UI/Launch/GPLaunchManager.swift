//
//  GPLaunchManager.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/1/6.
//

class GPLaunchManager {
    static let shared = GPLaunchManager()
    private var hasHandleFinish = false
    var launchTimer: Timer?
    var launchWindow: UIWindow?
    var launchVC: LanuchVC?
    
    func addNewLaunch() {
        // 1、使用新窗口，展示启动页
        let newWindow = UIWindow(frame: UIScreen.main.bounds)
        // 设置根视图控制器
        let viewController = LanuchVC()
        viewController.view.backgroundColor = .white
        newWindow.rootViewController = viewController
        // 设置窗口层级
        newWindow.windowLevel = UIWindow.Level.alert + 1
        // 显示窗口
        newWindow.makeKeyAndVisible()
        launchWindow = newWindow
        launchVC = viewController
        
        // 2、设置1秒超时关闭
        let _minTimer = Timer.init(timeInterval: 1, repeats: false, block: { [weak self](tm) in
            guard let self = self else { return }
            if !self.hasHandleFinish {
                self.handelResult()
            }
        })
        RunLoop.current.add(_minTimer, forMode: RunLoop.Mode.common)
        launchTimer = _minTimer
        
        // 3、监听
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handelResult),
                                               name: GPNotification.launchFinishNotification,
                                               object: nil)
    }
        
    @objc func handelResult() {
        guard !hasHandleFinish else { return }
        hasHandleFinish = true

        launchTimer?.invalidate()
        launchTimer = nil
        
        UIView.animate(withDuration: 0.3, delay: 0.1) {
            self.launchVC?.view.alpha = 0
        } completion: { finish in
            self.launchWindow?.isHidden = true
            self.launchWindow = nil
        }
        
        NotificationCenter.default.removeObserver(self)
    }

}
