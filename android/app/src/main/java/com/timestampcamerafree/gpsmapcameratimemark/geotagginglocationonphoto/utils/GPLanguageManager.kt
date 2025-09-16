package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.lang.GpLanguageType
import java.util.Locale

/**
 * GPLanguageManager 语言本地化类
 */
object  GPLanguageManager {
    private const val TAG = "GPLanguageManager"

    private val dic = mapOf(
        "es" to Pair("es", GpLanguageType.xibanyayu),//西班牙语: es
        "hi" to Pair("hi", GpLanguageType.yidaliyu),//印地语: hi
        "id" to Pair("id", GpLanguageType.yinniyu),//印尼语: id
        "ja" to Pair("ja", GpLanguageType.riyu),//日语: ja
        "ko" to Pair("ko", GpLanguageType.hanguoyu),//韩语: ko
        "ms" to Pair("ms", GpLanguageType.malaiyu),//马来语: ms
        "th" to Pair("th", GpLanguageType.taiyu),//泰语: th
        "vi" to Pair("vi", GpLanguageType.yuenanyu),//越南语: vi
        "pt" to Pair("pt-PT", GpLanguageType.putaoyayu),//葡萄牙语: pt-PT
        "bn" to Pair("bn", GpLanguageType.mengjialayu),//孟加拉语: bn
        "de" to Pair("de", GpLanguageType.deyu),//德语: de
        "ru" to Pair("ru", GpLanguageType.eyu),//俄语: ru
        "fr" to Pair("fr", GpLanguageType.fayu),//法语: fr
        "it" to Pair("it", GpLanguageType.yidaliyu),//意大利语: it
        "am" to Pair("am", GpLanguageType.amuhalayu),//阿姆哈拉语: am
        "sw" to Pair("sw", GpLanguageType.siwaxiliyu),//斯瓦希里语: sw
        "tr" to Pair("tr", GpLanguageType.tuerqiyu)//土耳其语: tr
        // 中文: zh-Hans
        // 其余所有: en
    )


    /// 获取水印业务特定地区代码映射
    fun localLanguageType(defaultLocaleIdentifier: String = "en") : GpLanguageType {
        var info = localeInfo(defaultLocaleIdentifier)
        return info.second
    }
    fun localeInfo(defaultLocaleIdentifier: String = "en") : Pair<String, GpLanguageType> {
        /// 港澳台返回英文，特殊处理下
        if (isSimplifiedChinese) {
            return Pair("zh-Hans", GpLanguageType.simplifiedChinese)
        }

        /// 命中直接使用
        dic[defaultLocaleIdentifier]?.let {
            return it
        }
        /// 没命中检查，通过前缀匹配使用
        dic.entries.firstOrNull { defaultLocaleIdentifier.startsWith(it.key) }?.value?.let {
            return it
        }

        
        /// 兜底
        return Pair(defaultLocaleIdentifier, GpLanguageType.other)
    }

    /// 判断当前语言是否是**简体中文**
    /// - Note: 映射表: [zh_Hans: 中文, 'en': 英文]
    val isSimplifiedChinese: Boolean
        get() {
            val locale = Locale.getDefault()
            return locale.language == "zh" && locale.country == "CN"
        }

    /// Android 获取App当前语言代码
    val currentLanguage: String
        get() {
            val locale = Locale.getDefault()
            return "${locale.language}-${locale.country}"
        }

    val currentLanguageOny: String
        get() {
            val locale = Locale.getDefault()
            return "${locale.language}"
        }
    val currentCountryOny: String
        get() {
            val locale = Locale.getDefault()
            return "${locale.country}"
        }
}