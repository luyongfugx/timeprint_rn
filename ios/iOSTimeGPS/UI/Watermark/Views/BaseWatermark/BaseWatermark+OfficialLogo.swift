//
//  BaseWatermark+OfficialLogo.swift
//  iOSTimeGPS
//
//  Created by mac on 2025/6/8.
//

let OffcialLogoViewTag = 1009

class OffcialLogoView: GPView {
    
    private lazy var contentView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .boldSystemFont(ofSize: 12)
       // label.textColor = UIColor(red: 0.95, green: 0.96, blue: 1.0, alpha: 0.92)
        label.textColor =  UIColor.theme_yellow_color
       // label.textColor = UIColor(red: 0.95, green: 0.96, blue: 1.0, alpha: 0)
        label.text = "Timeprint"
        label.textAlignment = .right  // 右对齐
        label.lineBreakMode = .byWordWrapping
        
        // 阴影效果（可调整 offset 使阴影朝左下方）
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 2.0
        label.layer.shadowOpacity = 0.5
        label.layer.shadowOffset = CGSize(width: 1, height: 1)
        label.layer.masksToBounds = false
        
        return label
    }()

    lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 9)
        label.textColor = UIColor(red: 0.92, green: 0.93, blue: 0.95, alpha: 0.85)
        label.text = "k_brand_real_time".localized()
        label.textAlignment = .right  // 右对齐
        label.lineBreakMode = .byWordWrapping
        
        // 阴影效果
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 1.5
        label.layer.shadowOpacity = 0.5
        label.layer.shadowOffset = CGSize(width: 1, height: 1)
        label.layer.masksToBounds = false
        
        return label
    }()
    
    override func buildUI() {
        super.buildUI()
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)        
        // 添加子控件
        [titleLabel, subTitleLabel].forEach({ contentView.addSubview($0) })
                
        // 布局 titleLabel 和 subTitleLabel
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(3)
        }
       
        subTitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(1)
            make.bottom.equalToSuperview().inset(2)
            make.leading.trailing.equalToSuperview().inset(3)
        }
        //设置渐变
       
        
        // 布局 contentView（自适应大小，右上角）
        contentView.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(12)
            make.top.equalToSuperview().inset(4)
            //make.bottom.equalToSuperview().inset(11)
        }
        //设置渐变
        //titleLabel.setGradientText(colors: [ .yellow,.white])
        //subTitleLabel.setGradientText(colors: [.white,.yellow])
    }

    
    
}

// MARK: - Placement API for OffcialLogoView
extension OffcialLogoView {
    /// 右上角（默认）
    func placeTopRight() {
        contentView.snp.remakeConstraints { make in
            make.right.equalToSuperview().inset(12)
            make.top.equalToSuperview().inset(4)
        }
        setNeedsLayout()
        layoutIfNeeded()
    }

    /// 右下角（避让右上角 100x100 被占用的情况）
    func placeBottomRight() {
        contentView.snp.remakeConstraints { make in
            make.right.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(11)
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
}
