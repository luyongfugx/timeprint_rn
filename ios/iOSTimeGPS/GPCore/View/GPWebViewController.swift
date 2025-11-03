//
//  GPWebViewController.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/17.
//

import UIKit
import WebKit
import SnapKit
import Kingfisher

protocol WebContainer {
    var webView: WKWebView? { get }
}

class GPWebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler, WebContainer {
    
    var linkUrl: String?
    let scriptMessageName = "XCamera"
    
    var webView : WKWebView?
    var progressView : UIProgressView?
    
    var forTXC = false
    var parameters:[String: Any]?
    
    // 分享相关参数
    var shareTitle: String?
    var shareDescription: String?
    var shareIcon: String?
    var shareUrl: String?
    
    // V2.9.105:是否隐藏导航栏
    var isHideNavBar: Bool = false
    
    // V2.9.105: 是否隐藏右上角按钮
    var isHideRightBtn: Bool = false
    
    // V2.9.105: 状态栏的样式
    var statusBarStyle: UIStatusBarStyle = .default
    
    // V2.9.220:标题是否随着网页改变
    var isChangeTitle: Bool = true

    // V2.9.225: 测试
    var startTime: TimeInterval?
    
    /// V2.9.300: 添加, 判断第二次展示web, 给h5 js call back
    var isFirstLoad: Bool = true
    
    // 2.9.330:半屏H5内容的承载view
    var halfScreenContentView: UIView?
    
    // 2.9.330:是不是半屏显示
    var isHalfScreen: Bool = false

    // 2.9.345: webView的背景色
    var webviewBgColor: UIColor = .white
    
    var progressViewTopSpace = GPApp.statusBarAndNavigationBarHeight
    
