//
//  BaseIconWatermarkView.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/12/19.
//

import Foundation
//
//  WatermarkID10View.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/12/18.
//

import Foundation



import Foundation
import UIKit

class BaseIconWatermarkView: BaseWatermark{


    //水印名字key
    var markNameKey: String {
          return ""
      }
    var imageName : String  {
        return "receipt"
    }
    
    var textColor: UIColor {
        return UIColor.white
    }
    // 主题色
    var themeColor: UIColor {
        return UIColor.systemBlue
    }
    //背景色
    var bgColor: UIColor {
        return .gray.withAlphaComponent(0.9)
    }
    

    
    var bgTitleW: CGFloat = 69
    let placeHolder = " "
    
    // 背景的view
    var bgView: UIView = {
        let view = UIView()
        //view.backgroundColor = .white // Set your desired background color
        view.layer.cornerRadius = 6 // Set the corner radius
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner] // Round top-left and top-right corners
        view.layer.masksToBounds = true // Ensure subviews are clipped to the rounded corners
        
        return view
    }()

    var cleanImageView: UIImageView = UIImageView(image: UIImage(named: "clean"))
    
    var bgColorView: UIView = {
        let bgView = UIView()
//        bgView.backgroundColor = .gray.withAlphaComponent(0.9)
        return bgView
    }()
    var inlineLogoView: UIView = { UIView() }()
    
    // 大标题的背景
    var bigTitleBg: UIView = { UIView(backgroundColor: UIColor.clear) }()
    // 大标题
    var bigTitleLabel: GPQStickerLabel = {
        return GPQStickerLabel(text: "", textColor: UIColor.fromHex("#ffffff"), textFont: UIFont.bigShouldersMedium(20), textAlignment: .center, numberLines: 0, backgroundColor: .clear, cornerRadius: 0)
    }()



    
    var topTableView: WatermarkID8TopTableView = {
        let tableView = WatermarkID8TopTableView(frame: .zero)
        return tableView
    }()
    
  
    
    //animation_View的宽度
    var currentAnimationViewWidth: CGFloat {
        return 240
    }
    
    override func buildViews() {
        super.buildViews()
        
        
        bgView.frame = CGRect(x: 6, y: 6, width: getBgViewWidth(), height: 0)
        animationView.addSubview(bgView)
        
        bgColorView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        bgColorView.backgroundColor = bgColor
        bgView.addSubview(bgColorView)

        inlineLogoView = UIView(backgroundColor: UIColor.fromHex("#ffffff"))
        inlineLogoView.layerCornerRadius = 2
        inlineLogoView.isHidden = true
        bgView.addSubview(inlineLogoView)
        inlineLogoView.frame = CGRect(x: 2, y: 2, width: 44, height: 44)
        
        bigTitleBg.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
        bgView.addSubview(bigTitleBg)
        cleanImageView.frame = CGRect(x: 8, y: 4, width: 16, height: 16)
        cleanImageView.image = UIImage(named: imageName)
        bgView.addSubview(cleanImageView)
        
        bigTitleLabel.frame = CGRect(x: 8, y: 6, width: 0, height: 0)
        bigTitleLabel.lineBreakMode = .byCharWrapping
        bigTitleBg.addSubview(bigTitleLabel)
        bgView.addSubview(topTableView)
        outLogoPadding = 6
    }
    
    func getBgViewWidth() -> CGFloat {
        currentAnimationViewWidth - 12
    }
    
    override func updateUI() {
        super.updateUI()
                
        let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
        let watermarkTextColor = watermarkModel?.textColor ?? textColor

        // 时间
        reloadTimes()
        updateThemeText()
        topTableView.configDatas(baseID: watermarkModel?.baseID, items: watermarkModel?.allBottomOpenItem ?? [], maxWidth: currentAnimationViewWidth, textColor: watermarkTextColor, themeColor: watermarkThemeColor)
        //标题背景色
        bigTitleBg.backgroundColor = watermarkThemeColor.withAlphaComponent(0.9)
        bigTitleLabel.textColor = watermarkTextColor
        cleanImageView.image = cleanImageView.image?.withTintColor(watermarkTextColor)
        for item in bgView.subviews {
            if let label = item as? UILabel {
                label.textColor = watermarkTextColor
            }
        }
        
        for item in scaleContentView.subviews {
            if let label = item as? UILabel {
                label.textColor = watermarkTextColor
            }
        }
        
        for item in animationView.subviews {
            if let label = item as? UILabel {
                label.textColor = watermarkTextColor
            }
        }
        
        setNeedsLayout()
    }

    override func reloadTimes() {
        super.reloadTimes()
        // 刷新时间条目
        self.topTableView.tableView?.reloadData()
    }
    
    //更新大标题,更新小标题
    private func updateThemeText() {

        var isInLine = false
        if let logoModel = watermarkModel?.items?.first(where: { $0.idType == .logo }), logoModel.isOpen == true, logoModel.extraLogo.enumPosition == .inline  {
            isInLine = true
        }
        self.inlineLogoView.isHidden = !isInLine
        logoImageView.isHidden = isInLine
    
        self.bigTitleLabel.removeFromSuperview()
        self.bigTitleLabel.strokeWidth = 3
        self.bigTitleLabel.textColor = .black
        self.bigTitleLabel.textAlignment = .center
        self.bigTitleBg.addSubview(bigTitleLabel)
        let titleSize = calTitleSize(isInline: isInLine, text: markNameKey.localized())
        self.bigTitleBg.width =  getBgViewWidth()
        bigTitleLabel.text = markNameKey.localized()
        bigTitleLabel.width = titleSize.width
        bigTitleLabel.height = titleSize.height
        self.bigTitleBg.height = titleSize.height + 30
        bigTitleBg.isHidden = false
        
    }
    
    func calTitleSize(isInline: Bool, text: String) -> CGSize {
        let maxWidth = isInline ? (currentAnimationViewWidth - 50 - 12) : (currentAnimationViewWidth - 12)
        let labelSize = text.size(WithFont: bigTitleLabel.font, ConstrainedToWidth: maxWidth)
        return CGSize.init(width: labelSize.width, height: labelSize.height)
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        resetLogoFrame()
        var middleViewH: CGFloat = 0
        let bgViewW: CGFloat = getBgViewWidth()
        layoutTopViews()
        let bgView_y: CGFloat = bgView.top
        let listTableView_h: CGFloat = topTableView.height
        let listTableViewWidth: CGFloat = bgViewW - 6
        
        topTableView.frame = CGRect(x: 6, y: bigTitleBg.height + 4, width: listTableViewWidth, height: listTableView_h)
        middleViewH = topTableView.bottom + 8
        bgView.height = middleViewH
        bgColorView.height = middleViewH
        bgColorView.width = bgViewW
        let bgViewH = middleViewH
        var animationViewH = bgView_y + bgViewH + 6
        var animationViewW = bgViewW + 12
        
        if logoWidth > 0 {
            animationViewW = max(animationViewW, logoWidth+12)
        }
        if bigTitleBg.isHidden == false && bigTitleBg.height != 16 {
            if bigTitleBg.top < 0 {
                animationViewH = animationViewH+bigTitleBg.height+7
            }
        }
        bgView.bottom = animationViewH - 6
        if animationView.bottom == 0{
            animationView.bottom = height
        }
        
        animationView.frame = CGRect.init(x: animationView.left, y: animationView.bottom - animationViewH, width: animationViewW, height: animationViewH)
                
        if sizeScale != 1 {
            makeChangSizeUI(animationView_w: animationViewW, content_y: animationViewH)
        } else {
            scaleContentView.transform = CGAffineTransform(scaleX: 1, y: 1)
        }
        resetFrame()
    }
    
    func layoutTopViews() {
        
        let bgViewW: CGFloat = getBgViewWidth()
        var lineTopH:CGFloat = 0
        var titleLeft: CGFloat = 36
        // 处理logo
        bgView.top = 6
        
        var onWatermark = false
        var hasLogo = false
        if let logoModel = watermarkModel?.items?.first(where: { $0.idType == .logo }), logoModel.isOpen == true {
            hasLogo = true
            if logoModel.extraLogo.enumPosition == .onWatermark {
                onWatermark = true
            }
        }
        
        // 有logo
        if hasLogo {
            
            if logoHeight > 0 && onWatermark {
                bgView.top = lineTopH + logoHeight + 12
            } else {
                bgView.top = lineTopH
            }
            
        }
        
        let  titleSize = calTitleSize(isInline: onWatermark, text: markNameKey.localized())
        titleLeft =  (bgViewW - titleSize.width)/2
    
        self.bigTitleLabel.frame = CGRect(x: titleLeft, y: 8, width: bgViewW - titleLeft - 10, height: 20)
        bigTitleLabel.sizeToFit()
            if bigTitleLabel.height<lineTopH-8 {
                bigTitleLabel.centerY = 48*0.5
            } else {
                lineTopH = bigTitleLabel.bottom+12
            }
        self.cleanImageView.height = 32
        self.cleanImageView.width = 32
        self.bigTitleBg.height = 40

    }
}
