package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate;

import android.annotation.SuppressLint


data class AddressData(
    var places: ArrayList<AddressItem>,
    val geoInfo: GeoInfo
)

data class AddressItem(
    var name: String,
    val typecode: String,
    val address: String,
    val specialTip: String,
    val distance: String,
    val lat: Double,
    val lng: Double,
    val formattedAddress: String,
    var tel: String = "",
    var coverFile: String ="",
    var adcode: String = "", //区域编码
    var locationID:String = ""
)

@SuppressLint("")
data class GeoInfo(val address: String, val distance: String)
data class GlobalAddress(val largeAddressName: String, val smallAddressName: String)