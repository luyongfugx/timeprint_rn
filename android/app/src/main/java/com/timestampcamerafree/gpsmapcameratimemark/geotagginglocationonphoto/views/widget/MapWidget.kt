package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.views.widget

import android.app.Activity
import android.content.Context
import android.util.AttributeSet
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.widget.FrameLayout
import android.widget.ImageView
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.GoogleMap
import com.google.android.gms.maps.MapView
import com.google.android.gms.maps.MapsInitializer
import com.google.android.gms.maps.OnMapReadyCallback
import com.google.android.gms.maps.OnMapsSdkInitializedCallback
import com.google.android.gms.maps.model.LatLng
import com.google.android.gms.maps.model.Marker
import com.google.android.gms.maps.model.MarkerOptions
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.activities.MainActivity
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.receivers.CommonBroadcastReceiver
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.ServiceConfig
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpDataStores
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpStoreKey
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.store.GpStoreKeys
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.EditClickFrom
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.WatermarkItemID

class MapWidget @JvmOverloads constructor(
    private val context: Context,
    attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr), OnMapReadyCallback, OnMapsSdkInitializedCallback {
    private val TAG = "MapWidget"

    companion object {
        const val MAP_STATE_SUC = 0
        const val MAP_STATE_LOADING = 1
        const val MAP_STATE_FAIL = 2
        var mapLoadState = MAP_STATE_LOADING
        var isMapSucc = false
    }

    private var zoom = 13f
    private lateinit var mapView: MapView

    //    private var bitmapView:View
    private lateinit var mapViewContainer: View
    private lateinit var map: GoogleMap
    private var mMark: Marker? = null
    private lateinit var mapImageView: ImageView

    init {
        try {
            LayoutInflater.from(context).inflate(R.layout.layout_map_widget, this, true)
            mapView = findViewById(R.id.mapView)
            mapView.onCreate(null)
            mapView.getMapAsync(this)
            mapView.visibility = View.VISIBLE
            mapViewContainer = findViewById(R.id.mapViewContainer)
            mapImageView = findViewById(R.id.mapImageView)
            observeEvent()

        } catch (e: Exception) {
            Log.d(TAG, "init MapWidget error: ${e.message}")
        }

    }

//    override fun onFinishInflate()
// {
//     super.onFinishInflate()
//     Log.d(TAG,"CommonBroadcastReceiver == CommonBroadcastReceiverdddddd ")
//       commonBroadcastReceiver = CommonBroadcastReceiver{
//           Log.d(TAG,"CommonBroadcastReceiver ==CommonBroadcastReceiver  ${it}")
//           //如果是本地消息
//           if(BroadcastManagerUtil.getLocalMessage(it).equals(BroadcastManagerUtil.locationSucc)){
//               Log.d(TAG,"CommonBroadcastReceiver locationSucc  ")
//               onWaterMarkChage()
//           }
//           //如果定位权限已经开通，但是获取定位失败，弹出消息，说明无法获取定位，这时候应该关注network是否成功
//           else if(BroadcastManagerUtil.getLocalMessage(it).equals(BroadcastManagerUtil.locationError)){
//               Log.d(TAG,"CommonBroadcastReceiver locationError ")
//           }
//       }
//    }

    var scale = 1.0f
    private var startLoadingMapTime = 0L

    private fun getLifecycleOwner(): LifecycleOwner? {
        if (context is Activity && context is LifecycleOwner) {
            return context
        }
        return null
    }

    private fun <T> observeDataStores(storeKey: String, observer: Observer<T>) {
        var lifecycleOwner = getLifecycleOwner()
        if (lifecycleOwner != null) {
            GpDataStores.observe(
                GpStoreKey.valueOf(
                    storeKey,
                    lifecycleOwner,
                ), observer, lifecycleOwner
            )
        }
    }

    private fun observeEvent() {
        //监听旋转
        observeDataStores<Int>(GpStoreKeys.KEY_ORIENTATION, Observer {
            // getModel()?.qrCodeChangeModel?.qrCodeGravityAngle?.set(it)
        })
        //监听改变水印
        this.observeDataStores(GpStoreKeys.WATERMARK_ID_CHANGE, { updateValue: Boolean ->
            onWaterMarkChage()
        })
        //监听修改
        this.observeDataStores(GpStoreKeys.KEY_WATERMARK_UPDATE, { updateValue: Boolean ->
            onWaterMarkChage()
        })
    }

     fun onWaterMarkChage() {
         try{
             var mapItem =
                 WatermarkManager.getSelectWatermarkModel().items.find { it?.id == WatermarkItemID.map.id }
             if (mapItem?.isOpen == true) {
                 mapViewContainer.visibility = View.VISIBLE
             } else {
                 mapViewContainer.visibility = View.GONE
             }
             map.mapType = mapItem?.extraMap?.mapType!!
             zoom = mapItem?.extraMap?.mapZoom!!
             setMapLocation()
         } catch (e: Exception) {
             Log.d(TAG, "onWaterMarkChage error: ${e.message}")
         }

    }


    override fun onMapReady(googleMap: GoogleMap) {
        Log.d(TAG,"onMapReady called parent:${this.hashCode()}")
        try {
            var latLng = LatLng(0.0, 0.0)
            val addressItem =
                WatermarkManager.getSelectWatermarkModel().items.find { it?.id == WatermarkItemID.address.id }
            addressItem?.let {
                it.extraAddressInfo?.let { addressInfo ->
                    latLng = addressInfo.getLatLng() ?: latLng
                }.run { }
            }
            googleMap.addMarker(MarkerOptions().position(latLng))
            googleMap.moveCamera(CameraUpdateFactory.newLatLngZoom(latLng, zoom))
            map = googleMap
            map.setOnCameraIdleListener {
                snapshotMap()
            }
            var mapItem =
                WatermarkManager.getSelectWatermarkModel().items.find { it?.id == WatermarkItemID.map.id }
            mapViewContainer.visibility = View.VISIBLE
            map.mapType = mapItem?.extraMap?.mapType ?: GoogleMap.MAP_TYPE_NORMAL
            zoom = mapItem?.extraMap?.mapZoom ?: 13f
            map.moveCamera(CameraUpdateFactory.newLatLngZoom(latLng, zoom))
            map.uiSettings.isZoomControlsEnabled = false
            map.setOnMapClickListener {
                handleClick()
            }
            map.setOnMarkerClickListener {
                handleClick()
                true
            }
            if (mapItem?.isOpen == true) {
                setMapLocation()
            } else {
                mapViewContainer.visibility = View.GONE
            }
        } catch (e: Exception) {
            Log.d(TAG, "onMapReady error: ${e.message}")
        }
    }

    private fun handleClick() {
        try {
            if (context is MainActivity) {

                (context).showEditWaterView(EditClickFrom.Map)
            }
        } catch (e: Exception) {
            Log.d(TAG, "handleClick error: ${e.message}")
        }
    }


    private var lastLatLng: LatLng? = null
    private var isCapturing = false
    private fun setMapLocation(show: Boolean = true) {
        try {
            mapView.visibility = View.VISIBLE
            if (!::map.isInitialized) {
                return
            }
            with(map) {
                var latLng: LatLng? = null
                var addressItem =
                    WatermarkManager.getSelectWatermarkModel().items.find { it?.id == WatermarkItemID.address.id }
                addressItem?.let {
                    it.extraAddressInfo?.let { addressInfo ->
                        latLng = addressInfo.getLatLng() ?: latLng
                    }
                }
                if (latLng == null) { //直接从locationServicen拿位置

                    val locationService = ServiceConfig.getLocationService()
                    val location =  locationService.getLocationInfo()
                    location?.let {
                        latLng=  LatLng(location.latitude, location.longitude)
                    }
                }
                latLng?.let { latLng ->
                    if (isSameLatLng(latLng, lastLatLng) && mapLoadState == MAP_STATE_SUC) {
                        return@let
                    }
                    map.clear()
                    map.addMarker(MarkerOptions().position(latLng))
                    map.moveCamera(CameraUpdateFactory.newLatLngZoom(latLng, zoom))
                    if (mapLoadState != MAP_STATE_SUC) {
                        mapLoadState = MAP_STATE_LOADING
                    }
                    isCapturing = true
                    lastLatLng = latLng
                    startLoadingMapTime = System.currentTimeMillis()
                    mMark?.position = latLng
                    isMapSucc = true
                    //截图，把bigMapImage赋值给
                    snapshotMap()
                } ?: run {
                    Log.d(TAG,"onWaterMarkChageis isMapSucc latLng ")
                    snapshotMap()
                    mapLoadState = MAP_STATE_FAIL
                }
            }
        } catch (e: Exception) {
            Log.d(TAG, "setMapLocation error: ${e.message}")
        }
    }

    private fun snapshotMap() {
        try {
            Log.d(TAG,"onWaterMarkChage snapshotMap called")
//底下两个return 都是为了比慢
//            FATAL EXCEPTION: androidmapsapi-Snapshot (Ask Gemini)
//            Process: com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.debug, PID: 21803
//            java.lang.IllegalArgumentException: width and height must be > 0
//            at android.graphics.Bitmap.createBitmap(Bitmap.java:1111)
//            at android.graphics.Bitmap.createBitmap(Bitmap.java:1078)
//            at android.graphics.Bitmap.createBitmap(Bitmap.java:1028)
//            at android.graphics.Bitmap.createBitmap(Bitmap.java:989)
//            at com.google.maps.api.android.lib6.impl.a.c(:com.google.android.gms.policy_maps_core_dynamite@250625407@250625402025.745714853.745714853:16)
//            at com.google.maps.api.android.lib6.impl.bu.run(:com.google.android.gms.policy_maps_core_dynamite@250625407@250625402025.745714853.745714853:10)
//
            if (!::map.isInitialized) { //判断是否加载完毕，不然可能crash
                return
            }
            //判断是否加载完毕，不然可能crash
            if(mapView.width <= 0){
                return ;
            }
            mapImageView.postDelayed({
                map.snapshot { bitmap ->
                    if (bitmap != null) {
                       // WatermarkManager.mapBitmap = bitmap
                        mapImageView.setImageBitmap(bitmap)
                    }
                }
            },300)
        } catch (e: Exception) {
            Log.d(TAG, "snapshotMap error: ${e.message}")
        }

    }

    private fun isSameLatLng(latLng1: LatLng?, latLng2: LatLng?): Boolean {
        if (latLng1 == null || latLng2 == null) {
            return false
        }
        return Math.abs(latLng1.latitude - latLng2.latitude) < 0.0001 && Math.abs(latLng1.longitude - latLng2.longitude) < 0.0001
    }

    override fun onMapsSdkInitialized(renderer: MapsInitializer.Renderer) {
        Log.d(TAG,"onMapsSdkInitialized ==")
        try {

            when (renderer) {
                MapsInitializer.Renderer.LATEST -> Log.d(
                    TAG,
                    "The latest version of the renderer is used."
                )

                MapsInitializer.Renderer.LEGACY -> Log.d(
                    TAG,
                    "The legacy version of the renderer is used."
                )
            }
        } catch (e: Exception) {
            Log.d(TAG, "onMapsSdkInitialized error: ${e.message}")
        }
    }

}