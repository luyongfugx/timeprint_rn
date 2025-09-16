package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

enum class WeatherDataSet(val value: String) {
    currentWeather("currentWeather"),
    forecastDaily("forecastDaily");

    fun stringValue(): String {
        return value
    }
}