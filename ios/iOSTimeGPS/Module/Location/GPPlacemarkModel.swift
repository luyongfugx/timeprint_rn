//
//  GPPlacemarkModel.swift
//  iOSTimeGPS
//
//  Created by batman on 2024/9/18.
//

import Foundation
import UIKit
import Contacts
import CoreLocation

enum FormattedAddressType: Int {
    case none = 0
    // formattedAddress3地址
    case formattedAddress3 = 1
    // formattedAddressDouhao地址
    case formattedAddressDouhao = 2
    // 自己拼接地址，POI+Street
    case formattedAddressPoi = 3
    // city, Country
    case formattedAddressCity = 4
}

// MARK: - 位置地标（省、市、区、镇、乡、具体地址），对应接口中的locationDetail
class GPPlacemarkModel: GPCodable {
    
    var country: String?      // 国家
    var province: String?     // 省
    var city: String?         // 市
    var district: String?     // 区
    var township: String?     // 乡镇
    var poi: String?          // 地点
    
    // V2.0.60:地图来源，取值范围：system / google / grab / here
    var from: String?
    // 高德定义的地址类型
    var typeCode: String?
    var originType: String?
    var postalCode: String?
    
    // V1.0.75: 逆地理国家编码ISOCountryCode
    var geoCountryCode: String?
    
    convenience init(country: String?, province: String?, city: String?, district: String?, township: String?, poi: String?, from: String?, typeCode: String?, originType: String?, postalCode: String?, geoCountryCode: String?) {
        self.init()
        self.country = country
        self.province = province
        self.city = city
        self.district = district
        self.township = township
        self.poi = poi
        self.from = from
        self.typeCode = typeCode
        self.originType = originType
        self.postalCode = postalCode
        self.geoCountryCode = geoCountryCode
    }
    
}

extension CLPlacemark {
    
    var poiStreet: String? {
        // 3、使用 POI+Street
        if let poi = self.areasOfInterest?.joined(separator: ", "), poi.count > 0 {
            var poiString = poi
            if let streetName = self.thoroughfare, streetName.count > 0 {
                poiString = "\(poiString), \(streetName)"
            }
            return poiString
        } else {
            return nil
        }
    }
    //add by waynelu,文件名的地址获取规则，后续可以在这里改
    var fileNameAddress: String? {
        // 3、使用 POI+Street
        if let poi = self.areasOfInterest?.joined(separator: ", "), poi.count > 0 {
           // var poiString = poi
            return poi
        } else {
            return nil
        }
    }
    
    var formattedAddress: String? {
        guard let postalAddress = postalAddress else {
            return nil
        }
        let formatter = CNPostalAddressFormatter()
        return formatter.string(from: postalAddress)
    }
    
    var formattedAddressDouhao: String? {
        guard let formattedAddress = formattedAddress else {
            return nil
        }
        let arr = formattedAddress.split(separator: "\n")
        var newAddressList: [String]? = NSMutableArray(array: arr) as? [String]
        // V2.0.40: 非中国大陆地区，最后一个信息包括国家时，直接去掉
        if let lastComponent = newAddressList?.last, let countryName = self.country, self.isoCountryCode != "CN", lastComponent.contains(countryName) {
            newAddressList?.removeLast()
        }
        if let countryName = self.country, self.isoCountryCode == "CN" {
            newAddressList?.removeAll(where: { $0 == countryName })
        }
        let address = newAddressList?.joined(separator: ", ")
        return address
    }
    
    /// Get a formatted address.
    var formattedAddress2: String? {
        guard let postalAddress = postalAddress else {
            return nil
        }
        
        let updatedPostalAddress: CNPostalAddress
        if postalAddress.isoCountryCode == "US" {
            // add "," after city name
            let mutablePostalAddress = postalAddress.mutableCopy() as! CNMutablePostalAddress
            mutablePostalAddress.city += ","
            updatedPostalAddress = mutablePostalAddress
        } else {
            updatedPostalAddress = postalAddress
        }
        
        return CNPostalAddressFormatter.string(from: updatedPostalAddress, style: .mailingAddress)
    }
    
    /// Get a formatted address.
    var formattedAddress3: String? {
        let addressList = self.addressDictionary?["FormattedAddressLines"] as? [String]
        var newAddressList: [String]? = NSMutableArray(array: addressList ?? []) as? [String]
        // V2.0.40: 非中国大陆地区，最后一个信息包括国家时，直接去掉
        if let lastComponent = newAddressList?.last, let countryName = self.country, self.isoCountryCode != "CN", lastComponent.contains(countryName) {
            newAddressList?.removeLast()
        }
        if let countryName = self.country, self.isoCountryCode == "CN" {
            newAddressList?.removeAll(where: { $0 == countryName })
        }
        let address = newAddressList?.joined(separator: ", ")
        return address
    }
    
    // V2.0.65：获取有效formataddress地址
    func getValiedFormattedAddress() -> (String?, FormattedAddressType) {
        // 1、优先 formattedAddress3
        if let formattedAddress3 = formattedAddress3, formattedAddress3.count > 0 {
            return (formattedAddress3, .formattedAddress3)
        }
        
        // 2、formattedAddressDouhao 作为备份
        if let formattedAddressDouhao = formattedAddressDouhao, formattedAddressDouhao.count > 0 {
            return (formattedAddressDouhao, .formattedAddressDouhao)
        }
        
        // 3、使用 POI+Street
        if let poi = poiStreet, poi.count > 0 {
            return (poi, .formattedAddressPoi)
        }
                
        // 4、city+country
        if let locality, let country {
            let cityCountry = "\(locality), \(country)"
            return (cityCountry, .formattedAddressCity)
        }
        
        return (nil, .none)
    }
        
}
