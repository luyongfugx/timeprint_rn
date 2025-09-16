package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.address


import android.location.Address
import android.util.Log
import com.google.android.gms.maps.model.LatLng

/**
 * 组装地址显示类
 */
class GPWatermarkAddressInfo(placeMark: Address) {
    private var TAG:String ="GPWatermarkAddressInfo"
    private var formataddress: String? = null
    private var addressDic: MutableMap<GPAddressStyle, List<String?>>? = null
    private var pMark: Address? = null
    init {
        pMark = placeMark
        addressDic = mutableMapOf()
        for (item in GPAddressStyle.values()) {
            val componentList = mutableListOf<String?>()
            when (item) {
                GPAddressStyle.formatAddress -> componentList.add(placeMark.formattedAddress)
                GPAddressStyle.addressName -> componentList.add(placeMark.featureName) // 地点名称，比如某个建筑名称
                GPAddressStyle.nameStreet -> { // 地点名称+街道
                    componentList.add(placeMark.featureName)
                    componentList.add(placeMark.thoroughfare)
                }
                GPAddressStyle.nameRegion -> {
                    componentList.add(placeMark.featureName)
                    componentList.add(placeMark.subLocality)
                }
                GPAddressStyle.nameCity -> { //城市+建筑名称
                    componentList.add(placeMark.featureName)
                    componentList.add(placeMark.locality)
                }
                GPAddressStyle.street -> componentList.add(placeMark.thoroughfare)
                GPAddressStyle.streetRegion -> {
                    componentList.add(placeMark.thoroughfare)
                    componentList.add(placeMark.subLocality)
                }
                GPAddressStyle.streetCity -> {
                    componentList.add(placeMark.thoroughfare)
                    componentList.add(placeMark.locality)
                }
                GPAddressStyle.streetCityCountry -> {
                    componentList.add(placeMark.thoroughfare)
                    componentList.add(placeMark.locality)
                    componentList.add(placeMark.countryName)
                }
                GPAddressStyle.cityCountry -> {
                    componentList.add(placeMark.locality)
                    componentList.add(placeMark.countryName)
                }
            }
            addressDic?.set(item, componentList)
        }
    }



    fun getLatLng(): LatLng? {
        Log.d(TAG, "getLatLng: $pMark.")
        pMark?.let {
            if (pMark!!.latitude != 0.0 && pMark!!.longitude != 0.0){
                return LatLng(pMark!!.latitude, pMark!!.longitude)
            }
            else {
                return null
            }
        }
        return null;

    }
    /**
     * 根据用户的选择样式拼凑地址格式
     *
     * @param addressStyle
     * @return
     */
    fun getShowAddress(addressStyle: GPAddressStyle): String? {

        if (addressStyle != GPAddressStyle.formatAddress && addressDic?.containsKey(addressStyle) == true) {
            addressDic?.get(addressStyle)?.let { componentList ->
                getComponetMerge(componentList)?.let { address ->
                    return address
                }
            }
        }
        // 通过formatAddress类型，返回地址
        addressDic?.get(GPAddressStyle.formatAddress)?.let { formataddressList ->
            getComponetMerge(formataddressList)?.let { address ->
                return address
            }
        }

        return formataddress
    }

    /**
     * 获取所有格式
     *
     * @return
     */
    fun getAddressFormats():MutableMap<Int, String>{
        var formatMap: MutableMap<Int, String> = mutableMapOf()
        for (style in GPAddressStyle.values()) {
            var format = getShowAddress(style)
            if (format?.isNotEmpty() == true && formatMap.values.none { it == format }) {
                formatMap.put(style.style,format)
            }
        }
        return formatMap

    }
    private fun getComponetMerge(list: List<String?>): String? {
        val filteredList = list.filter { it?.isNotEmpty() == true } as List<*> // 过滤空字符串

        return if (pMark?.countryCode == "CN") {
            // 中国正着拼接
            filteredList.reversed().joinToString(", ")
        } else {
            // 其它国家反拼接
            filteredList.joinToString(", ")
        }
    }

    fun getAddressByStyle(style: GPAddressStyle): String? {
        addressDic?.get(style)?.let { addressList ->
            return getComponetMerge(addressList)
        }
        return null
    }
}

var Address.formattedAddress: String?
    get() {
        //如果有addressLine
        val addressLines = with(StringBuilder()) {
            getAddressLine(0)?.let { append(it) }
        }
        return addressLines?.toString()
    }
    set(value) { /* 不需要 setter */ }


var Address.addressLines: MutableList<String>?
    get() = null
    set(value) { /* 不需要 setter */ }









