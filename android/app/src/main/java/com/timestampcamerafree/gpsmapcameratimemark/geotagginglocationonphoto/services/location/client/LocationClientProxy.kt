package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.client
import android.content.Context
import android.webkit.WebView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.GpLocationInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.LocationInfoData




class LocationClientProxy:ILocationClient {

    private var locationClient:ILocationClient? = null

    fun setLocationClient(locationClient:ILocationClient){
        this.locationClient = locationClient
    }

    override fun getName(): String {
        return locationClient?.getName()?:""
    }

    override fun init(context: Context,options: LocationOptions) {
        locationClient?.init(context,options)
    }

    override fun registerListener(listener: (Int, GpLocationInfo<LocationInfoData>?) -> Unit) {
        locationClient?.registerListener(listener)
    }

    override fun isStarted(): Boolean {
        return locationClient?.isStarted()?:false
    }

    override fun start() {
        locationClient?.start()
    }

    override fun reStart() {
        locationClient?.reStart()
    }

    override fun resetLocationOption(options: LocationOptions) {
        locationClient?.resetLocationOption(options)
    }

    override fun stop() {
        locationClient?.stop()
    }

    override fun destroy() {
        locationClient?.destroy()
    }

    override fun requestLocation() {
        locationClient?.requestLocation()
    }


    override fun startAssistantLocation(webView: WebView) {
        locationClient?.startAssistantLocation(webView)
    }

    override fun stopAssistantLocation() {
        locationClient?.stopAssistantLocation()
    }
}