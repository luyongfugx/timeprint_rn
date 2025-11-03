//
//  GPPhotoShowShareView.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/3.
//

import MessageUI

class GPPhotoShowShareView: UIView {
    
    private var isAnimation = false
    private var contentHeight: CGFloat = 100
    private var shareTypes: [XHPhotoShowShareType] = []
    private var shareCallBack: ((XHPhotoShowShareType)->())?
    private var closeCallBack: (()->())?
    private var contentView: UIView = .init()
    private var bgView: UIView?
    private var fromPlace = ""
    private var shareTitle: String?
    
    @discardableResult
    static func showDefault(
        in superView: UIView,
        shareTitle: String? = nil,
        fromPlace: String,
        closeCallBack: ((()->())?) = nil,
        shareCallBack: ((XHPhotoShowShareType)->())?
    ) -> GPPhotoShowShareView {
        
        var shareTypes: [XHPhotoShowShareType] = GPShareManager.getSupportShareTypes()

        return GPPhotoShowShareView.show(in: superView, shareTitle: shareTitle, fromPlace: fromPlace, shareTypes: shareTypes, closeCallBack: closeCallBack, shareCallBack: shareCallBack)
    }
    
    @discardableResult
    private static func show(
        in superView: UIView,
        shareTitle: String?,
        fromPlace: String,
        shareTypes: [XHPhotoShowShareType],
        closeCallBack: ((()->())?),
        shareCallBack: ((XHPhotoShowShareType)->())?
    ) -> GPPhotoShowShareView {
        let shareView = GPPhotoShowShareView(frame: superView.bounds)
        
        shareView.shareTypes = shareTypes
        shareView.shareCallBack = shareCallBack
        shareView.closeCallBack = closeCallBack
        shareView.fromPlace = fromPlace
        shareView.shareTitle = shareTitle
        shareView.buildUI()
        superView.addSubview(shareView)
        
        shareView.layoutIfNeeded()
        shareView.show(isShow: true)
        
        return shareView
    }
    
    @discardableResult
    func show(isShow: Bool) -> Bool {
        
        if isAnimation {
            return false
        }
        
        isAnimation = true
        contentView.layer.removeAllAnimations()
        
        bgView?.isHidden = !isShow
        let trans: CGAffineTransform = isShow ? .identity : .identity.translatedBy(x: 0, y: contentHeight)
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
            
            self.contentView.transform = trans
        } completion: { _ in
            
            self.isAnimation = false
            
            if !isShow {
                
                self.removeFromSuperview()
            }
        }
        
        return true
    }
    
    func hide() {
        
        show(isShow: false)
    }

    @objc
    private func closeAction() {
        hide()
        closeCallBack?()
    }
    
    @objc
    func bgTapAction() {
        hide()
        closeCallBack?()
    }
    
    @objc
    private func shareButtonAction(_ sender: UIButton) {
        guard let shareType = shareTypes[safe: sender.tag] else {
            return
        }
        shareCallBack?(shareType)
    }
    
    //MARK: -UI
    func buildUI() {
                
        let guideTopSpace: CGFloat = 56
        let guideBottomSpace: CGFloat = 40 + GPApp.tabBarBottomHeight
        
        let shareItemWidth: CGFloat = 74
        let shareItemHeight: CGFloat = 70
        
        let shareItemRowSpace: CGFloat = 20
        let row = (shareTypes.count + 3)/4
        let shareItemTotalHeight = CGFloat(row) * shareItemHeight + CGFloat(row - 1) * shareItemRowSpace
        let centerHeight: CGFloat = 12 * 2 + shareItemTotalHeight
        
        contentHeight = guideTopSpace + centerHeight + guideBottomSpace
        let contentY = GPApp.screenHeight - contentHeight
        
        bgView = UIView(backgroundColor: UIColor.black.withAlphaComponent(0.6))
        addSubview(bgView!)
        bgView?.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
            
        let topGestureView = UIView(backgroundColor: .clear).then {
            
            $0.addTapGestureRecognizer(target: self, action: #selector(bgTapAction))
        }
        addSubview(topGestureView)
        topGestureView.snp.makeConstraints { make in
            make.left.right.top.equalTo(0)
            make.height.equalTo(contentY)
        }
        
        // 1. contentView
        contentView.frame = CGRect(x: 0, y: contentY, width: width, height: height - contentY)
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.top.equalTo(contentY)
            make.left.right.bottom.equalToSuperview()
        }
        
        let shadowView = UIView()
        shadowView.frame = contentView.bounds
        shadowView.backgroundColor = .white
        shadowView.layer.shadowColor = UIColor.black.withAlphaComponent(0.41).cgColor
        shadowView.layer.shadowRadius = 24
        shadowView.layer.shadowOpacity = 1
        shadowView.layer.shadowOffset = .init(width: 0, height: -12)
        shadowView.layer.cornerRadius = 12
        contentView.addSubview(shadowView)
        shadowView.snp.makeConstraints { make in
            make.center.size.equalToSuperview()
        }
        
        let shareTitleText = shareTitle ?? "i_share_to_title".localized()
        let titleLabel = UILabel(text: shareTitleText, textColor: .text_black_color, textFont: .title_small_bold, textAlignment: .center)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(18)
            make.height.equalTo(21)
            make.left.right.equalTo(0)
        }
        
        let closeButton = GPButton.init(frame: .init(x: 0, y: 0, width: 44, height: 44), fontSize: 20, iconType: .btn_close)
        closeButton.setTitleColor(.text_black_color, for: .normal)
        closeButton.addTarget(self, action: #selector(closeAction), for: .touchUpInside)
        contentView.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.trailing.equalTo(-8)
            make.width.height.equalTo(32)
            make.centerY.equalTo(titleLabel.snp.centerY)
        }
        
        var shareLeftSpace: CGFloat = 8
        let shareButtonSpace: CGFloat = (GPApp.screenWidth - 4 * shareItemWidth - 2 * shareLeftSpace) / 5
        shareLeftSpace += shareButtonSpace
        var shareButtonTop = guideTopSpace + 12
        
        for (index, shareType) in shareTypes.enumerated() {
            
            let info = shareType.info
            let shareButton = BCCustomItemsLayoutButton(titleRect: CGRect(x: 0, y: shareItemHeight - 15, width: shareItemWidth, height: 15), imageRect: CGRect(x: (shareItemWidth - 48) * 0.5, y: 0, width: 48, height: 48), title: info.title, titleColor: .text_weak, titleFont: UIFont.regular(12), imageName: info.imageName, textAlignment: .center)
            shareButton.tag = index
            contentView.addSubview(shareButton)
            shareButton.addTarget(self, action: #selector(shareButtonAction(_ :)), for: .touchUpInside)
            
            let column = CGFloat(index % 4)
            let row = CGFloat(index / 4)
            
            let shareButtonX = shareLeftSpace + column * (shareItemWidth + shareButtonSpace)
            let shareButtonY = shareButtonTop  + row * (shareItemHeight + shareItemRowSpace)
            
            shareButton.frame = CGRect(x: shareButtonX, y: shareButtonY, width: shareItemWidth, height: shareItemHeight)
        }

        contentView.transform = .identity.translatedBy(x: 0, y: contentHeight)
    }
    
}
