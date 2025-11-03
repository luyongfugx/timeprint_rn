//
//  LocationGoogleMapVC.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/12/13.
//

import Foundation


import Foundation
import UIKit
import WebKit

class LocationGoogleMapVC: GPWebViewController, UIGestureRecognizerDelegate {
    
    static func show(completeBlock: ((UIImage)->())?) {
//        let url = LogoSearchGoogleVC.getSearchUrl("")
        let vc = LogoSearchGoogleVC(urlString: "", parameters: nil)
        vc.completeBlock = completeBlock
        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        GPApp.topViewController?.present(nav, animated: true)
    }
    
    private lazy var backBtn: GPButton = {
        let button = GPButton.init(frame: .init(x: 0, y: 0, width: 44, height: 44), fontSize: 20, iconType: .btn_back)
        button.setTitleColor(.text_black_color, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        return button
    }()
    
    private lazy var searchBar: GPSearchBar = {
        let searchB = GPSearchBar()
        searchB.backgroundColor = UIColor.fromHex("#EBEBEB")
        searchB.setStartPlaceHolderX(28, clearRight: 24)
        searchB.updateTintColor(UIColor.fromHex("#0093FF"))
        searchB.updateFont(font: UIFont.systemFont(ofSize: 16))
        searchB.updateKeyboardType(keybordType: .asciiCapable)
        let textField = searchB.getTextField()
        textField.textAlignment = .center
        textField.textColor = .text_black_color
        searchB.showOrNotShowSearch(shouldShow: false)
        searchB.searchPlaceholder = "k_search_your_company".localized()
    
        return searchB
    }()
    
    private lazy var searchBtn: GPButton = {
        let button = GPButton()
        button.setTitle("k_search".localized(), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(.button_blue, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(searchAction), for: .touchUpInside)
        return button
    }()
    
    var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 0, right: 0)
        collectionView.backgroundColor = .white
        collectionView.keyboardDismissMode = .onDrag
        collectionView.alwaysBounceVertical = true
        collectionView.register(GPGoogleSearchLogoCell.self, forCellWithReuseIdentifier: "GPGoogleSearchLogoCell")
        return collectionView
    }()
    
    var longPress: UILongPressGestureRecognizer?
    private var isInLongPress: Bool = false
    private var currentLoadingUrl: String?
    var completeBlock: ((UIImage)->())?
    var logoModelList: [GPGoogleLogoProcessResult] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        buildUIView()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            // delay
            self.searchBar.searchTextField.becomeFirstResponder()
        }
    }
    
    func buildUIView() {
        self.navigationController?.navigationBar.isHidden = true
        view.backgroundColor = .white
                
        view.addSubview(backBtn)
        backBtn.snp.makeConstraints { make in
            make.left.equalTo(6)
            make.width.height.equalTo(44)
            make.top.equalTo(GPApp.statusBarHeight)
        }
        
        view.addSubview(searchBtn)
        let searchText = searchBtn.titleLabel?.text ?? ""
        let searchWidth = searchText.size(WithFont: .systemFont(ofSize: 16), ConstrainedToWidth: GPApp.screenWidth).width
        searchBtn.snp.makeConstraints { make in
            make.right.equalTo(-12)
            make.width.equalTo(searchWidth + 12)
            make.height.equalTo(44)
            make.centerY.equalTo(backBtn.snp.centerY)
        }
        
        view.addSubview(searchBar)
        searchBar.layerCornerRadius = 18
        searchBar.snp.makeConstraints { make in
            make.right.equalTo(searchBtn.snp.left).offset(-6)
            make.left.equalTo(backBtn.snp.right).offset(2)
            make.height.equalTo(36)
            make.centerY.equalTo(backBtn.snp.centerY)
        }
        searchBar.didSearch = { [weak self] text in
            self?.searchAction()
        }
        
        view.addSubview(collectionView)
//        collectionView.dataSource = self
//        collectionView.delegate = self
        collectionView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(GPApp.statusBarAndNavigationBarHeight+1)
        }
    }
    
    override func buildWebView() {
        super.buildWebView()
        
        let js1 = "document.documentElement.style.webkitTouchCallout='none';"
        let js2 = "document.documentElement.style.webkitUserSelect='none';"
        
        let noneSelectScript = WKUserScript.init(source: "\(js1)\(js2)", injectionTime: WKUserScriptInjectionTime.atDocumentEnd, forMainFrameOnly: false)
        
        webView?.configuration.userContentController.addUserScript(noneSelectScript)
        webView?.backgroundColor = .white
        let longPress = UILongPressGestureRecognizer.init(target: self, action: #selector(handleLongPress(_ :)))
        longPress.minimumPressDuration = 0.45;
        longPress.delegate = self
        webView?.addGestureRecognizer(longPress)
        self.longPress = longPress
    }
    
    // MARK: - 禁用web本身的长按手势
    override func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        super.webView(webView, didFinish: navigation)
        
        webView.scrollView.gestureRecognizers?.forEach({
            
            if let longGes = $0 as? UILongPressGestureRecognizer, longGes != longPress {
                longGes.isEnabled = false
            }
        })
        
        webView.scrollView.subviews.forEach {
            $0.gestureRecognizers?.forEach({ ges in
                (ges as? UILongPressGestureRecognizer)?.isEnabled = false
                ges.require(toFail: longPress!)
            })
        }
        
//        scroll { [weak self] in
//            
//            //self?.webView?.scrollView.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
//            //self?.processLogo()
//        }
    }
    
    func reloadCollectionDatas() {
        if logoModelList.count > 0 {
            self.collectionView.isHidden = false
            self.collectionView.reloadData()
        } else {
            self.collectionView.isHidden = true
        }
    }
}

