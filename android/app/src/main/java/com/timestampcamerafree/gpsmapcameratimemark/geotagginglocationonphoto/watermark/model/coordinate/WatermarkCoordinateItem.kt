package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.coordinate

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpLocationUtil

/**
 *
 * 经纬度item
 */
class WatermarkCoordinateItem {
    var coordinateStyle: Int = GpCoordinateStyle.Decimal.style
    var latitude: Double = 0.0
    var longitude: Double = 0.0

    fun getLatLngFormats(): MutableMap<Int, String>? {
         return  GpLocationUtil.formatLatLng(latitude, longitude)
    }

    //根据用户当前选择的格式，
    fun getShowLatLng():String {
        var latLngMap =  GpLocationUtil.formatLatLng(latitude,longitude)
        return GpCoordinateStyle.fromStyle(coordinateStyle)?.let { latLngMap.get(coordinateStyle) } ?:""
    }

}