package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model

import android.graphics.Color
import com.google.gson.annotations.SerializedName

/**
 * 颜色值data类型，增加一个是否被选中的参数,默认为被选中
 *
 * @property isChecked
 * @property colorStr
 */
data class ColorData (@SerializedName("isChecked") var isChecked: Boolean = false, @SerializedName("colorStr")  var colorStr: String){
    fun getColor(): Int {
        val colorStr = colorStr?:"#FFFFFF"
        if(!colorStr.startsWith("#")){
            return Color.parseColor("#$colorStr")
        }
        return Color.parseColor(colorStr)
    }
}