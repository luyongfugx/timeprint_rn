package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

import com.google.gson.annotations.SerializedName
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.extensions.GenerateNoArg
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.weather.GpWeatherStyle

@GenerateNoArg
data class WeatherInfoResponse(
    @SerializedName("msg")  val msg: String,
    @SerializedName("status")  val status: Int,
    @SerializedName("data")   val data: WeatherInfo
)

@GenerateNoArg
data class WeatherInfo(
    @SerializedName("currentWeather")   val currentWeather: CurrentWeather?,
    @SerializedName("forecastDaily")   val forecastDaily: ForecastDaily?,
    @SerializedName("temperatureUnit")   var temperatureUnit:String = "metric"
){
    private fun emojiWeather(condition:String): String {
        return when (condition) {
            WeatherEmoji.clear.stringValue()-> "☀️"
            WeatherEmoji.blowingDust.stringValue() -> "💨"
            WeatherEmoji.cloudy.stringValue() -> "☁️"
            WeatherEmoji.foggy.stringValue() -> "🌫️"
            WeatherEmoji.haze.stringValue() -> "😶‍🌫️"
            WeatherEmoji.mostlyClear.stringValue() -> "🌤️"
            WeatherEmoji.mostlyCloudy.stringValue() -> "🌥️"
            WeatherEmoji.partlyCloudy.stringValue() -> "⛅️"
            WeatherEmoji.smokey.stringValue() -> "😶‍🌫️"
            WeatherEmoji.breezy.stringValue() -> "💨"
            WeatherEmoji.windy.stringValue() -> "🍃"
            WeatherEmoji.drizzle.stringValue() -> "☔️"
            WeatherEmoji.heavyRain.stringValue() -> "🌧️"
            WeatherEmoji.isolatedThunderstorms.stringValue() -> "⚡️"
            WeatherEmoji.rain.stringValue() -> "🌧️"
            WeatherEmoji.sunShowers.stringValue() -> "🌤️"
            WeatherEmoji.scatteredThunderstorms.stringValue() -> "⚡️"
            WeatherEmoji.strongStorms.stringValue() -> "⛈️"
            WeatherEmoji.thunderstorms.stringValue() -> "⛈️"
            WeatherEmoji.frigid.stringValue() -> "🧣"
            WeatherEmoji.hail.stringValue() -> "❄️"
            WeatherEmoji.hot.stringValue() -> "🔥"
            WeatherEmoji.flurries.stringValue() -> "💨"
            WeatherEmoji.sleet.stringValue() -> "🌨️"
            WeatherEmoji.snow.stringValue() -> "☃️"
            WeatherEmoji.sunFlurries.stringValue() -> "🌤️"
            WeatherEmoji.wintryMix.stringValue() -> "🧣"
            WeatherEmoji.blizzard.stringValue() -> "🌨️"
            WeatherEmoji.blowingSnow.stringValue() -> "🌨️"
            WeatherEmoji.freezingDrizzle.stringValue() -> "🥶"
            WeatherEmoji.freezingRain.stringValue() -> "🌧️"
            WeatherEmoji.heavySnow.stringValue() -> "🌨️"
            WeatherEmoji.hurricane.stringValue() -> "🌪️"
            WeatherEmoji.tropicalStorm.stringValue() -> "🌪️"
            else -> "☀️" // Equivalent of @unknown default
        }
    }
    private fun celsiusToFahrenheit(celsius: Double): Double {
        return (celsius * 9 / 5) + 32
    }

    fun showWeather(style: GpWeatherStyle = GpWeatherStyle.Celsius):String{
            val current = currentWeather ?: return ""
            val emojiWeather = emojiWeather(current.conditionCode)
            val tUnit = when(style) {
                GpWeatherStyle.Fahrenheit -> "°F"
                else -> "°C"
            }
            val temperature = when(style) {
                GpWeatherStyle.Fahrenheit-> celsiusToFahrenheit(current.temperature)
                else -> current.temperature
            }
           val temText = "${temperature.format(1)} $tUnit"
            return "$temText $emojiWeather"
    }
}

@GenerateNoArg
data class CurrentWeather(
    @SerializedName("temperature")  val temperature: Double,
    @SerializedName("conditionCode")  val conditionCode: String,
    @SerializedName("windSpeed")  val windSpeed: Double,
    @SerializedName("windDirection")  val windDirection: Double,
    @SerializedName("humidity")  val humidity: Double,
    @SerializedName("cloudCover") val cloudCover: Double,
    @SerializedName("visibility") val visibility: Double,
    @SerializedName("pressure") val pressure: Double,
    @SerializedName("uvIndex")  val uvIndex: Int,
    @SerializedName("sunrise")  val sunrise: String,
    @SerializedName("sunset") val sunset: String,
    @SerializedName("daylight") val daylight: Boolean,
    @SerializedName("asos") val asos: String
)

@GenerateNoArg
data class ForecastDaily(
    @SerializedName("days") val days: List<DayWeather>
)

@GenerateNoArg
data class DayWeather(
    @SerializedName("date") val date: String,
    @SerializedName("temperatureMax") val temperatureMax: Double,
    @SerializedName("temperatureMin") val temperatureMin: Double,
    @SerializedName("conditionCode") val conditionCode: String,
    @SerializedName("windSpeed") val windSpeed: Double,
    @SerializedName("windDirection") val windDirection: Double,
    @SerializedName("humidity") val humidity: Double,
    @SerializedName("cloudCover") val cloudCover: Double,
    @SerializedName("precipitationChance") val precipitationChance: Double,
    @SerializedName("uvIndex") val uvIndex: Int,
    @SerializedName("sunrise") val sunrise: String,
    @SerializedName("sunset") val sunset: String,
    @SerializedName("daylight") val daylight: Double
)
private fun Double.format(fractionDigits: Int): String {
    return String.format("%.${fractionDigits}f", this)
}

