package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.client


import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.os.Looper
import android.util.Log
import android.webkit.WebView
import com.google.android.gms.common.GoogleApiAvailability
import com.google.android.gms.common.api.ResolvableApiException
import com.google.android.gms.location.*
import com.google.android.gms.tasks.OnFailureListener
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.GpLocationInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.LocationInfoData
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpLocationUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.TencentCOSUtils
import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers
import io.reactivex.rxjava3.core.Observable
import io.reactivex.rxjava3.disposables.Disposable

import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.TimeUnit


/**
 * google 定位,获取定位信息
 *
 */
class GoogleLocationClient : ILocationClient{
    private val TAG = "GoogleLocationClient"
    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private val locationListeners = CopyOnWriteArrayList<(Int, GpLocationInfo<LocationInfoData>?) -> Unit>()
    private var started = false
    private var periodDisposable : Disposable? = null
    override fun getName(): String {
        return GOOGLE
    }
    override fun init(context: Context, options: LocationOptions) {
        GoogleApiAvailability.getInstance().isGooglePlayServicesAvailable(App.context)
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(App.context)
    }
    override fun registerListener(listener: (Int, GpLocationInfo<LocationInfoData>?) -> Unit) {
        locationListeners.add(listener)
    }

    override fun isStarted(): Boolean {
        return started
    }

    @SuppressLint("MissingPermission")
    override fun start() {
        if (isStarted()) {
            return
        }
        stop()
        started = true
        val locationRequest: LocationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY,10 * 1000)
                .setMinUpdateDistanceMeters(10F)
                .build()
        Log.d(TAG,"GoogleLocationClient start  called ")
        try {
            fusedLocationClient.requestLocationUpdates(locationRequest, locationCallback, Looper.getMainLooper()).addOnCanceledListener {
            }.addOnFailureListener {
                handleFailed(null)
            }
            fusedLocationClient.getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY,null).addOnSuccessListener {
                Log.d(TAG,"GoogleLocationClient addOnSuccessListener")
                if (it != null) {
                    val latLng = GpLocationUtil.gps84_To_Gcj02(it.latitude,it.longitude)
                    val text ="GoogleLocationClient  succ: lat:${it.latitude} lon:${it.longitude} }"
                    Log.d(TAG,"getCurrentLocation $text")
                    TencentCOSUtils.uploadErrorLog(App.context,text,"GoogleLocationClient_succ")
                    val locationInfo = GpLocationInfo<LocationInfoData>().apply {
                        latitude = latLng[0]
                        longitude = latLng[1]
                        speed = 0f
                        accuracy = it.accuracy
                        altitude = it.altitude
                        createTime = System.currentTimeMillis()
                        locationClientName = getName()
                        locationTag = "exist"
                    }
                    locationListeners.forEach { listener ->
                        listener.invoke(
                            ILocationClient.SUCCESS,
                            locationInfo
                        )
                    }
                }
                else {
                    Log.d(TAG,"GoogleLocationClient getCurrentLocation location null")
                    val text ="getCurrentLocation location null "
                    TencentCOSUtils.uploadErrorLog(App.context,text,"getCurrentLocation_error")
                    handleFailed(null)
                }
            }.addOnFailureListener{
                Log.d(TAG,"GoogleLocationClient addOnFailureListener")
                val text ="GoogleLocationClient getCurrentLocation addOnFailureListener error: ${it.message} }"
                Log.d(TAG,"GoogleLocationClient getCurrentLocation addOnFailureListener error: ${it.message}")
                TencentCOSUtils.uploadErrorLog(App.context,text,"getCurrentLocation_error")
                handleFailed(null)
            }
        } catch (e:Exception) {
            val text ="GoogleLocationClient  error: ${e.message} }"
            TencentCOSUtils.uploadErrorLog(App.context,text,"GoogleLocationClient_fail")
            handleFailed(null)
        }


    }

    override fun reStart() {
        started = false;
        start()
    }

    private fun handleFailed(location: Location?) {
        try{
            periodDisposable?.dispose()
            periodDisposable = Observable.interval(0L, 5000L, TimeUnit.MILLISECONDS).observeOn(
                AndroidSchedulers.mainThread()).subscribe {
               // Log.d(TAG, "5 seconds period")
            }
        }
        catch (e:Exception){
            val text ="GoogleLocationClient  handleFailed: ${e.message} }"
            TencentCOSUtils.uploadErrorLog(App.context,text,"GoogleLocationClient_handleFailed")
        }

    }

    override fun resetLocationOption(options: LocationOptions) {
    }

    override fun stop() {
        try{
        fusedLocationClient.removeLocationUpdates(locationCallback)
        started = false
        periodDisposable?.dispose()
        }
        catch (e:Exception){
            val text ="GoogleLocationClient  stop: ${e.message} }"
            TencentCOSUtils.uploadErrorLog(App.context,text,"GoogleLocationClient_stoperror")

        }
    }

    override fun destroy() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
        started = false
    }

    override fun requestLocation() {
        start()
    }

    override fun startAssistantLocation(webView: WebView) {
    }

    override fun stopAssistantLocation() {
    }

    private var locationCallback = object : LocationCallback() {
        override fun onLocationResult(locationResult: LocationResult) {
            try {
                var result: Location? = null
                for (location in locationResult.locations) {
                    result = location
                }
                result?.let {
                    Log.d(TAG,"GoogleLocationClient onLocationResult ${result}")
                    val latLng = GpLocationUtil.gps84_To_Gcj02(result.latitude, result.longitude)
                    val locationInfo = GpLocationInfo<LocationInfoData>().apply {
                        latitude = latLng[0]
                        longitude = latLng[1]
                        speed = 0f
                        accuracy = result.accuracy
                        altitude = result.altitude
                        createTime = System.currentTimeMillis()
                        locationClientName = getName()
                        locationTag = "google"
                    }
                    locationListeners.forEach { listener ->
                        listener.invoke(
                            ILocationClient.SUCCESS,
                            locationInfo
                        )
                    }
                }
            }
            catch (e:Exception){
                val text ="GoogleLocationClient  locationCallback: ${e.message} }"
                Log.d(TAG,"locationCallback ${text}")
                TencentCOSUtils.uploadErrorLog(App.context,text,"GoogleLocationClient_locationCallback")
            }
        }

        override fun onLocationAvailability(availability: LocationAvailability) {
              if (!availability.isLocationAvailable) {
                // handleFailed(null)
                  val text ="GoogleLocationClient  onLocationAvailability not LocationAvailable }"
                  TencentCOSUtils.uploadErrorLog(App.context,text,"GoogleLocationClient_locationCallback")
              }
        }
    }
}