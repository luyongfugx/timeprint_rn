package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate;

import android.location.Address
import com.google.gson.Gson
import com.google.gson.annotations.SerializedName
import java.util.Locale


/**
 * 定位info
 *
 * @param T
 */
class GpLocationInfo<T> {


    @SerializedName("latitude")
    var latitude: Double = 0.0
    
    @SerializedName("longitude") 
    var longitude: Double = 0.0
    
    @SerializedName("altitude")
    var altitude: Double = Double.MIN_VALUE
    
    @SerializedName("createTime")
    var createTime: Long = 0
    
    @SerializedName("addressName")
    var addressName: String? = null
    
    @SerializedName("cityName")
    var cityName: String? = null
    
    @SerializedName("cityCode")
    var cityCode: String? = null
    
    @SerializedName("countryCode")
    var countryCode: String? = null
    
    @SerializedName("accuracy")
    var accuracy: Float = 0f
    
    @SerializedName("speed")
    var speed: Float = 0f
    
    @SerializedName("type")
    var type: String? = null
    
    @SerializedName("satelliteNumber")
    var satelliteNumber: Int = 0
    
    @SerializedName("locationClientName")
    var locationClientName: String = ""
    
    @SerializedName("locationTag")
    var locationTag: String = ""

    @SerializedName("locationInfoDataObject")
    var locationInfoDataObject: T? = null

    @SerializedName("status")
    var status = STATUS_LOCATION_FAILED
    
    @SerializedName("refreshType")
    var refreshType = REFRESH_STATE_FORGROUND
    
    //原始定位的信息,是个数组，上面这些信息取的是0,
    @SerializedName("rawAddress")
    var rawAddress: List<Address> = listOfNotNull()
    fun altitudeIsLegal(): Boolean {
        return altitude != Double.MIN_VALUE
    }

    fun copy(): GpLocationInfo<T> {
        val locationInfo = GpLocationInfo<T>()
        locationInfo.latitude = latitude
        locationInfo.longitude = longitude
        locationInfo.altitude = altitude
        locationInfo.addressName = addressName
        locationInfo.speed = speed
        locationInfo.createTime = System.currentTimeMillis()
        locationInfo.status = status
        locationInfo.refreshType = refreshType
        locationInfo.satelliteNumber = satelliteNumber
        locationInfo.locationClientName = locationClientName
        locationInfo.type = type
        locationInfo.accuracy = accuracy
        locationInfo.cityName = cityName
        locationInfo.rawAddress = rawAddress
        return locationInfo
    }

    override fun toString(): String {
        return "GpLocationInfo{" +
                "latitude=" + latitude +
                ", longitude=" + longitude +
                ", altitude=" + altitude +
                ", createTime=" + createTime +
                ", addressName='" + addressName + '\'' +
                ", cityName='" + cityName + '\'' +
                ", cityCode='" + cityCode + '\'' +
                ", speed=" + speed +
                ", satelliteNumber=" + satelliteNumber +
                ", locationClientName=" + locationClientName +
                ", type=" + type +
                ", status=" + status +
                '}'
    }

    companion object {
        const val STATUS_LOCATION_SUCCESS: Int = 0
        const val STATUS_REQUEST_PLACE_SUCCESS: Int = 1
        const val STATUS_LOCATION_FAILED: Int = -1
        const val STATUS_REQUEST_PLACE_FAILED: Int = -2
        const val REFRESH_FORCE: Int = 0
        const val REFRESH_STATE_SWITCHED: Int = 1
        const val REFRESH_STATE_FORGROUND: Int = 2
    }
}

