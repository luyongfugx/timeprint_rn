package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.location

import android.content.Context
import android.webkit.WebView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.GpLocationInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.LocationInfoData
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.LocationServiceEvent
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.client.LocationClient
import io.reactivex.rxjava3.core.Observable

/**
 * 基础定位类
 *
 */
interface BaseLocationService:
    ILocationService<LocationInfoData> {
    companion object {
        const val REFRESH_STATE_FORGROUND = 2
        const val LOCATION_MODE_ONCE = 0
        const val LOCATION_MODE_PERIODIC = 1
    }
    fun init(context: Context, @LocationClient clientName: String)
    fun observeLocationInfo(
        refreshStrategy: GpLocationStrategy?,
        type: LocationObserverType,
        parentType: LocationObserverType?
    ): Observable<GpLocationInfo<LocationInfoData>>


    fun setRefreshState(state: Int): Unit
    fun setLocationPeriodic(periodic: Boolean)
    fun setOnlyGps(onlyGps: Boolean)
    fun refreshPlace(
        newLocation: GpLocationInfo<LocationInfoData>,
        observerList: List<LocationLiveData>
    )
    fun switchLocationClient(@LocationClient clientName: String): Observable<Boolean>

    fun getCurrentLocationClientName(): String

    fun startAssistantLocation(webView: WebView)

    fun stopAssistantLocation()
    fun registerServiceEvent(eventListener: LocationServiceEventListener)
    fun unregisterServiceEvent(eventListener: LocationServiceEventListener)
    fun registerLocationListener(listener: (Int, GpLocationInfo<LocationInfoData>?) -> Unit)
    interface LocationServiceEventListener {
        fun onEvent(event: LocationServiceEvent)
    }


}