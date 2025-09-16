package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model

import com.google.android.gms.maps.GoogleMap
import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.address.WatermarkAddressItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.coordinate.WatermarkCoordinateItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.map.WatermarkMapItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.GPDateStyle
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.WatermarkTimeItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.logo.WatermarkLogoItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.weather.GpWeatherStyle


/**
 *  WatermarkItem 项
 *  waynelu
 */
data class WatermarkItem(
    @SerializedName("id") var id: Int? = null,
    @SerializedName("isOpen") var isOpen: Boolean? = null,
    @SerializedName("title") var title: String? = null,
    @SerializedName("content") var content: String? = null,
    @SerializedName("editType") var editType: Int? = null,
    @SerializedName("scale") var scale: Float? = null,
    @SerializedName("extraMapInfo")var extraMapInfo: WatermarkMapItem? = null,
    @SerializedName("extraTimeInfo") var extraTimeInfo: WatermarkTimeItem? = null,
    @SerializedName("extraAddressInfo") var extraAddressInfo: WatermarkAddressItem? = null,
    @SerializedName("logoInfo") var logoInfo: WatermarkLogoItem? = null,
    @SerializedName("extraCoordinateInfo") var extraCoordinateInfo: WatermarkCoordinateItem? = null,
    @SerializedName("weatherStyle") var weatherStyle: GpWeatherStyle = GpWeatherStyle.Celsius,
    ) {

    //根据id 来获取id Type
    val idType: WatermarkItemID
        get() {
            return WatermarkItemID.values().find { it.id == id } ?: WatermarkItemID.customItem
        }
    //标题可以编辑
    fun isTitleEditable(): Boolean {
        return idType in listOf(
            WatermarkItemID.customItem
        )
    }
    //内容可以编辑
    fun isContentEditable(): Boolean {
        return idType in listOf(
            WatermarkItemID.note,
            WatermarkItemID.wm8_meeting_title,
            WatermarkItemID.wm10_clean_title,
            WatermarkItemID.watermarkTitle,
            WatermarkItemID.watermarkSubtitle,
            WatermarkItemID.customItem,
            WatermarkItemID.phoneNumber1,
            WatermarkItemID.phoneNumber2,
            WatermarkItemID.serviceDetail1,
            WatermarkItemID.serviceDetail2,
            WatermarkItemID.serviceDetail3

        )
    }

    fun clone(): WatermarkItem {
        return WatermarkItem(
        id,
        isOpen,
        title,
        content,
        editType,
        scale, extraMapInfo,
        extraTimeInfo,
        extraAddressInfo,
        logoInfo,
        extraCoordinateInfo,
            weatherStyle
            )
    }
    val switchEnable: Boolean
        get() {
            return true
        }
    //是否可以点击，右边有没有箭头
    val clickable: Boolean
        get() {
        return (id in listOf(
            WatermarkItemID.customItem.id,
            WatermarkItemID.logo.id,
            WatermarkItemID.note.id,
            WatermarkItemID.watermarkTitle.id,
            WatermarkItemID.watermarkSubtitle.id,
            WatermarkItemID.coordinate.id,
            WatermarkItemID.map.id,
            WatermarkItemID.weather.id,
            WatermarkItemID.time.id,
            WatermarkItemID.phoneNumber1.id,
            WatermarkItemID.phoneNumber2.id,
            WatermarkItemID.serviceDetail1.id,
            WatermarkItemID.serviceDetail2.id,
            WatermarkItemID.serviceDetail3.id,
            WatermarkItemID.address.id,
            WatermarkItemID.wm7_area.id,
            WatermarkItemID.wm7_project.id,
            WatermarkItemID.wm7_operator.id,
            WatermarkItemID.wm7_developer.id,
            WatermarkItemID.wm7_inspection.id,
            WatermarkItemID.wm7_inspectior.id,
            WatermarkItemID.wm7_description.id,
            WatermarkItemID.wm10_clean_title.id,
        ))|| idType == WatermarkItemID.customItem}
    //地图类型额外信息
    var extraMap: WatermarkMapItem
        get() {
            if (extraMapInfo == null) {
                extraMapInfo = WatermarkMapItem().apply {
                    mapType = GoogleMap.MAP_TYPE_NORMAL
                }
            }
            return extraMapInfo!!
        }
        set(value) {this.extraMapInfo = value}
    var extraTime: WatermarkTimeItem
        get() {
            if (extraTimeInfo == null) {
                extraTimeInfo = WatermarkTimeItem().apply {
                    is12Hour = false
                    style = GPDateStyle.dayMonthYear
                    showWeek = true
                }
            }
            return extraTimeInfo!!
        }
        set(value) {this.extraTimeInfo = value}

    val extraAddress: WatermarkAddressItem
        get() {
            if (extraAddressInfo == null) {
                extraAddressInfo = WatermarkAddressItem().apply {
                    addressStyleInt = 0
                }
            }
            return extraAddressInfo!!
        }

}