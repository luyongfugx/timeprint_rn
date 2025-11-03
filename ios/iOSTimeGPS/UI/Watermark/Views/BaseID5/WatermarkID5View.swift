//
//  BaseID5.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/26.
//

import Foundation
import UIKit

class WatermarkID5View: BaseWatermark{
    var bgTitleW: CGFloat = 69
    let placeHolder = " "
    let bgAlpha: CGFloat  = 0.7
    var arraowHeight:Double = 12
    // 背景的view
    var bgView: UIView = { UIView() }()
    var inlineLogoView: UIView = { UIView() }()
    
    var bgColorView: UIView = {
        return UIView(backgroundColor: UIColor.fromHex("#0023FF", alpha: 0), cornerRadius: 4)
    }()
    
    // 大标题的背景
    var bigTitleBg: UIView = { UIView(backgroundColor: UIColor.clear) }()
    // 大标题
    var bigTitleLabel: GPQStickerLabel = {
        return GPQStickerLabel(text: "", textColor: UIColor.fromHex("#FFEE5B"), textFont: UIFont.robotoCondensedBold(16), textAlignment: .left, numberLines: 0, backgroundColor: .clear, cornerRadius: 0)
    }()
    // 小标题
    var smallTitleLabel: GPQStickerLabel = {
        return GPQStickerLabel(text: "", textColor: UIColor.white, textFont: UIFont.robotoCondensedMedium(14), textAlignment: .left, numberLines: 0, backgroundColor: .clear, cornerRadius: 0)
    }()
    // 时间：21:30
    var timeLabel: UILabel = {
        let timeLabel = UILabel(text: "", textColor: UIColor.fromHex("#FFEE5B"), textFont: UIFont.bigShouldersMedium(36), textAlignment: .left, numberLines: 0, backgroundColor: .clear, cornerRadius: 0)
        return timeLabel
    }()
    
    var dateHeight: CGFloat = 20
    let defaultDateSize: CGFloat = 14
    var needReCaculateDateFont: Bool = false
    var lastTimeText = ""

    // 日期：2022年1月31日
    var bottomDateLabel: UILabel = {
        return UILabel(text: "", textColor: UIColor.white, textFont: UIFont.robotoCondensedRegular(14), textAlignment: .left, numberLines: 0, backgroundColor: .clear, cornerRadius: 0)
    }()
    
    var topDateLabel: UILabel = {
        return UILabel(text: "", textColor: UIColor.white, textFont: UIFont.robotoCondensedRegular(14), textAlignment: .left, numberLines: 0, backgroundColor: .clear, cornerRadius: 0)
    }()

    
    
