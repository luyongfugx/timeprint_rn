//
//  WatermarkID6TableView.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/28.
//

import UIKit

import UIKit

struct ID100WatermarkUILayoutParams {
    
    // cell中标题的左边距
    let cell_title_left: CGFloat = 6.0
    
    // cell中标题的宽度
    let cell_title_width: CGFloat = 54.0
    
    // cell中内容的左边距
    let cell_content_left: CGFloat = 68.0
    
    // cell中内容的宽度
    let cell_content_width: CGFloat = 143.0
    
    // cell中的字体
    let cell_textFont = UIFont.robotoCondensedRegular(12)
    
    // 中间线的宽度
    func center_line_width(isCover: Bool) -> CGFloat {
        return isCover ? 3 : 0.5
    }
    
    // 外部线的宽度
    func out_line_width(isCover: Bool) -> CGFloat {
        return isCover ? 3 : 1.0
    }
    
    // 线的颜色
    let line_color = UIColor.fromHex("#74DDA2")
    
    // 顶部线的高度
    let top_line_height: CGFloat = 4.0
    
    // cell中中间线的左边距
    let center_line_left: CGFloat = 64.0
    
    // 表格的宽度
    let table_width: CGFloat = 215.0
    
    // 标题条目的字体
    let titleItemFont = UIFont.robotoCondensedBold(14)
    // 标题条目的字体
    let titleItemColor = UIColor.fromHex("#74DDA2")
    // 标题条目的左边距
    let titleItemLeft: CGFloat = 6
    // 标题条目的宽度
    let titleItemWidth: CGFloat = 203
}

class WatermarkID6TableView: GPView {
    
    var topLine: UIView = { UIView() }()
    
    var bgView: UIView = {
        UIView(backgroundColor: UIColor.fromHex("#000000", alpha: 0.4))
    }()
    
    var tableView: UITableView = {
        UITableView(frame: CGRect.zero, style: .plain)
    }()
    
    var headerView: XHID100WatermarkTitleItemView = { XHID100WatermarkTitleItemView() }()
    
    var items: [WatermarkItem] = []
    var baseID: WatermarkModelBaseID?
    var titleItem: WatermarkItem?
    
    let UIParams = ID100WatermarkUILayoutParams()
    
    var themeColor: UIColor = UIColor.fromHex("#74DDA2")
    var textColor: UIColor = UIColor.white
    var isCover: Bool = false

    override func buildUI() {
        super.buildUI()
        
        backgroundColor = UIColor.clear
        
        topLine.backgroundColor = UIParams.line_color
        addSubview(topLine)
        addSubview(bgView)
        
        tableView.register(XHID100WatermarkCell.self, forCellReuseIdentifier: "XHID100WatermarkCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.separatorColor = UIColor.clear
        tableView.backgroundColor = UIColor.clear
        tableView.isScrollEnabled = false
        tableView.isUserInteractionEnabled = false
        tableView.clipsToBounds = false
        
        // iOS 15 UITableView顶部空白解决方案
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0.0
        } else {
            // Fallback on earlier versions
        }
        
        addSubview(tableView)
    }
   
    func reloadDatas() {
        self.tableView.reloadData()
    }
    
    func configDatas(baseID: WatermarkModelBaseID?, items: [WatermarkItem], titleItem: WatermarkItem?, textColor: UIColor, themeColor: UIColor, isCover: Bool) {
        
        self.items = items
        self.baseID = baseID
        self.titleItem = titleItem
        self.themeColor = themeColor
        self.textColor = textColor
        self.isCover = isCover
        
        if let currentM = titleItem, currentM.isOpen == true, let titleStr = currentM.content, titleStr.count > 0 {
            self.tableView.tableHeaderView = self.headerView
            self.headerView.isHidden = false
            headerView.configData(titleText: titleStr, themeColor: themeColor, textColor: textColor)
        } else {
            self.tableView.tableHeaderView = nil
            self.headerView.isHidden = true
        }
        
        topLine.backgroundColor = themeColor
        
        tableView.reloadData()
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if self.bounds == .zero {
            return
        }
        
        let view_w = self.viewFrameWidth
        
        topLine.frame = CGRect(x: 0, y: 0, width: view_w, height: UIParams.top_line_height)
        
        let info = WatermarkID6TableView.getTableHeight(baseID: self.baseID, items: self.items, titleText: self.titleItem?.content)
        headerView.frame = CGRect(x: 0, y: 0, width: view_w, height: info.header_h)
        tableView.frame = CGRect(x: 0, y: UIParams.top_line_height, width: view_w, height: info.table_h - UIParams.top_line_height)
        bgView.frame = self.tableView.frame
    }
    
}

extension WatermarkID6TableView: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        let currentModel = self.items[indexPath.row]
        let cell_h = XHID100WatermarkCell.getCellHeight(titleStr: currentModel.title, contentStr: currentModel.getShowContent(baseID: baseID)).cell_h
        return cell_h
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let currentModel = self.items[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "XHID100WatermarkCell", for: indexPath) as? XHID100WatermarkCell {
            
            cell.configData(title: currentModel.title, conent: currentModel.getShowContent(baseID: baseID), isLastCell: (indexPath.row == (items.count - 1)), themeColor: self.themeColor, textColor: self.textColor, isCover: isCover)
            return cell
        }
        return UITableViewCell()
    }
}

extension WatermarkID6TableView {
    
    // 获取tableView的高度
    class func getTableHeight(baseID: WatermarkModelBaseID?, items: [WatermarkItem], titleText: String?) -> (table_h: CGFloat, header_h: CGFloat) {
        
        if items.count == 0, titleText == nil {
            return (0, 0)
        }
        
        let UIParams = ID100WatermarkUILayoutParams()
        
        // 标题的高度
        let header_h: CGFloat = XHID100WatermarkTitleItemView.getTitleItemHeight(content: titleText)
        
        // 表格的高度
        var table_h: CGFloat = 0
        for item in items {
            
            let cellSize = XHID100WatermarkCell.getCellHeight(titleStr: item.title, contentStr: item.getShowContent(baseID: baseID))
            let cell_h: CGFloat = cellSize.cell_h
            table_h += cell_h
        }
        
        // 4.5是顶部和底部线的高度
        return (table_h + UIParams.top_line_height + header_h, header_h)
    }
}
