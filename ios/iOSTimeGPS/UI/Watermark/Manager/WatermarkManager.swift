//
//  WatermarkManager.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/8/17.
//

import Foundation
import UIKit

class WatermarkManager: NSObject {
    
    static let shared = WatermarkManager()
    //原有排序
//    dict baseID: Optional("1") id: Optional("1")
//    dict baseID: Optional("4") id: Optional("4")
//    dict baseID: Optional("2") id: Optional("2")
//    dict baseID: Optional("5") id: Optional("6")
//    dict baseID: Optional("7") id: Optional("8")
//    dict baseID: Optional("6") id: Optional("7")
//    dict baseID: Optional("4") id: Optional("5")
//    dict baseID: Optional("3") id: Optional("3")
//    dict baseID: Optional("8") id: Optional("8_1")
//    dict baseID: Optional("9") id: Optional("9_1")
//    dict baseID: Optional("10") id: Optional("10_1")
//    dict baseID: Optional("11") id: Optional("11_1")
//    
    //根据国家排序
//    let defaultSortArray: [WatermarkID] = [.ID1,.ID4,.ID2,.ID6,.ID8,.ID7,.ID5,.ID3,.ID8_1,.ID9_1,.ID10_1,.ID11_1]
//    let cnSortArray: [WatermarkID] = [.ID1,.ID4,.ID2,.ID6,.ID8,.ID7,.ID5,.ID3,.ID8_1,.ID9_1,.ID10_1,.ID11_1]
//    let usSortArray: [WatermarkID] = [.ID1,.ID4,.ID2,.ID6,.ID8,.ID7,.ID5,.ID3,.ID8_1,.ID9_1,.ID10_1,.ID11_1]
//    let vnSortArray: [WatermarkID] = [.ID1,.ID4,.ID10_1,.ID11_1,.ID2,.ID6,.ID8,.ID7,.ID5,.ID3,.ID8_1,.ID9_1]
//    let thSortArray: [WatermarkID] = [.ID1,.ID4,.ID8_1,.ID9_1,.ID2,.ID6,.ID8,.ID7,.ID5,.ID3,.ID10_1,.ID11_1]
//  
    //侵权后
   // let defaultSortArray: [WatermarkID] = [.ID1, .ID2,.ID4,.ID6, .ID12, .ID7, .ID8,.ID5,.ID3,.ID8_1,.ID9_1,.ID10_1,.ID11_1]
//        let cnSortArray: [WatermarkID] = [.ID12,.ID8_1,.ID9_1,.ID10_1,.ID11_1,.ID1]
//        let usSortArray: [WatermarkID] = [.ID12,.ID8_1,.ID9_1,.ID10_1,.ID11_1,.ID1]
//        let vnSortArray: [WatermarkID] = [.ID12,.ID8_1,.ID9_1,.ID10_1,.ID11_1,.ID1]
//        let thSortArray: [WatermarkID] = [.ID12,.ID8_1,.ID9_1,.ID10_1,.ID11_1,.ID1]
      
    let defaultSortArray: [WatermarkID] = [.ID13,.ID14,.ID1, .ID2, .ID15_1,.ID15_2, .ID4, .ID5,.ID6, .ID12, .ID7,.ID3,.ID8_1,.ID9_1,.ID10_1,.ID11_1]
    //去掉service name 和security ,如果当前用户是这个水印跳转到defaultSelectId
   // let defaultSortArray: [WatermarkID] = [.ID13,.ID14,.ID1, .ID2, .ID15,.ID4, .ID5,.ID12, .ID7,.ID3,.ID8_1,.ID9_1,.ID10_1,.ID11_1]
    // 新用户启用默认水印id
    // var defaultSelectId = "12"
     var defaultSelectId = "1"
    // 水印临时位置缓存
    var markPostionDic: [String: (edge: UIEdgeInsets, size: CGSize)] = [:]

    // 内存中使用的水印，从沙盒获取，获取不到再从内置的json中获取
    var watermarkModel: [String: BaseWatermarkModel] = [:]
    
