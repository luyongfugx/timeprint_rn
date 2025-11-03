//
//  EditWatermarkVC+tableView.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/10.
//

import Foundation
import UIKit

extension EditWatermarkVC: UITableViewDataSource, UITableViewDelegate {
    
    func buildTableView() {
        editWatermarkContentView.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(bottomBarView.snp.top)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row <= self.items.count - 1 {
            let currentModel = self.items[indexPath.row]
            let favoriteTexts = currentModel.getItemContentFavoriteHistory()
            if !favoriteTexts.isEmpty {
                let calHeight = QuickOptionListView.calculateHeight(items: favoriteTexts, maxWidth2: EditWatermarkCell.maxContentWidth)
                return calHeight + 50
            }
        }
        return 50
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return needAddCustom ? (items.count + 1) : items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row <= self.items.count - 1 {
            let currentModel = self.items[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "EditWatermarkCell", for: indexPath) as! EditWatermarkCell
            cell.configModel(baseID: watermarkModel?.baseID, item: currentModel, block: { [weak self] isOpen in
                self?.switchItem(isOpen, currentModel)
            }, clickOptionBlock: { [weak self] in
                self?.reloadItems(indexPath)
            })
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddWatermarkCell", for: indexPath) as! AddWatermarkCell
            return cell
        }
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row <= self.items.count - 1 {
            let currentModel = self.items[indexPath.row]
            tableView.deselectRow(at: indexPath, animated: true)
            self.clickItem(currentModel)
        } else {
            self.gotoAddCustomItem()
        }
    }
}

extension EditWatermarkVC {
    
    func switchItem(_ isOn: Bool, _ item: WatermarkItem) {
        item.isOpen = isOn

        switch item.idType {
        case .note:
            if isOn, !isNotEmpty(item.content) {
                gotoEditContent(item: item, title: "k_edit_content".localized())
            }
        case .logo:
            if watermarkModel?.baseID == .ID7 {
                let list = watermarkModel?.logoItem()?.extraLogoListInfo.logoList?.compactMap({ logo in
                    if logo.isOpen == true {
                        return logo
                    }
                    return nil
                }) ?? []
                if list.isEmpty, isOn {
                    gotoChangeLogo(item)
                }
            } else {
                if item.getLogo() == nil, isOn {
                    gotoChangeLogo(item)
                }
            }
        case .weather:
            if isOn {
                WeatherManger.shared.requstWeather()
            }
        
        default:
            break
        }
        
        self.reloadDatas()

    }
    
    func clickItem(_ item: WatermarkItem) {
        switch item.idType {
        case .logo:
            // 添加logo/编辑logo TODO:
            gotoChangeLogo(item)
        case .watermarkTitle, .watermarkSubtitle:
            gotoEditCustomItem(item)
        case .note:
            gotoEditContent(item: item, title: "k_edit_content".localized())
            
        case .serviceDetail1,.serviceDetail2,.serviceDetail3:
            gotoEditPhoneNumber(item: item, title:"k_content".localized())
            
        case.phoneNumber1,.phoneNumber2:
            gotoEditPhoneNumber(item: item, title:"k_phone_number".localized())
            
        case .wm7_project:
            gotoEditContent(item: item, title: "k_edit_project".localized())
        case .wm7_developer:
            gotoEditContent(item: item, title: "k_edit_develop".localized())
        case .weather:
            gotoWeatherDetail()
        case .time:
            gotoEditTime(item)
        case .address:
            gotoEditAddress(item)
        case .map:
            gotoEditMap(item)
        case .customItem, .wm7_area, .wm7_operator, .wm7_inspection, .wm7_inspectior, .wm7_description:
            gotoEditCustomItem(item)
            
        default:
            break
        }
    }
    
    func gotoEditMap(_ item: WatermarkItem) {
        // 地图默认标注样式 style=0，卫星地图样式style=1
        let currentMapStyle: WatermarkMapStyle = item.getMapStyle() ?? .standard
        let vc = GPChooseHalfVC(title: "k_choose_map_style".localized(), selectIndex: currentMapStyle.rawValue, chooseOnce: true, dataList: [WatermarkMapStyle.standard.getTitle(), WatermarkMapStyle.satellite.getTitle()]) { [weak self] selectIndex in
            let chooseStyle = WatermarkMapStyle.init(rawValue: selectIndex) ?? .standard
            item.updateMapStyle(chooseStyle)
            self?.reloadDatas()
        }
        customPresent(vc, animated: true, completion: nil)
    }
    
    private func gotoEditAddress(_ item: WatermarkItem) {
        if GPSGeoManager.wartermarkGPSInfo.canEditAddress {
            let vc = EditAddressVC(addressItem: item.extraAddress) { [weak self] addressM in
                item.extraAddress = addressM
                self?.reloadDatas()
            }
            customPresent(vc, animated: true, completion: nil)
        }
        
    }
    
