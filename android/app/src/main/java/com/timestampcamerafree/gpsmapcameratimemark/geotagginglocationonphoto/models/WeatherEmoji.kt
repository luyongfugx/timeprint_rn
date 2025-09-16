package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models

enum class WeatherEmoji(val value: String)  {
    blowingDust("blowingDust"),
    clear("clear"),
    cloudy("cloudy"),
    foggy("foggy"),
    haze("haze"),
    mostlyClear("mostlyClear"),
    mostlyCloudy("mostlyCloudy"),
    partlyCloudy("partlyCloudy"),
    smokey("smokey"),
    breezy("breezy"),
    windy("windy"),
    drizzle("drizzle"),
    heavyRain("heavyRain"),
    isolatedThunderstorms("isolatedThunderstorms"),
    rain("rain"),
    sunShowers("sunShowers"),
    scatteredThunderstorms("scatteredThunderstorms"),
    strongStorms("strongStorms"),
    thunderstorms("thunderstorms"),
    frigid("frigid"),
    hail("hail"),
    hot("hot"),
    flurries("flurries"),
    sleet("sleet"),
    snow("snow"),
    sunFlurries("sunFlurries"),
    wintryMix("wintryMix"),
    blizzard("blizzard"),
    blowingSnow("blowingSnow"),
    freezingDrizzle("freezingDrizzle"),
    freezingRain("freezingRain"),
    heavySnow("heavySnow"),
    hurricane("hurricane"),
    tropicalStorm("tropicalStorm");
    fun stringValue(): String {
        return value.replaceFirstChar { it.uppercase() }
    }

}