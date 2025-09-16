package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime

import com.google.gson.annotations.SerializedName


/**
 * 日期格式
 */
enum class GPDateStyle(var style: Int) {
    @SerializedName("yearMonthDateSpecialCountry")
     yearMonthDateSpecialCountry(0),

    @SerializedName("dayMonthYear")
    dayMonthYear(1),

    @SerializedName("monthDayYear")
    monthDayYear(2);
    fun getDateFmt(): String  = when (this) {
        dayMonthYear -> "dd/MM/yyyy"
        monthDayYear -> "MM/dd/yyyy"
        yearMonthDateSpecialCountry -> "yyyy/MM/dd"
    }


}

/**
 * 日期格式
 */
enum class GPID9DateStyle(var style: Int) {

    // yy/mm/dd
    @SerializedName("yearMonthDate")
    yearMonthDate(0),
    // dd/mm/yy
    @SerializedName("dayMonthYear")
    dayMonthYear(1),
    // yy/mm/dd
    @SerializedName("monthDayYear")
    monthDayYear(2);
}




