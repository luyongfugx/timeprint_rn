//
//  GPSearchBar.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/17.
//

import Foundation
import UIKit

class GPSearchTextField: UITextField {
    
    var startRectX: CGFloat = 34
    var clearRight: CGFloat = 7

    private lazy var searchIcon: UILabel = {
        let label = UILabel.iconLabel(fontSize: 14, labelWidth: 14, iconType: .icon_search)
        label.textColor = UIColor.fromRGBA(131, g: 131, b: 131)
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(searchIcon)
        
        searchIcon.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(8)
            make.width.height.equalTo(24)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        .init(x: startRectX, y: bounds.origin.y, width: bounds.width - startRectX, height: bounds.height)
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        .init(x: startRectX, y: bounds.origin.y, width: bounds.width - startRectX*2, height: bounds.height)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        .init(x: startRectX, y: bounds.origin.y, width: bounds.width - startRectX*2, height: bounds.height)
    }
    
    override func clearButtonRect(forBounds bounds: CGRect) -> CGRect {
        layoutIfNeeded()
        return .init(origin: .init(x: bounds.width - 18 - clearRight, y: bounds.height / 2 - 9), size: .init(width: 18, height: 18))
    }
}

class GPSearchBar: UIView {
        
    var searchPlaceholder: String = "" {
        didSet {
            searchTextField.attributedPlaceholder = NSAttributedString(string: searchPlaceholder, attributes: [.foregroundColor: UIColor.fromHex("848484"), .font: UIFont.systemFont(ofSize: 16)])
        }
    }
    
    var didSearch: ((String) -> Void)?
    var willEdit: (() -> Void)?
    var willEnd: (() -> Void)?
    var didChange: ((String) -> Void)?

    // V2.9.355:输入框自带的删除按钮点击的时候触发
    var clearButtonClickHandler: (()->())?
    
    private(set) lazy var searchTextField: GPSearchTextField = {
        let searchTextField = GPSearchTextField()
        searchTextField.textColor = .text_black_color
        searchTextField.font = .systemFont(ofSize: 16)
        searchTextField.returnKeyType = .search
        searchTextField.clearButtonMode = .whileEditing
        searchTextField.delegate = self
        return searchTextField
    }()

    // V2.9.355：设置内容
    func setText(text: String?) {
        self.searchTextField.text = text
        showOrNotShowSearch(shouldShow: text?.isEmpty == false)
    }
    
    func getTextField() -> GPSearchTextField {
        return searchTextField
    }
    
    func updateKeyboardType(keybordType: UIKeyboardType) {
        searchTextField.keyboardType = keybordType
    }
    
    func updateFont(font: UIFont) {
        searchTextField.font = font
    }
    
    func getSearchText() -> String? {
        return self.searchTextField.text
    }
    
    func setStartPlaceHolderX(_ startX: CGFloat, clearRight: CGFloat) {
        self.searchTextField.startRectX = startX
        self.searchTextField.clearRight = clearRight
        self.searchTextField.layoutIfNeeded()
    }
    
    func updateTintColor(_ tintColor: UIColor) {
        self.searchTextField.tintColor = tintColor
    }

    private lazy var seperator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.fromHex("BDC2C8")
        return view
    }()
    
    private(set) lazy var searchBtn: UIButton = {
        let button = UIButton()
        button.setTitle("i_search".localized(), for: .normal)
        button.setTitleColor(.fromHex("0093FF"), for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        layer.cornerRadius = 4
        layer.masksToBounds = true
        
        backgroundColor = .white
        
        addSubview(searchTextField)
        addSubview(seperator)
        addSubview(searchBtn)
        
        searchTextField.snp.makeConstraints { make in
            make.left.top.bottom.right.equalToSuperview()
        }
        
        searchBtn.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-12)
        }
        
        seperator.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalTo(searchBtn.snp.left).offset(-12)
            make.width.equalTo(1)
            make.height.equalToSuperview().offset(-24)
        }
        
        searchBtn.isHidden = true
        seperator.isHidden = true
        
        searchTextField.addTarget(self, action: #selector(textFieldDidChange), for: .editingChanged)
        searchBtn.addTarget(self, action: #selector(didClickSearch), for: .touchUpInside)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func textFieldDidChange() {
        let text = self.searchTextField.text ?? ""
        self.showOrNotShowSearch(shouldShow: false)
        self.didChange?(text)
    }
    
    @objc func didClickSearch() {
        self.searchTextField.resignFirstResponder()
        self.showOrNotShowSearch(shouldShow: false)
        self.didSearch?(self.searchTextField.text ?? "")
    }
    
    override func becomeFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return self.searchTextField.becomeFirstResponder()
    }
    
    override func resignFirstResponder() -> Bool {
        super.becomeFirstResponder()
        return self.searchTextField.resignFirstResponder()
    }
}

extension GPSearchBar: UITextFieldDelegate {

    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        clearButtonClickHandler?()
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        if string.elementsEqual("\n") {
            textField.resignFirstResponder()
            self.showOrNotShowSearch(shouldShow: false)
            self.didSearch?(textField.text ?? "")
            return false
        }
        return true
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        showOrNotShowSearch(shouldShow: false)
        self.willEnd?()
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.willEdit?()
    }
}

extension GPSearchBar {
    
    func showOrNotShowSearch(shouldShow: Bool) {
        if shouldShow {
            searchBtn.isHidden = false
            seperator.isHidden = false
            searchTextField.snp.remakeConstraints({ make in
                make.left.top.bottom.equalToSuperview()
                make.right.equalTo(seperator.snp.left).offset(-12)
            })
        } else {
            searchBtn.isHidden = true
            seperator.isHidden = true
            searchTextField.snp.remakeConstraints({ make in
                make.left.top.bottom.right.equalToSuperview()
            })
        }
    }
}