    private func gotoEditTime(_ item: WatermarkItem) {
        let vc = EditTimeVC(timeItem: item.extraTime, baseID: watermarkModel?.baseID ?? .ID1) { [weak self] timeM in
            item.extraTime = timeM
            self?.reloadDatas()
        }
        customPresent(vc, animated: true, completion: nil)
    }
    private func gotoEditPhoneNumber(item: WatermarkItem , title: String){
                GPTextEditView.show(in: self.view, defaultText: item.content ?? "", placeHolder: "k_please_input".localized(), showTitle: title) { [weak self] content in
                    item.content = content
                    if content.count > 0 {
                        item.isOpen = true
                    }
                    self?.reloadDatas()
                } cancelHandler: {
                    // 取消
                }
    }
    private func gotoEditContent(item: WatermarkItem, title: String) {
//        GPTextEditView.show(in: self.view, defaultText: item.content ?? "", placeHolder: "k_please_input".localized(), showTitle: title) { [weak self] content in
//            item.content = content
//            if content.count > 0 {
//                item.isOpen = true
//            }
//            self?.reloadDatas()
//        } cancelHandler: {
//            // 取消
//        }
        if !isNotEmpty(item.title) {
            item.title = title
        }
        let customTtem = item
        guard let itemID = item.id else { return }
        let vc = WatermarkEditViewController(entryId: "\(itemID)", title: customTtem.title ?? "", content: customTtem.content ?? "") { [weak self] title, content in
            customTtem.content = content
            customTtem.title = title
            if content.count > 0 || title.count > 0 {
                customTtem.isOpen = true
                self?.reloadDatas()
            } else if content.count == 0 && title.count == 0 {
                // 删除条目
                self?.watermarkModel?.items?.removeAll(where: { $0 == customTtem })
                self?.reloadDatas()
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        self.present(nav, animated: true)
    }
    
    private func gotoAddCustomItem() {
        let customTtem = WatermarkItem()
        customTtem.id = Int(TimeManager.shared.getRealTime().toString_xh(format: "yyyyMMddhhmmss"))
        
        GPTitleContentEditView.show(in: self.view, showTitle: customTtem.title ?? "", showContent: customTtem.content ?? "") { [weak self] title, content in
            customTtem.content = content
            customTtem.title = title
            if content.count > 0 || title.count > 0 {
                customTtem.isOpen = true
                self?.watermarkModel?.items?.append(customTtem)
                self?.reloadDatas()
            }
        } cancelHandler: {
            //
        }
    }
    
    private func gotoEditCustomItem(_ customTtem: WatermarkItem) {
        
//        GPTitleContentEditView.show(in: self.view, showTitle: customTtem.title ?? "", showContent: customTtem.content ?? "") { [weak self] title, content in
//            customTtem.content = content
//            customTtem.title = title
//            if content.count > 0 || title.count > 0 {
//                customTtem.isOpen = true
//                self?.reloadDatas()
//            } else if content.count == 0 && title.count == 0 {
//                // 删除条目
//                self?.watermarkModel?.items?.removeAll(where: { $0 == customTtem })
//                self?.reloadDatas()
//            }
//        } cancelHandler: {
//            //
//        }
        guard let itemID = customTtem.id else { return }
        let vc = WatermarkEditViewController(entryId: "\(itemID)", title: customTtem.title ?? "", content: customTtem.content ?? "") { [weak self] title, content in
            customTtem.content = content
            customTtem.title = title
            if content.count > 0 || title.count > 0 {
                customTtem.isOpen = true
                self?.reloadDatas()
            } else if content.count == 0 && title.count == 0 {
                // 删除条目
                self?.watermarkModel?.items?.removeAll(where: { $0 == customTtem })
                self?.reloadDatas()
            }
        }
        let nav = UINavigationController(rootViewController: vc)
        self.present(nav, animated: true)
    }
    
    private func gotoChangeLogo(_ item: WatermarkItem) {
        
        func addLogo(fromVC: UIViewController) {
            let vc = GPChooseAddLogoVC()
            vc.complete = { [weak self] img in
                guard let self = self else { return }
                item.addLogo(img)
                item.isOpen = true
                self.reloadDatas()
            }
            fromVC.customPresent(vc, animated: true, completion: nil)
        }
        
        if watermarkModel?.baseID == .ID7 {
            // 多Logo特殊处理
            let vc = WatermarkMultiLogoEditViewController(logoListInfo: item.extraLogoListInfo) { [weak self] logoListItem in
                guard let self = self else { return }
                // 检测item是否应该打开
                item.isOpen = (logoListItem.logoList?.first(where: { $0.isOpen == true })) != nil
                self.reloadDatas()
            }
            customPresent(vc, animated: true, completion: nil)
        } else {
            // 如果没有logo那么直接添加
            if item.getLogo() == nil {
                addLogo(fromVC: self)
            } else {
                let editLogoVC2 = GPEditLogoVC(logoItem: item.extraLogo, complete: { [weak self] logo in
                    guard let self = self else { return }
                    self.reloadDatas()
                }, replaceAction: { [weak self] in
                    guard let self = self, let editLogoVC = self.editLogoVC else { return }
                    addLogo(fromVC: editLogoVC)
                })
                editLogoVC = editLogoVC2
                customPresent(editLogoVC2, animated: true, completion: nil)
            }
        }
        
    }
    
    func gotoWeatherDetail() {
        let vc = EditWeatherVC()
        customPresent(vc, animated: true, completion: nil)
    }
}

