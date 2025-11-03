//
//  WatermarkID12View.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2025/2/25.
// 简单水印，从会议水印修改过过来

class WatermarkID12View: BaseWatermark{
    let placeHolder = " "
    // 背景的view

    // 时间：21:30
    var timeLabel: UILabel = {
        let timeLabel = UILabel(text: "", textColor:.clear, textFont: UIFont.bigShouldersMedium(36), textAlignment: .left, numberLines: 0, backgroundColor: .clear, cornerRadius: 0)
        timeLabel.isHidden = true
        return timeLabel
    }()
    
    // 时间：21:30
    var timeView: ID12TimeView = {
        return ID12TimeView(frame: .zero)
    }()

    var tableWidth: CGFloat = 0
    var maxDateWidth: CGFloat = 0
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

    
    var lineView2: UIImageView  = UIImageView(image: UIImage(named: "sep_line"))

    var topTableView: WatermarkID12TopTableView = {
        let tableView = WatermarkID12TopTableView(frame: .zero)
        return tableView
    }()
    
    var themeColor: UIColor {
        return UIColor.white
    }
    
    //animation_View的宽度
    var currentAnimationViewWidth: CGFloat {
        let defaultWidth = GPApp.screenWidth - 100
        return sizeScale*defaultWidth
    }
    
    override func buildViews() {
        super.buildViews()
        
        timeView.frame = CGRect(x: 5, y: 3, width: 70, height: 32)
        animationView.addSubview(timeView)
        
        timeLabel.frame = CGRect(x: 5, y: 3, width: 70, height: 32)
        animationView.addSubview(timeLabel)
        
        bottomDateLabel.frame = CGRect(x: 5, y: 0, width: 0, height: defaultDateSize)
        animationView.addSubview(bottomDateLabel)
        
        topDateLabel.frame = CGRect(x: 5, y: 0, width: 0, height: defaultDateSize)
        animationView.addSubview(topDateLabel)
        
        lineView2.frame = CGRect(x: 5, y: 0, width: animationView.width-10, height: 1)
        
        animationView.addSubview(lineView2)
        animationView.addSubview(topTableView)
        outLogoPadding = 12
    }
    
    func getBgViewWidth() -> CGFloat {
        currentAnimationViewWidth - 12
    }
    
    override func updateUI() {
        super.updateUI()
        reloadTimes()
        
        let topDateLabelW = (topDateLabel.text ?? "").size(WithFont: topDateLabel.font, ConstrainedToWidth: 200).width+8
        let bottomDateLabelW = (bottomDateLabel.text ?? "").size(WithFont: bottomDateLabel.font, ConstrainedToWidth: 200).width+8
        maxDateWidth = max(topDateLabelW,bottomDateLabelW)
        tableWidth = currentAnimationViewWidth
        
        let watermarkThemeColor = watermarkModel?.templateColor ?? themeColor
        let watermarkTextColor = watermarkModel?.textColor ?? .black
        lineView2.image = lineView2.image?.withTintColor(watermarkThemeColor)
        topTableView.configDatas(baseID: watermarkModel?.baseID, items: watermarkModel?.allBottomOpenItem ?? [], maxWidth: tableWidth, textColor: watermarkTextColor, themeColor: watermarkThemeColor)
        for item in animationView.subviews {
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
      //  timeLabel.text =  id43TimeInfo.hhmm
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
        let is12Hours = timeItemModel.is12Hour ?? false
        let watermarkTextColor = watermarkModel?.textColor ?? .black
        let timeArr = GPDateFormat.getID8TimeString(TimeManager.shared.getRealTime(), style: timeItemModel.dateStyleEnum, is12Hours: is12Hours)
        timeView.updateDate(dataList: timeArr, textColor: watermarkTextColor, rate: 2.6)
        
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
        
    override func layoutSubviews() {
        super.layoutSubviews()

        var content_y: CGFloat = 12
        resetLogoFrame()
        if logoHeight > 0 && logoImageView.image != nil {
            content_y = (logoImageView.bottom) + 4
        }
            
        timeView.top = content_y + 11
        timeView.left = 12
    
        let dateX = timeView.right + 6
        topDateLabel.frame = CGRect(x: dateX, y: timeView.top - 3, width: maxDateWidth, height: dateHeight)
        bottomDateLabel.frame = CGRect(x: dateX, y: timeView.bottom  - dateHeight + 3, width: maxDateWidth, height: dateHeight)
        lineView2.left = 12
        lineView2.top = timeView.bottom + 10
        lineView2.width = bottomDateLabel.right - lineView2.left
        let listTableView_h: CGFloat = topTableView.height
        let listTableViewWidth: CGFloat = tableWidth
        topTableView.frame = CGRect(x: 0, y: lineView2.bottom, width: listTableViewWidth, height: listTableView_h)
        let animationViewH = topTableView.bottom + 10
        var animationViewW = listTableViewWidth + 2
        if logoWidth > 0 {
            animationViewW = max(animationViewW, logoWidth+12)
        }
        if animationView.bottom == 0 {
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
    
}
