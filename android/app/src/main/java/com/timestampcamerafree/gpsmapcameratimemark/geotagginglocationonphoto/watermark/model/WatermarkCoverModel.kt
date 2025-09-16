package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model

import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg


// cover类
@GenerateNoArg
data class WatermarkCoverModel (
    @SerializedName("isSelect") var isSelect: Boolean? = null,
    @SerializedName("name") var name: String? = null,
    @SerializedName("cover") var cover: String?  = null,
    @SerializedName("watermark") var watermark: String?  = null,
    @SerializedName("watermarkModel")  var watermarkModel: BaseWatermarkModel? =null

)
