//
//  GPLanguageManager.swift
//  XCamera
//
//  Copyright © 2023 xhey. All rights reserved.
//

import Foundation

public final class GPLanguageManager {

    enum LanguageType {
        
        enum EnglishLanguageType {
            case USA
            //马来西亚
            case MY
            // 菲律宾
            case PH
            case Other
        }
        
        ///西班牙语, "es": "es"
        case xibanyayu
        ///"hi": "hi",//印地语: hi
        case yindiyu
        ///"id": "id",//印尼语: id
        case yinniyu
        ///"ja": "ja",//日语: ja
        case riyu
        ///"ko": "ko",//韩语: ko
        case hanguoyu
        ///马来语: "ms": "ms",
        case malaiyu
        ///"th": "th",//泰语: th
        case taiyu
        ///"vi": "vi",//越南语: vi
        case yuenanyu
        ///"pt": "pt-PT",//葡萄牙语: pt-PT
        case putaoyayu
        ///孟加拉语: bn"bn": "bn",
        case mengjialayu
        ///"de": "de",//德语: de
        case deyu
        ///"ru": "ru",//俄语: ru
        case eyu
        ///"fr": "fr",//法语: fr
        case fayu
        ///"it": "it",//意大利语: it
        case yidaliyu
        ///"am": "am",//阿姆哈拉语: am
        case amuhalayu
        ///"sw": "sw",//斯瓦希里语: sw
        case siwaxiliyu
        ///"tr": "tr"//土耳其语: tr
        case tuerqiyu
        /// 中文: isSimplifiedChinese
        case chinese
        /// 英语
        case english(GPLanguageManager.LanguageType.EnglishLanguageType)
        case other
    }
    
    static let dic: [String: (String, GPLanguageManager.LanguageType)] = [
        "es": ("es", .xibanyayu),//西班牙语: es
        "hi": ("hi", .yidaliyu),//印地语: hi
        "id": ("id", .yinniyu),//印尼语: id
        "ja": ("ja", .riyu),//日语: ja
        "ko": ("ko", .hanguoyu),//韩语: ko
        "ms": ("ms", .malaiyu),//马来语: ms
        "th": ("th", .taiyu),//泰语: th
        "vi": ("vi", .yuenanyu),//越南语: vi
        "pt": ("pt-PT", .putaoyayu),//葡萄牙语: pt-PT
        "bn": ("bn", .mengjialayu),//孟加拉语: bn
        "de": ("de", .deyu),//德语: de
        "ru": ("ru", .eyu),//俄语: ru
        "fr": ("fr", .fayu),//法语: fr
        "it": ("it", .yidaliyu),//意大利语: it
        "am": ("am", .amuhalayu),//阿姆哈拉语: am
        "sw": ("sw", .siwaxiliyu),//斯瓦希里语: sw
        "tr": ("tr", .tuerqiyu)//土耳其语: tr
        // 中文: zh-Hans
        // 其余所有: en
    ]
        
    /// 判断当前语言是否是**简体中文**
    /// - Note: 映射表: [zh_Hans: 中文, 'en': 英文]
    public static var isSimplifiedChinese: Bool {
        currentLanguage == "zh_Hans" || currentLanguage == "zh-Hans"
    }
    
    /// iOS 获取App当前语言代码
    public static var currentLanguage: String {
        Bundle.main.preferredLocalizations.first ?? "en"
    }

    /// iOS 获取设备当前地区代码
    public static var localeIdentifier: String {
        
        // 保稳起见, 点击过app内的切换语言, 才使用app语言
        if currentLanguage.count > 0 {
            return currentLanguage
        }
        
        let resource = systemLocaleIdentifier()
        return resource
    }
    
    public static func shortDeviceLanguage2() -> String {
        
        let language = localeIdentifier
        if language.count >= 2 {
            return "\(language.prefix(2))"
        }
        return language
    }
    
    public static func shortAppLanguage2() -> String {
        let language = GPLanguageManager.xhSpecialLocaleIdentifier()
        if language.count >= 2 {
            return "\(language.prefix(2))"
        }
        return language
    }
    
