package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.weather

import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R

/**
 * 天气类型 celsius °C
 * fahrenheit °F
 * @property style
 */

enum class GpWeatherStyle(var style: Int) {
    @SerializedName("Fahrenheit")
    Fahrenheit(0),
    @SerializedName("Celsius")
    Celsius(1);

    fun getWeatherStyleString(style:GpWeatherStyle): String {
        var styleString = ""
        when (style) {
            Fahrenheit -> styleString = App.context.resources.getString(R.string.k_weather_fahrenheit)
            Celsius -> styleString = App.context.resources.getString(R.string.k_weather_celsius)
        }
        return styleString
    }
    companion object {
        fun fromStyle(style: Int): GpWeatherStyle {
            var s = GpWeatherStyle.values().find { it.style == style }
            s?.let {
                return s;
            }
            //默认是全部
            return Celsius
        }
    }
}