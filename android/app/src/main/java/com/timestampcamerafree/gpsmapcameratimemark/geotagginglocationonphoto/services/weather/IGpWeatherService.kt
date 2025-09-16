package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.weather

import android.content.Context
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.WeatherInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.IService

/**
 *
 *
 */
interface IGpWeatherService : IService {
    interface Callback {
        fun onCurrentWeather(weather: WeatherInfo)
        fun onError(e:Exception)
        fun onComplete()
    }

    fun start(context: Context?, callback: Callback?, lat: Double?, lon: Double?)
}