//
//  GPButton.swift
//  iOSTimeGPS
//
//
import Foundation
import UIKit

/// 防连点按钮,默认防连点时间为1秒
open class GPButton: UIButton {
    
    var redDot: UIView?
    
    open var disableMultipleClickTimeInterval:TimeInterval = 1
    private var isEnabledClick: Bool = true
    private var iconType: IconFontType?
    
    /// 按钮样式
    var buttonStyle: ButtonStyle = .imageLeftTextRight(0, nil, .init(title: "", font: nil, titleColor: nil)) {
        didSet {
            configStyle()
        }
    }
    
    /// 按钮组件初始化
    /// - Parameters:
    ///   - frame: 按钮的frame
    ///   - style: 按钮样式
    /// - Version: 2.9.270
    /// - Date: 2022.06.02
    init(frame: CGRect = .zero, style: ButtonStyle = .imageLeftTextRight(0, nil, .init(title: "", font: nil, titleColor: nil))) {
        super.init(frame: frame)
        self.buttonStyle = style
        
        configStyle()
    }
        
    /// 设置按钮的固有大小
    open override var intrinsicContentSize: CGSize {
        
        var imageSize = imageView?.intrinsicContentSize ?? .zero
        var titleSize = titleLabel?.intrinsicContentSize ?? .zero
        
        if imageSize.width < 0 {
            imageSize.width = 0
        }
        
        if imageSize.height < 0 {
            imageSize.height = 0
        }
        
        if titleSize.width < 0 {
            titleSize.width = 0
        }
        
        if titleSize.height < 0 {
            titleSize.height = 0
        }
        
        switch buttonStyle {
        case .textLeftImageRight(let space, _, _), .imageLeftTextRight(let space, _, _):
            return .init(width: imageSize.width + titleSize.width + (imageSize == .zero ? 0 : space), height: max(imageSize.height, titleSize.height))
        case .textTopImageBottom(let space, _, _), .imageTopTextBottom(let space, _, _):
            return .init(width: max(imageSize.width, titleSize.width), height: imageSize.height + titleSize.height + (imageSize == .zero ? 0 : space))
        }
    }
    
    open override func setImage(_ image: UIImage?, for state: UIControl.State) {
        super.setImage(image, for: state)
        
        reloadEdgeInset()
    }
    
    open override func setTitle(_ title: String?, for state: UIControl.State) {
        super.setTitle(title, for: state)
        
        reloadEdgeInset()
    }
    
    convenience init(frame: CGRect, fontSize: CGFloat, iconType: IconFontType) {
        self.init(frame: frame)
        self.iconType = iconType
        self.titleLabel?.font = UIFont.iconfont(fontSize)
        self.setTitle(iconType.rawValue, for: .normal)
    }
    
    static func createImage(size: CGSize, iconType: IconFontType, imgColor: UIColor = .white) -> UIImage {
        let btn = GPButton(frame: .init(origin: .zero, size: size), fontSize: size.width, iconType: iconType)
        btn.setTitleColor(imgColor, for: .normal)
        return btn.screenshots()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        buildUI()
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        
    }
    
    open func buildUI() { }
    
    open override func sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        
        if disableMultipleClickTimeInterval > 0 {
            
            isUserInteractionEnabled = false
            super.sendAction(action, to: target, for: event)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + disableMultipleClickTimeInterval) {[weak self] in
                self?.isUserInteractionEnabled = true
            }
        } else {
            
            super.sendAction(action, to: target, for: event)
        }
        
        // 默认加按钮动画
        DispatchQueue.main.async {
            self.viewClickAnimation()
        }
    }
    
    open override func sendActions(for controlEvents: UIControl.Event) {
        
        if disableMultipleClickTimeInterval > 0 {
            
            isUserInteractionEnabled = false
            super.sendActions(for: controlEvents)
            
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + disableMultipleClickTimeInterval) {[weak self] in
                self?.isUserInteractionEnabled = true
            }
        } else {
            
            super.sendActions(for: controlEvents)
        }
        
        // 默认加按钮动画
        DispatchQueue.main.async {
            self.viewClickAnimation()
        }
    }
    
    func showRedDot(isShow: Bool, point: CGPoint = .zero) {
        if isShow {
            if redDot == nil {
                let _redDot = UIView(frame: .init(x: point.x, y: point.y, width: 10, height: 10))
                _redDot.layerCornerRadius = 5
                _redDot.backgroundColor = .red
                redDot = _redDot
                self.addSubview(_redDot)
            }
        } else {
            redDot?.isHidden = true
            redDot?.removeFromSuperview()
        }
        self.setNeedsLayout()
    }
        
}

