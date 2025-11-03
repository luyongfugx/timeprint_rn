//
//  GPPhotoPreviewOrderModel.swift
//  iOSTimeGPS
//
//  Created by mac on 2024/11/2.
//

import Foundation

class XHPhotoPreviewOrderItemModel: GPCodable {
    var function: String?
    var icon: String?
    var name: String?
    var isShow: String?
    var iconFontType: IconFontType?
    var customShareType: XHPhotoShowShareType?
}

class XHPhotoPreviewOrderModel: GPCodable {
    var top: [XHPhotoPreviewOrderItemModel]?
    var bottom: [XHPhotoPreviewOrderItemModel]?
}

extension XHPhotoPreviewOrderModel {
    /// 构造 非特殊国家 默认的底部item
    static func buildInDefaultData() -> XHPhotoPreviewOrderModel? {
        
        func getShareTypeModel(_ type: XHPhotoShowShareType) -> XHPhotoPreviewOrderItemModel {
            let info = type.info
            var shareModel = createPhotoPreviewOrderItem(
                function: .directShare,
                icon: info.imageName,
                name: "i_share",
                customShareType: type
            )
            if type == .system {
                shareModel = createPhotoPreviewOrderItem(
                    function: .directShare,
                    name: "i_share",
                    iconFontType: .album_share,
                    customShareType: type
                )
            }
            return shareModel
        }
        
        let model = XHPhotoPreviewOrderModel()

        // 默认分享和删除项
        let defaultItems = createDefaultItems()
//        // 多图预览
//        if let multiPhotoItem = createMultiPhotoItem() {
//            defaultItems.insert(multiPhotoItem, at: 0)
//        }
        model.bottom = defaultItems

        if let type = XHPhotoShowShareType(rawValue: GPShareManager.photoShowShareTypeCacheKey), type.supportInfo().isSupport {
            model.bottom?.insert(getShareTypeModel(type), at: 0)
        } else {
            let defaultShareType = GPShareManager.getDefaultShareType()
            model.bottom?.insert(getShareTypeModel(defaultShareType), at: 0)
        }
        
        if GPCheetManager.isCheetMode {
            model.bottom?.removeAll(where: { $0.function == "more" || $0.function == "directShare" })
        }
        
        return model
    }
    
    /// 根据countryCode创建底部item，不同国家的分享item不同
    /// - Parameter countryCode: 国家代码
    static func buildItem(with countryCode: String?) -> XHPhotoPreviewOrderModel? {
        let model = XHPhotoPreviewOrderModel()

        let defaultItems = createDefaultItems()

        guard let countryCode = countryCode,
              let country = PhotoShowShareSpecialCountry(rawValue: countryCode) else {
            model.bottom = defaultItems
            return model
        }

        var bottomItems = country.getShareItems()
        bottomItems.append(contentsOf: defaultItems)
        model.bottom = bottomItems
        return model
    }
    
    static func createDefaultItems() -> [XHPhotoPreviewOrderItemModel] {
        let editItem = createPhotoPreviewOrderItem(
            function: .edit,
            name: "i_edit",
            iconFontType: .album_edit
        )
        let defaultShareItem = createPhotoPreviewOrderItem(
            function: .more,
            name: "i_share_more",
            iconFontType: .album_more
        )
        let deleteItem = createPhotoPreviewOrderItem(
            function: .delete,
            name: "i_delete",
            iconFontType: .album_delete
        )
        return [editItem, deleteItem, defaultShareItem]
    }
    
    static func createCustomShareItem(type: XHPhotoShowShareType) -> XHPhotoPreviewOrderItemModel {
        createPhotoPreviewOrderItem(function: .directShare, icon: type.info.imageName, name: type.info.title, customShareType: type)
    }
    
    static func createMultiPhotoItem() -> XHPhotoPreviewOrderItemModel? {
        return createPhotoPreviewOrderItem(
            function: .toMultiPhoto,
            icon: PhotoShowBottomViewItemType.toMultiPhoto.iconName,
            name: "i_kmz".localized()
        )
    }
    
    static func createPhotoPreviewOrderItem(
        function: PhotoShowBottomViewItemType,
        icon: String? = nil,
        name: String,
        iconFontType: IconFontType? = nil,
        customShareType: XHPhotoShowShareType? = nil
    ) -> XHPhotoPreviewOrderItemModel {
        let item = XHPhotoPreviewOrderItemModel()
        item.function = function.rawValue
        item.icon = icon
        item.name = name
        item.iconFontType = iconFontType
        item.customShareType = customShareType
        return item
    }
}

enum PhotoShowShareSpecialCountry: String, CaseIterable {
    case ID, VN, TH, IN, KH, MY, PH, KR, CO, MX, BR, PE, EC
    
    static func supportedCountry() -> [String] {
        PhotoShowShareSpecialCountry.allCases.map { $0.rawValue }
    }
    
    var shareTypes: [XHPhotoShowShareType] {
        let defaultShareTypes: [XHPhotoShowShareType]
        switch self {
        case .ID:
            defaultShareTypes = [.whatsApp]
        case .VN:
            defaultShareTypes = [.zalo, .fbMessenger]
        case .TH:
            defaultShareTypes = [.line, .fbMessenger]
        case .IN:
            defaultShareTypes = [.whatsApp, .telegram]
        case .KH, .CO, .MX, .BR, .PE, .EC:
            defaultShareTypes = [.whatsApp, .waBusiness]
        case .MY:
            defaultShareTypes = [.whatsApp]
        case .PH:
            defaultShareTypes = [.fbMessenger, .whatsApp]
        case .KR:
            defaultShareTypes = [.kakaoTalk, .telegram]
        }
        return defaultShareTypes
    }
    
    func getShareItems() -> [XHPhotoPreviewOrderItemModel] {
//        if let multiPhotoItem = multiPhotoItem(), let shareType = shareTypes.first {
//            return [shareItem(shareType)] + [multiPhotoItem]
//        }
        return shareTypes.map { shareItem($0) }
    }
    
    private func shareItem(_ type: XHPhotoShowShareType) -> XHPhotoPreviewOrderItemModel {
        XHPhotoPreviewOrderModel.createCustomShareItem(type: type)
    }
    
    private func multiPhotoItem() -> XHPhotoPreviewOrderItemModel? {
        XHPhotoPreviewOrderModel.createMultiPhotoItem()
    }
}
