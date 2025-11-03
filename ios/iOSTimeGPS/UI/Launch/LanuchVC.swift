//
//  LanuchVC.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/11/20.
//

import Foundation
class LanuchVC: UIViewController {
    let bgView = UIView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
//        let takeLabel = UILabel()
//        takeLabel.numberOfLines = 3
//        takeLabel.text = ("i_launch_take".localized())
//        takeLabel.font = UIFont.systemFont(ofSize: 41, weight: .heavy)
//        takeLabel.textColor = .black
//        takeLabel.textAlignment = .center
//        takeLabel.frame = CGRect(x: 0, y: 200, width: view.frame.width, height: 150)
//        view.addSubview(takeLabel)
                
        let logoImageView = UIImageView(image: UIImage(named: "brandView3.png"))
        logoImageView.frame = CGRect(x: (view.frame.width - 180) / 2, y: view.frame.height - 45.3 - 80 - GPApp.tabBarBottomHeight, width: 180, height: 45.3)
        view.addSubview(logoImageView)
    }
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    func createBottomBrandView() {
        
        view.addSubview(bgView)
        
        let label = UILabel()
        label.text = "Timeprint"
        label.font = UIFont.boldSystemFont(ofSize: 36)
        label.textColor = .black
        bgView.addSubview(label)
        
        let logoImageView = UIImageView(image: UIImage(named: "icon80.png"))
        bgView.addSubview(logoImageView)

        logoImageView.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.height.equalTo(56)
        }
        label.snp.makeConstraints { make in
            make.left.equalTo(logoImageView.snp.right).offset(10)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        bgView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(-100)
            make.top.equalTo(logoImageView.snp.top)
            make.right.equalTo(label.snp.right)
            make.left.equalTo(logoImageView.snp.left)

        }
        
    }
}
