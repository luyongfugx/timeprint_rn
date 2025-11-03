//
//  GPNavigateBar.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/1.
//

import Foundation
import UIKit

protocol GPNavigateBarDelegate: AnyObject {
    func clickBack()
}

class GPNavigateBar: GPView {
    
    weak var delegate: GPNavigateBarDelegate?
    
    lazy var backBtn: GPButton = {
        let button = GPButton.init(frame: .init(x: 0, y: 0, width: 44, height: 44), fontSize: 20, iconType: .btn_back)
        button.setTitleColor(.text_black_color, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        return button
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel(text: "", textColor: .text_black_color, textFont: .title_normal_bold, textAlignment: .center)
        return label
    }()
    
    lazy var lineView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .table_line_color
        return view
    }()
    
    deinit {
        LogDebug("GPNavigateBar--deinit")
    }
    
    override func buildUI() {
        super.buildUI()
        backgroundColor = .white
        addSubview(backBtn)
        backBtn.snp.makeConstraints { make in
            make.left.equalTo(4)
            make.width.height.equalTo(44)
            make.top.equalToSuperview()
        }
        
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints({ (make) in
            make.left.equalTo(60)
            make.right.equalTo(-60)
            make.centerY.equalToSuperview()
        })
        
        addSubview(lineView)
        lineView.snp.makeConstraints({ (make) in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        })
    }
    
    @objc
    func backAction() {
        delegate?.clickBack()
    }
    
}
