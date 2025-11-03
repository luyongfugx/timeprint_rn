//
//  EditThemeView.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/9/28.
//

import Foundation
import UIKit

protocol EditThemeViewDelegate: AnyObject {
    
    func updateWatermarkColor(themeColorStr: String?, textColorStr: String?)
    func updateWatermarkScale(scale: CGFloat)
    func updateLogoScale(scale: CGFloat)

}

class EditThemeView: GPView {
    
    let colorListStr: [String] = ["FFFFFF", "0060FF", "19C0BF", "00A80D", "FF7800", "D80007", "A901AB", "00BCFF", "1DE9B6", "64DD17", "FFC233", "FF5252", "CE48FF", "43E8FF", "64FFDA", "76FF03", "FFEF40", "FFAB91", "ED84FF", "000000"]
        
    private lazy var backBtn: GPButton = {
        let button = GPButton.init(frame: .init(x: 0, y: 0, width: 44, height: 44), fontSize: 24, iconType: .btn_back)
        button.setTitleColor(.text_black_color, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(backAction), for: .touchUpInside)
        return button
    }()
    
    let themeColorLabel: UILabel = {
        return UILabel(text: "k_template_color".localized(), textColor: UIColor.fromHex("222222"), textFont: UIFont.Semibold(18))
    }()
    
    let textColorLabel: UILabel = {
        return UILabel(text: "k_text_color".localized(), textColor: UIColor.fromHex("222222"), textFont: UIFont.Semibold(18))
    }()
    
    let sizeLabel: UILabel = {
        return UILabel(text: "k_template_size".localized(), textColor: UIColor.fromHex("222222"), textFont: UIFont.Semibold(18))
    }()
    
    let sizeSliderView: GPSizeSliderBar = {
        return GPSizeSliderBar(frame: .zero)
    }()
    
    lazy var themeColorScrollView: UIScrollView = {
        let _themeColorScrollView = UIScrollView()
        _themeColorScrollView.alwaysBounceVertical = false
        _themeColorScrollView.alwaysBounceHorizontal = true
        _themeColorScrollView.showsVerticalScrollIndicator = false
        _themeColorScrollView.showsHorizontalScrollIndicator = true
        return _themeColorScrollView
    }()
    
    lazy var textColorScrollView: UIScrollView = {
        let _textColorScrollView = UIScrollView()
        _textColorScrollView.alwaysBounceVertical = false
        _textColorScrollView.alwaysBounceHorizontal = true
        _textColorScrollView.showsVerticalScrollIndicator = false
        _textColorScrollView.showsHorizontalScrollIndicator = true
        return _textColorScrollView
    }()
    
    var themeChooseColorStr: String?
    var allThemeColorButtons: [UIButton] = []
    
    var textChooseColorStr: String?
    var allTextColorButtons: [UIButton] = []

    weak var delegate: EditThemeViewDelegate?
    var watermarkModel: BaseWatermarkModel?
    
    init(frame: CGRect, model: BaseWatermarkModel) {
        self.watermarkModel = model
        self.themeChooseColorStr = model.templateColorStr
        self.textChooseColorStr = model.textColorStr
        super.init(frame: frame)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func buildUI() {
        backgroundColor = .white
        
        let topBar = UIView(backgroundColor: UIColor.fromHex("#FAFAFA"))
        addSubview(topBar)
        topBar.snp.makeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(44)
        }
        
        addSubview(backBtn)
        backBtn.snp.makeConstraints { make in
            make.left.equalTo(6)
            make.width.height.equalTo(44)
            make.top.equalTo(0)
        }
        addSubview(themeColorLabel)
        themeColorLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(backBtn.snp.bottom).offset(20)
        }
        buildThemeColorView()
        
