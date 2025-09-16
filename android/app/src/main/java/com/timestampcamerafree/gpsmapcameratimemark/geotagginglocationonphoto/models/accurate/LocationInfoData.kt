package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate;

import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg

@GenerateNoArg
data class LocationInfoData(
    @SerializedName("addressList") var addressList: ArrayList<PlaceItem>,
    @SerializedName("map_source") var map_source: String?
) {
    constructor() : this(arrayListOf(), "")
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is LocationInfoData) return false
        if (addressList != other.addressList) return false
        return true
    }
    override fun hashCode(): Int {
        var result = 0
        result = 31 * result + (addressList?.hashCode() ?: 0)
        return result
    }

    override fun toString(): String {
        return "LocationInfoData( addressList=$addressList, map_source=$map_source"
    }


}