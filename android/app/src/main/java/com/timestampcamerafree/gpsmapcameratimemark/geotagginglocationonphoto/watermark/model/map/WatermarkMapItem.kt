package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.map

import com.google.android.gms.maps.GoogleMap
import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils


/**
 * 地图扩展信息
 *
 * @property mapType
 */
@GenerateNoArg
data class WatermarkMapItem (
    //放大缩小level 对应google map 的level
    @SerializedName("mapZoom") var mapZoom: Float = 13.0f,
    @SerializedName("mapType") var mapType:Int =   GoogleMap.MAP_TYPE_NORMAL) {
    fun getMapTypeString(mapType:Int): String {
        var mapTypeString = ""
        when (mapType) {
            GoogleMap.MAP_TYPE_NORMAL -> mapTypeString = GpUiUtils.getString(R.string.k_map_standard)
            GoogleMap.MAP_TYPE_SATELLITE -> mapTypeString = GpUiUtils.getString(R.string.k_map_satellite)
        }
        return mapTypeString
    }
}
