//
//  ClockInView.swift
//

class ClockInView: UIView {
    
    private lazy var bgView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        return view
    }()
    
    private lazy var checkIcon: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .scaleAspectFit
        imgView.image = UIImage(named: "confirm_yes")
        return imgView
    }()
    
    lazy var clockLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .white
        label.text = "clock in".localized()
        label.lineBreakMode = .byTruncatingTail
        return label
    }()
    
    var timeLB: UILabel = {
        return UILabel.init(text: "--:--", textColor: UIColor.black, textFont: .bebasDaka(32), textAlignment: .center)
    }()
        
    var ampmLabel: UILabel = {
        return UILabel.init(text: "--", textColor: UIColor.black, textFont: .systemFont(ofSize: 8), textAlignment: .left)
    }()
    
    var timeZoneLabel: UILabel = {
        return UILabel.init(text: "--", textColor: UIColor.black, textFont: .systemFont(ofSize: 8), textAlignment: .left)
    }()
    
    private lazy var logoImgView: UIImageView = {
        let imgView = UIImageView()
        imgView.layer.cornerRadius = 4
        imgView.clipsToBounds = true
        imgView.contentMode = .scaleAspectFit
        return imgView
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        buildViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func buildViews() {
        self.height = 44
        self.backgroundColor = .white
        self.layer.cornerRadius = 4

        addSubview(bgView)
        bgView.addSubview(checkIcon)
        bgView.addSubview(clockLabel)
        addSubview(timeLB)
        addSubview(ampmLabel)
        addSubview(timeZoneLabel)
        addSubview(logoImgView)
    }
    
    func updateData(bgColor: UIColor, clockTitle: String?, timeStr: String, amStr: String?, timezoneStr: String?, logo: UIImage?) {
        bgView.backgroundColor = bgColor
        timeLB.textColor = bgColor
        ampmLabel.textColor = bgColor
        timeZoneLabel.textColor = bgColor
        let padding = 6.0

        var bgWidth = 32.0
        let bgHeight = 32.0
        let logoSize = calculateLogoFrame(logo: logo)
        if let clockTitle, !clockTitle.isEmpty {
            var maxColorWidth = GPApp.screenWidth - 100 - 60 - 100 - (isNotEmpty(amStr) ? 30 : 0) - (isNotEmpty(timezoneStr) ? 56 : 0) - logoSize.width
            if maxColorWidth < 80 {
                maxColorWidth = 80
            }
            var clockWidth = clockTitle.size(WithFont: clockLabel.font, ConstrainedToWidth: 1000).width
            if clockWidth > maxColorWidth {
                clockWidth = maxColorWidth
            }
            clockLabel.text = clockTitle
            clockLabel.sizeToFit()
            clockLabel.width = clockWidth
            bgWidth = 26 + clockWidth + padding + 2
        } else {
            clockLabel.width = 0
            bgWidth = 32
        }
        checkIcon.frame = .init(x: 5, y: 3, width: 22, height: 22)
        checkIcon.centerY = bgHeight/2.0
        clockLabel.left = checkIcon.right + 2
        clockLabel.centerY = bgHeight/2.0
        bgView.frame = .init(x: padding, y: (44.0 - bgHeight)/2.0, width: bgWidth, height: bgHeight)
        timeLB.text = timeStr
        timeLB.sizeToFit()
        timeLB.left = bgView.right + padding
        timeLB.centerY = 22.0 - 1.5
        
        let timeLBright = timeLB.right + padding
        var startX = timeLBright
        if let amStr, !amStr.isEmpty {
            ampmLabel.text = amStr
            ampmLabel.sizeToFit()
            ampmLabel.left = startX
            startX = ampmLabel.right + padding
        } else {
            ampmLabel.width = 0
        }
        ampmLabel.top = 9.5
        
        if let timezoneStr, !timezoneStr.isEmpty {
            timeZoneLabel.text = timezoneStr
            timeZoneLabel.sizeToFit()
            timeZoneLabel.left = timeLBright
            startX = timeZoneLabel.right + padding
        } else {
            timeZoneLabel.width = 0
        }
        timeZoneLabel.top = 25
        
        if let logo {
            logoImgView.image = logo
            logoImgView.frame = .init(x: startX, y: (44.0 - logoSize.height)/2.0, width: logoSize.width, height: logoSize.height)
            startX = logoImgView.right + padding
        } else {
            logoImgView.frame = .zero
        }
        
        self.width = startX
    }
    
    private func calculateLogoFrame(logo: UIImage?) -> CGSize {
        guard let logo else { return .zero }
        var logoHeight = CGFloat(44 - 12)
        let widthRate = logo.size.height/logo.size.width
        let logoFirstW = logoHeight/widthRate
        var logoWidth = 0.0
        let maxLogoWidth = logoHeight*2
        if logoFirstW > maxLogoWidth {
            logoWidth = maxLogoWidth
            logoHeight = maxLogoWidth * widthRate
        } else {
            logoWidth = logoFirstW
        }
        return .init(width: logoWidth, height: logoHeight)
    }
}
