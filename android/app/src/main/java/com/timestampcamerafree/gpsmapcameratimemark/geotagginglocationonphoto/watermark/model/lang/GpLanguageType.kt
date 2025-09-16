package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.lang

/**
 * 语言类型
 *
 * @property id
 */
enum class GpLanguageType (var id: String) {
//    "es": ("es", .xibanyayu),//西班牙语: es
//    "hi": ("hi", .yidaliyu),//印地语: hi
//    "id": ("id", .yinniyu),//印尼语: id
//    "ja": ("ja", .riyu),//日语: ja
//    "ko": ("ko", .hanguoyu),//韩语: ko
//    "ms": ("ms", .malaiyu),//马来语: ms
//    "th": ("th", .taiyu),//泰语: th
//    "vi": ("vi", .yuenanyu),//越南语: vi
//    "pt": ("pt-PT", .putaoyayu),//葡萄牙语: pt-PT
//    "bn": ("bn", .mengjialayu),//孟加拉语: bn
//    "de": ("de", .deyu),//德语: de
//    "ru": ("ru", .eyu),//俄语: ru
//    "fr": ("fr", .fayu),//法语: fr
//    "it": ("it", .yidaliyu),//意大利语: it
//    "am": ("am", .amuhalayu),//阿姆哈拉语: am
//    "sw": ("sw", .siwaxiliyu),//斯瓦希里语: sw
//    "tr": ("tr", .tuerqiyu)//土耳其语: tr
    ///西班牙语, "es": "es"
    xibanyayu("es"),
    ///"hi": "hi",//印地语: hi
    yindiyu("hi"),
    ///"id": "id",//印尼语: id
    yinniyu("id"),
    ///"ja": "ja",//日语: ja
    riyu("ja"),
    ///"ko": "ko",//韩语: ko
    hanguoyu("ko"),
    ///马来语: "ms": "ms",
    malaiyu("ms"),
    ///"th": "th",//泰语: th
    taiyu("th"),
    ///"vi": "vi",//越南语: vi
    yuenanyu("vi"),
    ///"pt": "pt-PT",//葡萄牙语: pt-PT
    putaoyayu("pt"),

    ///孟加拉语: bn"bn": "bn",
    mengjialayu("bn"),
    ///"de": "de",//德语: de
    deyu("de"),
    ///"ru": "ru",//俄语: ru
    eyu("ru"),
    ///"fr": "fr",//法语: fr
    fayu("fr"),
    ///"it": "it",//意大利语: it
    yidaliyu("it"),
    ///"am": "am",//阿姆哈拉语: am
    amuhalayu("am"),
    ///"sw": "sw",//斯瓦希里语: sw
    siwaxiliyu("sw"),
    ///"tr": "tr"//土耳其语: tr
    tuerqiyu("tr"),
    /// 中文: isSimplifiedChinese
    simplifiedChinese("zh_Hans"),
    /// 中文: isTraditionalChinese
    traditionalChinese("zh_Hant"),
    /// 英语
    en_US("en_US"),
    en_My("en_MY"),
    en_Ph("en_PH"),
    en_other("en"),
    other(EnglishLanguageType.Other.id)
}