package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils;

import android.annotation.SuppressLint
import android.os.SystemClock
import android.util.Log
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.GPRealTimeModel
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.RealTimeData
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.deepCopy
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;
import java.util.TimeZone
import kotlin.math.abs

/**
 * 时间管理类，单例
 */
object  GpTimeManager {
    private val TAG = "GpTimeManager"
    private var hasRequestApi = false
    private var timeZone: TimeZone = TimeZone.getDefault()
    private var currentDate: Date = Date()
    //可以确认为真实事件
    var canMakeSureRealTime: Boolean = true;
    //服务器获取的时间
    private var globalTimeModel: GPRealTimeModel? = null
    //真实时间类，包含一个服务器获取的时间和一个deltaTime(即当时的系统启动时间SystemClock.elapsedRealtime())
    private var realTimeData: RealTimeData? = null

    //没有网路的时候，如果通过校验过的开机时间+SystemClock.elapsedRealtime() 和当前时间最大的时间差
    private var maxGapTime =60*1000
    //系统启动时间，毫秒
//    private var systemBootTime = SystemClock.elapsedRealtime()
     fun getGlobalTimeZone() : TimeZone {
        var timeZone = TimeZone.getDefault()
        var timezoneID = globalTimeModel?.timeZone;
        if (!timezoneID.isNullOrEmpty()){
            timeZone = TimeZone.getTimeZone(timezoneID)
        }
        return timeZone
    }
    fun getCurrentTimezoneOffsetShort(): String {
        val timeZone = TimeZone.getDefault()
        val rawOffset = timeZone.rawOffset // 获取原始偏移量 (毫秒)
        val hours = rawOffset / (60 * 60 * 1000) // 将毫秒转换为小时
        val sign = if (hours >= 0) "+" else "-"
        val offsetString = String.format("%s%02d", sign, Math.abs(hours))
        return "GMT$offsetString"
    }

    private fun getTimeZoneAbbreviation(timeZone: TimeZone): String {
        val rawOffset = timeZone.rawOffset // 获取原始偏移量 (毫秒)
        val hours = rawOffset / (60 * 60 * 1000) // 将毫秒转换为小时
        val sign = if (hours >= 0) "+" else "-"
        val absHours = Math.abs(hours)
        val offsetString = if (absHours < 10) "${sign}${absHours}" else String.format("%s%02d", sign, absHours)
        return "GMT$offsetString"
    }

    fun getGlobalTimeZoneAbbreviation(): String? {
        var timeZone = getGlobalTimeZone()
        if (getTimeZoneAbbreviation(timeZone) =="Asia/Kolkata") {
            return "IST"
        } else {
            val abbreviation = getTimeZoneAbbreviation(timeZone)
            return abbreviation
        }
    }
//    private fun getRealTime() : Date {
//
//        return realTimeData?.currentDate ?: Date()
//    }

    private fun setRealTimeData() {
        //如果有时间
        globalTimeModel?.let {
            val realDate = globalTimeModel?.timestamp?.let { it1 -> Date(it1) } ?: Date()
            //系统启动到现在的时间
            var upTime = SystemClock.elapsedRealtime()
           // val deltaTime = realDate.time - Date().time  //服务器时间和本地时间的毫秒差距，
            realTimeData = RealTimeData(realDate, false, true, upTime)
        }?:run{
            val localDate = Date()
            realTimeData = RealTimeData(localDate, false, false, 0)
        }
    }
    /**
     * 根据经纬度获取时间
     *
     * @param lat
     * @param lon
     */
    fun requestTimeApi(lat: Double, lon: Double,callback: (time: GPRealTimeModel?) -> Unit) {
        if (hasRequestApi) {
            return
        }
        AnalyticsManager.logEvent("network_time_request")
        GpHttpRequestApi.realtime( lat,  lon) {

            var message = it;
            Log.d(TAG, "requestTimeApi Server ${message}")
            var timezoneID = message?.timeZone
            //如果是200说明成功
            if(it?.status ==200) {
                AnalyticsManager.logEvent("network_time_succ")
                hasRequestApi = true;
            }
            if (timezoneID != null) {

                timeZone = TimeZone.getTimeZone(timezoneID)
                var timeStr = message?.time


                // 测试一下：
               // {"msg":"ok","status":200,"data":{"time":"2025-05-10 09:47:10","timeZone":"GMT+7"}}}
//                timeStr = "2025-05-10 09:47:10"
//                timeZone = TimeZone.getTimeZone("GMT+7")
                var glbalDate = timeStr?.let { it1 ->
                    getDateFromString(timeZone,
                        it1, "yyyy-MM-dd HH:mm:ss")
                }

                Log.d(TAG, "requestTimeApi  timeStr: ${timeStr} timeZone: ${timeZone}  glbalDate : ${glbalDate}")
                glbalDate?.let {
                    currentDate = glbalDate
                    var serviceTimeStamp = currentDate.time
                    var serverTimeModel = message?.deepCopy()
                    //当系网络获取成功的时候，通过 服务器时间（globalTimeModel）减去 SystemClock.elapsedRealtime() 得到的时间，这个会存在本次存储里面
                   var mPhoneBootTime = currentDate.time - SystemClock.elapsedRealtime()
                    Log.d(TAG,"currentDate:${currentDate} savePhoneBootTime ${mPhoneBootTime} currentDate.time：${currentDate.time} ${SystemClock.elapsedRealtime()}")
                    LocalStorageManager.savePhoneBootTime(mPhoneBootTime)
                    serverTimeModel?.timestamp = serviceTimeStamp
                    updateServiceTime( serviceTimeStamp,serverTimeModel)
                    callback(serverTimeModel)
                    //本地时间
                    val nowDate = Date()
                    val nowPhoneTime = nowDate.time;
                    val localNetGapTime =  abs(nowPhoneTime- currentDate.time)
                    val maxLocalNetGapTime = 10*60*1000 //10分钟
                    var errorText =""
                    if (localNetGapTime>maxLocalNetGapTime){
                        errorText ="localNetGapTime>maxLocalNetGapTime localNetGapTime: ${localNetGapTime} currentDate:${currentDate} nowDate: ${nowDate} localNetGapTime：${localNetGapTime} nowPhoneTime:${nowPhoneTime} nowNetworkTime:${currentDate.time} lat: ${lat}, lon: ${lon},httpmsg:${message}"
                        Log.d(TAG,errorText)
                        TencentCOSUtils.uploadErrorLog(App.context,errorText,"local_network_time_gap_error")
                    }
                    else {
                        errorText ="localNetGapTime<maxLocalNetGapTime localNetGapTime: ${localNetGapTime}  currentDate:${currentDate} nowDate: ${nowDate} localNetGapTime：${localNetGapTime} nowPhoneTime:${nowPhoneTime} nowNetworkTime:${currentDate.time} lat: ${lat}, lon: ${lon},httpmsg:${message}"
                        Log.d(TAG,errorText)
                    }


                }
            }
            else {
                AnalyticsManager.logEvent("network_time_fail")
                //报错
                callback(message)
            }
        }

    }


