//
//  WatermarkID16BottomView.swift
//  iOSTimeGPS
//
//  Created by waynelu on 2025/6/24.
//


import Foundation
import UIKit

class WatermarkID16BottomView: UIView {
    var gradientLayer: CAGradientLayer?
    var tableView: UITableView?
    var items: [WatermarkItem] = []
    var maxWidth = 0.0
    var baseID: WatermarkModelBaseID?
    var templateColor: UIColor = .white
    var textColor: UIColor = .white
    override init(frame: CGRect) {
        super.init(frame: CGRect.zero)
        buildUI()
    }
    
    func configDatas(baseID: WatermarkModelBaseID? = nil, items: [WatermarkItem], maxWidth: CGFloat, templateColor: UIColor, textColor: UIColor) {
        self.items = items
        self.baseID = baseID
        self.templateColor = templateColor
        self.textColor = textColor
        self.maxWidth = maxWidth - 12+20
        let tableSize = WatermarkID16BottomView.getTableHeight(items: items, maxWidth: self.maxWidth, baseID: baseID)
        self.width = tableSize.tableMaxW
        self.height = tableSize.tableMaxH
        self.tableView?.reloadData()
        self.setNeedsLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer?.frame = self.bounds
        tableView?.frame = CGRect(x: 6, y: 4, width: self.width - 12.0, height: self.height - 8.0)
    }
    
}

extension WatermarkID16BottomView: UITableViewDataSource, UITableViewDelegate {
    
    private func buildUI() {
        self.backgroundColor = UIColor.black.withAlphaComponent(0.1)
        
//        gradientLayer = UIColor.gradient(left: UIColor.fromHex("#FFFFFF", alpha: 0.3), right: UIColor.fromHex("#FFFFFF",alpha: 0), rect: CGRect.zero)
//        gradientLayer?.cornerRadius = 3
//        self.layer.addSublayer(gradientLayer!)
        
        tableView = UITableView(frame: CGRect.zero, style: .plain)
        tableView?.register(WatermarkID16BottomCell.self, forCellReuseIdentifier: "WatermarkID16BottomCell")
        tableView?.dataSource = self
        tableView?.delegate = self
        tableView?.separatorStyle = .none
        tableView?.separatorColor = UIColor.clear
        tableView?.backgroundColor = UIColor.clear
        tableView?.isScrollEnabled = false
        tableView?.isUserInteractionEnabled = false
        self.addSubview(tableView!)
        
        // 2.9.295
        tableView?.clipsToBounds = false
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let currentModel = self.items[indexPath.row]
        let isBold = currentModel.idType == .shortAddress
        let cell_h = WatermarkID16BottomCell.getCellHeight(text: currentModel.getShowText(baseID: baseID), maxWidth: maxWidth, isBold: isBold,item: currentModel).1
        return cell_h
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentModel = self.items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "WatermarkID16BottomCell", for: indexPath) as! WatermarkID16BottomCell
        print("tableView currentModel.getShowText \(currentModel.getShowText(baseID: baseID))")
        cell.configModel(text: currentModel.getShowText(baseID: baseID), textColor: textColor, isBold: currentModel.idType == .shortAddress,item:currentModel,templateColor:templateColor)
        return cell
    }
}

extension WatermarkID16BottomView {
    
    // 获取tableView的高度
    class func getTableHeight(items: [WatermarkItem], maxWidth: CGFloat, baseID: WatermarkModelBaseID?) -> (tableMaxW: CGFloat, tableMaxH: CGFloat) {
        
        if items.count == 0 {
            return (0,0)
        }
                
        var table_h: CGFloat = 4.0 + 4.0
        if baseID == .ID13 {
            table_h = 0
        }
    
        var table_w: CGFloat = 0
        for item in items {
            let cellSize = WatermarkID16BottomCell.getCellHeight(text: item.getShowText(), maxWidth: maxWidth, isBold: item.idType == .shortAddress,item:item)
            let cell_h: CGFloat = cellSize.1
            table_h += cell_h
            
            let cell_w: CGFloat = cellSize.0.width
            if table_w<cell_w {
                table_w = cell_w
            }
        }
        
        return (table_w+12,table_h)
    }
}
