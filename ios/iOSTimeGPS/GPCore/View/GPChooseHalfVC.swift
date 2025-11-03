//
//  GPChooseHalfVC.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/6.
//

import Foundation
import UIKit

class GPChooseHalfVC: GPHalfBaseVC {
    
    private var viewHeight: CGFloat = 0
    
    override var preferredContentSize: CGSize {
        get { .init(width: view.bounds.width, height: viewHeight) }
        set {}
    }
    // 是否只选择一次
    var selectIndex = 0
    var chooseOnce = false
    var showTitle: String?
    var complete: ((Int) -> Void)?
    var dataList: [String] = []

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.isScrollEnabled = true
        tableView.register(ChooseFormatCell.self, forCellReuseIdentifier: "ChooseFormatCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 0)
        tableView.separatorColor = .border_medium
        tableView.tableHeaderView = UIView()
        return tableView
    }()
    
    class func calViewHeight(_ datas: [String]) -> CGFloat {
        var vHeight: CGFloat = 44 + GPApp.tabBarBottomHeight
        for item in datas {
            vHeight += ChooseFormatCell.getCellHeight(item)
        }
        return vHeight
    }
    
    init(title: String, selectIndex: Int, chooseOnce: Bool, dataList: [String], complete: ((Int) -> Void)?) {
        self.dataList = dataList
        self.showTitle = title
        self.selectIndex = selectIndex
        self.chooseOnce = chooseOnce
        self.complete = complete
        self.viewHeight = GPChooseHalfVC.calViewHeight(dataList)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bgColor = chooseOnce ? .black.withAlphaComponent(0.5) : .clear
        view.backgroundColor = .white
        vcTitle = showTitle ?? ""
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
        }
        loadDatas()
    }
    
    func loadDatas() {
        tableView.reloadData()
        if selectIndex < dataList.count {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                self.tableView.scrollToRow(at: .init(row: self.selectIndex, section: 0), at: .middle, animated: true)
            }
        }
    }
}

extension GPChooseHalfVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let currentModel = self.dataList[indexPath.row]
        return ChooseFormatCell.getCellHeight(currentModel)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataList.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentModel = self.dataList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseFormatCell", for: indexPath) as! ChooseFormatCell
        let cellIndex = indexPath.row
        cell.configData(isSelect: selectIndex == cellIndex, text: currentModel)
        cell.chooseBlock = { [weak self] in
            self?.selectIndex = cellIndex
            self?.tableView.reloadData()
            self?.handleComplete()
            if self?.chooseOnce == true {
                self?.popOrDismissVC()
            }
        }
        return cell
    }
    
    func handleComplete() {
        complete?(selectIndex)
    }
}
