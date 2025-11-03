//
//  FeedbackVC.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/13.
//

import Foundation
import UIKit

class FeedbackVC: GPBaseVC {
    
    class func gotoFeedback() {
        let vc = FeedbackVC()
        GPApp.topViewController?.navigationController?.pushViewController(vc, animated: true)
    }
    
    var bgColor: UIColor = .black.withAlphaComponent(0.5)
    
    lazy var contentTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.placeholderColor = .text_weak
        textView.placeholder = "k_feedback_placeholder".localized()
        textView.textColor = .text_black_color
        textView.spellCheckingType = .no
        textView.autocorrectionType = .no
        textView.smartInsertDeleteType = .no
        return textView
    }()
    
    lazy var contactTextField: UITextField = {
        let textfield =  UITextField(text: "", textColor: .text_black_color, textFont: .systemFont(ofSize: 16), placeholder: "k_enter_email".localized(), placeholderColor: .text_weak, placeholderFont: .systemFont(ofSize: 16))
        textfield.returnKeyType = .next
        textfield.keyboardType = .emailAddress
        textfield.autocapitalizationType = .none
        textfield.autocorrectionType = .no
        // 添加编辑变化监听
        textfield.addTarget(self, action: #selector(emailTextChanged), for: .editingChanged)
        return textfield
    }()
    
    lazy var doneButton: GPButton = {
        let button = GPButton(frame: .zero, style: .imageLeftTextRight(0, nil, .init(title: "i_submit".localized(), font: .boldSystemFont(ofSize: 17), titleColor: .white)))
        button.isEnabled = false
        button.alpha = 0.5
        return button
    }()
    
    // 常见问题视图
    lazy var faqTextView: UITextView = {
        let textView = UITextView()
        textView.isEditable = false
        textView.isScrollEnabled = true
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 14)
        textView.textColor = .text_weak
        textView.dataDetectorTypes = .link
        textView.linkTextAttributes = [.foregroundColor: UIColor.systemBlue]
        return textView
    }()
    
    var faqTitleLabel: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vcTitle = "k_feed_back".localized()
        buildViews()
        setupFAQContent()

        if AppConfigManager.shared.config.close_recommend_tf == "1" {
            faqTitleLabel?.isHidden = true
            faqTextView.isHidden = true
        }
    }
    
    func buildViews() {
        let contentFieldBackgrondView = UIView(backgroundColor: .bg_default)
        contentFieldBackgrondView.layerCornerRadius = 4
        view.addSubview(contentFieldBackgrondView)
        contentFieldBackgrondView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(navBar.snp.bottom).offset(20)
            make.right.equalTo(-16)
            make.height.equalTo(120)
        }
        
        contentFieldBackgrondView.addSubview(contentTextView)
        contentTextView.snp.makeConstraints { make in
            make.left.equalTo(8)
            make.right.equalTo(-8)
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        let titleFieldBackgrondView = UIView(backgroundColor: .bg_default)
        titleFieldBackgrondView.layerCornerRadius = 4
        titleFieldBackgrondView.layer.borderWidth = 1
        titleFieldBackgrondView.layer.borderColor = UIColor.clear.cgColor
        view.addSubview(titleFieldBackgrondView)
        titleFieldBackgrondView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(contentTextView.snp.bottom).offset(20)
            make.right.equalTo(-16)
            make.height.equalTo(40)
        }
        
        titleFieldBackgrondView.addSubview(contactTextField)
        contactTextField.snp.makeConstraints { make in
            make.left.equalTo(14)
            make.right.equalTo(-14)
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        doneButton.backgroundColor = .btnprimary_normal
        doneButton.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)
        doneButton.layerCornerRadius = 4
        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.top.equalTo(titleFieldBackgrondView.snp.bottom).offset(20)
            make.left.equalTo(16)
            make.height.equalTo(40)
        }
        
        // 常见问题标题
        let faqTitleLabel = UILabel()
        faqTitleLabel.text = "k_faq_title".localized()
        faqTitleLabel.font = UIFont.boldSystemFont(ofSize: 16)
        faqTitleLabel.textColor = .text_black_color
        view.addSubview(faqTitleLabel)
        faqTitleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(doneButton.snp.bottom).offset(30)
            make.right.equalTo(-16)
        }
        self.faqTitleLabel = faqTitleLabel
        
        // 常见问题内容
        view.addSubview(faqTextView)
        faqTextView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.right.equalTo(-16)
            make.top.equalTo(faqTitleLabel.snp.bottom).offset(10)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
        }
        
        view.addTapGestureRecognizer(target: self, action: #selector(clickBG))
    }
    
    // 设置常见问题内容
    func setupFAQContent() {
        let faqContent = """
        \("k_faq_issue1_title".localized())
        \("k_faq_issue1_content".localized())

        \("k_faq_issue2_title".localized())
        \("k_faq_issue2_content".localized())

        \("k_faq_issue3_title".localized())
        \("k_faq_issue3_content".localized())

        \("k_faq_issue4_title".localized())
        \("k_faq_issue4_content".localized())
        """
        
        faqTextView.text = faqContent
    }
    
    // MARK: - 邮箱验证方法
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    @objc private func emailTextChanged() {
        guard let email = contactTextField.text else {
            updateSubmitButtonState(isEnabled: false)
            updateEmailBorderStyle(isValid: false)
            return
        }
        
        let isValid = isValidEmail(email)
        updateSubmitButtonState(isEnabled: isValid)
        updateEmailBorderStyle(isValid: isValid)
    }
    
    private func updateSubmitButtonState(isEnabled: Bool) {
        doneButton.isEnabled = isEnabled
        doneButton.alpha = isEnabled ? 1.0 : 0.5
    }
    
    private func updateEmailBorderStyle(isValid: Bool) {
        let emailBackgroundView = contactTextField.superview
        if isValid {
            emailBackgroundView?.layer.borderColor = UIColor.clear.cgColor
        } else {
            emailBackgroundView?.layer.borderColor = UIColor.red.cgColor
        }
    }
    
    @objc func clickBG() {
        view.endEditing(true)
    }
    
    //MARK: - 提交方法
    @objc func doneButtonAction() {
        // 确保邮箱有效时才提交
        guard let email = contactTextField.text, isValidEmail(email) else {
            GPToast.text("请输入有效的邮箱地址")
            return
        }
        
        // firebase event
        guard let feedbackInfo = contentTextView.text, !feedbackInfo.isEmpty else {
            GPToast.text("请输入反馈内容")
            return
        }
        
        // firebase 埋点
        let params: [String: Any] = ["feedbackInfo": feedbackInfo,
                                     "appversion": GPApp.version,
                                     "contackInfo": contactTextField.text ?? "",
                                     "deviceID": DeviceIDManager.deviceID]
        GPFirebaseManager.logEvent(event: "gps_feedback", parameters: params)
        
        //新增时间
        let startRequestTime = Date()
        networkAPI.feedback(title: contactTextField.text ?? "", content: feedbackInfo) { [weak self] error, message in
            let endRequestTime = Date()
            let requestTotalTime = endRequestTime.timeIntervalSince(startRequestTime)
            
            if error == nil {
                GPToast.text("k_summit_success".localized())
            
                GPFirebaseManager.feedback_api_success(Int(requestTotalTime))
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    self?.popOrDismissVC()
                }
            } else {
                GPFirebaseManager.feedback_api_fail( errorMsg: "\(String(describing: error))")
                GPToast.text("k_network_exception_later".localized())
            }
        }
        
        // 主动反馈时，也上报日志
        GPLogManager.uploadLogs(isFromFeedback: true)
    }
}
