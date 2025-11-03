//
//  GPRealTimeAlert.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/13.
//

import Foundation
import UIKit
import Kingfisher

class GPRealTimeAlert: GPBaseAlert {
    
    @GPPersistance(key: "com.gpscamera.key.realtimeAlert", defaultValue: false)
    static var hasShowRealtimeAlert: Bool
    
    class func cehckShowSuccessAlert(superView: UIView, viewController: UIViewController, complete: GPCustomAlertHandler?) {
        
        if GPCheetManager.isCheetMode {
            // 中国模式不展示该弹窗
            return
        }
        
        guard !GPRealTimeAlert.hasShowRealtimeAlert else {
            return
        }
        GPRealTimeAlert.hasShowRealtimeAlert = true
        
        let alert = GPRealTimeAlert(viewController: viewController, complete: complete)
        superView.addSubview(alert)
        alert.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }
        alert.show()
    }
    
    deinit {
        LogDebug("deinit - GPRealTimeAlertView")
    }
    
    init(viewController: UIViewController, complete: GPCustomAlertHandler?) {
        super.init(frame: CGRect.zero)
        self.completionHandler = complete
        self.viewController = viewController
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func buildUI() {
        super.buildUI()
        
        contentView.layerCornerRadius = 10
        contentView.snp.remakeConstraints({ (make) in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(10)
            make.height.equalTo((374 + GPApp.tabBarBottomHeight) + 10)
        })
        
        let backGrond = UIImageView(image: UIImage(named: "value_promotion_bg_texture"))
        contentView.addSubview(backGrond)
        backGrond.snp.remakeConstraints({ (make) in
            make.right.top.equalToSuperview()
            make.width.equalTo(192)
            make.height.equalTo(300)
        })
        
        let leftSpace: CGFloat = 35
        let titleLabel = UILabel(text: "k_value_promotion_title".localized(), textColor: .black, textFont: .Semibold(20), textAlignment: .left, numberLines: 0)
        let titleH = titleLabel.sizeThatFits(CGSize(width: GPApp.screenWidth - leftSpace * 2, height: CGFloat.greatestFiniteMagnitude)).height + 2
        contentView.addSubview(titleLabel)
        titleLabel.snp.remakeConstraints({ (make) in
            make.left.equalTo(leftSpace)
            make.right.equalTo(-leftSpace)
            make.height.equalTo(titleH)
            make.top.equalTo(40)
        })
        
        let icon1 = UIImageView(image: UIImage(named: "key_feature_icon_anti_fake_gps"))
        contentView.addSubview(icon1)
        icon1.snp.remakeConstraints({ (make) in
            make.top.equalTo(titleLabel.snp.bottom).offset(40)
            make.width.equalTo(28)
            make.height.equalTo(34)
            make.left.equalTo(leftSpace)
        })

        let descr1 = UILabel(text: "k_key_feature_anti_fake_time".localized(), textColor: .black, textFont: .Semibold(18), textAlignment: .left, numberLines: 0)
        contentView.addSubview(descr1)
        descr1.snp.remakeConstraints({ (make) in
            make.centerY.equalTo(icon1.snp.centerY)
//            make.left.equalTo(icon1.snp.right).offset(16)
            make.left.equalTo(leftSpace)
            make.right.equalTo(-leftSpace)
        })

        let icon2 = UIImageView(image: UIImage(named: "key_feature_icon_anti_fake_gps"))
        contentView.addSubview(icon2)
        icon2.snp.remakeConstraints({ (make) in
            make.top.equalTo(icon1.snp.bottom).offset(30)
            make.width.equalTo(28)
            make.height.equalTo(34)
            make.left.equalTo(leftSpace)
        })

        let descr2 = UILabel(text: "k_key_feature_anti_fake_gps".localized(), textColor: .black, textFont: .Semibold(18), textAlignment: .left, numberLines: 0)
        contentView.addSubview(descr2)
        descr2.snp.remakeConstraints({ (make) in
            make.centerY.equalTo(icon2.snp.centerY)
//            make.left.equalTo(icon2.snp.right).offset(16)
            make.left.equalTo(leftSpace)
            make.right.equalTo(-leftSpace)
        })
        
        let okBtn =  GPPrimaryButton(title: "k_got_it".localized())
        okBtn.addTarget(self, action: #selector(onButtonAction), for: .touchUpInside)
        contentView.addSubview(okBtn)
        okBtn.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(48)
            make.bottom.equalTo(-GPApp.tabBarBottomHeight - 24)
        }
        
        // 下拉手势
        let panContainerGesture = UIPanGestureRecognizer(target: self, action: #selector(contentViewPanGestureAction(_:)))
        contentView.addGestureRecognizer(panContainerGesture)
    }
    
    // 重写基类方法
    @objc override func backgroundViewTapAction() {
        self.hide()
    }
    
    @objc private func onButtonAction() {
        self.hide()
    }
    
    // MARK: - contentView的手势响应的方法
    @objc func contentViewPanGestureAction(_ recognizer: UIPanGestureRecognizer) {
        
        // 往上滑动是负数，往下滑动是正数
        let currentPanY: CGFloat = recognizer.translation(in: contentView).y
        
        if recognizer.state == .began {
            
        } else if recognizer.state == .changed {
            if currentPanY > 0  {
                self.contentView.transform = CGAffineTransform.identity.translatedBy(x: 0, y: currentPanY)
            }
        } else {
            if currentPanY > 150 {
                // 下拉偏移量大于150，就收起
                self.hide()
            } else {
                
                // 回弹
                UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 2.0, options: UIView.AnimationOptions.curveLinear, animations: {[weak self] in
                    
                    self?.contentView.transform = CGAffineTransform.identity
                })
            }
        }
    }
    
}
