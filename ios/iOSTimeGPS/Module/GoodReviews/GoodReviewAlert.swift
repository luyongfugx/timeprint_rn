//
//  GoodReviewAlert.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/12/11.
//

import Foundation

protocol GPImageTextAlertDelegate: AnyObject {
    func didClickComplain()
    func didClickDone()
    
}

class GoodReviewAlert: UIViewController {
    
    weak var delegate: GPImageTextAlertDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        view.addSubview(bgView)
        bgView.addSubview(bottomBtn)
        bgView.addSubview(coverImgView)
        bgView.addSubview(descLabel)
        bgView.addSubview(titleLabel)
        bgView.addSubview(closeBtn)
        bgView.addSubview(cancleBtn)
        view.addSubview(topView)
        
        bgView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        cancleBtn.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.bottom.equalTo(-12)
            make.height.equalTo(40)
        }
        bottomBtn.snp.makeConstraints { make in
            make.leading.equalTo(16)
            make.trailing.equalTo(-16)
            make.bottom.equalTo(cancleBtn.snp.top).offset(-12)
            make.height.equalTo(48)
        }
        coverImgView.snp.makeConstraints { make in
            make.leading.equalTo(32)
            make.trailing.equalTo(-32)
            make.bottom.equalTo(bottomBtn.snp.top).offset(-24)
            let height = (198 / 310) * (GPApp.screenWidth - 64) // 图片原始高宽比例为198:310
            make.height.equalTo(height)
        }
        descLabel.snp.makeConstraints { make in
            make.leading.equalTo(20)
            make.trailing.equalTo(-20)
            make.bottom.equalTo(coverImgView.snp.top).offset(-6)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(20)
            make.trailing.equalTo(-20)
            make.bottom.equalTo(descLabel.snp.top).offset(-8)
            make.top.equalTo(26)
        }
        closeBtn.snp.makeConstraints { make in
            make.top.equalTo(16)
            make.trailing.equalTo(-16)
            make.size.equalTo(32)
        }
        topView.snp.makeConstraints { make in
            make.leading.trailing.top.equalToSuperview()
            make.bottom.equalTo(bgView.snp.top).offset(0)
        }
    }
    
    @objc private func doneAction() {
        delegate?.didClickDone()
        ZLMainAsync(after: 0.3) {
            self.view.removeFromSuperview()
        }
    }
    
    @objc private func complainAction() {
        delegate?.didClickComplain()
        ZLMainAsync(after: 0.3) {
            self.view.removeFromSuperview()
        }
    }
    
    private lazy var topView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var bgView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .white
        view.layer.cornerRadius = 8
        view.layer.maskedCorners = CACornerMask(arrayLiteral: .layerMaxXMinYCorner, .layerMinXMinYCorner)
        return view
    }()
    
    private lazy var bottomBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .fromHex("#0061F3")
        button.layer.cornerRadius = 4
        button.setTitle("k_five_star".localized(), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .title_normal_bold
        button.addTarget(self, action: #selector(doneAction), for: .touchUpInside)
        return button
    }()
    
    private lazy var cancleBtn: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .clear
        button.layer.cornerRadius = 4
        button.setTitle("k_want_complain".localized(), for: .normal)
        button.setTitleColor(.fromHex("#777777"), for: .normal)
        button.titleLabel?.font = UIFont.regular(16)
        button.addTarget(self, action: #selector(complainAction), for: .touchUpInside)
        return button
    }()
    
    private lazy var coverImgView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.image = UIImage(named: "five_star")
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        return imageView
    }()
    
    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "k_good_review_des".localized()
        label.textColor = .text_medium
        label.font = .body_normal
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "k_thank_you_use".localized()
        label.textColor = .text_ultrastrong
        label.font = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()
    
    private lazy var closeBtn: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "global_border_close"), for: .normal)
        return button
    }()
}
