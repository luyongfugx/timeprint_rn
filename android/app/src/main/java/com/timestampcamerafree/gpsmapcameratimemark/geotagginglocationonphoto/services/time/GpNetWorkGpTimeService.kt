package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.time
import android.content.Context
import android.util.Log
import com.google.android.gms.maps.model.LatLng
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpTimeManager
import java.util.concurrent.Executors


/**
 * 使用网络来校准，目前使用网络来校准更好
 */
class GpNetWorkGpTimeService : IGpTimeService {
    private val TAG = "GpNetWorkGpTimeService"
    private val retryMax = 3L
    private var retryCount = 0L
    private var callback : IGpTimeService.Callback? = null
    //线程类
    private val singleExecutor = Executors.newSingleThreadExecutor()
    override fun start(
        context: Context?,
        callback: IGpTimeService.Callback?,
        lat: Double?,
        lon: Double?
    ) {

        this.callback = callback
        retryCount = 0
        singleExecutor.execute {
            startGetNetWorkTime(lat,lon)
        }
    }

    private fun startGetNetWorkTime(lat: Double?, lon: Double?) {
        Log.d(TAG, "fun start startGetNetWorkTime retryCount ${retryCount}")
           // 把定位次数置为0
            //默认北京时间
        //lat = 19.969528
        //lon = 58.663483
       // AnalyticsManager.logEvent("locationListener_fail")
            var latLng = LatLng(lat?:39.9042, lon?:116.4074)

        GpTimeManager.requestTimeApi(lat ?: latLng.latitude, lon ?: latLng.longitude ){
                 Log.d(TAG, "startGetNetWorkTime  GpTimeManager.requestTimeApi callback : ${it?.msg} ${it?.status}  ${it?.timeZone}" )
                if (it?.status == 500 && retryCount < retryMax) {
                    Log.d(TAG, "startGetNetWorkTime retryCount ${retryCount}")
                    retryCount++
                    startGetNetWorkTime(lat,lon)

                }
                //重试多次还有错误
                else if (it?.status == 500 && retryCount >= retryMax) {
                    var e = Exception("newWork 500")
                    callback?.onError(e)
                    callback?.onComplete();
                }
                else {
                    it?.timestamp?.let { it1 ->
                        callback?.onCurrentTime(it1)
                        callback?.onComplete();
                    }
                }
            }
    }



    override fun refresh(context: Context?,lat: Double?, lon: Double?) {
        Log.d(TAG,"refresh startGetNetWorkTime retryCount $retryCount")
        retryCount = 0
        singleExecutor.execute {
            Log.d(TAG,"refresh startGetNetWorkTime ")
            startGetNetWorkTime(lat,lon)
        }
    }

    override fun stop() {
        TODO("Not yet implemented")
    }

}