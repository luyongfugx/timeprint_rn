package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime

import com.google.gson.annotations.SerializedName

/**
 * water mark time
 */
data class WatermarkTimeItem(
    @SerializedName("style")  var style: GPDateStyle = GPDateStyle.monthDayYear,
    @SerializedName("is12Hour") var is12Hour: Boolean = false,
    @SerializedName("showWeek") var showWeek: Boolean = true,
    @SerializedName("showTimeZone")  var showTimeZone: Boolean = false,
)