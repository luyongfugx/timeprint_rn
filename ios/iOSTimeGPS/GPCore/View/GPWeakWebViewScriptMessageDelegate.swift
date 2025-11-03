//
//  GPWeakWebViewScriptMessageDelegate.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/17.
//

import Foundation
import UIKit
import WebKit

// MARK: - 解决WKWebView内存不释放的问题
class GPWeakWebViewScriptMessageDelegate: NSObject, WKScriptMessageHandler {
    
    //WKScriptMessageHandler 这个协议类专门用来处理JavaScript调用原生OC的方法
    weak var scriptDelegate : AnyObject?
    
    deinit {
//        XHLogDebug("[deinit] - WeakWebViewScriptMessageDelegate")
    }
    
    init(scriptDelegate : AnyObject) {
        super.init()
        self.scriptDelegate = scriptDelegate
    }
    
    
    // MARK: - WKScriptMessageHandler
    //遵循WKScriptMessageHandler协议，必须实现如下方法，然后把方法向外传递
    //通过接收JS传出消息的name进行捕捉的回调方法
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        
        if let delegate = self.scriptDelegate, delegate.responds(to: #selector(userContentController(_:didReceive:)))  {
            delegate.userContentController(userContentController, didReceive: message)
        }
    }
}
