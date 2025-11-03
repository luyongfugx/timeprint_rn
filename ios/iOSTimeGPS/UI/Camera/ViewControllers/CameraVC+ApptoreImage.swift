//
//  CameraVC+ApptoreImage.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/9/26.
//

import Foundation
import UIKit


extension CameraVC {

    // 修改图片
    func changeAppStoreImage(_ imageName: String) {
        appstoreImagView?.image = UIImage(named: imageName)
    }

    func appStoreImage() {
        
        // 测试代码，上架图
        if appstoreImagView == nil {
                        
            let bgView2 = UIView(frame: .zero)
            self.view.insertSubview(bgView2, aboveSubview: glView)
            bgView2.clipsToBounds = true
            bgView2.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(topView.snp.bottom)
                make.bottom.equalTo(bottomView.snp.top)
            }
            
            let _appstoreImagView = UIImageView(frame: .zero)
            _appstoreImagView.contentMode = .scaleAspectFill
            _appstoreImagView.isHidden = true
            bgView2.addSubview(_appstoreImagView)
            _appstoreImagView.isHidden = false
            _appstoreImagView.image = UIImage(named: "cover6")
            _appstoreImagView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            _appstoreImagView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalTo(topView.snp.bottom)
                make.bottom.equalTo(bottomView.snp.top)
            }
            
            let bgView1 = UIView(frame: .zero)
            bgView1.backgroundColor = .black
            self.view.insertSubview(bgView1, aboveSubview: glView)
            bgView1.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.top.equalToSuperview()
                make.bottom.equalTo(bottomView.snp.top)
            }
            
            let bgView3 = UIView(frame: .zero)
            bgView2.addSubview(bgView3)
            // 黑色蒙层透明度
            bgView3.backgroundColor = .black.withAlphaComponent(0.4)
            bgView3.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            appstoreImagView = _appstoreImagView
        }
        
    }
    
}