    var topBlackBgView: UIView = {
        let view = UIView(backgroundColor: .black)
        let cornerRadius: CGFloat = 4.0
        let maskPath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 188, height: 100), byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: cornerRadius, height: cornerRadius))
        let maskLayer = CAShapeLayer()
        maskLayer.path = maskPath.cgPath
        view.layer.mask = maskLayer
        view.alpha = 0
        return view
    }()
    
    // 黄色的线
    //var yellowLine: UIView = { UIView(backgroundColor: UIColor.fromHex("#FFEE5B", alpha: 1.0)) }()
    // 箭头分割线
    var arrowBar: UIImageView = {

        let originalImage = UIImage(named: "watermark_5_line") // Using an SF Symbol for demonstration
        //tempView.image = UIImage(named: "watermark_5_line")
        let templateImage = originalImage?.withRenderingMode(.alwaysTemplate)
        let tempView = UIImageView(image: templateImage)
        tempView.contentMode = .scaleAspectFit
        tempView.tintColor = UIColor.fromHex("#FFEE5B")
        return tempView
        
    }()
    
    var arrowBar2: UIImageView = {
        let originalImage = UIImage(named: "watermark_5_line") // Using an SF Symbol for demonstration
        //tempView.image = UIImage(named: "watermark_5_line")
        let templateImage = originalImage?.withRenderingMode(.alwaysTemplate)
        let tempView = UIImageView(image: templateImage)
        tempView.contentMode = .scaleAspectFit
        tempView.tintColor = UIColor.fromHex("#FFEE5B")
        return tempView
        
    }()
    
    
    var topTableView: WatermarkID5TopTableView = {
        let tableView = WatermarkID5TopTableView(frame: .zero)
        return tableView
    }()
    
    var themeColor: UIColor {
        return UIColor.fromHex("#00A80D")
    }
    
    //animation_View的宽度
    var currentAnimationViewWidth: CGFloat {
        return 200
    }
    
    override func buildViews() {
        super.buildViews()
        
        
        bgView.frame = CGRect(x: 6, y: 6, width: getBgViewWidth(), height: 0)
        animationView.addSubview(bgView)
        bgColorView.frame = CGRect(x: 0, y: 0, width: 0, height: 0)
        bgView.addSubview(bgColorView)
        bgView.addSubview(topBlackBgView)

        inlineLogoView = UIView(backgroundColor: UIColor.fromHex("#ffffff"))
        inlineLogoView.layerCornerRadius = 2
        inlineLogoView.isHidden = true
        bgView.addSubview(inlineLogoView)
        inlineLogoView.frame = CGRect(x: 2, y: 2, width: 44, height: 44)
        
        bigTitleBg.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
        bgView.addSubview(bigTitleBg)
        
        bigTitleLabel.frame = CGRect(x: 0, y: 6, width: 0, height: 0)
        bigTitleLabel.lineBreakMode = .byCharWrapping
        bigTitleBg.addSubview(bigTitleLabel)
        
        smallTitleLabel.frame = CGRect(x: 0, y: 10, width: 0, height: 0)
        smallTitleLabel.lineBreakMode = .byCharWrapping
        bgView.addSubview(smallTitleLabel)
        
        bgView.addSubview(arrowBar)
        
        arrowBar.frame = CGRect(x: 0, y: 4.5, width: 0, height: arraowHeight)
        // add 把箭头隐藏,避免抄袭问题
       // arrowBar.isHidden = true
        
        timeLabel.frame = CGRect(x: 5, y: 3, width: 70, height: 32)
        bgView.addSubview(timeLabel)
        
        bottomDateLabel.frame = CGRect(x: 5, y: 0, width: 0, height: 14)
        bgView.addSubview(bottomDateLabel)
        
        topDateLabel.frame = CGRect(x: 5, y: 0, width: 0, height: 14)
        bgView.addSubview(topDateLabel)
        
        arrowBar2.frame = CGRect(x: 0, y: 4.5, width: 0, height: arraowHeight)
        bgView.addSubview(arrowBar2)
        bgView.addSubview(topTableView)
        topBlackBgView.snp.makeConstraints { make in
            make.top.left.equalToSuperview()
            make.width.equalTo(188)
            make.bottom.equalTo(arrowBar.snp.top)
        }
        

        
        outLogoPadding = 6
    }
    
    func getBgViewWidth() -> CGFloat {
        currentAnimationViewWidth - 12
    }
    
    override func updateUI() {
        super.updateUI()
                
        let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
        let watermarkTextColor = watermarkModel?.textColor ?? .white
//        watermarkTextColor = .fromHex("#FFFFFF")
//        watermarkThemeColor = .fromHex("#6b07d4")
        bgColorView.backgroundColor = watermarkThemeColor.withAlphaComponent(bgAlpha)
        topBlackBgView.backgroundColor = watermarkThemeColor.withAlphaComponent(bgAlpha)
        // 时间
        reloadTimes()
        
        updateThemeText()
        
        topTableView.configDatas(baseID: watermarkModel?.baseID, items: watermarkModel?.allTopOpenItem ?? [], maxWidth: currentAnimationViewWidth, textColor: watermarkTextColor, themeColor: watermarkThemeColor)
        
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
        // 获取时间
        guard let timeItem = watermarkModel?.items?.first(where: { $0.idType == .time }) else { return }
        let timeItemModel = timeItem.extraTime
        
        let id43TimeInfo = GPDateFormat.watermarkUICommpentForID5(with: timeItemModel)
        timeLabel.text =  id43TimeInfo.hhmm
        let currentTimeText = id43TimeInfo.hhmm
        bottomDateLabel.text = id43TimeInfo.bottomDateString
        topDateLabel.text = id43TimeInfo.topExtraDateString
       
        var maxText = bottomDateLabel.text ?? ""
        
        if (topDateLabel.text?.count ?? 0) > maxText.count {
            maxText = topDateLabel.text ?? ""
        }
        
        let dateWidth = bottomDateLabel.width
        var font = UIFont.robotoCondensedRegular(defaultDateSize)
        var caculatedSize = defaultDateSize
        var caculatedInfo = maxText.size(WithFont: font, ConstrainedToWidth: 1000)
        dateHeight = ceil(caculatedInfo.height) + 1
        
        // 计算出来的宽度比最大宽度大
        while caculatedInfo.width > (dateWidth + 1) {
            
            if caculatedSize < defaultDateSize - 3 {
                break
            }
            
            caculatedSize -= 1
            font = UIFont.robotoCondensedRegular(caculatedSize)
            caculatedInfo = maxText.size(WithFont: font, ConstrainedToWidth: 1000)
            dateHeight = ceil(caculatedInfo.height) + 1
        }
        topDateLabel.font = font
        bottomDateLabel.font = font
        
        
        if lastTimeText != currentTimeText {
            setNeedsLayout()
            layoutIfNeeded()
        }
        lastTimeText = currentTimeText
        let bgViewW: CGFloat = getBgViewWidth()
        self.arrowBar2.frame = CGRect(x: 3, y: timeLabel.frame.origin.y+timeLabel.frame.height+2, width: bgViewW-6, height: arraowHeight)
                
    }
    
    //更新大标题,更新小标题
    private func updateThemeText() {

        var isInLine = false
        if let logoModel = watermarkModel?.items?.first(where: { $0.idType == .logo }), logoModel.isOpen == true, logoModel.extraLogo.enumPosition == .inline  {
            isInLine = true
        }

//        bigTitleBg.isHidden = false
        self.inlineLogoView.isHidden = !isInLine
//        self.logoImageView.removeFromSuperview()
//        animationView.addSubview(logoImageView)
        logoImageView.isHidden = isInLine
        
        _ = watermarkModel?.templateColor ?? themeColor
        let watermarkTextColor = watermarkModel?.textColor ?? .white
       
        self.bigTitleLabel.removeFromSuperview()
        self.bigTitleLabel.strokeWidth = 3
        timeLabel.textColor = watermarkTextColor
        //self.bigTitleLabel.textColor = UIColor.fromHex("#FFEE5B")
        self.bigTitleLabel.textColor = watermarkTextColor
        self.bottomDateLabel.textColor = watermarkTextColor
        self.topDateLabel.textColor = watermarkTextColor
        self.bigTitleLabel.textAlignment = .left
        self.bigTitleBg.addSubview(bigTitleLabel)
        
        var showTitle = false
        if let bigTitleItem = watermarkModel?.items?.first(where: { $0.idType == .watermarkTitle }), bigTitleItem.isOpen == true {
            showTitle = true
            let titleSize = calTitleSize(isInline: isInLine, text: bigTitleItem.content ?? "")
            bigTitleLabel.text = bigTitleItem.content
            bigTitleLabel.width = titleSize.width
            bigTitleLabel.height = titleSize.height
            bigTitleBg.height = titleSize.height + 5
            
        } else {
            self.bigTitleBg.width = 16
            self.bigTitleBg.height = 16
            bigTitleLabel.text = ""
        }
        
        var showSubTitle = false

        if let subTitleItem = watermarkModel?.items?.first(where: { $0.idType == .watermarkSubtitle }), subTitleItem.isOpen == true {
            showSubTitle = true
            let subtitleSize = calSubTitleSize(isInline: isInLine, text: subTitleItem.content ?? "")
            smallTitleLabel.text = subTitleItem.content
            smallTitleLabel.width = subtitleSize.width
            smallTitleLabel.height = subtitleSize.height
            smallTitleLabel.top = self.bigTitleBg.bottom + 1
        } else {
            smallTitleLabel.text = ""
        }
        smallTitleLabel.textColor = watermarkTextColor
        

    
        if !showTitle, !showSubTitle {
            bigTitleBg.isHidden = true
        }else{
            bigTitleBg.isHidden = false
        }
        
        
    }
    
    func calTitleSize(isInline: Bool, text: String) -> CGSize {
       // let maxWidth = isInline ? (currentAnimationViewWidth - 50 - 12) : (currentAnimationViewWidth - 12)
        let maxWidth = currentAnimationViewWidth
        let labelSize = text.size(WithFont: bigTitleLabel.font, ConstrainedToWidth: maxWidth)
        return CGSize.init(width: labelSize.width, height: labelSize.height)
    }
    
    func calSubTitleSize(isInline: Bool, text: String) -> CGSize {
        //let maxWidth = isInline ? (currentAnimationViewWidth - 50 - 12) : (currentAnimationViewWidth - 12)
        let maxWidth = currentAnimationViewWidth
        let labelSize = text.size(WithFont: smallTitleLabel.font, ConstrainedToWidth: maxWidth)
        return CGSize.init(width: labelSize.width, height: labelSize.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
                
        resetLogoFrame()
                
        var middleViewH: CGFloat = 0
        let bgViewW: CGFloat = getBgViewWidth()
        
        layoutTopViews()
        
        let bgView_y: CGFloat = bgView.top
        
        let timeWidth = (timeLabel.text ?? "").size(WithFont: timeLabel.font, ConstrainedToWidth: 200).width + 6
        timeLabel.width = timeWidth
        timeLabel.top = arrowBar.bottom + 8.5
        
        let dateX = timeLabel.right + 4
        let dateMaxWidth = bgViewW - dateX - 3
        
        topDateLabel.frame = CGRect(x: dateX, y: timeLabel.top - 3, width: dateMaxWidth, height: dateHeight)
        bottomDateLabel.frame = CGRect(x: dateX, y: timeLabel.bottom  - dateHeight + 2, width: dateMaxWidth, height: dateHeight)
        
        let listTableView_h: CGFloat = topTableView.height
        let listTableViewWidth: CGFloat = bgViewW - 6
        
        topTableView.frame = CGRect(x: 6, y: timeLabel.bottom + 12, width: listTableViewWidth, height: listTableView_h)
        
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
                animationViewH = animationViewH+bigTitleBg.height-arrowBar.top+7
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
       // print("bgViewW \(bgViewW) bigTitleLabel \(bigTitleLabel.width)")
        var titleLeft: CGFloat =   (bgViewW-bigTitleLabel.width)/2
        let subTitleLeft: CGFloat =   (bgViewW-smallTitleLabel.width)/2
        // 处理logo
        bgView.top = 6
        
        var isInLine = false
        var isonWatermark = false
        var hasLogo = false
        if let logoModel = watermarkModel?.items?.first(where: { $0.idType == .logo }), logoModel.isOpen == true {
            hasLogo = true
            if logoModel.extraLogo.enumPosition == .inline {
                isInLine = true
            }
            if logoModel.extraLogo.enumPosition == .onWatermark {
                isonWatermark = true
            }
        }
        
        // 有logo
        if hasLogo {
            // 内嵌
            if isInLine {
                titleLeft = 50
                lineTopH = 48
                logoImageView.frame = CGRect(x: 1, y: 1, width: 42, height: 42)
            } else {
                if logoHeight > 0 && isonWatermark {
                    bgView.top = lineTopH + logoHeight + 12
                } else {
                    bgView.top = lineTopH
                }
            }
        }
        
        var smallHid = true
        var bigHid = true
        if let bigTitleItem = watermarkModel?.items?.first(where: { $0.idType == .watermarkTitle }), bigTitleItem.isOpen == true {
            bigHid = false
        }
        if let subTitleItem = watermarkModel?.items?.first(where: { $0.idType == .watermarkSubtitle }), subTitleItem.isOpen == true {
            smallHid = false
        }
    
        if smallHid == false || bigHid == false {
            
            // 处理标题副标题
            self.bigTitleLabel.frame = CGRect(x: titleLeft, y: 6, width: bgViewW - titleLeft - 10, height: 18)
            self.smallTitleLabel.frame = CGRect(x: subTitleLeft, y: self.bigTitleLabel.bottom + 1, width: bgViewW - subTitleLeft - 7, height: 18)
            //smallTitleLabel.sizeToFit()
            
            if bigHid == false && smallHid == false {
                lineTopH = smallTitleLabel.bottom+4
            } else if bigHid == false {
                if bigTitleLabel.height<lineTopH-8 {
                    bigTitleLabel.centerY = 48*0.5
                } else {
                    lineTopH = bigTitleLabel.bottom+4
                }
            } else if smallHid == false {
                if smallTitleLabel.height<lineTopH-8 {
                    smallTitleLabel.centerY = 48*0.5
                } else {
                    smallTitleLabel.top = 10
                    lineTopH = smallTitleLabel.bottom+4
                }
            }
            // self.yellowLine.frame = CGRect(x: 0, y: lineTopH, width: bgViewW, height: 2)
             self.arrowBar.frame = CGRect(x: 3, y: lineTopH, width: bgViewW-6, height: arraowHeight)

            self.arrowBar2.frame = CGRect(x: 3, y: timeLabel.frame.origin.y+timeLabel.frame.height+2, width: bgViewW-6, height: arraowHeight)
           
        } else {
            arrowBar.frame = .zero
            bigTitleLabel.frame = .zero
            smallTitleLabel.frame = .zero
        }
        self.arrowBar2.frame = CGRect(x: 3, y: timeLabel.frame.origin.y+timeLabel.frame.height+2, width: bgViewW-6, height: arraowHeight)

        self.inlineLogoView.centerY = self.arrowBar.top*0.5
    }
}
