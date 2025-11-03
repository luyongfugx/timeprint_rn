//
//  LogoSearchGoogleVC+HandleResult.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/17.
//

import Foundation
import WebKit

class GPGoogleLogoProcessResult {
    
    enum LogoType {
        case image
        case url
    }
    
    var logoType: GPGoogleLogoProcessResult.LogoType = .url
    var image: UIImage?
    var url: String?
    
    init(url: String) {
        self.url = url
        self.logoType = .url
    }
    
    init(image: UIImage) {
        self.image = image
        self.logoType = .image
    }
}

extension LogoSearchGoogleVC {
    
    //MARK: -Logo搜索处理
    func processLogo() {
        
        var jsFunc = """
                    function xCameraGetResultImage(start, end) {
                      let wrappers = []
                      if (start && end) {
                        wrappers = Array.from(document.querySelectorAll('div[data-attrid="images universal"]')).slice(start, end)
                      } else {
                        wrappers = Array.from(document.querySelectorAll('div[data-attrid="images universal"]'))
                      }
                      let res = []
                      wrappers.forEach(wrapper => {
                        let img = wrapper.querySelector('img')
                        if (img) {
                          res.push(img.getAttribute('src'))
                        }
                      })
                      return res
                    }
                    """
        
        GPToast.remove()
        processLogoStrategy1(with: jsFunc) { [weak self] logos, errorMsg in
            
            if let logos = logos, logos.count > 0 {
                
                DispatchQueue.main.async { [weak self] in
                    
                    self?.logoModelList = logos
                    self?.reloadCollectionDatas()
                }
            } else {
                // 展示原始web网页，让用户自己长按图片添加
                self?.logoModelList.removeAll()
                self?.reloadCollectionDatas()
            }
        }
        
    }
    
    // 新的策略
    func processLogoStrategy1(with jsFunc: String, finish: (([GPGoogleLogoProcessResult]?, _ errorMsg: String?)->())?) {
        
        webView?.evaluateJavaScript(jsFunc) { [weak self] result, error in
            
            if error == nil {
                
                self?.webView?.evaluateJavaScript("window.xCameraGetResultImage(\'0\',\'40\')") { result, error in
                    
                    if error == nil {
                        
                        if let result = result as? [String] {
                            
                            var logos: [GPGoogleLogoProcessResult] = []
                            
                            result.forEach {
                                
                                if $0.hasPrefix("https") {
                                    logos.append(.init(url: $0))
                                } else {
                                    
                                    if let base64 = $0.components(separatedBy: ",").last, let data = Data.init(base64Encoded: base64, options: .ignoreUnknownCharacters),
                                       let logo = UIImage(data: data), logo.size.width > 5, logo.size.height > 5 {
                                        logos.append(.init(image: logo))
                                    } else {
                                        
                                    }
                                }
                            }
                            
                            finish?(logos, nil)
                        } else {
                            finish?(nil, "result不是string数组")
                        }
                    } else {
                        
                        finish?(nil, error.debugDescription)
                    }
                }
            } else {
                
                finish?(nil, error.debugDescription)
            }
        }
    }
    
    func scroll(com: GPVoidBlock?) {
        
        let webViewHeight = (webView?.height ?? 100)
        webView?.scrollView.setContentOffset(CGPoint(x: 0, y: webViewHeight), animated: false)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            
            self?.webView?.scrollView.setContentOffset(CGPoint(x: 0, y: webViewHeight * 2), animated: false)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                
                self?.webView?.scrollView.setContentOffset(CGPoint(x: 0, y: webViewHeight * 3), animated: false)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                    
                    self?.webView?.scrollView.setContentOffset(CGPoint(x: 0, y: webViewHeight * 4), animated: false)
                    com?()
                }
            }
        }
    }
    
}