    // V2.0.20
    public static func systemLocaleIdentifier() -> String {
        var resource = "en"
        
        if #available(iOS 16.0, *) {
            resource = Locale.current.language.languageCode?.identifier ?? "en"
        } else {
            resource = Locale.current.languageCode ?? "en"
        }
        
        return resource
    }
    /// 语言是否是印尼
    public static func isYN() -> Bool {
        
        let resource = localeIdentifier
        return resource == "id"
    }
    
    /// 获取水印业务特定地区代码映射
    public static func xhSpecialLocaleIdentifier(with defaultLocaleIdentifier: String = "en") -> String {
        let info = localeInfo(with: defaultLocaleIdentifier)
        return info.localeIdentifier
    }
    
    /// 快速获取语言代码,不经过localeInfo(with:)方法,省去获得languageType的步骤
    public static func fastLocaleIdentifier(with defaultLocaleIdentifier: String = "en") -> String {
        // 如果App语言是中文, 直接返回"zh-Hans"
        if isSimplifiedChinese {
            return "zh-Hans"
        }
        // 再将App语言和dic进行匹配
        if let match = dic.first(where: { localeIdentifier == $0.key }).map({ $0.value }) {
            return match.0
        }
        if let match = dic.first(where: { localeIdentifier.hasPrefix($0.key) }).map({ $0.value }) {
            return match.0
        }
        // 默认返回
        return defaultLocaleIdentifier
    }
    
    /// 获取水印业务特定地区代码映射
    static func localLanguageType(with defaultLocaleIdentifier: String = "en") -> GPLanguageManager.LanguageType {
        let info = localeInfo(with: defaultLocaleIdentifier)
        return info.languageType
    }
    
    private static func localeInfo(with defaultLocaleIdentifier: String = "en") -> (localeIdentifier: String, languageType: GPLanguageManager.LanguageType){
        
        /// 港澳台返回英文，特殊处理下
        if isSimplifiedChinese {
            return ("zh-Hans", .chinese)
        }
        
        /// 命中直接使用
        if let match = dic.first(where: { localeIdentifier == $0.key }).map({ $0.value }) {
            return match
        }
        
        /// 没命中检查，通过前缀匹配使用
        if let value = dic.first(where: { localeIdentifier.hasPrefix($0.key) }).map({ $0.value }) {
            return value
        }
        
//        let englishType = XHEnglishLanguageTypeHelper.shared.getEnglishLanguageType()
        
        /// 兜底
        return (localeIdentifier, .other)
    }
    
    static func contryISOCode() -> String? {
        return (NSLocale.autoupdatingCurrent as NSLocale).countryCode?.uppercased()
    }
    
    // 系统设置的国家地区是否中国
    static func deviceLocalIsChina() -> Bool {
        return contryISOCode() == "CN"
    }
}

extension GPLanguageManager {
    
//    static func languageRecordReport() {
//        
//        let curLanguageID = localeIdentifier
//        let perferredLanguage = currentLanguage
//        var lastLanguage = curLanguageID
//        
//        if let lastCached = UserDefaults.standard.string(forKey: XHGlobalConstant.UdKey.lastLanguageIDCacheKey), lastLanguage.count > 0 {
//            lastLanguage = lastCached
//        }
//        
//        UserDefaults.standard.setValue(curLanguageID, forKey: XHGlobalConstant.UdKey.lastLanguageIDCacheKey)
//        
//        Report.app_start_language_record(lastLanguage: lastLanguage, nowLanguage: curLanguageID, perferredLanguage: perferredLanguage)
//    }
}

public extension String {