    // 根据国家重新排序或者过滤，
    func reOrderOrFilterList(watermarkTemplateList: [WatermarkCoverModel]) ->  [WatermarkCoverModel] {
       // print("reOrderOrFilterList ===")
        /* 获取设备国家编码唯一入口:
            CN 中国
            US 美国
            ID 印尼
            JP 日本
            VN 越南
            TH 泰国
            ES 西班牙
            PT 葡萄牙 */
        
        var watermarkDictionary: [String: [WatermarkID]] = [:]
//        watermarkDictionary["CN"] = cnSortArray;
//        watermarkDictionary["US"] = usSortArray;
//        watermarkDictionary["VN"] = vnSortArray;
//        watermarkDictionary["TH"] = thSortArray;
        var watermarkList: [WatermarkCoverModel] = []
        
         var tempWatermarkDictionary: [String: WatermarkCoverModel] = [:]
        //先放入一个dict里
        for waterItem in watermarkTemplateList {
           // print("waterItem \(waterItem.watermarkModel?.id?.rawValue))")
         tempWatermarkDictionary[(waterItem.watermarkModel?.id?.rawValue)!] = waterItem
        }

       // let sortArray = watermarkDictionary[GPCountryManager.geoCountryCode] ?? defaultSortArray
        let sortArray =  defaultSortArray
        for wId in sortArray {
            if let waterMark = tempWatermarkDictionary[wId.rawValue] { // Ensure this returns a Watermark
                watermarkList.append(waterMark)
            }
        }
   
        return watermarkList
        
        
    }
    var watermarkTemplateList: [WatermarkCoverModel] {
        get {
            if let _localWatermarkTemplateList {
                //print("reOrderOrFilterList === _localWatermarkTemplateList ")
                return _localWatermarkTemplateList
            } else {
               // print("reOrderOrFilterList === _localWatermarkTemplateList else")
                let fileName = "filtercolor.json"
                guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else{
                    return []
                }
                guard let jsonData = try? Data.init(contentsOf: url) else{
                    return []
                }
                guard let jsonString = String.init(data: jsonData, encoding: .utf8), jsonString.count > 0 else{
                    return []
                }
                guard let categorys = SpeedyModel.anyToModel([WatermarkCoverModel].self, param: jsonString), categorys.count > 0 else{
                    return []
                }
                for cover in categorys {
                    cover.name = cover.name?.localized()
                    for item in cover.watermarkModel?.items ?? [] {
                        item.title = item.title?.localized()
                        item.content = item.content?.localized()
                    }
                }
                
                _localWatermarkTemplateList = reOrderOrFilterList(watermarkTemplateList: categorys)
                return _localWatermarkTemplateList!
             //return categorys
            }
        }
    }
    private var _localWatermarkTemplateList: [WatermarkCoverModel]?
    
    var watermarkCategoryList: [WatermarkCategory2] {
        get {
            if let _caregoryList {
               // print("_caregoryList === _caregoryList ")
                return _caregoryList
            } else {
               // print("_caregoryList === else ")
                let fileName = "filtercolor_en.json"
                guard let url = Bundle.main.url(forResource: fileName, withExtension: nil) else{
                    return []
                }
                guard let jsonData = try? Data.init(contentsOf: url) else{
                    return []
                }
                guard let jsonString = String.init(data: jsonData, encoding: .utf8), jsonString.count > 0 else{
                    return []
                }
                guard let categorys = SpeedyModel.anyToModel([WatermarkCategory2].self, param: jsonString), categorys.count > 0 else{
                    return []
                }
                //过滤掉k_inspection
                var filterCaregoryList: [WatermarkCategory2] = []
                for fileterCategory in categorys {
                   // if(fileterCategory.name != "k_inspection"){
                        filterCaregoryList.append(fileterCategory)
                   // }
                }
                for oneCategory in filterCaregoryList {
                    if(oneCategory.name == "k_general"){
                        //过滤掉通用里的service name 和 安保水印
                        oneCategory.list = reOrderOrFilterList(watermarkTemplateList: oneCategory.list ?? [] )
                    }
                    //翻译
                    oneCategory.name = oneCategory.name?.localized()
                    for cover in oneCategory.list ?? [] {
                        //service name 新版
                        if(cover.watermarkModel?.id == WatermarkID.ID5.rawValue){
                            cover.watermarkModel?.base_id = WatermarkModelBaseID.ID16.rawValue
                        }
                        for item in cover.watermarkModel?.items ?? [] {
                            item.title = item.title?.localized()
                            item.content = item.content?.localized()
                        }
                    }
                    
                }
                
                _caregoryList = filterCaregoryList
                return _caregoryList!
            }
        }
    }
    private var _caregoryList: [WatermarkCategory2]?
    
