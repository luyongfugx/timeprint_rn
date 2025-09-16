package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.address

import android.location.Address
import com.google.android.gms.maps.model.LatLng
import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg

/**
 *
 *
 * @property addressStyleInt
 * @property rawAddress
 */
@GenerateNoArg
data class WatermarkAddressItem (
    //默认
    @SerializedName("addressStyleInt") var addressStyleInt: Int = GPAddressStyle.formatAddress.style,

    var rawAddress: List<Address> = listOfNotNull()){
    /**
     * 根据用户的选择样式拼凑地址格式
     * @return
     */
    fun getShowAddress():String {
        if (rawAddress.isEmpty()) return ""
        val address = rawAddress.get(0).let { GPWatermarkAddressInfo(it) }
        return GPAddressStyle.fromStyle(addressStyleInt)?.let { address.getAddressByStyle(it) } ?:""
    }
    //获取地址的n个格式，供选择
    fun getAddressFormats(): MutableMap<Int, String>? {
        if (rawAddress.isEmpty()) {
            return mutableMapOf()
        }

        rawAddress.let {
            val address = rawAddress[0].let { GPWatermarkAddressInfo(it) }
            return address.getAddressFormats()
        }
    }


    fun getLatLng(): LatLng? {
        rawAddress.let {
            if (rawAddress.isEmpty()) return null
            val address = GPWatermarkAddressInfo(rawAddress[0])
            return address.getLatLng()
        }
    }



}