//
//  XHID100WatermarkTitleItemView.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/28.
//

import UIKit

class XHID100WatermarkTitleItemView: GPView {
    
    var leftLine: UIView = { UIView() }()
    var rightLine: UIView = { UIView() }()
    var bottomLine: UIView = { UIView() }()
    var titleLab: UILabel = { UILabel() }()
    
    let UIParams = ID100WatermarkUILayoutParams()
    
    var titleText: String?
    
    override func buildUI() {
        super.buildUI()
        
        leftLine.backgroundColor = UIParams.line_color
        addSubview(leftLine)
        
        rightLine.backgroundColor = UIParams.line_color
        addSubview(rightLine)
        
        bottomLine.backgroundColor = UIParams.line_color
        addSubview(bottomLine)
        
        titleLab.textColor = UIParams.titleItemColor
        titleLab.font = UIParams.titleItemFont
        titleLab.numberOfLines = 0
        titleLab.textAlignment = .center
        addSubview(titleLab)
    }
    
    func configData(titleText: String?, themeColor: UIColor, textColor: UIColor) {
        
        self.titleText = titleText
        
        guard let titleStr = titleText, titleStr.count > 0 else {
            titleLab.text = nil
            return
        }
        titleLab.textColor = textColor
        titleLab.text = titleStr
        
        backgroundColor = themeColor
        leftLine.backgroundColor = themeColor
        rightLine.backgroundColor = themeColor
        bottomLine.backgroundColor = themeColor
        
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.bounds == .zero {
            return
        }
        
        let view_w = self.viewFrameWidth
        let view_h = self.viewFrameHeight
        
        leftLine.frame = CGRect(x: 0, y: 0, width: UIParams.out_line_width(isCover: false), height: view_h)
        rightLine.frame = CGRect(x: view_w - UIParams.out_line_width(isCover: false), y: 0, width: UIParams.out_line_width(isCover: false), height: view_h)
        bottomLine.frame = CGRect(x: 0, y: view_h - UIParams.center_line_width(isCover: false), width: view_w, height: UIParams.center_line_width(isCover: false))
        
        let title_h = Self.getTitleItemHeight(content: self.titleText)
        titleLab.frame = CGRect(x: UIParams.titleItemLeft, y: 0, width: UIParams.titleItemWidth + 3.0, height: title_h)
    }
    
    func getTitleItemShowText() -> String? {
        return self.titleLab.text
    }
}

extension XHID100WatermarkTitleItemView {
    
    // 获取标题条目的高度
    static func getTitleItemHeight(content: String?) -> CGFloat {
        
        guard let content, content.count > 0 else {
            return 0
        }
        
        let UIParams = ID100WatermarkUILayoutParams()
        
        var titleSize = content.getStringSizeByLabel(WithFont: UIParams.titleItemFont, ConstrainedToWidth: UIParams.titleItemWidth)
        titleSize = CGSize(width: titleSize.width, height: titleSize.height + 10.0)
        
        var header_h: CGFloat = titleSize.height
        if header_h < 28 {
            header_h = 28
        }
        
        return header_h
    }
}
