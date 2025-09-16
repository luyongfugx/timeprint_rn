package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime

import com.google.gson.annotations.SerializedName
import java.util.Date

data class RealTimeData(
    @SerializedName("currentDate") val currentDate: Date,
    @SerializedName("isNeedCorrectTime") val isNeedCorrectTime: Boolean,
    @SerializedName("canMakeSureRealTime")  val canMakeSureRealTime: Boolean,
    @SerializedName("deltaTime")  val deltaTime: Long
)