package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.location


import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.GpLocationInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.GpLocationInfo.Companion.REFRESH_FORCE
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.GpLocationInfo.Companion.REFRESH_STATE_FORGROUND
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.GpLocationInfo.Companion.REFRESH_STATE_SWITCHED
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.LocationInfoData
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpLocationUtil

/**
 * 刷新策略
 *
 */
interface GpLocationStrategy {
    companion object{
        private val TAG = "GpLocationStrategy"
        fun getDefaultStrategy() : GpLocationStrategy{
            return object:GpLocationStrategy{
                override fun shouldRefreshWhenGotPlace(oldLocation: GpLocationInfo<LocationInfoData>, newLocation: GpLocationInfo<LocationInfoData>, refreshType:Int): Boolean {
                    if (refreshType == REFRESH_FORCE) {
                        return true
                    }
                    else{
                        return needChangeLocation(calculateDistanceDiff(oldLocation, newLocation), newLocation.speed, refreshType)
                    }
                }

                override fun shouldRefreshWhenGotLocation(
                    oldLocation: GpLocationInfo<LocationInfoData>,
                    newLocation: GpLocationInfo<LocationInfoData>,
                ): Boolean {
                    return true
                }

                override fun strategyName() = "default"
            }
        }
    }
    fun strategyName():String
    fun shouldRefreshWhenGotPlace(oldLocation:GpLocationInfo<LocationInfoData>, newLocation: GpLocationInfo<LocationInfoData>, refreshType:Int):Boolean
    fun shouldRefreshWhenGotLocation(oldLocation:GpLocationInfo<LocationInfoData>, newLocation: GpLocationInfo<LocationInfoData>):Boolean

    fun calculateDistanceDiff(oldLocation: GpLocationInfo<LocationInfoData>, newLocation: GpLocationInfo<LocationInfoData>) : Double {
        val oldLatLng = doubleArrayOf(oldLocation.latitude, oldLocation.longitude)
        val newLatLng = doubleArrayOf(newLocation.latitude, newLocation.longitude)
        return GpLocationUtil.calculateLineDistance(oldLatLng, newLatLng)
    }

    fun needChangeLocation(distance: Double, speed: Float,refreshType: Int): Boolean {
        var distanceResume = 20
        var distanceNotMove = 40
        var intervalMove =  25

        return when(refreshType){
            REFRESH_STATE_SWITCHED ->
                distance > distanceResume
            REFRESH_STATE_FORGROUND -> {
                val speedDis = (speed * intervalMove * 10 / 36).toInt()
                val result = distance > distanceNotMove.coerceAtLeast(speedDis)
                result
            }
            else -> {
                distance > distanceResume
            }
        }
    }
}

abstract class NoRefreshStrategy: GpLocationStrategy{
    override fun shouldRefreshWhenGotPlace(
        oldLocation: GpLocationInfo<LocationInfoData>,
        newLocation: GpLocationInfo<LocationInfoData>,
        refreshType: Int
    ): Boolean {
        return false
    }

    override fun shouldRefreshWhenGotLocation(
        oldLocation: GpLocationInfo<LocationInfoData>,
        newLocation: GpLocationInfo<LocationInfoData>
    ): Boolean {
        return false
    }
}

object EmptyRefreshStrategy:NoRefreshStrategy() {
    override fun strategyName(): String {
        return "empty"
    }
}