    /// 本地化字符串，支持字符串格式化
    ///
    /// - 示例:
    ///
    /// ```
    /// /// 纯文本本地化
    /// /// 在`Localizable.strings`文件对应的语言目录下定义好`"首页" = "xxx"`
    /// someViewController.title = "首页".localized()
    /// ...
    ///
    /// /// 格式化字符串(单个)
    /// /// 在`Localizable.strings`文件对应的语言目录下定义好`"拜访客户" = "今日已拜访%@个客户"`
    ///
    /// let customers = CustomerManager.shared.customers
    /// countLabel.text = "拜访客户".localized(String(customers.count))
    /// LogDebug(countLabel.text)
    /// 输出: countLabel.text = "今日已拜访10个客户"
    ///
    ///
    /// /// 格式化字符串(多个)
    /// /// 在`Localizable.strings`文件对应的语言目录下定义好`"考勤统计" = "%@，本周拍照%@张， 迟到%@次"`
    ///
    /// let user = UserManager.shared
    /// textLabel.text = "考勤统计".localized(user.name, String(user.weekPhotos), String(user.lateTimes))
    /// 输出: textLabel.text = "张三，本周拍照10张， 迟到0次"
    ///
    /// ```
    /// - 注意事项：
    /// 在使用格式化的字符串是，需要保证**定义的参数类型和实际传入的参数类型保持一致**，否则会崩溃，比如：
    /// ```
    /// "用户名" = "用户：%@"
    /// countLabel.text = "用户名".localized(String(photos.count))
    /// ```
    /// 从测试验证的情况来看，定义为%@的形参，如果传入非对象参数，会崩溃
    ///
    /// - Note: 目前只支持默认文件`Localizable.strings`，对于自定义的本地文件不支持
    /// - Parameter arguments: 参数对应`%@`，**只能传入字符串，如果传入其他的，编译器会报错，防止类型错误引起的崩溃**
    /// - Parameter defalutValue: 默认值，当未获取到翻译的时候，会使用默认值
    /// - Returns: 返回对应的本地化字符串
    func localized(_ arguments: String...) -> String {
                
        let format = localized(using: nil, in: .main)
        let s = String(format: format, arguments: arguments)
        return s
    }

    func localized(using tableName: String?, in bundle: Bundle?) -> String {
        
        func trans(with lan: String) -> String? {
            let bundle: Bundle = bundle ?? .main
            if let path = bundle.path(forResource: lan, ofType: "lproj"), let bundle = Bundle(path: path) {
                return bundle.localizedString(forKey: self, value: nil, table: tableName)
            }
            return self
        }
        
        var resource = GPLanguageManager.localeIdentifier
        resource = GPLanguageManager.xhSpecialLocaleIdentifier()
        
//        if let path = bundle.path(forResource: resource, ofType: "lproj"), let bundle = Bundle(path: path) {
//            return bundle.localizedString(forKey: self, value: nil, table: tableName)
//        } else if let path = bundle.path(forResource: "en", ofType: "lproj"), let bundle = Bundle(path: path) {
//            return bundle.localizedString(forKey: self, value: nil, table: tableName)
//        }

        // V2.0.15: i_key翻译使用en进行兜底
        if let transResult = trans(with: resource), transResult.count > 0, transResult != self {
            return transResult
        } else if let transResult = trans(with: "en") {
            return transResult
        }
        return self
    }
    
    // 根据传入的语言翻译，做本地化
    func localized(targetLan: String) -> String {
        let bundle: Bundle = .main
        
        if let path = bundle.path(forResource: targetLan, ofType: "lproj"), let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: self, value: nil, table: nil)
        } else if let path = bundle.path(forResource: "en", ofType: "lproj"), let bundle = Bundle(path: path) {
            return bundle.localizedString(forKey: self, value: nil, table: nil)
        }
        return self
    }

    func availableLanguages() -> [String] {
        var availableLanguages = Bundle.main.localizations
        if let indexOfBase = availableLanguages.firstIndex(of: "Base") {
            availableLanguages.remove(at: indexOfBase)
        }
        return availableLanguages
    }
    
    // 多语言翻译，将%s都统一替换成%@
    // 后面使用Format格式化即可如 let txt = "My name is %@, I am %@ years old".format("Mickael", 24)
    func localizedFormatChange() -> String {
        let formatSourceStr = localized(using: nil, in: .main)
        return formatSourceStr.replacingOccurrences(of: "%s", with: "%@")
    }
    
    func format(_ arguments: CVarArg...) -> String {
        let args = arguments.map {
            if let arg = $0 as? Int { return String(arg) }
            if let arg = $0 as? Float { return String(arg) }
            if let arg = $0 as? Double { return String(arg) }
            if let arg = $0 as? Int64 { return String(arg) }
            if let arg = $0 as? String { return String(arg) }

            return "(null)"
        } as [CVarArg]

        return String.init(format: self, arguments: args)
    }

}

