package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils

import android.util.Log
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.CurrentWeather
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.WeatherInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.weather.IGpWeatherService

/**
 * 天气管理类，单例
 */
object  GpWeatherManager {
    private val TAG = "GpWeatherManager"
    private var globalWeatherInfo: WeatherInfo? = null
    private var hasRequestApi = false;
    fun getWeatherInfo(): WeatherInfo? {
       return  globalWeatherInfo
    }
    fun getFakeWeatherInfo():WeatherInfo?{
        var currentWeather = CurrentWeather(
            temperature = 24.5,
            conditionCode = "light_rain",
            windSpeed = 15.0,
            windDirection = 45.0,
            humidity = 70.0,
            cloudCover = 60.0,
            visibility = 10.0,
            pressure = 1013.25,
            uvIndex = 3,
            sunrise = "2023-03-01 06:00:00",
            sunset = "2023-03-01 18:00:00",
            daylight = true,
            asos = "ZBAA"
        )

      return   WeatherInfo(currentWeather,null,"metric")
    }
    /**
     * 根据经纬度获取时间
     *
     * @param latitude
     * @param longitude
     */
    fun requestWeatherApi(latitude: Double, longitude: Double,language: String, dataSet:String,callback:IGpWeatherService.Callback) {
        Log.i(TAG, "requestWeatherApi")
        if (hasRequestApi) {
            return
        }
        val weatherCallBack = object : IGpWeatherService.Callback {
            override fun onCurrentWeather(weather: WeatherInfo) {
                Log.i(TAG, "onCurrentWeather: ${weather}")
                hasRequestApi = true;
                callback.onCurrentWeather(weather)
                globalWeatherInfo =  weather
            }
            override fun onError(e: Exception) {
                callback.onError(e)
            }
            override fun onComplete() {}
        }
        GpHttpRequestApi.getWeather(latitude, longitude,language, dataSet,weatherCallBack);


    }


}