    private fun updateServiceTime(serviceTime: Long, model: GPRealTimeModel?) {
       // Log.d(TAG, "updateServiceTime serviceTime: $serviceTime")
        saveGlobalServerTime(model)
    }

    private fun saveGlobalServerTime(model: GPRealTimeModel?) {
       // Log.d(TAG, "saveGlobalServerTime serviceTime: ")
        var timeModel = model;
        timeModel?.let {
            // 1、更新内存中的值
            globalTimeModel = timeModel
            setRealTimeData()
        }
    }

    //获取准确时间
    fun getExactTime(): Long {
        //测试
//        if(true){
//            // Log.d(TAG,"netWorkTime fake_time")
//            // AnalyticsManager.logEvent("fake_time")
//            canMakeSureRealTime = false;
//            return -1L
//        }
        realTimeData?.let {
            //当时网络获取的时间+系统启动到现在的时间就是真实的时间
           // Log.d(TAG,"get getExactTime realTimeData not null  set canMakeSureRealTime = true ")
            canMakeSureRealTime = true;
            //设置上一次联网时间
            LocalStorageManager.saveHasNetWork(realTimeData!!.currentDate.time)
            return realTimeData!!.currentDate.time + (SystemClock.elapsedRealtime()- realTimeData!!.deltaTime)
        }?:run{
            //如果没有网络时间就返回当前时间
            //当系网络获取成功的时候，通过 服务器时间（globalTimeModel）减去 SystemClock.elapsedRealtime() 得到的时间，这个会存在本次存储里面
            var mPhoneBootTime = LocalStorageManager.getPhoneBootTime()
//            Log.d(TAG,"get mPhoneBootTime  ${mPhoneBootTime}")
//            if(mPhoneBootTime == -1L){
//                //没有经过校验，则返回-1时间
//                canMakeSureRealTime = false;
//                Log.d(TAG,"get getExactTime mPhoneBootTime == -1L  set canMakeSureRealTime = false ")
//                return -1L
//            }

            val nowTime = Date().time;
            val nowGapTime =  abs(nowTime- (mPhoneBootTime+SystemClock.elapsedRealtime()))
            //Log.d(TAG," nowTime:${nowTime} mPhoneBootTime  ${mPhoneBootTime} SystemClock.elapsedRealtime:${SystemClock.elapsedRealtime()} nowGapTime:${nowGapTime}")
            if(nowGapTime <= maxGapTime){
               // Log.d(TAG,"get getExactTime nowGapTime <= maxGapTime set canMakeSureRealTime = true ")
                canMakeSureRealTime = true;
                return nowTime
            }
            else { //返回-1时间错误
                //Log.d(TAG,"get getExactTime nowGapTime <= maxGapTime set canMakeSureRealTime = false ")
                //如果一直没有连过网，则认为当前时间正确
                val netWorkTime = LocalStorageManager.getHasNetWork();
                //如果曾经连过网，则认为当前时间不对
                if(netWorkTime>0){
                   // Log.d(TAG,"netWorkTime fake_time")
                   // AnalyticsManager.logEvent("fake_time")
                    canMakeSureRealTime = false;
                    return -1L
                }
                else { //为了第一次起来的时候快速显示时间，优化用户体验
                   // AnalyticsManager.logEvent("no_net_time")
                   // Log.d(TAG,"netWorkTime no_net_time")
                    canMakeSureRealTime = true;
                    return Date().time
                }
            }
        }
    }
    @SuppressLint("SuspiciousIndentation")
    private fun getDateFromString(timezone: TimeZone, dateString: String, formatterString: String): Date? {
        Log.d(TAG, "requestTimeApi getDateFromString dateString: ${dateString} formatterString:${formatterString}" )
        val formatter = SimpleDateFormat(formatterString)
        //var dateT = parseDateWithTimeZone(timezone,dateString,formatterString)
        //Log.d(TAG,"requestTimeApi dataT :${dateT}")
        //注释掉，因为设置了timeZone 反而是错误的，接口已经返回正确的时间了
//        formatter.timeZone = timezone
        return try {
            var d =  formatter.parse(dateString)

            Log.d(TAG,"getDateFromString: ${d}")
            return d
        } catch (e: Exception) {
            Log.d(TAG,"getDateFromString error: ${e.message}")
            null // 解析失败返回 null
        }
    }




}