extension GPButton {
    
    func reloadEdgeInset() {
        if imageView?.image != nil && (titleLabel?.text != nil && titleLabel?.text?.isEmpty == false) {
            
            titleEdgeInsets = .zero
            imageEdgeInsets = .zero
            
            switch buttonStyle {
            case .textLeftImageRight(let space, _, _):
                titleEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: space / 2)
                imageEdgeInsets = .init(top: 0, left: space / 2, bottom: 0, right: 0)
            case .imageLeftTextRight(let space, _, _):
                titleEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: -(space / 2))
                imageEdgeInsets = .init(top: 0, left: -(space / 2), bottom: 0, right: 0)
            case .textTopImageBottom(let space, _, _):
                let imageSize = imageView?.intrinsicContentSize ?? .zero
                let titleSize = titleLabel?.intrinsicContentSize ?? .zero
                titleEdgeInsets = .init(top: -imageSize.height - space / 2, left: -imageSize.width, bottom: 0, right: 0)
                imageEdgeInsets = .init(top: 0, left: 0, bottom: -titleSize.height - space / 2, right: -titleSize.width)
            case .imageTopTextBottom(let space, _, _):
                let imageSize = imageView?.intrinsicContentSize ?? .zero
                let titleSize = titleLabel?.intrinsicContentSize ?? .zero
                titleEdgeInsets = .init(top: 0, left: -imageSize.width, bottom: -imageSize.height - space / 2, right: 0)
                imageEdgeInsets = .init(top: -titleSize.height - space / 2, left: 0, bottom: 0, right: -titleSize.width)
            }
        }
        
    }
    
    /// 对按钮样式进行配置和绘制渲染
    /// - Version: 2.9.270
    /// - Date: 2022.06.02
    func configStyle() {
        switch buttonStyle {
        case .textLeftImageRight(let space, let icon, let titleConfig):
            setImage(icon, for: .normal)
            setImage(icon, for: .highlighted)
            setImage(icon, for: .disabled)
            setImage(icon, for: .selected)
            setTitle(titleConfig.title, for: .normal)
            setTitleColor(titleConfig.titleColor, for: .normal)
            titleLabel?.font = titleConfig.font
            self.semanticContentAttribute = .forceRightToLeft
            if icon != nil {
                titleEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: space / 2)
                imageEdgeInsets = .init(top: 0, left: space / 2, bottom: 0, right: 0)
            }
        case .imageLeftTextRight(let space, let icon, let titleConfig):
            setImage(icon, for: .normal)
            setImage(icon, for: .highlighted)
            setImage(icon, for: .disabled)
            setImage(icon, for: .selected)
            setTitle(titleConfig.title, for: .normal)
            setTitleColor(titleConfig.titleColor, for: .normal)
            titleLabel?.font = titleConfig.font
            self.semanticContentAttribute = .forceLeftToRight
            if icon != nil {
                titleEdgeInsets = .init(top: 0, left: 0, bottom: 0, right: -(space / 2))
                imageEdgeInsets = .init(top: 0, left: -(space / 2), bottom: 0, right: 0)
            }
        case .textTopImageBottom(let space, let icon, let titleConfig):
            setImage(icon, for: .normal)
            setImage(icon, for: .highlighted)
            setImage(icon, for: .disabled)
            setImage(icon, for: .selected)
            setTitle(titleConfig.title, for: .normal)
            setTitleColor(titleConfig.titleColor, for: .normal)
            titleLabel?.font = titleConfig.font
            if icon != nil {
                let imageSize = imageView?.intrinsicContentSize ?? .zero
                let titleSize = titleLabel?.intrinsicContentSize ?? .zero
                titleEdgeInsets = .init(top: -imageSize.height - space / 2, left: -imageSize.width, bottom: 0, right: 0)
                imageEdgeInsets = .init(top: 0, left: 0, bottom: -titleSize.height - space / 2, right: -titleSize.width)
            }
        case .imageTopTextBottom(let space, let icon, let titleConfig):
            setImage(icon, for: .normal)
            setImage(icon, for: .highlighted)
            setImage(icon, for: .disabled)
            setImage(icon, for: .selected)
            setTitle(titleConfig.title, for: .normal)
            setTitleColor(titleConfig.titleColor, for: .normal)
            titleLabel?.font = titleConfig.font
            if icon != nil {
                let imageSize = imageView?.intrinsicContentSize ?? .zero
                let titleSize = titleLabel?.intrinsicContentSize ?? .zero
                titleEdgeInsets = .init(top: 0, left: -imageSize.width, bottom: -imageSize.height - space, right: 0)
                imageEdgeInsets = .init(top: -titleSize.height - space, left: 0, bottom: 0, right: -titleSize.width)
            }
        }
    }
}

