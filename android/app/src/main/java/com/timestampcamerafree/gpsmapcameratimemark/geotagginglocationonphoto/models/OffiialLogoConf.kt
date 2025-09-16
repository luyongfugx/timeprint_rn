
package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg

//{ "bottomRightLanguages": "en,ja,th,vi,ko,id,es",
// "bottomRightCountries": "MY,US",
// "bottomRightBaseUrl": "https://wm-1330977225.cos.ap-singapore.myqcloud.com/official_logo/timeprint20250607_",
// "topRightCountries": "MY",
// "topRightLanguages": "id",
// "topRightBaseUrl": "https://wm-1330977225.cos.ap-singapore.myqcloud.com/official_logo/timeprint20250607_"
// }
@GenerateNoArg
data class OfficialLogoConfig(
    @SerializedName("show") val show: Boolean,
    @SerializedName("bottomRightLanguages") val bottomRightLanguages: String,
    @SerializedName("bottomRightCountries") val bottomRightCountries: String,
    @SerializedName("bottomRightBaseUrl") val bottomRightBaseUrl: String,
    @SerializedName("topRightLanguages") val topRightLanguages: String,
    @SerializedName("topRightCountries") val topRightCountries: String,
    @SerializedName("topRightBaseUrl") val topRightBaseUrl: String
){
    fun getLogoUrlForLanguage(languageCode: String): String? {
        return when {
            bottomRightLanguages.split(",").contains(languageCode) -> bottomRightBaseUrl
            topRightLanguages.split(",").contains(languageCode) -> topRightBaseUrl
            else -> null
        }
    }
    fun getLogoPos(languageCode: String): String {
        return when {
            bottomRightLanguages.split(",").contains(languageCode) -> "br"
            topRightLanguages.split(",").contains(languageCode) -> "tr"
            else -> "br"
        }
    }
}