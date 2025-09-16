package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.location

import android.content.Context
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.GpLocationInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.IService

interface ILocationService<T> : IService {
     fun getLocationInfo(): GpLocationInfo<T>? // Kotlin 中使用可空类型

     fun init(context: Context)

     fun startLocation(context: Context?)

     fun reStartLocation(context: Context?)

     fun refreshLocation(context: Context?)

     fun stopLocation()

}