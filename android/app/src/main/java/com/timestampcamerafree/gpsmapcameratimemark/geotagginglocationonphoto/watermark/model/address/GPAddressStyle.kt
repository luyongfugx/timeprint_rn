package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.address

import com.google.gson.annotations.SerializedName

/**
 * GPAddressStyle 地址格式类型
 * @property style
 */
enum class GPAddressStyle (var style: Int) {
    @SerializedName("formatAddress")
    formatAddress(0), //全部
    @SerializedName("nameStreet")
    nameStreet(6), //名字接到
    @SerializedName("nameRegion")
    nameRegion(7),
    @SerializedName("nameCity")
    nameCity(8),
    @SerializedName("street")
    street(9),
    @SerializedName("streetRegion")
    streetRegion(10),
    @SerializedName("streetCity")
    streetCity(11),
    @SerializedName("streetCityCountry")
    streetCityCountry(12),
    @SerializedName("cityCountry")
    cityCountry(13),
    @SerializedName("addressName")
    addressName(5);
    //根据int值获得枚举
    companion object {
        fun fromStyle(style: Int): GPAddressStyle? {
            var s = values().find { it.style == style }
            s?.let {
                return s;
            }
            //默认是全部
            return formatAddress
        }
    }
}