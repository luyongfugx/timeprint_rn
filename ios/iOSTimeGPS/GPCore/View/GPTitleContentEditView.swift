//
//  GPTitleContentEditView.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/13.
//

import Foundation
import UIKit

class GPTitleContentEditView: UIView, UITextFieldDelegate {
    
    lazy var titleLabel: UILabel = {
        return UILabel(text: "k_edit_title_tip".localized(), textColor: .text_black_color, textFont: .boldSystemFont(ofSize: 16))
    }()
    
    lazy var titleTextField: UITextField = {
        let textfield =  UITextField(text: "", textColor: .text_black_color, textFont: .systemFont(ofSize: 16), placeholder: "k_please_input_title".localized(), placeholderColor: .text_weak, placeholderFont: .systemFont(ofSize: 16))
        textfield.returnKeyType = .next
        return textfield
    }()
    
    lazy var contentLabel: UILabel = {
        return UILabel(text: "k_edit_content_tip".localized(), textColor: .text_black_color, textFont: .boldSystemFont(ofSize: 16))
    }()
    
    lazy var contentTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.font = UIFont.systemFont(ofSize: 16)
        textView.placeholderColor = .text_weak
        textView.placeholder = "k_please_input_content".localized()
        textView.textColor = .text_black_color
        textView.spellCheckingType = .no
        textView.autocorrectionType = .no
        textView.smartInsertDeleteType = .no
        return textView
    }()
    
    lazy var doneButton: GPButton = {
        return GPButton(frame: .zero, style: .imageLeftTextRight(0, nil, .init(title: "i_done".localized(), font: .boldSystemFont(ofSize: 17), titleColor: .white)))
    }()
    
    private lazy var deleteBtn: GPButton = {
        let button = GPButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.setBorder(color: .border_medium, width: 1)
        button.layer.cornerRadius = 6
        button.setTitle("i_delete".localized(), for: .normal)
        button.setTitleColor(.text_weak, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.titleEdgeInsets = .init(top: 0, left: 8, bottom: 0, right: 8)
        button.titleLabel?.adjustsFontSizeToFitWidth = true
        button.addTarget(self, action: #selector(deleteAction), for: .touchUpInside)
        return button
    }()
    
    private var sureHandler:((String, String)->())?
    private var cancelHandler: GPVoidBlock?
    private var showTitle: String = ""
    private var showContent: String = ""
    
    private weak var bottomContentView:UIView?
    
    private var isAnimation: Bool = false
    
    class func show(in superView: UIView, showTitle: String, showContent: String, sureHandler:((String, String)->())?, cancelHandler: GPVoidBlock?) {
        
        let editView = GPTitleContentEditView(frame: superView.bounds)
        
        editView.sureHandler = sureHandler
        editView.cancelHandler = cancelHandler
        editView.showTitle = showTitle
        editView.showContent = showContent
        
        superView.addSubview(editView)
        editView.buildUI()
        editView.loadDatas()
        editView.addObserver()
        
        editView.layoutIfNeeded()
        editView.titleTextField.becomeFirstResponder()
    }
    
    deinit {
        removeObserver()
    }
    
    private func addObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(noti:)), name: UITextField.keyboardWillChangeFrameNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(textFieldDidChangedText(_ :)), name: UITextField.textDidChangeNotification, object: nil)
    }
    
    private func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func textFieldDidChangedText(_ notification: Notification) {
        
    }
    
    func buildUI(){
        
        backgroundColor = .black.withAlphaComponent(0.4)
        
        let tapDismissView = UIView(backgroundColor: .clear)
        addSubview(tapDismissView)
        tapDismissView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tapDismissView.addTapGestureRecognizer(target: self, action: #selector(tapToDismiss))
        let _bottomContentView = UIView(backgroundColor: .white)
        addSubview(_bottomContentView)
        _bottomContentView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(95 + 188)
        }
        bottomContentView = _bottomContentView
        
        _bottomContentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(16)
            make.right.equalTo(-16)
            make.height.equalTo(20)
        }
        
        let titleFieldBackgrondView = UIView(backgroundColor: .bg_default)
        titleFieldBackgrondView.layerCornerRadius = 4
        _bottomContentView.addSubview(titleFieldBackgrondView)
        titleFieldBackgrondView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(47)
            make.right.equalTo(-16)
            make.height.equalTo(40)
        }
        
        titleTextField.delegate = self
        titleFieldBackgrondView.addSubview(titleTextField)
        titleTextField.snp.makeConstraints { make in
            make.left.equalTo(14)
            make.right.equalTo(-14)
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
        _bottomContentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(titleFieldBackgrondView.snp.bottom).offset(20)
            make.right.equalTo(-16)
            make.height.equalTo(20)
        }
        
        let contentFieldBackgrondView = UIView(backgroundColor: .bg_default)
        contentFieldBackgrondView.layerCornerRadius = 4
        _bottomContentView.addSubview(contentFieldBackgrondView)
        contentFieldBackgrondView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(contentLabel.snp.bottom).offset(11)
            make.right.equalTo(-16)
            make.height.equalTo(80)
        }
        
        contentFieldBackgrondView.addSubview(contentTextView)
        contentTextView.snp.makeConstraints { make in
            make.left.equalTo(8)
            make.right.equalTo(-8)
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        
//        if let btnLabel = deleteBtn.titleLabel, let btnText = btnLabel.text, let btnFont = btnLabel.font {
//            let deleteWidth = btnText.size(WithFont: btnFont, ConstrainedToWidth: GPApp.screenWidth).width + 8*2
//            _bottomContentView.addSubview(deleteBtn)
//            deleteBtn.snp.makeConstraints { make in
//                make.width.equalTo(deleteWidth)
//                make.bottom.equalTo(-8)
//                make.left.equalTo(16)
//                make.height.equalTo(40)
//            }
//        }
        
        doneButton.backgroundColor = .btnprimary_normal
        doneButton.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)
        doneButton.layerCornerRadius = 6
        _bottomContentView.addSubview(doneButton)
        doneButton.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.bottom.equalTo(-8)
            make.left.equalTo(16)
            make.height.equalTo(40)
        }
    }
    
    func loadDatas() {
        titleTextField.text = showTitle
        contentTextView.text = showContent
    }
    
    @objc func tapToDismiss() {
        
        cancelHandler?()
        hide()
    }
    
    private func hide() {
        
        titleTextField.resignFirstResponder()
        contentTextView.resignFirstResponder()
        
        if isAnimation {
            return
        }
        
        isAnimation = true
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseInOut) {
            
            self.alpha = 0
        } completion: { [weak self] _ in
            
            self?.isAnimation = false
            self?.removeObserver()
            self?.removeFromSuperview()
        }
    }
    
    //MARK: -方法
    @objc func doneButtonAction() {
        sureHandler?(titleTextField.text ?? "", contentTextView.text ?? "")
        hide()
    }
    
    @objc func deleteAction() {
//        sureHandler?(titleTextField.text ?? "", contentTextView.text ?? "")
//        hide()
    }
    
    @objc func keyboardWillChangeFrame(noti:NSNotification){
        
        guard let _bottomContentView = bottomContentView,let userInfo = noti.userInfo as? [String:Any],let endkeyboardRect = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else{
            return
        }
        
        let rect =  _bottomContentView.frame
        let transFromY = rect.maxY - endkeyboardRect.minY
        
        let animateDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0.25
        
        UIView.animate(withDuration: animateDuration) {[weak self] in
            
            var transform:CGAffineTransform? = CGAffineTransform.identity
            
            if endkeyboardRect.minY >= GPApp.screenHeight{
                
                
            }else{
                transform = self?.bottomContentView?.transform.translatedBy(x: 0, y: -transFromY)
            }
            
            if let _transform = transform{
                self?.bottomContentView?.transform =  _transform
            }
        }
    }
    
    
    @objc func keyBoardDidShow(noti:NSNotification){
        
        guard let _bottomContentView = bottomContentView,let endkeyboardRect = (noti.userInfo as! [String:Any])[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else{
            return
        }
        
        let rect =  _bottomContentView.frame
        let transFromY = rect.maxY - endkeyboardRect.minY
        
        if transFromY <= 0{return}
        
        UIView.animate(withDuration: 0.25) {[weak self] in
            
            if let transform = self?.bottomContentView?.transform.translatedBy(x: 0, y: -transFromY){
                self?.bottomContentView?.transform =  transform
            }
        }
    }
    
    @objc func keyBoardWillHidden(noti:NSNotification){
        
        UIView.animate(withDuration: 0.25) {[weak self] in
            
            self?.bottomContentView?.transform = CGAffineTransform.identity
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        contentTextView.becomeFirstResponder()
        return true
    }
}

