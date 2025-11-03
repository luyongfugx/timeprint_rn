//
//  EditAddressVC.swift
//  iOSTimeGPS
//
//

import Foundation
import UIKit

class EditAddressVC: GPHalfBaseVC {
    
    private var viewHeight: CGFloat = 0
    
    override var preferredContentSize: CGSize {
        
        get { .init(width: view.bounds.width, height: viewHeight) }
        set {}
    }
    var complete: ((WatermarkAddressItem) -> Void)?
    var addressItem: WatermarkAddressItem
    var addressStyleList: [(GPAddressStyle, String)] = []

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
    
    init(addressItem: WatermarkAddressItem, complete: ((WatermarkAddressItem) -> Void)?) {
        self.addressItem = addressItem
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
        vcTitle = "k_choose_addressstyle".localized()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
        }
        
        loadDatas()
    }
    
    func loadDatas() {
        let addressSet = NSMutableSet()
        for item in GPAddressStyle.allCases {
            if let address = GPSGeoManager.wartermarkGPSInfo.address?.getAddressByStyle(item), !address.isEmpty, !addressSet.contains(address) {
                addressStyleList.append((item, address))
                addressSet.add(address)
            }
        }
        tableView.reloadData()
        
        if let selectIndex = addressStyleList.firstIndex(where: { $0.0 == addressItem.addressStyle }) {
            DispatchQueue.main.asyncAfter(deadline: .now()+0.2) {
                self.tableView.scrollToRow(at: .init(row: selectIndex, section: 0), at: .middle, animated: true)
            }
        }
    }
}

extension EditAddressVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let currentModel = self.addressStyleList[indexPath.row]
        return ChooseFormatCell.getCellHeight(currentModel.1)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.addressStyleList.count
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let currentModel = self.addressStyleList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseFormatCell", for: indexPath) as! ChooseFormatCell
        cell.configData(isSelect: addressItem.addressStyle == currentModel.0, text: currentModel.1)
        cell.chooseBlock = { [weak self] in
            self?.addressItem.addressStyle = currentModel.0
            self?.tableView.reloadData()
            self?.handleComplete()
            self?.popOrDismissVC()
        }
        return cell
    }
    
    func handleComplete() {
        complete?(addressItem)
    }
}
