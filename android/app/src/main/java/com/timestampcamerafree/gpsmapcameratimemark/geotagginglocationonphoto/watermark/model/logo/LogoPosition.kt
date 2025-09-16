package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo

import com.google.gson.annotations.SerializedName

// logo在水印上的位置
enum class LogoPosition(var position: Int) {
    @SerializedName("ON_WATER_MARK")
    ON_WATER_MARK(0),
    @SerializedName("LEFT_TOP")
    LEFT_TOP(1),
    @SerializedName("RIGHT_TOP")
    RIGHT_TOP(2),
    @SerializedName("CENTER")
    CENTER(3),
    @SerializedName("INLINE")
    INLINE(4),
    @SerializedName("RIGHT_BOTTOM")
    RIGHT_BOTTOM(5);
}