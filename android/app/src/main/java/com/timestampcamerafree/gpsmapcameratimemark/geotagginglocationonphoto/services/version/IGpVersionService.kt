package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.version

import android.content.Context
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.AndroidConf
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.WeatherInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.IService

/**
 * 版本检测service
 *
 */
interface IGpVersionService : IService {
    interface Callback {
        fun onCurrentAndroidConf(conf: AndroidConf)
        fun onError(e:Exception)
        fun onComplete()
    }
    fun start(context: Context?, callback: Callback?)
}