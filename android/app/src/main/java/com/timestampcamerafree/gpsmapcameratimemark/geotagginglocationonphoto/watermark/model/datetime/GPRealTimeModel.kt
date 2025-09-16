package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime

import com.google.gson.annotations.SerializedName
import java.text.SimpleDateFormat
import java.util.TimeZone

/**
 *
 *
 */

data class GPRealTimeModel(
    @SerializedName("status")  var status: Int? = null,
    @SerializedName("msg")  var msg: String? = null,
    @SerializedName("data")  var data: Data? = null
) {
    var timestamp: Long?
        get() = data?.timestamp
        set(value) {
            data?.timestamp = value
        }
    val timeZone: String?
        get() = data?.timeZone
    val time: String?
        get() = data?.time
    fun initTimeStamps() {
        data?.initTimeStamps()
    }
}
data class Data(
    @SerializedName("time")  var time: String? = null,
    @SerializedName("timeZone") var timeZone: String? = null,
    @SerializedName("timestamp") var timestamp: Long? = null
) {
    fun initTimeStamps() {
        if (time == null || timeZone == null) {
            return
        }
        try {
            val format = SimpleDateFormat("yyyy-MM-dd HH:mm:ss")
           format.timeZone = TimeZone.getTimeZone(timeZone)
            val date = time?.let { format.parse(it) }
            timestamp = date?.time
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
fun GPRealTimeModel.deepCopy(): GPRealTimeModel {
    return GPRealTimeModel(this.status, this.msg, this.data)
}