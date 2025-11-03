//
//  GPBaseAlert.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/13.
//

import UIKit

typealias GPCustomAlertHandler = (GPBaseAlert) -> ()

class GPBaseAlert: UIView {
    
    @discardableResult
    class func show(superView: UIView, viewController: UIViewController, complete: @escaping GPCustomAlertHandler) -> GPBaseAlert {
        
        let alert = GPBaseAlert.init()
        alert.viewController = viewController
        alert.completionHandler = complete
        superView.addSubview(alert)
        alert.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }
        alert.show()
        
        return alert
    }
    
    var backgroundView: UIView = {
        let view = UIView(backgroundColor: UIColor.black)
        view.alpha = 0.6
        return view
    }()
    
    var contentView: UIView = {
        let view = UIView(backgroundColor: UIColor.white, cornerRadius: 4.0)
        return view
    }()
    
    var completionHandler: GPCustomAlertHandler?
    
    weak var viewController: UIViewController?
    
    deinit {
        //XHLogDebug("[deinit] - GPBaseAlert")
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buildUI() {
        _ = backgroundView.addTapGestureRecognizer(target: self, action: #selector(backgroundViewTapAction))
        self.addSubview(backgroundView)
        backgroundView.snp.makeConstraints { (make) in
            make.top.left.right.bottom.equalToSuperview()
        }
        
        self.addSubview(contentView)
        contentView.snp.makeConstraints({ (make) in
            make.width.equalTo(295)
            make.height.equalTo(352)
            make.centerX.centerY.equalToSuperview()
        })
    }
    
    func show() {
        self.isHidden = false
        UIView.animate(withDuration: 0.2, animations: {
            self.contentView.alpha = 1.0
            self.backgroundView.alpha = 0.6
        }) { _ in
        }
        
    }
    
    func hide() {
        UIView.animate(withDuration: 0.2, animations: {
            self.contentView.alpha = 0
            self.backgroundView.alpha = 0
        }) { (finished) in
            self.isHidden = true
            if let handelr = self.completionHandler {
                handelr(self)
            }
            self.removeFromSuperview()
        }
    }
    
    @objc func backgroundViewTapAction() {
        self.hide()
    }
}
