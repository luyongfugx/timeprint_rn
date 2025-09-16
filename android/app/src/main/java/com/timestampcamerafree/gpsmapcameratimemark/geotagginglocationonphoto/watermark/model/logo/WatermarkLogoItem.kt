package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo

import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg


// Logo补充信息
@GenerateNoArg
data class WatermarkLogoItem(
    // 缩放大小
    @SerializedName("scale")  var scale: Float? = null,
    // 透明度大小
    @SerializedName("alpha")  var alpha: Float? = null,
    // 当前logo
    @SerializedName("selectLogoPath")  var selectLogoPath: String? = null,
    //原始logo,因为可能被去了背景，用来恢复
    @SerializedName("originLogoPath")  var originLogoPath: String? = null,
    //是否去了背景
    @SerializedName("isRemoveBg")  var isRemoveBg: Boolean? = false,
    // 当前预览的logoList
    @SerializedName("logoList") var logoList: Array<String?> = emptyArray(),
    // 位置，0 跟随水印位置，1左上 2右上 3中间
    @SerializedName("position")  var position: LogoPosition? = null
)