    /**
     
     */
    @GPPersistance(key: "com.gpscamera.key.selectWatermarkID", defaultValue: "1")
    static var selectStoreWatermarkID: String
    
    @GPPersistance(key: "com.gpscamera.key.hasupdateDefaultWatermarkID", defaultValue: false)
    static var hasupdateDefaultWatermarkID: Bool
    
    func getWatermarkID(from storeId: String) -> WatermarkID? {
        return WatermarkID(rawValue: storeId)
    }
    //增加一个逻辑，因为要下掉某些水印，之前在使用这个水印的用户强制跳转到新的默认水印
    func selectWatermarkID() -> String {
        let storeId = WatermarkManager.selectStoreWatermarkID
        let storeWatermarId: WatermarkID  = getWatermarkID(from: storeId) ?? WatermarkID.ID1
        //如果这个id已经不在水印列表里，强制跳到defaultSelectId
        if(!defaultSortArray.contains(storeWatermarId)){
            
            WatermarkManager.selectStoreWatermarkID = defaultSelectId
            return defaultSelectId
        }
        print("storeId \(storeId) storeWatermarId \(storeWatermarId) defaultSelectId\(defaultSelectId)")
        return storeId

    }

    // 获取当前选中的水印Model对象
    func getSelectWatermarkModel() -> BaseWatermarkModel {
                
        if watermarkModel.keys.contains(selectWatermarkID()), let model = watermarkModel[selectWatermarkID()] {
            return  model
        }
        if let selectModel = getWaterModelByID(selectWatermarkID()) {
            watermarkModel[selectModel.id ?? defaultSelectId] = selectModel
            return selectModel
        }
                
        // 新水印分类方式，获取水印
        for categoryItem in watermarkCategoryList {
            if let model = categoryItem.list?.first(where: { $0.watermarkModel?.id == selectWatermarkID() })?.watermarkModel {
                watermarkModel[model.id ?? defaultSelectId] = model
                return model
            }
        }
        
        if let model = watermarkTemplateList.first(where: { $0.watermarkModel?.id == selectWatermarkID() })?.watermarkModel {
            watermarkModel[model.id ?? defaultSelectId] = model
            return model
        }
        
        return BaseWatermarkModel()
    }
    /**
          清理本地数据
     */
    func clearLocalWaterModel() {
        if let _localWatermarkTemplateList {
            for model in _localWatermarkTemplateList {
                guard let watermarkID = model.watermarkModel?.id else { return }
                let key = getWatermarkLocalKey(watermarkID)
                LocalStorageManger.delDataFormLocal(key)
                GPDataCacheManager.shared.delCacheWatermarkCover(watermarkID)
            }
        }
        //都赋值为空
        watermarkModel.removeAll()
        _localWatermarkTemplateList = nil
    }
    
    // 保存水印对象到本地
    func saveWatermarkModel(_ model: BaseWatermarkModel?) {
        guard let model, let watermarkID = model.id else { return }
        let key = getWatermarkLocalKey(watermarkID)
        LocalStorageManger.saveDataToLocal(key, model)
    }
    
    // 根据水印ID获取本地水印对象
    func getWaterModelByID(_ watermarkID: String) -> BaseWatermarkModel? {
        let key = getWatermarkLocalKey(watermarkID)

        let baseModel  = LocalStorageManger.getDataFromLocal(key, BaseWatermarkModel())
        //ID5的baseID 强制跳转到baseID16
        if(baseModel?.id == WatermarkID.ID5.rawValue){
            baseModel?.base_id = WatermarkModelBaseID.ID16.rawValue
        }
        return baseModel
    }
    
    private func getWatermarkLocalKey(_ watermarkID: String) -> String {
        return LocalStorageManger.prefixLocalKey + "watermark_\(watermarkID)"
    }
    
}
