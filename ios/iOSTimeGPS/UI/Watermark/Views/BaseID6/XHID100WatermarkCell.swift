//
//  XHID100WatermarkCell.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/28.
//

import UIKit

class XHID100WatermarkCell: GPTableviewCell {
    
    var titleLab: UILabel = { UILabel() }()
    var titleBGView: UIView = { UIView() }()
    var contentLab: UILabel = { UILabel() }()
    var contentBGView: UIView = { UIView() }()

    var centerLine: UIView = { UIView() }()
    var bottomLine: UIView = { UIView() }()
    var leftLine: UIView = { UIView() }()
    var rightLine: UIView = { UIView() }()
    
    let UIParams = ID100WatermarkUILayoutParams()
        
    // 是不是最下面的cell
    private var isLastCell: Bool = false
    var isCover = false

    override func buildUI() {
        super.buildUI()
        
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        titleLab.textColor = UIColor.white
        titleLab.font = UIParams.cell_textFont
        titleLab.numberOfLines = 0
        contentView.addSubview(titleLab)
        
        contentLab.textColor = UIColor.white
        contentLab.font = UIParams.cell_textFont
        contentLab.numberOfLines = 0
        contentView.addSubview(contentLab)
        
        centerLine.backgroundColor = UIParams.line_color
        contentView.addSubview(centerLine)
        
        bottomLine.backgroundColor = UIParams.line_color
        contentView.addSubview(bottomLine)
        
        leftLine.backgroundColor = UIParams.line_color
        contentView.addSubview(leftLine)
        
        rightLine.backgroundColor = UIParams.line_color
        contentView.addSubview(rightLine)
        
        contentView.insertSubview(titleBGView, at: 0)
        titleBGView.snp.makeConstraints { make in
            make.leading.equalTo(leftLine.right)
            make.top.equalToSuperview()
            make.trailing.equalTo(centerLine.snp.leading)
            make.bottom.equalTo(bottomLine.snp.top)
        }
        
        contentView.insertSubview(contentBGView, at: 0)
        contentBGView.snp.makeConstraints { make in
            make.leading.equalTo(centerLine.right)
            make.top.equalToSuperview()
            make.trailing.equalTo(rightLine.snp.leading)
            make.bottom.equalTo(bottomLine.snp.top)
        }

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        if bounds == .zero {
            return
        }
        
        let view_w = self.viewFrameWidth
        let view_h = self.viewFrameHeight
        
        let titleStr = self.titleLab.text ?? ""
        let contentStr = self.contentLab.text ?? ""
        
        let titleSize = Self.getLabelHeight(text: titleStr, font: UIParams.cell_textFont, maxWidth: UIParams.cell_title_width)
        let contentSize = Self.getLabelHeight(text: contentStr, font: UIParams.cell_textFont, maxWidth: UIParams.cell_content_width)
        
        titleLab.frame = CGRect(x: UIParams.cell_title_left, y: 0, width: UIParams.cell_title_width, height: titleSize.height)
        contentLab.frame = CGRect(x: UIParams.cell_content_left, y: 0, width: UIParams.cell_content_width, height: contentSize.height)
        
        centerLine.frame = CGRect(x: UIParams.center_line_left, y: 0, width: UIParams.center_line_width(isCover: isCover), height: view_h)
        leftLine.frame = CGRect(x: 0, y: 0, width: UIParams.out_line_width(isCover: isCover), height: view_h)
        rightLine.frame = CGRect(x: view_w - UIParams.out_line_width(isCover: isCover), y: 0, width: UIParams.out_line_width(isCover: isCover), height: view_h)
        
        if isLastCell {
            bottomLine.frame = CGRect(x: 0, y: view_h - UIParams.out_line_width(isCover: isCover), width: view_w, height: UIParams.out_line_width(isCover: isCover))
        } else {
            bottomLine.frame = CGRect(x: 0, y: view_h - UIParams.center_line_width(isCover: isCover), width: view_w, height: UIParams.center_line_width(isCover: isCover))
        }
    }
    
    // 填充数据
    func configData(title: String?, conent: String?, isLastCell: Bool, themeColor: UIColor, textColor: UIColor, isCover: Bool) {
        
        self.isCover = isCover
        self.isLastCell = isLastCell
        titleLab.text = title
        contentLab.text = conent
        titleLab.textColor = textColor
        contentLab.textColor = textColor

        centerLine.backgroundColor = themeColor
        bottomLine.backgroundColor = themeColor
        leftLine.backgroundColor = themeColor
        rightLine.backgroundColor = themeColor
        titleBGView.backgroundColor = themeColor.withAlphaComponent(0.1)
        contentBGView.backgroundColor = .black.withAlphaComponent(0.1)
        setNeedsLayout()
    }
}

extension XHID100WatermarkCell {
    
    // MARK: - 计算cell高度
    class func getCellHeight(titleStr: String?, contentStr: String?) -> (titleSize: CGSize, contentSize: CGSize, cell_h: CGFloat) {
                
        let UIParams = ID100WatermarkUILayoutParams()
                
        let titleSize = getLabelHeight(text: titleStr ?? "", font: UIParams.cell_textFont, maxWidth: UIParams.cell_title_width)
        let contentSize = getLabelHeight(text: contentStr ?? "", font: UIParams.cell_textFont, maxWidth: UIParams.cell_content_width)
        
        var cell_h: CGFloat = titleSize.height
        if contentSize.height > titleSize.height {
            cell_h = contentSize.height
        }
        
        if cell_h < 24 {
            cell_h = 24
        }
        
        return (titleSize, contentSize, cell_h)
    }
    
    // MARK: - 计算label高度
    class func getLabelHeight(text: String, font: UIFont, maxWidth: CGFloat) -> CGSize {
        
        var size = text.getStringSizeByLabel(WithFont: font, ConstrainedToWidth: maxWidth)
        var label_h: CGFloat = size.height + 10
        if label_h < 24 {
            label_h = 24
        }
        size = CGSize(width: size.width, height: label_h)
        return size
    }
}
