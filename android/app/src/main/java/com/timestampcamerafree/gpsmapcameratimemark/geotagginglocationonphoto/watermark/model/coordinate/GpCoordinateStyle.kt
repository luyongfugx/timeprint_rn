package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.coordinate

import com.google.gson.annotations.SerializedName

/**
 * 经纬度格式
 *
 * @property style
 */
enum class GpCoordinateStyle (var style: Int) {
    //表示简易的度数格式，保留两位小数。
    @SerializedName("DegreeSimple")
    DegreeSimple(0),
    //表示精确的度数格式，保留六位小数。
    @SerializedName("DegreePrecise")
    DegreePrecise(1),
    // 表示度分秒格式。
    @SerializedName("Dms")
    Dms(2),
    //表示度和小数分格式。
    @SerializedName("DegreeDecimalMinute")
    DegreeDecimalMinute(3),
    //表示纯小数格式。
    @SerializedName("Decimal")
    Decimal(4);
    //根据int值获得枚举
    companion object {
        fun fromStyle(style: Int): GpCoordinateStyle? {
            var s = values().find { it.style == style }
            s?.let {
                return s;
            }
            //默认是全部
            return Decimal
        }
    }
}