extension LocationGoogleMapVC {
    //MARK:-长按事件处理
    @objc func handleLongPress(_ longGes: UILongPressGestureRecognizer){
        
        defer {
            switch longGes.state {
            case .began, .possible, .changed: break
            case .ended, .failed, .cancelled: do {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.isInLongPress = false
                }
            }
            @unknown default: do {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    self.isInLongPress = false
                }
            }
            }
        }
        isInLongPress = true
        
        if longGes.state != .began{return}
        
        let touchPoint = longGes.location(in: webView)
        
        //        tagName
        // 获取长按位置对应的图片url的JS代码
        let imgJS = "document.elementFromPoint(\(touchPoint.x),\(touchPoint.y)).tagName"
        
        // 执行对应的JS代码 获取url
        webView?.evaluateJavaScript(imgJS) {[weak self] (resourcesType, error) in
            
            guard let imgTypeStr = resourcesType as? String else{return}
            if imgTypeStr != "IMG"{return}
            
            let getImgUrlJs  = "document.elementFromPoint(\(touchPoint.x),\(touchPoint.y)).src"
            
            self?.webView?.evaluateJavaScript(getImgUrlJs) {[weak self] (resourcesUrl, error1) in
                
                guard let imgUrlStr = resourcesUrl as? String else {return}
                guard let url = URL.init(string: imgUrlStr) else {return}
                self?.currentLoadingUrl = imgUrlStr
                
                DispatchQueue.global().async {
                    
                    guard let data = try? Data.init(contentsOf: url) else {
                        return
                    }
                    
                    guard self?.currentLoadingUrl == imgUrlStr, let img = UIImage.init(data: data) else {
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self?.handleAlert(with: img)
                    }
                }
            }
        }
    }
    
    func handleAlert(with img: UIImage?){
        
        guard let img = img else {
            return
        }
        self.completeBlock?(img)
        self.dismiss(animated: true)

    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

extension LocationGoogleMapVC {
    
    @objc func backAction() {
        GPToast.remove()
        self.navigationController?.dismiss(animated: true)
    }
    
    @objc func searchAction() {
        let searchText = searchBar.getSearchText() ?? ""
        if !searchText.isEmpty {
            let seachUrl = LogoSearchGoogleVC.getSearchUrl(searchText)
            self.linkUrl = seachUrl
            GPToast.showLoading(text: "k_loading".localized())
            self.loadPage()
        }
    }
    
    static func getSearchUrl(_ keyword: String) -> String {
        let googleUrl = "https://www.google.com/search?tbm=isch&q="
        let finalKeyWord = keyword.contains("logo") ? keyword : "\(keyword) logo"
        let url = googleUrl + finalKeyWord.urlEncode()
        return url
    }
        
}
