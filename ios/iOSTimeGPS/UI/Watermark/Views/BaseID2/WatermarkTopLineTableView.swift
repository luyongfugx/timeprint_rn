//
//  WatermarkTopLineTableView.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/19.
//

import Foundation
import UIKit

class WatermarkTopLineTableView: UIView {
    var tableView: UITableView?
    var items: [WatermarkItem] = []
    var baseID: WatermarkModelBaseID?
    var maxWidth = 0.0
    var textColor: UIColor = .white
    var canShowLine: Bool = true
    // 左侧主题色条
    let verArrow: UIView = .init(backgroundColor: .fromHex("#0075FF"), cornerRadius: 0.5)

    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        buildUI()
    }
    
    func configDatas(baseID: WatermarkModelBaseID?, items: [WatermarkItem], canShowLine: Bool = true, maxWidth: CGFloat, textColor: UIColor, themeColor: UIColor) {
        self.items = items
        self.baseID = baseID
        self.canShowLine = canShowLine
        self.textColor = textColor
        self.maxWidth = maxWidth
        let tableSize = getTableHeight(items: items, maxWidth: maxWidth)
        self.width = tableSize.tableMaxW
        self.height = tableSize.tableMaxH
        self.tableView?.reloadData()
        verArrow.backgroundColor = themeColor
        verArrow.isHidden = !canShowLine
        self.setNeedsLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        if canShowLine {
            verArrow.frame = CGRect(x: 0, y: 8, width: 3, height: self.height - 16)
            tableView?.frame = CGRect(x: 10, y: 4, width: self.width - 10.0, height: self.height - 8.0)
        } else {
            tableView?.frame = CGRect(x: 10, y: 4, width: self.width - 10, height: self.height - 8.0)
        }
    }
    
}

extension WatermarkTopLineTableView: UITableViewDataSource, UITableViewDelegate {
    
    private func buildUI() {
        self.backgroundColor = UIColor.clear
        
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView?.register(WatermarkTopLineCell.self, forCellReuseIdentifier: "WatermarkTopLineCell")
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.separatorStyle = .none
        tableView?.separatorColor = UIColor.clear
        tableView?.backgroundColor = UIColor.clear
        tableView?.isScrollEnabled = false
        tableView?.isUserInteractionEnabled = false
        tableView?.clipsToBounds = false
        self.addSubview(tableView!)

        self.addSubview(verArrow)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let currentModel = self.items[indexPath.row]
        let cell_h = WatermarkTopLineCell.getCellHeight(text: currentModel.getShowText(baseID: baseID), maxWidth: maxWidth).1
        return cell_h
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentModel = self.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "WatermarkTopLineCell", for: indexPath) as! WatermarkTopLineCell
        let needBold = currentModel.idType == .time
        cell.configModel(text: currentModel.getShowText(baseID: baseID), textColor: textColor, needBold: needBold)
        return cell
    }
}

extension WatermarkTopLineTableView {
    
    // 获取tableView的高度
    func getTableHeight(items: [WatermarkItem], maxWidth: CGFloat) -> (tableMaxW: CGFloat, tableMaxH: CGFloat) {
        
        if items.count == 0 {
            return (0,0)
        }
                
        var table_h: CGFloat = 4.0 + 4.0
    
        var table_w: CGFloat = 0
        for item in items {
            let cellSize = WatermarkTopLineCell.getCellHeight(text: item.getShowText(baseID: baseID), maxWidth: maxWidth)
            let cell_h: CGFloat = cellSize.1
            table_h += cell_h
            
            let cell_w: CGFloat = cellSize.0.width
            if table_w<cell_w {
                table_w = cell_w
            }
        }
        
        return (table_w+16,table_h)
    }
}
