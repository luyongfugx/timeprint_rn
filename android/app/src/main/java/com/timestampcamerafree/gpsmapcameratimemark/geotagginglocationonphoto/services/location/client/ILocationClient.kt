package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.client

import android.content.Context
import android.webkit.WebView
import androidx.annotation.IntRange
import androidx.annotation.StringDef
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.GpLocationInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.LocationInfoData


/**
 * LocationClient 接口类
 *
 */
interface ILocationClient {
    companion object{
        const val SUCCESS = 1
        const val FAILED = 0

    }
    fun getName():String
    fun init(context: Context, options: LocationOptions)
    fun registerListener(listener:(Int, GpLocationInfo<LocationInfoData>?)->Unit)
    fun isStarted():Boolean
    fun start()
    fun reStart();
    fun resetLocationOption(options: LocationOptions)
    fun stop()
    fun destroy()
    fun requestLocation()
    fun startAssistantLocation(webView: WebView)
    fun stopAssistantLocation()
}

class LocationOptions(
    val isPeriodic:Boolean = true,
    @IntRange(from = 1000L)
    val intervalInMS:Int = 5000,
    val onlyGps:Boolean = false,
)

const val GAODE = "gaode"
const val BAIDU = "baidu"
const val GOOGLE = "google"
const val NATIVE = "native"
const val HYBRID = "hybrid"



@Retention(AnnotationRetention.SOURCE)
@Target(AnnotationTarget.VALUE_PARAMETER)
@StringDef(value = [GAODE,BAIDU,NATIVE,HYBRID])
annotation class LocationClient
