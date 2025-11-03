//
//  WatermarkID8TopTableView.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2024/12/14.
//


import Foundation
import UIKit

class WatermarkID8TopTableView: UIView {
    var tableView: UITableView?
    var items: [WatermarkItem] = []
    var baseID: WatermarkModelBaseID?
    var maxWidth = 0.0
    var textColor: UIColor = .white

    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        buildUI()
    }
    
    func configDatas(baseID: WatermarkModelBaseID?, items: [WatermarkItem], maxWidth: CGFloat, textColor: UIColor, themeColor: UIColor) {
        self.items = items
        self.baseID = baseID
        self.textColor = textColor
        self.maxWidth = maxWidth
        let tableHeight = getTableHeight(items: items, maxWidth: maxWidth)
        self.height = tableHeight
        self.tableView?.reloadData()
        self.setNeedsLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        tableView?.frame = CGRect(x: 0, y: 4, width: self.width, height: self.height - 8.0)
    }
    
}

extension WatermarkID8TopTableView: UITableViewDataSource, UITableViewDelegate {
    
    private func buildUI() {
        self.backgroundColor = UIColor.clear
        
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView?.register(WatemrarkID8Cell.self, forCellReuseIdentifier: "WatemrarkID8Cell")
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.separatorStyle = .none
        tableView?.separatorColor = UIColor.clear
        tableView?.backgroundColor = UIColor.clear
        tableView?.isScrollEnabled = false
        tableView?.isUserInteractionEnabled = false
        tableView?.clipsToBounds = false
        self.addSubview(tableView!)

    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let currentModel = self.items[indexPath.row]
        let cell_h = WatemrarkID8Cell.getCellHeight(text: currentModel.getShowText(baseID: baseID), maxWidth: maxWidth)
        return cell_h
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentModel = self.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "WatemrarkID8Cell", for: indexPath) as! WatemrarkID8Cell
        cell.configModel(text: currentModel.getShowText(baseID: baseID), textColor: textColor)
        return cell
    }
}

extension WatermarkID8TopTableView {
    
    // 获取tableView的高度
    func getTableHeight(items: [WatermarkItem], maxWidth: CGFloat) -> CGFloat {
        if items.count == 0 {
            return 0
        }
        var table_h: CGFloat = 0.0
        for item in items {
            let cellSize = WatemrarkID8Cell.getCellHeight(text: item.getShowText(baseID: baseID), maxWidth: maxWidth)
            let cell_h: CGFloat = cellSize
            table_h += cell_h
        }
        return table_h
    }
}
