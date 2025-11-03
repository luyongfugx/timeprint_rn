//
//  WatermarkMultiLogoEditCell.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/6.
//

import UIKit

class WatermarkMultiLogoEditCell: GPTableviewCell {
    
    var onSwitchValueDidChanged: ((_ isOn: Bool) -> Void)?
    
    private lazy var logoSwitch: UISwitch = {
        let logoSwitch = UISwitch()
        logoSwitch.addTarget(self, action: #selector(switchValueDidChanged(_:)), for: .valueChanged)
        return logoSwitch
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .text_ultrastrong
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    private lazy var content: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.cornerRadius = 4
        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderWidth = 0.5
        imageView.layer.borderColor = UIColor.border_medium.cgColor
        return imageView
    }()
    
    private lazy var indicator: UIImageView = {
        return UIImageView(image: .init(named: "arrow_right_gray"))
    }()
    
    private lazy var addLogoBtn: GPButton = {
        let button = GPButton(frame: .zero, style: .imageLeftTextRight(2, .init(named: "global_fill_add_28"), .init(title: "image", font: .systemFont(ofSize: 16, weight: .medium), titleColor: .text_highlight)))
        button.isUserInteractionEnabled = false
        return button
    }()
    
    override func buildUI() {
        super.buildUI()
        
        let switch_x = 20.0 - (logoSwitch.viewFrameWidth - 40.0) / 2.0
        
        contentView.addSubview(logoSwitch)
        
        logoSwitch.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(switch_x)
        }
        
        let scaleX: CGFloat = 40.0 / logoSwitch.viewFrameWidth
        let scaleY: CGFloat = 25.0 / logoSwitch.viewFrameHeight
        logoSwitch.transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(content)
        contentView.addSubview(indicator)
        contentView.addSubview(addLogoBtn)
        
        let switch_w: CGFloat = 40.0
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(switch_x + switch_w + 12)
            make.centerY.equalToSuperview()
        }
        
        indicator.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }
        
        content.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(indicator.snp.left).offset(-8)
            make.size.equalTo(44)
        }
        
        addLogoBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }
        
        indicator.isHidden = true
        content.isHidden = true
    }
    
    func loadLogoItem(_ logoItem: WatermarkLogoOneItem?, title: String) {
        guard let logoItem = logoItem else { return }
        logoSwitch.isOn = logoItem.isOpen == true
        titleLabel.text = title
        titleLabel.textColor = logoSwitch.isOn ? .text_ultrastrong : .text_weak
        
        if let logoURL = logoItem.logoPath, !logoURL.isEmpty {
            addLogoBtn.isHidden = true
            indicator.isHidden = false
            content.isHidden = false
            self.content.image = logoItem.getLogoImage()
        } else {
            addLogoBtn.isHidden = false
            indicator.isHidden = true
            content.isHidden = true
        }
    }
}

@objc
private extension WatermarkMultiLogoEditCell {
    
    func switchValueDidChanged(_ sender: UISwitch) {
        onSwitchValueDidChanged?(sender.isOn)
    }
}
