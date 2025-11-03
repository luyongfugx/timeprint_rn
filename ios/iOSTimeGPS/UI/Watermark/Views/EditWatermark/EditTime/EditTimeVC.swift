//
//  EditTimeVC.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/10/1.
//

import Foundation
import UIKit

class EditTimeVC: GPHalfBaseVC {
    
    private var viewHeight: CGFloat = 0
    
    override var preferredContentSize: CGSize {
        
        get { .init(width: view.bounds.width, height: viewHeight) }
        set {}
    }
    var complete: ((WatermarkTimeItem) -> Void)?
    var timeItem: WatermarkTimeItem
    var baseID: WatermarkModelBaseID
    var dateStyleList: [GPDateStyle] = [.yearMonthDateSpecialCountry, .dayMonthYear, .monthDayYear]
    var dateExtensionStyleList: [GPDateExtenstionStyle] = [.weak, .hour, .timezone]

    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.backgroundColor = .white
        tableView.separatorStyle = .singleLine
        tableView.isScrollEnabled = true
        tableView.register(ChooseFormatCell.self, forCellReuseIdentifier: "ChooseFormatCell")
        tableView.register(SwitchFormatCell.self, forCellReuseIdentifier: "SwitchFormatCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorInset = .init(top: 0, left: 16, bottom: 0, right: 0)
        tableView.separatorColor = .border_medium
        tableView.tableHeaderView = UIView()
        return tableView
    }()
    
    init(timeItem: WatermarkTimeItem, baseID: WatermarkModelBaseID, complete: ((WatermarkTimeItem) -> Void)?) {
        self.timeItem = timeItem
        self.baseID = baseID
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
        vcTitle = "k_choose_time_style".localized()
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navBar.snp.bottom)
        }
        tableView.reloadData()
    }
}

extension EditTimeVC: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        3
    }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let currentModel = self.dateStyleList[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChooseFormatCell", for: indexPath) as! ChooseFormatCell
            
            var timeContent = GPDateFormat.getDateFormatString(with: TimeManager.shared.getRealTime(), sytle: currentModel, needWeek: timeItem.showWeak ?? true)
            if WatermarkItem.specialTimeID.contains(baseID) {
                timeContent = GPDateFormat.localizedDateString(TimeManager.shared.getRealTime(), style: currentModel, is12Hours: timeItem.is12Hour ?? true, isShowWeek: timeItem.showWeak ?? true, isShowTimezone: timeItem.showTimeZone ?? false) ?? timeContent
            }
            
            cell.configData(isSelect: timeItem.dateStyle == currentModel.rawValue, text: timeContent)
            cell.chooseBlock = { [weak self] in
                self?.timeItem.dateStyle = currentModel.rawValue
                self?.tableView.reloadData()
                self?.handleComplete()
            }
            return cell
        } else if indexPath.section == 1 {
            let currentModel = self.dateExtensionStyleList[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "SwitchFormatCell", for: indexPath) as! SwitchFormatCell
            switch currentModel {
            case .hour:
                cell.configData(timeItem.is12Hour == false, "k_hour_time".localized())
            case .timezone:
                cell.configData(timeItem.showTimeZone == true, "k_timezone_time".localized())
            case .weak:
                cell.configData(timeItem.showWeak == true, "k_weak_time".localized())
            }
                        
            cell.swichBlock = { [weak self] isOpen in
                switch currentModel {
                case .hour:
                    self?.timeItem.is12Hour = !isOpen
                case .timezone:
                    self?.timeItem.showTimeZone = isOpen
                case .weak:
                    self?.timeItem.showWeak = isOpen
                }
                self?.tableView.reloadData()
                self?.handleComplete()
            }
            return cell
        }
        
        return UITableViewCell()
    }
    
    func handleComplete() {
        complete?(timeItem)
    }
}