    var closeBlock: GPVoidBlock?
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }

    deinit {
        closeBlock?()
        webView?.configuration.userContentController.removeScriptMessageHandler(forName: scriptMessageName)
        removeObservers()
        // 2.9.228版本移除，解决H5中localstorage被清空的bug，h5需要使用缓存数据
        // clearWKWebView()
    }
    
    init(urlString: String, parameters: [String: Any]? = nil) {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
        self.linkUrl = urlString
        self.parameters = parameters
        configUIStyle()
    }
    
    init(forTXC urlString:String, parameters:[String:Any]) {
        super.init(nibName: nil, bundle: nil)
        forTXC = true
        modalPresentationStyle = .fullScreen
        self.parameters = parameters
        self.linkUrl = urlString
        configUIStyle()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - 配置UI样式
    private func configUIStyle() {
        // V2.9.105:是否隐藏导航栏和右上角按钮
        let urlParameters = self.linkUrl?.urlParameters2
        if let isHideRightBtn = urlParameters?["app-hide-actions"] as? String, isHideRightBtn == "1" {
            self.isHideRightBtn = true
        }
        
        if let isHideNavBar = urlParameters?["app-transparent-navbar"] as? String, isHideNavBar == "1"{
            self.isHideNavBar = true
        }
        
        if let style = urlParameters?["statusbar-text-color"] as? String, style == "1" {
            self.statusBarStyle = .lightContent
        }

        // V2.9.345：这个逻辑预埋，后续需要用的时候，再打开
//        if let webview_bg_color = urlParameters?["webview-bg-color"] as? String {
//            self.webviewBgColor = UIColor.fromHex(webview_bg_color)
//        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        
        if isFirstLoad {
            isFirstLoad = false
        } else {
            // 原生界面回到webview页面时调用的H5注册的钩子函数，全局通用
            webView?.evaluateJavaScript("NativePageBackToWebview()")
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        buildWebView()
        buildProgressView()
        addObserverForProgressAndTitle()
        
        loadPage()
        
        if let progressViewSupView = progressView?.superview {
           
            progressViewSupView.bringSubviewToFront(progressView!)
        }
    }
    
    // 加载网页
    func loadPage() {
        if var url = URL(string: linkUrl ?? "") {
            if !forTXC {
                /// 以下代码是解决同一个url，切换网络环境不刷新的问题
                /// - Note: url组成部分: protocol://host[:port]/path/[;parameters]/[?query]#fragment
                /// - Authors:BatMan
                /// - Date: 2022-11-16
                /// - Version: 2.9.323
                /// - SeeAlso: [URL组成介绍](https://www.rfc-editor.org/rfc/rfc3986)
                if var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false) {
                    var list = urlComponents.queryItems ?? []
                    list.append(.init(name: "v", value: "\(Int(Date().timeIntervalSince1970))"))
                    urlComponents.queryItems = list
                    if let _url = urlComponents.url {
                        url = _url
                    }
                }
            }

            var request = URLRequest(url: url)
            webView?.load(request)
        } else {
//            UIAlertController.showAlert(title: "", message: "此链接已失效", buttonTitles: ["i_item_close_button".localized()], viewController: self) { (index, alert) in
//                self.popOrDismissViewController()
//            }
        }
    }
        
    func buildWebView() {

        // V2.9.245【安俊】
        self.webView = GPWebviewManager.shared.top
        // 自定义的WKScriptMessageHandler 是为了解决内存不释放的问题
        let weakScriptMessageDelegate = GPWeakWebViewScriptMessageDelegate.init(scriptDelegate: self)
        self.webView?.configuration.userContentController.add(weakScriptMessageDelegate, name: GPWebviewManager.scriptMessageName)

        // V2.9.345：这个逻辑预埋，后续需要用的时候，再打开
//        // V2.9.345：比如H5是红色，就会有一个先白后红的效果，加这个逻辑是为了让整个页面的背景色不出现白色闪屏的效果，让整体色调看起来更协调【安俊】
//        self.webView?.isOpaque = false // 不设置这个，背景色始终为白色
//        self.webView?.backgroundColor = webviewBgColor

        self.webView?.uiDelegate = self // UI代理
        self.webView?.navigationDelegate = self  // 导航代理
        // 是否允许手势左滑返回上一级, 类似导航控制的左滑返回
        self.webView?.allowsBackForwardNavigationGestures = true;
        
        //        let y = self.isHideNavigationBar == true ? statusBarHeight :  statusBarAndNavigationBarHeight
        //        self.webView?.scrollView.contentInset = UIEdgeInsetsMake(y, 0, tabBarBottomHeight, 0)
        
        // 2.9.330:封装半屏的vc
        // self.view.addSubview(self.webView!)
        if isHalfScreen == true, let tempView = self.halfScreenContentView {
            tempView.addSubview(self.webView!)
        } else {
            self.view.addSubview(self.webView!)
        }
        
        // 解决webView不能全屏展示的bug
        if #available(iOS 11.0, *) {
            self.webView?.scrollView.contentInsetAdjustmentBehavior = .never
        }
        
        // 2.9.330:封装半屏的vc
        if isHalfScreen == true, let _ = self.halfScreenContentView {
            self.webView?.snp.makeConstraints({ (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(0)
            })
        } else {
            if self.isHideNavBar {
                self.webView?.snp.makeConstraints({ (make) in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalTo(0)
                })
            } else {
                self.webView?.snp.makeConstraints({ (make) in
                    make.left.right.bottom.equalToSuperview()
                    make.top.equalTo(GPApp.statusBarAndNavigationBarHeight)
                })
            }
        }
        
        if forTXC == false {
            webView?.evaluateJavaScript("navigator.userAgent") { [weak self](result, error) in
                if let ua = result as? String {
                    self?.webView?.customUserAgent = ua + " GPS/\(GPApp.version)"
                }
            }
            
            // V2.9.105版本，注入全局参数
            let userDict: [String: Any] = ["userId": "", // XHUserManager.shared.userModel.userId,
                                           "nickname": "", //XHUserManager.shared.userModel.nickname,
                                           "headimgurl": "", //XHUserManager.shared.userModel.headimgurl,
                                           "mobile": "", // XHUserManager.shared.userModel.mobile,
                                           "isTry": false] //XHUserManager.shared.isTryAccount]
            let userStr = GPJson.dictionaryToJsonString(userDict)
            webView?.evaluateJavaScript("window.APP_USER=\'\(userStr)\'", completionHandler: { (result, error) in
//                LogDebug("[H5调试] - [调用JS的函数后的回调] - \(String(describing: result)) - error:[\(String(describing: error))]")
            })
            
            let deviceStr = UUID.init()
            webView?.evaluateJavaScript("window.APP_DEVICE_ID=\'\(deviceStr)\'", completionHandler: { (result, error) in
//                LogDebug("[H5调试] - [调用JS的函数后的回调] - \(String(describing: result)) - error:[\(String(describing: error))]")
            })
        }
    }
    
    // MARK: - 构建进度条
    private func buildProgressView() {
        
        progressView = UIProgressView(progressViewStyle: .bar)
        progressView?.frame = CGRect.init(x: 0, y: progressViewTopSpace , width: GPApp.screenWidth, height: 1)
        progressView?.progressTintColor = UIColor.button_blue
        progressView?.trackTintColor = UIColor.clear
        
        if isHalfScreen {
            halfScreenContentView?.addSubview(progressView!)
        } else {
            
            view.addSubview(progressView!)
        }
        
        // 2.9.220:调小进度条的高度
        progressView?.transform = CGAffineTransform(scaleX: 1, y: 0.5)
    }
    
    // MARK: - 添加进度和标题的观察者
    private func addObserverForProgressAndTitle() {
        //添加监测网页加载进度的观察者
        webView?.addObserver(self, forKeyPath: "estimatedProgress", options: .new, context: nil)
        //添加监测网页标题的观察者
        webView?.addObserver(self, forKeyPath: "title", options: .new, context: nil)
    }
    
    // MARK: -  移除观察者
    private func removeObservers() {
        webView?.removeObserver(self, forKeyPath:"estimatedProgress")
        webView?.removeObserver(self, forKeyPath:"title")
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if keyPath == "estimatedProgress" {
            
            progressView?.setProgress(Float(webView?.estimatedProgress ?? 0.0), animated: true)
            if progressView?.progress == 1{
                progressView?.isHidden = true
            }else{
                progressView?.isHidden = false
            }
            
        } else if keyPath == "title" {
            updateTitle(webView?.title)
        } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    // V2.9.220:更新标题
    func updateTitle(_ newTitle: String?) {
        
        if let newTitle = newTitle, newTitle.count > 0, isChangeTitle == true {
            self.title = newTitle
            self.navigationItem.title = newTitle
        }
    }
    
    // MARK: - WKScriptMessageHandler
    //被自定义的WKScriptMessageHandler在回调方法里通过代理回调回来，绕了一圈就是为了解决内存不释放的问题
    //通过接收JS传出消息的name进行捕捉的回调方法
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "GPS" {
//            if let dic = message.body as? Dictionary<String, Any>{
//                XHJavaScriptManager.shared.receiveScriptMessage(dic, self.webView, delegate: self, viewController: self)
//            }
        }
    }
    
    // MARK: - WKNavigationDelegate
    
    /*
     WKNavigationDelegate主要处理一些跳转、加载处理操作，WKUIDelegate主要处理JS脚本，确认框，警告框等
     */
    // 页面开始加载
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        startTime = Date().timeIntervalSince1970
    }
    
    // 页面加载失败时调用
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        
        self.progressView?.setProgress(0.0, animated: false)
        
        let userInfo = (error as NSError).userInfo
        if let urlStr = userInfo["NSErrorFailingURLStringKey"] as? String, urlStr.contains("//itunes.apple.com/") {
            return
        }
        
        // 1.0.95：处理飞书问卷调查多次点击底部技术支持，弹出加载失败弹框的情况
        if let urlStr = userInfo["NSErrorFailingURLStringKey"] as? String, urlStr.contains("feishu.cn/") {
            return
        }
        
        self.showNetErrorRetryView()
    }
    
    // 当内容开始返回时调用，已开始加载页面，可以在这一步向view中添加一个过渡动画
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        
    }
    
    // 页面已全部加载，可以在这一步把过渡动画去掉
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
//        self.webView?.hideNetworkErrorTip()
        updateTitle(webView.title)
        //这种方式经web端确认不再使用
