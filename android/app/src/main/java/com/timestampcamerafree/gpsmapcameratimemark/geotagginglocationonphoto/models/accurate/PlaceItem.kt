package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate

import android.os.Parcel
import android.os.Parcelable
import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg

//地址的来源，0是表示地址是使用系统api获取的，1是表示地址是使用服务端api获取的
const val ADDRESS_SOURCE_TYPE_SYSTEM = 0
const val ADDRESS_SOURCE_TYPE_SERVER = 1
@GenerateNoArg
data class PlaceItem @JvmOverloads constructor(
    @SerializedName("name") var name: String = "",
    @SerializedName("typecode") var typecode: String = "",
    @SerializedName("address") var address: String = "",
    @SerializedName("specialTip") var specialTip: String = "",
    @SerializedName("distance") var distance: String = "",
    @SerializedName("postalCode") var postalCode: String = "",
    @SerializedName("viewTypeHolder") var viewTypeHolder: Int = 0,
    var distanceNumeric: String = "", // 距离 单位米
    val from: String = "",   // 数据来源，preferLoc 常去地点，preferType 常去类型，aoi ，poi , road
    val originType: String? = null, // 原始数据来源类型，只有aoi,poi,road
    var lat: String = "",
    var lng: String = "",
    @SerializedName("locationID") var locationID: String = "",
    var formattedAddress: String = "",
    var streetAddress: String = "",
    val isMatchSearchText: Boolean = false
) : Parcelable {

    private var pureDistanceNumeric = Double.MAX_VALUE

    private var sourceType = ADDRESS_SOURCE_TYPE_SYSTEM // 0: 系统api 1：服务端api

    var sourceName: String = "system"

    fun setSourceType(type:Int){
        sourceType = type
    }

    fun getSourceType():Int{
        return sourceType
    }

    fun getPureDistance(defaultValue:Double = Double.MAX_VALUE):Double{
//        if (pureDistanceNumeric == Double.MAX_VALUE){
//            pureDistanceNumeric = distanceNumeric.toDoubleSafe(defaultValue)
//        }
        return pureDistanceNumeric
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is PlaceItem) return false
        if (name != other.name) return false
        return true
    }

//    fun convertToMixedPoiInfo(source:Int):MixedPoiInfo{
//        return MixedPoiInfo(lat,lng,name,address,distance, specialTip, typecode, source, locationID).also {
//            it.originType = this.originType
//            it.rawData = this
//            it.sourceType = this.sourceType
//        }
//    }

    override fun hashCode(): Int {
        return name?.hashCode() ?: 0
    }

    fun isSystemLocation(): Boolean {
        return sourceType == ADDRESS_SOURCE_TYPE_SYSTEM
    }

    constructor(source: Parcel) : this(
        source.readString()?:"",
        source.readString()?:"",
        source.readString()?:"",
        source.readString()?:"",
        source.readString()?:"",
        source.readString()?:"",
        source.readInt(),
        source.readString()?:"",
        source.readString()?:"",
        source.readString()?:"",
        source.readString()?:"",
        source.readString()?:"",
        source.readString()?:"",
        source.readString()?:"",
        source.readString()?:"",
        source.readByte().toInt() != 0
    )

    override fun describeContents() = 0

    override fun writeToParcel(dest: Parcel, flags: Int) = with(dest) {
        writeString(name)
        writeString(typecode)
        writeString(address)
        writeString(specialTip)
        writeString(distance)
        writeString(postalCode)
        writeInt(viewTypeHolder)
        writeString(distanceNumeric)
        writeString(from)
        writeString(originType)
        writeString(lat)
        writeString(lng)
        writeString(locationID)
        writeString(formattedAddress)
        writeString(streetAddress)
        writeByte(if (isMatchSearchText) 1.toByte() else 0.toByte())
        writeInt(sourceType)
    }

    companion object {
        @JvmField
        val CREATOR: Parcelable.Creator<PlaceItem> = object : Parcelable.Creator<PlaceItem> {
            override fun createFromParcel(source: Parcel): PlaceItem = PlaceItem(source).apply {
                sourceType = source.readInt()
            }
            override fun newArray(size: Int): Array<PlaceItem?> = arrayOfNulls(size)
        }
    }
}