package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime

import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils

/**
 * 是否显示周，小时，和时区
 *
 * @property style
 */
enum class GPDateExtenstionStyle (var style: Int) {
    @SerializedName("week")
    week(0),
    @SerializedName("hour")
    hour(1),
    @SerializedName("timezone")
    timezone(2);
    fun getText(): String  = when (this) {
        week -> GpUiUtils.getString(
            R.string.k_weak_time)
        hour -> GpUiUtils.getString(R.string.k_hour_time)
        timezone -> GpUiUtils.getString(R.string.k_timezone_time)
    }
}