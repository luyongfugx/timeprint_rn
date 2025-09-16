package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.time

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.GnssClock
import android.location.GnssMeasurement
import android.location.GnssMeasurementsEvent
import android.location.GnssNavigationMessage
import android.location.GnssStatus
import android.location.LocationManager
import android.os.Build
import android.os.Handler
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat

/**
 * gnss 时间校准器，使用卫星时间
 *
 */

@RequiresApi(api = Build.VERSION_CODES.N)
class GPSGnssGpTimeService :
    IGpTimeService {
    var callback: IGpTimeService.Callback? = null

    private var context: Context? = null
    private var locationManager: LocationManager? = null

    private var gnssMeasurements: Collection<GnssMeasurement>? = null
    private var gnssClock: GnssClock? = null

    var mInnerHandler: Handler = Handler()

    private val gnssStatusCallback: GnssStatus.Callback = object : GnssStatus.Callback() {
        override fun onSatelliteStatusChanged(status: GnssStatus) {
        }
    }
    private val gnssMeasurementsEventCallback: GnssMeasurementsEvent.Callback
    private val gnssNavigationMessageCallback: GnssNavigationMessage.Callback


    fun resumeCallbackAfterDelay() {
        mInnerHandler.removeCallbacks(mTimeOutCallback)
        mInnerHandler.postDelayed(mTimeOutCallback, 5000)
    }

    var mTimeOutCallback: Runnable = Runnable {
        if (currentTime != 0L) {
            callback?.onComplete()
        } else {
            callback?.onError(Exception("timeout"))
        }
    }

    override fun start(context: Context?, callback: IGpTimeService.Callback? ,lat: Double?,
                       lon: Double?) {
        currentTime = 0
        this.context = context
        this.callback = callback
        locationManager =
            this.context!!.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        if (ActivityCompat.checkSelfPermission(
                context!!,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        locationManager!!.registerGnssMeasurementsCallback(gnssMeasurementsEventCallback)
        locationManager!!.registerGnssNavigationMessageCallback(gnssNavigationMessageCallback)
        locationManager!!.registerGnssStatusCallback(gnssStatusCallback)
        resumeCallbackAfterDelay()
    }


    override fun refresh(context: Context?, lat: Double?, lon: Double?) {
    }

    override fun stop() {
        if (ActivityCompat.checkSelfPermission(
                context!!,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        locationManager!!.unregisterGnssMeasurementsCallback(gnssMeasurementsEventCallback)
        locationManager!!.unregisterGnssNavigationMessageCallback(gnssNavigationMessageCallback)
        locationManager!!.unregisterGnssStatusCallback(gnssStatusCallback)
    }


    var currentTime: Long = 0

    init {
        gnssMeasurementsEventCallback = object : GnssMeasurementsEvent.Callback() {
            override fun onGnssMeasurementsReceived(eventArgs: GnssMeasurementsEvent) {
                onMeasurementsReceived(eventArgs)
            }
        }

        gnssNavigationMessageCallback = object : GnssNavigationMessage.Callback() {
            override fun onGnssNavigationMessageReceived(event: GnssNavigationMessage) {
            }
        }
    }

    fun onMeasurementsReceived(event: GnssMeasurementsEvent) {
        this.gnssMeasurements = event.measurements
        this.gnssClock = event.clock


        var LeapSecond: Long = 0
        if (gnssClock!!.hasLeapSecond()) {
            //如果闰秒存在则显示闰秒
            LeapSecond = gnssClock!!.leapSecond.toLong()
        }
        val TimeNanos = gnssClock!!.timeNanos

        var FullBiasNanos: Long = 0
        if (gnssClock!!.hasFullBiasNanos()) {
            //如果存在接收机本地时钟总偏差，则显示
            FullBiasNanos = gnssClock!!.fullBiasNanos
        }
        var BiasNanos = 0.0
        if (gnssClock!!.hasBiasNanos()) {
            //亚纳秒偏差
            BiasNanos = gnssClock!!.biasNanos
        }
        val gpsTimeEpoch = TimeNanos - (FullBiasNanos + BiasNanos)

        for (meas in gnssMeasurements!!) {
            val tTx = meas.receivedSvTimeNanos
            val tRxGNSS = gpsTimeEpoch + meas.timeOffsetNanos
            if (tRxGNSS > 1.0) {
                val ld = (tRxGNSS / 1000000).toLong() + GPS_UTC_DIFF_MILLIS
                currentTime = ld
                callback?.onCurrentTime(ld)
                //Prefs.setGPSTime(ld)
            }
        }
    }


    companion object {
        const val UTC_TAI_LEAP_SECONDS: Int = 37
        const val GPS_UTC_LEAP_SECONDS: Int = -UTC_TAI_LEAP_SECONDS + 19
        const val GPS_UTC_DIFF_MILLIS: Long = 315964800000L + GPS_UTC_LEAP_SECONDS * 1000
    }
}