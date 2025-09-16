package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.weather

import android.content.Context
import android.util.Log
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.WeatherDataSet
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.WeatherInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpWeatherManager

import java.util.*
import java.util.concurrent.*

class GpAppleWeatherService : IGpWeatherService {
    private val TAG = "GpAppleWeatherService"
    private val singleExecutor = Executors.newSingleThreadExecutor()
    private val retryMax = 3L
    private var retryCount = 0L
    private var retryDelay = 1000L
    private var doCallback: IGpWeatherService.Callback? =null;
    private var  latitude: Double? = null
    private var  longitude: Double?  = null

    override fun start(
        context: Context?,
        callback: IGpWeatherService.Callback?,
        lat: Double?,
        lon: Double?
    ) {
        Log.d(TAG, "GpAppleWeatherService.start")
        retryCount = 0
        doCallback = callback
        latitude = lat
        longitude = lon
        singleExecutor.execute {
            try {
                val weatherCallBack = object : IGpWeatherService.Callback {
                    override fun onCurrentWeather(weather: WeatherInfo) {
                        Log.d(TAG, "onCurrentWeather: ${weather}")
                        AnalyticsManager.logEvent("weather_succ")
                        doCallback?.onCurrentWeather(weather)
                    }
                    override fun onError(e: Exception) {
                        AnalyticsManager.logEvent("weather_fail")
                        Log.d(TAG, "onError: ${e}")
                        retry()
                    }
                    override fun onComplete() {
                        Log.d(TAG, "onComplete")
                    }
                }
                Log.i(TAG, "GpAppleWeatherService.requestWeatherApi")

                GpWeatherManager.requestWeatherApi(
                    lat!!, lon!!, Locale.getDefault().toString(),
                    WeatherDataSet.currentWeather.stringValue(),
                    weatherCallBack
                )
            } catch (e: Exception) {
                AnalyticsManager.logEvent("weather_error")
                Log.d(TAG, "start: error $e")
                retry()
            }
        }
    }

    private fun retry() {
        if (retryCount < retryMax) {
            retryCount++
            Log.d(TAG, "retryCount: $retryCount")
            singleExecutor.execute {
                try {
                    Thread.sleep(retryDelay)
                    val weatherCallBack = object : IGpWeatherService.Callback {
                        override fun onCurrentWeather(weather: WeatherInfo) {
                            Log.d(TAG, "onCurrentWeather: ${weather}")
                            doCallback?.onCurrentWeather(weather)
                        }
                        override fun onError(e: Exception) {
                            Log.d(TAG, "onError: ${e}")
                            retry()
                        }
                        override fun onComplete() {
                            Log.d(TAG, "onComplete")
                        }
                    }
                    Log.d(TAG, "GpAppleWeatherService.requestWeatherApi")
                    GpWeatherManager.requestWeatherApi(
                        latitude!!, longitude!!, Locale.getDefault().toString(),
                        WeatherDataSet.currentWeather.stringValue(),
                        weatherCallBack
                    )
                } catch (e: InterruptedException) {
                    Log.d(TAG, "retry: InterruptedException $e")
                } finally {
                    retry()
                }
            }
        } else {
            Log.d(TAG, "retryCount: $retryCount, retryMax: $retryMax, stop retry")
        }
    }
}