extension GPButton {
    
    // 让文字自适应按钮大小，且不超过一定边界
    func autoResize(titleInsect: UIEdgeInsets) {
        titleEdgeInsets = titleInsect
        titleLabel?.adjustsFontSizeToFitWidth = true
    }
    
}

public enum ButtonStyle {
    
    /// 左边图片右边文字
    /// - Parameters:
    ///  - space: 图片文字的间距
    ///  - icon: 图片（可为空）
    ///  - titleConfig: 按钮标题样式
    case imageLeftTextRight(_ space: CGFloat, _ icon: UIImage?, _ titleConfig: ButtonTitleStyleConfiguration)
    
    /// 左边文字右边图片
    /// - Parameters:
    ///  - space: 图片文字的间距
    ///  - icon: 图片（可为空）
    ///  - titleConfig: 按钮标题样式
    case textLeftImageRight(_ space: CGFloat, _ icon: UIImage?, _ titleConfig: ButtonTitleStyleConfiguration)
    
    /// 上边图片下边文字
    /// - Parameters:
    ///  - space: 图片文字的间距
    ///  - icon: 图片（可为空）
    ///  - titleConfig: 按钮标题样式
    case imageTopTextBottom(_ space: CGFloat, _ icon: UIImage?, _ titleConfig: ButtonTitleStyleConfiguration)
    
    /// 上边文字下边图片
    /// - Parameters:
    ///  - space: 图片文字的间距
    ///  - icon: 图片（可为空）
    ///  - titleConfig: 按钮标题样式
    case textTopImageBottom(_ space: CGFloat, _ icon: UIImage?, _ titleConfig: ButtonTitleStyleConfiguration)
}

/// 按钮组件的标题样式
public struct ButtonTitleStyleConfiguration {
    
    /// 按钮标题
    let title: String
    /// 按钮字体
    let font: UIFont?
    /// 按钮标题颜色
    let titleColor: UIColor?
}

enum ButtonSizeMode {
    case ultra_small
    case large
    case ultra_large
    
    /// 不同大小定义下的字体
    var font: UIFont? {
        switch self {
        case .ultra_small: return .title_small_bold
        case .large, .ultra_large: return .title_normal_bold
        }
    }
    
    /// 不同大小定义下的标准高度
    var standardHeight: CGFloat {
        switch self {
        case .ultra_small: return 32
        case .large: return 44
        case .ultra_large: return 48
        }
    }
}

enum GhostButtonTitleWeight {
    case regular
    case bold
    case body_large
    
    /// 不同字重下的字体
    var font: UIFont? {
        switch self {
        case .regular: return .body_normal
        case .bold: return .title_normal_bold
        case .body_large: return .body_large
        }
    }
}
