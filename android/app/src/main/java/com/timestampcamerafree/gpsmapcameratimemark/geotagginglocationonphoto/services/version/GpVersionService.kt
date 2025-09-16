package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.version

import android.content.Context
import android.util.Log
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity.Companion
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.AndroidConf
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.WeatherDataSet
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.WeatherInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.weather.IGpWeatherService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.ApolloConfigUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpWeatherManager
import java.util.Locale
import java.util.concurrent.Executors

/**
 * 检测
 *
 */
class GpVersionService : IGpVersionService {
    private val TAG = "GpVersionService"
    private val singleExecutor = Executors.newSingleThreadExecutor()
    private val retryMax = 3L
    private var retryCount = 0L
    private var retryDelay = 1000L
    private var doCallback: IGpVersionService.Callback? =null;
    private var  latitude: Double? = null
    private var  longitude: Double?  = null

    override fun start(
        context: Context?,
        callback: IGpVersionService.Callback?,
    ) {
        Log.d(TAG, "IGpVersionService.start")
        retryCount = 0
        doCallback = callback
        singleExecutor.execute {
            val confCallBack = object : IGpVersionService.Callback {
                override fun onCurrentAndroidConf(conf: AndroidConf) {
                    Log.d(TAG, "onCurrentAndroidConf: ${conf}")
                    AnalyticsManager.logEvent("android_conf_succ")
                    doCallback?.onCurrentAndroidConf(conf)
                }
                override fun onError(e: Exception) {
                    AnalyticsManager.logEvent("android_conf_failed")
                    Log.d(TAG, "onError: ${e}")
                    retry()
                    doCallback?.onError(e)
                }
                override fun onComplete() {
                    Log.d(TAG, "onComplete")
                    doCallback?.onComplete()
                }
            }
            try {
                val androidConf =  ApolloConfigUtil.fetchAndroidConf()
                Log.i(TAG, "ApolloConfigUtil.fetchAndroidConf $androidConf")
                confCallBack.onCurrentAndroidConf(androidConf)
            } catch (e: Exception) {
                AnalyticsManager.logEvent("android_conf_error")
                Log.d(TAG, "android_conf_error: error $e")
                confCallBack.onError(e)
                retry()
            }
        }
    }

    private fun retry() {
        if (retryCount < retryMax) {
            retryCount++
            Log.d(TAG, "retryCount: $retryCount")
            singleExecutor.execute {
                val confCallBack = object : IGpVersionService.Callback {
                    override fun onCurrentAndroidConf(conf: AndroidConf) {
                        Log.d(TAG, "onCurrentAndroidConf: ${conf}")
                        AnalyticsManager.logEvent("android_conf_succ")
                        doCallback?.onCurrentAndroidConf(conf)
                    }
                    override fun onError(e: Exception) {
                        AnalyticsManager.logEvent("android_conf_failed")
                        Log.d(TAG, "onError: ${e}")
                        retry()
                        doCallback?.onError(e)
                    }
                    override fun onComplete() {
                        Log.d(TAG, "onComplete")
                        doCallback?.onComplete()
                    }
                }

                try {
                    Thread.sleep(retryDelay)
                    val androidConf =  ApolloConfigUtil.fetchAndroidConf()
                    Log.i(TAG, "ApolloConfigUtil.fetchAndroidConf $androidConf")
                    confCallBack.onCurrentAndroidConf(androidConf)
                } catch (e: Exception) {
                    Log.d(TAG, "retry: InterruptedException $e")
                    AnalyticsManager.logEvent("android_conf_error")
                    Log.d(TAG, "start: error $e")
                    confCallBack.onError(e)
                } finally {
                    retry()
                }
            }
        } else {
            Log.d(TAG, "retryCount: $retryCount, retryMax: $retryMax, stop retry")
        }
    }
}