//        getShareData()

        let responseTime = Date().timeIntervalSince1970
//        LogDebug("[H5调试] - [H5优化调试] - webview响应时间(单位秒)：\(responseTime - (startTime ?? 0))")
    }
    
    //提交发生错误时调用
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.progressView?.setProgress(0.0, animated: false)
    }
    
    // 接收到服务器跳转请求即服务重定向时之后调用
    func webView(_ webView: WKWebView, didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!) {
        
    }
    
    // 根据WebView对于即将跳转的HTTP请求头信息和相关信息来决定是否跳转
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
                
        // 在这里添加您的逻辑代码
        let url = navigationAction.request.url
        let urlString = url?.absoluteString ?? ""
        if urlString.contains("//itunes.apple.com/"),let url = url{
//            GPJump.jump(url: url, completionHandler: nil)
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }
        
        if urlString.contains("weixin://"),let url = url {
//            BCJump.jump(url: url, completionHandler: nil)
            decisionHandler(WKNavigationActionPolicy.cancel)
            return
        }
        
        decisionHandler(WKNavigationActionPolicy.allow)
    }
    
    // 根据客户端受到的服务器响应头以及response相关信息来决定是否可以跳转
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        
        decisionHandler(.allow);
    }
    
    //进程被终止时调用
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
//        XHLogDebug("webViewWebContentProcessDidTerminate")
        webView.reload()
    }
    
    
    // MARK: - WKUIDelegate
    /**
     *  web界面中有弹出警告框时调用
     *
     *  @param webView           实现该代理的webview
     *  @param message           警告框中的内容
     *  @param completionHandler 警告框消失调用
     */
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
//        UIAlertController.showAlert(title: nil, message: message, buttonTitles: ["确认"], viewController: self) { (index, alert) in
//            completionHandler()
//        }
    }
    
    // 确认框
    //JavaScript调用confirm方法后回调的方法 confirm是js中的确定框，需要在block中把用户选择的情况传递进去
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        
//        //  js 里面的alert实现，如果不实现，网页的alert函数无效
//        UIAlertController.showAlert(title: nil, message: message, buttonTitles: ["确认", "i_cancel".localized()], viewController: self) { (index, alert) in
//            completionHandler(index == 0)
//        }
    }
    
    // 输入框
    //JavaScript调用prompt方法后回调的方法 prompt是js中的输入框 需要在block中把用户输入的信息传入
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        
        // 客户端不处理程序
        completionHandler("Client Not handler");
    }
    
    // 页面是弹出窗口 _blank 处理 // 3.0.5：修复点击“联系客服”去留言无法正常跳转的问题
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        
//        XHLogDebug("页面是弹出窗口 _blank处理-[网页调试]")
        let isMainFrame = navigationAction.targetFrame?.isMainFrame ?? false
        if isMainFrame == false {
            webView.load(navigationAction.request)
        }
        return nil
    }
    
    private func clearWKWebView() {
        let websiteDataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
        let dateFrom = NSDate.init(timeIntervalSince1970: 0)
        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: dateFrom as Date) {
            
        }
    }
    
    /*
     //解决第一次进入的cookie丢失问题
     - (NSString *)readCurrentCookieWithDomain:(NSString *)domainStr {
     
     NSHTTPCookieStorage*cookieJar = [NSHTTPCookieStorage sharedHTTPCookieStorage];
     NSMutableString * cookieString = [[NSMutableString alloc]init];
     for (NSHTTPCookie*cookie in [cookieJar cookies]) {
     [cookieString appendFormat:@"%@=%@;",cookie.name,cookie.value];
     }
     
     //删除最后一个“;”
     if ([cookieString hasSuffix:@";"]) {
     [cookieString deleteCharactersInRange:NSMakeRange(cookieString.length - 1, 1)];
     }
     return cookieString;
     }
     */
    
    // 展示重试按钮的时候，一定需要有导航栏，用来让用户关闭（事实上，该VC的fakeNavBar一直都在，只是webview会根据isHideNavBar的值，决定要不要盖住fakeNavBar）【安俊】
    func showNetErrorRetryView() {
        
        // 2.9.330
        // if self.isHideNavBar {
        if self.isHideNavBar, self.isHalfScreen == false {
            self.webView?.snp.remakeConstraints({ (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(GPApp.statusBarAndNavigationBarHeight)
            })
        }
        
//        _ = self.webView?.showNetworkErrorTip { [weak self] in
//            
//            self?.loadPage()
//            if self?.isHideNavBar == true, self?.isHalfScreen == false {
//                self?.webView?.snp.remakeConstraints({ (make) in
//                    make.left.right.bottom.equalToSuperview()
//                    make.top.equalTo(0)
//                })
//            }
//        }
    }
    
}
