//
//  WatermarkMultiLogoEditViewController.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/6.
//

import Foundation
import UIKit

class WatermarkMultiLogoEditViewController: GPHalfBaseVC {
    
    private var viewHeight: CGFloat = 0
    
    override var preferredContentSize: CGSize {
        
        get { .init(width: view.bounds.width, height: viewHeight) }
        set {}
    }
    var complete: ((WatermarkLogoListItem) -> Void)?
    var logoListInfo: WatermarkLogoListItem

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.isScrollEnabled = true
        tableView.register(WatermarkMultiLogoEditCell.self, forCellReuseIdentifier: "WatermarkMultiLogoEditCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 0)
        tableView.separatorColor = .border_medium
        tableView.tableHeaderView = UIView()
        return tableView
    }()
    
    init(logoListInfo: WatermarkLogoListItem, complete: ((WatermarkLogoListItem) -> Void)?) {
        self.logoListInfo = logoListInfo
        logoListInfo.checkInit()
        self.complete = complete
        self.viewHeight = editWatermarkHeightRate * GPApp.screenHeight
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bgColor = .clear
        view.backgroundColor = .white
        vcTitle = "i_logo_group".localized()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
        }
        
    }
    
}

extension WatermarkMultiLogoEditViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentModel = self.logoListInfo.logoList?[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "WatermarkMultiLogoEditCell", for: indexPath) as! WatermarkMultiLogoEditCell
        guard let currentModel else { return cell }
        cell.loadLogoItem(currentModel, title: "Logo\(indexPath.row+1)")
        cell.onSwitchValueDidChanged = { [weak self] isOn in
            if currentModel.logoPath == nil {
                // 弹起Logo面板选择
                self?.addLogo(logoItem: currentModel)
            } else {
                // 直接打开
                currentModel.isOpen = isOn
                self?.handleComplete()
            }
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentModel = self.logoListInfo.logoList?[indexPath.row]
        guard let currentModel else { return }
        self.addLogo(logoItem: currentModel)
    }
    
    func addLogo(logoItem: WatermarkLogoOneItem) {
        let vc = GPChooseAddLogoVC()
        vc.complete = { [weak self] img in
            guard let self = self else { return }
            logoItem.addLogo(img)
            
            logoItem.isOpen = true
            self.tableView.reloadData()
            handleComplete()
        }
        self.customPresent(vc, animated: true, completion: nil)
    }
    
    func handleComplete() {
        complete?(logoListInfo)
    }
    
}
