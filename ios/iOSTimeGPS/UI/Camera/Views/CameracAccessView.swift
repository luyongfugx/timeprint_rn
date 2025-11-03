//
//  CameracAccessView.swift
//  iOSTimeGPS
//
//

import UIKit

class CameracAccessView: GPView {
    
    var permissionLab: UILabel!
    var permissionButton: UIButton!

    override func buildUI() {
        super.buildUI()
        
        permissionLab = UILabel(text: "i_allow_camera_now".localized(), textColor: .white, textFont: UIFont.Semibold(16), textAlignment: .center)
        addSubview(self.permissionLab)

        permissionButton = UIButton(title: "i_setting".localized(), titleColor: .white, titleFont: UIFont.Semibold(16), backgroundColor: UIColor.btnprimary_normal, cornerRadius: 5)
        permissionButton.titleLabel?.adjustsFontSizeToFitWidth = true
        permissionButton.addTarget(self, action: #selector(permissionButtonAction), for: .touchUpInside)
        permissionButton.width = 180
        permissionButton.height = 40
        permissionLab.width = GPApp.screenWidth
        permissionLab.height = 58
        addSubview(permissionButton)
        
        permissionLab.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
        }
        permissionButton.snp.makeConstraints { make in
            make.top.equalTo(permissionLab.snp.bottom).offset(30)
            make.width.equalTo(180)
            make.height.equalTo(40)
            make.centerX.bottom.equalToSuperview()
        }
    }
    
    @objc func permissionButtonAction() {
        GPApp.gotoSetting()
    }
    
}
