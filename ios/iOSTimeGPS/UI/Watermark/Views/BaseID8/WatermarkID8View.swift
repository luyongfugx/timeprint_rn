//
//  WatermarkID8View.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/12/14.
//



import Foundation
import UIKit

class WatermarkID8View: BaseWatermark{
    var bgTitleW: CGFloat = 69
    let placeHolder = " "
    // 背景的view
    var bgView: UIView = {
        let view = UIView()
        return view
    }()

    var quotImageView: UIImageView = UIImageView(image: UIImage(named: "quotation"))
    var bgColorView: UIView = {
        let bgView = UIView()
        bgView.backgroundColor = .white.withAlphaComponent(0.9)
        return bgView
    }()
    // 大标题的背景
    var bigTitleBg: UIView = { UIView(backgroundColor: UIColor.clear) }()
    // 大标题
    var bigTitleLabel: GPQStickerLabel = {
        return GPQStickerLabel(text: "", textColor: UIColor.fromHex("#FFEE5B"), textFont: UIFont.bigShouldersMedium(20), textAlignment: .center, numberLines: 0, backgroundColor: .clear, cornerRadius: 0)
    }()
    // 时间：21:30
    
    // 时间：21:30
    var timeView: ID8TimeView = {
        return ID8TimeView(frame: .zero)
    }()

    var dateHeight: CGFloat = 20
    let defaultDateSize: CGFloat = 14
    var needReCaculateDateFont: Bool = false
    
    // 日期：2022年1月31日
    var bottomDateLabel: UILabel = {
        return UILabel(text: "", textColor: UIColor.black, textFont: UIFont.robotoCondensedRegular(14), textAlignment: .left, numberLines: 0, backgroundColor: .clear, cornerRadius: 0)
    }()
    
    var topDateLabel: UILabel = {
        return UILabel(text: "", textColor: UIColor.black, textFont: UIFont.robotoCondensedRegular(14), textAlignment: .left, numberLines: 0, backgroundColor: .clear, cornerRadius: 0)
    }()

    
    var lineView: UIImageView  = UIImageView(image: UIImage(named: "sep_line"))
    var lineView2: UIImageView  = UIImageView(image: UIImage(named: "sep_line"))

    
    var topTableView: WatermarkID8TopTableView = {
        let tableView = WatermarkID8TopTableView(frame: .zero)
        return tableView
    }()
    
    var themeColor: UIColor {
        return UIColor.white
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


        
        bigTitleBg.frame = CGRect(x: 0, y: 0, width: 16, height: 16)
        bgView.addSubview(bigTitleBg)
        quotImageView.frame = CGRect(x: 8, y: 4, width: 16, height: 16)
        bgView.addSubview(quotImageView)
        
        bigTitleLabel.frame = CGRect(x: 8, y: 6, width: 0, height: 0)
        bigTitleLabel.lineBreakMode = .byCharWrapping
        bigTitleBg.addSubview(bigTitleLabel)
                
        lineView.frame = CGRect(x: 5, y: 0, width: bgView.width-10, height: 1)
    
        bgView.addSubview(lineView)
    
        timeView.frame = CGRect(x: 5, y: 3, width: 70, height: 32)
        bgView.addSubview(timeView)
        
        bottomDateLabel.frame = CGRect(x: 5, y: 0, width: 0, height: 14)
        bgView.addSubview(bottomDateLabel)
        
        topDateLabel.frame = CGRect(x: 5, y: 0, width: 0, height: 14)
        bgView.addSubview(topDateLabel)
        
        lineView2.frame = CGRect(x: 5, y: 0, width: bgView.width-10, height: 1)
        
        bgView.addSubview(lineView2)
        bgView.addSubview(topTableView)
        outLogoPadding = 6
    }
    
    func getBgViewWidth() -> CGFloat {
        currentAnimationViewWidth - 12
    }
    
    override func updateUI() {
        super.updateUI()
                
        let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
        let watermarkTextColor = watermarkModel?.textColor ?? .black

        // 时间
        reloadTimes()
        updateThemeText()
        topTableView.configDatas(baseID: watermarkModel?.baseID, items: watermarkModel?.allBottomOpenItem ?? [], maxWidth: currentAnimationViewWidth, textColor: watermarkTextColor, themeColor: watermarkThemeColor)
        
        bgColorView.backgroundColor = watermarkThemeColor.withAlphaComponent(0.9)
        bigTitleLabel.textColor = watermarkTextColor
        quotImageView.image = quotImageView.image?.withTintColor(watermarkTextColor)
        lineView.image = lineView.image?.withTintColor(watermarkTextColor)
        lineView2.image = lineView.image?.withTintColor(watermarkTextColor)
        
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
        // 获取时间
        guard let timeItem = watermarkModel?.items?.first(where: { $0.idType == .time }) else { return }
        let timeItemModel = timeItem.extraTime
        
        let id43TimeInfo = GPDateFormat.watermarkUICommpentForID5(with: timeItemModel)
  
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
//        updateTimeView(with: id43TimeInfo.hhmm)
        let is12Hours = timeItemModel.is12Hour ?? false
        let watermarkTextColor = watermarkModel?.textColor ?? .black
        let timeArr = GPDateFormat.getID8TimeString(TimeManager.shared.getRealTime(), style: timeItemModel.dateStyleEnum, is12Hours: is12Hours)
        timeView.updateDate(dataList: timeArr, textColor: watermarkTextColor)
        
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
        
        layoutIfNeeded()
    }
    
