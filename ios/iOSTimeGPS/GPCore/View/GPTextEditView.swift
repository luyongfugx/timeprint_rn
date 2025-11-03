//
//  GPTextEditView.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/17.
//

import Foundation
import UIKit

class GPTextEditView: UIView, UITextFieldDelegate {
    
    private var sureHandler:((String)->())?
    private var cancelHandler: GPVoidBlock?
    private var defaultText: String = ""
    private var placeHolder: String = ""
    private var showTitle: String = ""
    
    private weak var bottomContentView:UIView?
    private weak var textField: UITextField?
    private weak var doneButton: GPButton?
    
    private var isAnimation: Bool = false
    
    class func show(in superView: UIView, defaultText: String, placeHolder: String, showTitle: String, sureHandler:((String)->())?, cancelHandler: GPVoidBlock?) {
        
        let editView = GPTextEditView(frame: superView.bounds)
        
        editView.sureHandler = sureHandler
        editView.cancelHandler = cancelHandler
        editView.defaultText = defaultText
        editView.showTitle = showTitle
        editView.placeHolder = placeHolder
        
        superView.addSubview(editView)
        editView.buildUI()
        editView.addObserver()
        
        editView.layoutIfNeeded()
        editView.textField?.becomeFirstResponder()
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
        
        defer {
            
            let checkText = textField?.text?.replacingOccurrences(of: " ", with: "")
//            doneButton?.isEnabled = (checkText?.count ?? 0) > 0
        }
        
        guard let textF = notification.object as? UITextField, textF == textField else {
            return
        }
        
        if let selectedRange = textF.markedTextRange, let newText = textF.text(in: selectedRange), newText.count > 0 {
            return
        }
        
//        let maxCount: Int = 100 * 2
//        
//        if let toBeString = textF.text, toBeString.count > 0, toBeString.count > maxCount {
//            
//            let result = toBeString.speedySubString(to: maxCount)
//            textF.text = result
//        }
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
            make.height.equalTo(95)
        }
        bottomContentView = _bottomContentView
        
        let itemTitle = UILabel(text: showTitle, textColor: .text_black_color, textFont: .boldSystemFont(ofSize: 16))
        _bottomContentView.addSubview(itemTitle)
        itemTitle.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(16)
            make.right.equalTo(-20)
            make.height.equalTo(20)
        }
        
        let doneText = "i_done".localized()
        let doneWidth = doneText.size(WithFont: .boldSystemFont(ofSize: 16), ConstrainedToWidth: 120).width + 32
        let _doneButton = GPButton(frame: .zero, style: .imageLeftTextRight(0, nil, .init(title: doneText, font: .boldSystemFont(ofSize: 17), titleColor: .white)))
        _doneButton.backgroundColor = .btnprimary_normal
        _doneButton.setTitle(doneText, for: .normal)
        _doneButton.addTarget(self, action: #selector(doneButtonAction), for: .touchUpInside)
        _doneButton.layerCornerRadius = 4
        _bottomContentView.addSubview(_doneButton)
        _doneButton.snp.makeConstraints { make in
            make.right.equalTo(-16)
            make.bottom.equalTo(-8)
            make.width.equalTo(doneWidth)
            make.height.equalTo(40)
        }
        doneButton = _doneButton
        
        let textFieldBackgrondView = UIView(backgroundColor: .bg_default)
        textFieldBackgrondView.layerCornerRadius = 4
        _bottomContentView.addSubview(textFieldBackgrondView)
        textFieldBackgrondView.snp.makeConstraints { make in
            make.left.equalTo(16)
            make.top.equalTo(47)
            make.right.equalTo(_doneButton.snp.left).offset(-10)
            make.height.equalTo(40)
        }
        
        let _textField = UITextField(text: defaultText, textColor: .text_black_color, textFont: .systemFont(ofSize: 16), placeholder: placeHolder, placeholderColor: .text_weak, placeholderFont: .systemFont(ofSize: 16))
        
        _textField.delegate = self
        textFieldBackgrondView.addSubview(_textField)
        _textField.snp.makeConstraints { make in
            make.left.equalTo(14)
            make.right.equalTo(-14)
            make.height.equalToSuperview()
            make.centerY.equalToSuperview()
        }
        textField = _textField
        
    }
    
    @objc func tapToDismiss() {
        
        cancelHandler?()
        hide()
    }
    
    private func hide() {
        
        textField?.resignFirstResponder()
        
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
        
        sureHandler?(textField?.text ?? "")
        hide()
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
        
//        if let text = textField.text, text.replacingOccurrences(of: " ", with: "").count > 0 {
//            
//            
//        }
        doneButtonAction()
        return true
    }
}

