//
//  GPWebviewManager.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/17.
//

import Foundation
import WebKit

public class GPWebviewManager {

    static let shared = GPWebviewManager()

    var isSetup: Bool = false

    var stack: [WKWebView] = []
    var specielStack: [WKWebView] = []

    static let scriptMessageName = "gps"

    // 使用的时候，取最上面的那个webview，然后再new一个webview存入stack备用
    var top: WKWebView {
        if stack.count > 0 {
            let webView = stack.removeLast()
            preload()
            return webView
        }

        let webView = WKWebView(frame: .zero, configuration: defaultConfiguration)
        preload()
        return webView
    }

    func preload() {
        isSetup = true
        if stack.count > 0 { return }
        let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue, true, 2000008) { [weak self] (observer, activity) in
            if self?.stack.count ?? 0 > 0 { return }
            let webView = WKWebView(frame: .zero, configuration: self?.defaultConfiguration ?? WKWebViewConfiguration())

            // 加载一个空串，只是为了让这个webview放着备用
            webView.loadHTMLString("", baseURL: nil)
            self?.stack.append(webView)
            CFRunLoopObserverInvalidate(observer)
        }
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, CFRunLoopMode.defaultMode)
    }
    
    // V2.0.5: 一次启动只预加载一次特殊URL，提前把js、css文件下载下来
    func preloadSepcialUrl(url: String) {
        let urlKey = "preloadSepcialUrl_\(url)"
        if UserDefaults.standard.bool(forKey: urlKey) {
            return
        }
        UserDefaults.standard.setValue(true, forKey: urlKey)
        
        let observer = CFRunLoopObserverCreateWithHandler(kCFAllocatorDefault, CFRunLoopActivity.beforeWaiting.rawValue, true, 2000008) { [weak self] (observer, activity) in
            let webView = WKWebView(frame: .zero, configuration: self?.defaultConfiguration ?? WKWebViewConfiguration())
            if let loadUrl = URL(string: url) {
                let request = URLRequest(url: loadUrl)
                webView.load(request)
            }
            self?.specielStack.append(webView)
            CFRunLoopObserverInvalidate(observer)
        }
        CFRunLoopAddObserver(CFRunLoopGetMain(), observer, CFRunLoopMode.defaultMode)
    }

    private let processPool: WKProcessPool = WKProcessPool()

    private var preference: WKPreferences {

        let _preference = WKPreferences.init()
        // 最小字体大小 当将javaScriptEnabled属性设置为NO时，可以看到明显的效果
        _preference.minimumFontSize = 10

        // 设置是否支持javaScript 默认是支持的
        _preference.javaScriptEnabled = true

        // 在iOS上默认为NO，表示是否允许不经过用户交互由javaScript自动打开窗口
        _preference.javaScriptCanOpenWindowsAutomatically = true

        return _preference
    }

    // 自定义的WKScriptMessageHandler 是为了解决内存不释放的问题
//    private var weakScriptMessageDelegate: WeakWebViewScriptMessageDelegate {
//        let _weakWebViewScriptMessageDelegate = WeakWebViewScriptMessageDelegate.init(scriptDelegate: scriptDelegate ?? self)
//        return _weakWebViewScriptMessageDelegate
//    }

    private var wkUController: WKUserContentController {
        // 这个类主要用来做native与JavaScript的交互管理
        let wkUController = WKUserContentController.init()

        // 注册一个name为jsToOcNoPrams的js方法 设置处理接收JS方法的对象
//        wkUController.add(weakScriptMessageDelegate, name: XHWebviewManager.scriptMessageName)

        return wkUController
    }

    private var defaultConfiguration: WKWebViewConfiguration {
        let _defaultConfiguration = WKWebViewConfiguration()
        _defaultConfiguration.mediaTypesRequiringUserActionForPlayback = .all
        _defaultConfiguration.allowsInlineMediaPlayback = true
        _defaultConfiguration.processPool = processPool
        _defaultConfiguration.preferences = preference
        _defaultConfiguration.userContentController = wkUController

        // 是使用h5的视频播放器在线播放, 还是使用原生播放器全屏播放
        _defaultConfiguration.allowsInlineMediaPlayback = true

        // 设置视频是否需要用户手动播放  设置为NO则会允许自动播放
        //        webViewConfig.requiresUserActionForMediaPlayback = true

        // 设置是否允许画中画技术 在特定设备上有效
        _defaultConfiguration.allowsPictureInPictureMediaPlayback = true

        // 设置请求的User-Agent信息中应用程序名称 iOS9后可用
        _defaultConfiguration.applicationNameForUserAgent = GPWebviewManager.scriptMessageName

        // 是否支持记忆读取
        _defaultConfiguration.suppressesIncrementalRendering = true;

        return _defaultConfiguration
    }
}