    //更新大标题,更新小标题
    private func updateThemeText() {
        var isInLine = false
        if let logoModel = watermarkModel?.items?.first(where: { $0.idType == .logo }), logoModel.isOpen == true, logoModel.extraLogo.enumPosition == .inline  {
            isInLine = true
        }
    
        self.bigTitleLabel.removeFromSuperview()
        self.bigTitleLabel.strokeWidth = 3
        self.bigTitleLabel.textColor = .black
        self.bigTitleLabel.textAlignment = .center
        self.bigTitleBg.addSubview(bigTitleLabel)
        
        var showTitle = false
      
        if let bigTitleItem = watermarkModel?.items?.first(where: { $0.idType == .wm8_meeting_title }), bigTitleItem.isOpen == true {
            showTitle = true
            let titleSize = calTitleSize(isInline: isInLine, text: bigTitleItem.content ?? "")
            self.bigTitleBg.width =  getBgViewWidth()
            bigTitleLabel.text = bigTitleItem.content
            bigTitleLabel.width = titleSize.width
            bigTitleLabel.height = titleSize.height
            self.bigTitleBg.height = titleSize.height + 30
            
        } else {
            self.bigTitleBg.width = 0
            self.bigTitleBg.height = 0
            bigTitleLabel.height = 0
            bigTitleLabel.text = ""
        }
                
        if !showTitle{
            bigTitleBg.isHidden = true
            lineView.isHidden = true;
            quotImageView.isHidden = true;
        }else{
            bigTitleBg.isHidden = false
            lineView.isHidden = false;
            quotImageView.isHidden = false;
        }
        
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
        if logoHeight > 0 && logoImageView.image != nil {
            bgView.top = (logoImageView.bottom) + 4
        }
    
        let bgView_y: CGFloat = bgView.top
        
        let topDateLabelW = (topDateLabel.text ?? "").size(WithFont: topDateLabel.font, ConstrainedToWidth: 200).width+8
        let bottomDateLabelW = (bottomDateLabel.text ?? "").size(WithFont: bottomDateLabel.font, ConstrainedToWidth: 200).width+8
        let timeWidth = max(topDateLabelW,bottomDateLabelW)
        if bigTitleBg.isHidden == false {
            timeView.top = lineView.bottom + 11
        }
        else {
            timeView.top = 11
        }
      
        timeView.left = 12
   
        let dateX = bgViewW - timeWidth-3
        let dateMaxWidth = bgViewW - dateX - 3
        topDateLabel.frame = CGRect(x: dateX, y: timeView.top - 3, width: dateMaxWidth, height: dateHeight)
        bottomDateLabel.frame = CGRect(x: dateX, y: timeView.bottom  - dateHeight + 4, width: dateMaxWidth, height: dateHeight)
        lineView2.top = timeView.bottom+8.5
        let listTableView_h: CGFloat = topTableView.height
        let listTableViewWidth: CGFloat = bgViewW - 6
        
        topTableView.frame = CGRect(x: 6, y: timeView.bottom + 4, width: listTableViewWidth, height: listTableView_h)
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
                animationViewH = animationViewH+bigTitleBg.height-lineView.top+7
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
        var titleLeft: CGFloat = 6
        // 处理logo
        var isInLine = false
        var hasLogo = false
        if let logoModel = watermarkModel?.items?.first(where: { $0.idType == .logo }), logoModel.isOpen == true {
            hasLogo = true
            if logoModel.extraLogo.enumPosition == .inline {
                isInLine = true
            }
        }
        

        if hasLogo {

                if logoHeight > 0 {
                    bgView.top = lineTopH
                }
        }
        
        if let bigTitleItem = watermarkModel?.items?.first(where: { $0.idType == .wm8_meeting_title }), bigTitleItem.isOpen == true {
           let  titleSize = calTitleSize(isInline: isInLine, text: bigTitleItem.content ?? "")
            titleLeft =  (bgViewW - titleSize.width)/2
        }
   
        self.bigTitleLabel.frame = CGRect(x: titleLeft, y: 8, width: bgViewW - titleLeft - 10, height: 20)
        bigTitleLabel.sizeToFit()
            if bigTitleLabel.height<lineTopH-8 {
                bigTitleLabel.centerY = 48*0.5
            } else {
                lineTopH = bigTitleLabel.bottom+12
            }
        self.lineView.frame = CGRect(x: 5, y: lineTopH, width: bgViewW-10, height: 1)
    }
}