        addSubview(textColorLabel)
        textColorLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(44 + 60 + 70)
        }
        buildTextColorView()
        
        addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints { make in
            make.left.equalTo(20)
            make.top.equalTo(201+60+20)
        }
        buildSizeView()
    }
    
    func buildThemeColorView() {
                
        addSubview(themeColorScrollView)
        themeColorScrollView.frame = .init(x: 20, y: 44 + 60, width: GPApp.screenWidth - 40, height: 48)
        
        let btn_w: CGFloat = 36
        let btn_h: CGFloat = 36
        let margin: CGFloat = 0
        let spaceWidth: CGFloat = GPApp.screenWidth-40-CGFloat(6)*btn_w
        let space_x: CGFloat = spaceWidth/CGFloat(5)

        var contentW: CGFloat = 0
        for index in 0 ..< colorListStr.count {
            let colorStr = colorListStr[index]
            let button = UIButton()
            button.layerCornerRadius = 18.0
            button.tag = index
            if colorStr == "FFFFFF" {
                button.backgroundColor = UIColor.white
                button.setBorder(color: UIColor.fromHex("#222222"), width: 1)
                button.setImage(UIImage(named: "wm_choose_black"), for: .selected)
            } else {
                button.backgroundColor = UIColor.fromHex(colorStr)
                button.setImage(UIImage(named: "wm_choose_white"), for: .selected)
            }
            themeColorScrollView.addSubview(button)
            let startX = margin + (btn_w + space_x) * CGFloat(index)
            button.frame = .init(x: startX, y: 2, width: btn_w, height: btn_h)
            contentW = startX + btn_w + 30
            button.isSelected = colorStr == self.themeChooseColorStr
            button.addTarget(self, action: #selector(buttonAction(_:)), for: .touchUpInside)
            allThemeColorButtons.append(button)
        }
                            
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.themeColorScrollView.contentSize = .init(width: contentW, height: 40)
        }
    }
    
    func buildTextColorView() {
                
        addSubview(textColorScrollView)
        textColorScrollView.frame = .init(x: 20, y: 44 + 70 + 40 + 60, width: GPApp.screenWidth - 40, height: 48)
        
        let btn_w: CGFloat = 36
        let btn_h: CGFloat = 36
        let margin: CGFloat = 0
        let spaceWidth: CGFloat = GPApp.screenWidth-40-CGFloat(6)*btn_w
        let space_x: CGFloat = spaceWidth/CGFloat(5)

        var contentW: CGFloat = 0
        for index in 0 ..< colorListStr.count {
            let colorStr = colorListStr[index]
            let button = UIButton()
            button.layerCornerRadius = 18.0
            button.tag = index
            if colorStr == "FFFFFF" {
                button.backgroundColor = UIColor.white
                button.setBorder(color: UIColor.fromHex("#222222"), width: 1)
                button.setImage(UIImage(named: "wm_choose_black"), for: .selected)
            } else {
                button.backgroundColor = UIColor.fromHex(colorStr)
                button.setImage(UIImage(named: "wm_choose_white"), for: .selected)
            }
            textColorScrollView.addSubview(button)
            let startX = margin + (btn_w + space_x) * CGFloat(index)
            button.frame = .init(x: startX, y: 2, width: btn_w, height: btn_h)
            contentW = startX + btn_w + 30
            button.isSelected = colorStr == self.textChooseColorStr
            button.addTarget(self, action: #selector(textButtonAction(_:)), for: .touchUpInside)
            allTextColorButtons.append(button)
        }
                            
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.textColorScrollView.contentSize = .init(width: contentW, height: 40)
        }
    }
    
    @objc
    func backAction() {
        UIView.animate(withDuration: 0.3) {
            self.y = GPApp.screenHeight
        } completion: { finish in
            //
        }
    }

    @objc func buttonAction(_ sender: UIButton) {
    
        let currentTag = sender.tag
        self.themeChooseColorStr = colorListStr[currentTag]
        for tempBtn in allThemeColorButtons {
            tempBtn.isSelected = tempBtn.tag == currentTag
        }
        delegate?.updateWatermarkColor(themeColorStr: themeChooseColorStr, textColorStr: textChooseColorStr)
    }
    
    @objc func textButtonAction(_ sender: UIButton) {
    
        let currentTag = sender.tag
        self.textChooseColorStr = colorListStr[currentTag]
        for tempBtn in allTextColorButtons {
            tempBtn.isSelected = tempBtn.tag == currentTag
        }
        delegate?.updateWatermarkColor(themeColorStr: themeChooseColorStr, textColorStr: textChooseColorStr)
    }
    
    func flashScrollIndicators() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.themeColorScrollView.flashScrollIndicators()
            self?.textColorScrollView.flashScrollIndicators()
        }
    }
}
