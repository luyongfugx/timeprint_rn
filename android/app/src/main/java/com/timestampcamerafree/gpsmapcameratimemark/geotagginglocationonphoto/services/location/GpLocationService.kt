package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.location

import android.content.Context
import android.location.Address
import android.location.Geocoder
import android.util.Log
import android.webkit.WebView
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.WeatherInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.GpLocationInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.LocationInfoData
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.LocationServiceEvent
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.ServiceConfig
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.client.BAIDU
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.client.GoogleLocationClient
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.client.ILocationClient
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.client.LocationClient
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.client.LocationClientProxy
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.client.LocationOptions
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.location.BaseLocationService.Companion.LOCATION_MODE_ONCE
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.location.BaseLocationService.Companion.LOCATION_MODE_PERIODIC
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.location.BaseLocationService.Companion.REFRESH_STATE_FORGROUND
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.time.IGpTimeService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.weather.IGpWeatherService
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.BroadcastManagerUtil
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpTimeManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.TencentCOSUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.addTo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.launchSafe
import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers
import io.reactivex.rxjava3.core.Observable
import io.reactivex.rxjava3.disposables.CompositeDisposable
import io.reactivex.rxjava3.disposables.Disposable
import io.reactivex.rxjava3.schedulers.Schedulers
import com.google.gson.Gson
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.SerializableAddress

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * GpLocationService 真正的定位实现类
 */
open class GpLocationService: BaseLocationService {
    private val locationClient: LocationClientProxy by lazy {
        LocationClientProxy().apply {
            val client = GoogleLocationClient()
            client.init(App.context,getLocationOption())
            client.registerListener(locationListener)
            client.registerListener(netWorkTimeListener)
            client.registerListener(weatherServiceListener)
            setLocationClient(client)
        }
    }
    //根据经纬度获取地址
    private val geocoder = Geocoder(App.context)
    private val singleExecutor = Executors.newSingleThreadExecutor()
    private var context:Context? = null
    private val locationEmitterList = CopyOnWriteArrayList<LocationLiveData>()// Collections.synchronizedList(LinkedList<LocationLiveData>())
    private var periodMode:Int =  LOCATION_MODE_ONCE
    private var currentLocationClientName = BAIDU
    private var requestPlaceFailed = false
    private var requestPlaceFailedCount = 0

    companion object{
        private val TAG = "GpLocationService"
    }
    private var lastGotPlaceLocationInfo:GpLocationInfo<LocationInfoData>? = null
    private var currentRefreshState = REFRESH_STATE_FORGROUND
    private var periodDisposable: Disposable? = null
    private val retryMax = 0L
    private val retryAltitudeMax = 0L
    private var retryCount = 0L
    private var retryAltitudeCount = 0L
    private val locationDisposable = CompositeDisposable()
    private val netWorkTimeListener: (Int, GpLocationInfo<LocationInfoData>?) -> Unit = { status, locationInfo ->
        if (status == ILocationClient.SUCCESS) {
            val timeService = ServiceConfig.getGpTimeService()
            val callback = object : IGpTimeService.Callback {
                override fun onCurrentTime(t: Long) {
                    //可以保证时间为真了
                    GpTimeManager.canMakeSureRealTime = true
                    //说明 网络肯定通
                    App.isNetWorkConnected  = true
                }
                override fun onComplete() {}
                override fun onError(e: Exception) {
                    App.isTimeError  = true
                    BroadcastManagerUtil.sendLocalMessage(BroadcastManagerUtil.timeServiceError)
                }
            }

            timeService.start(App.context,callback,locationInfo?.latitude,locationInfo?.longitude)
        }
    }
    private val weatherServiceListener: (Int, GpLocationInfo<LocationInfoData>?) -> Unit = { status, locationInfo ->
        if (status == ILocationClient.SUCCESS) {
            val weatherService = ServiceConfig.getGpWeatherService()
            val callback = object : IGpWeatherService.Callback {
                override fun onCurrentWeather(weather: WeatherInfo) {
                   // Log.d(TAG,"weatherServiceListener onCurrentWeather: ${weather}")
                }

                override fun onError(e: Exception) {
                    val text ="weatherServiceListener  error:  ${e.message} "
                    TencentCOSUtils.uploadErrorLog(App.context,text,"weatherServiceListener_error")
                }
                override fun onComplete() {}
            }
            weatherService.start(App.context,callback,locationInfo?.latitude,locationInfo?.longitude)
        }
    }

    private val locationListener = { resultStatus:Int, result:GpLocationInfo<LocationInfoData>? ->
        if (resultStatus == ILocationClient.SUCCESS){
            AnalyticsManager.logEvent("locationListener_succ")
            Log.d(TAG,"locationListener succ ${result}")
            result!!
            val text ="locationListener  succ:  ${result.altitude} ${result.latitude} ${result.longitude}}"
            TencentCOSUtils.uploadErrorLog(App.context,text,"locationListener_succ")

            if (!result.altitudeIsLegal() && periodMode == LOCATION_MODE_ONCE){
                retryAltitude()
            }
            App.isLocationSucc = true;
            retryCount = Long.MAX_VALUE
            // 判断是否需要刷新
            val placeNeedRefreshList = ArrayList<LocationLiveData>()
            locationEmitterList.forEach {
                val refreshStrategy = it.getRefreshStrategy()
                if (it.oldLocationInfo == null || refreshStrategy.shouldRefreshWhenGotLocation(it.oldLocationInfo!!,result)) { // 需要更新经纬度
                    it.apply {// 更新旧地点的经纬度
                        oldLocationInfo?.apply {
                            latitude = result.latitude
                            longitude = result.longitude
                            if (result.altitude != Double.MIN_VALUE)
                                altitude = result.altitude
                            speed = result.speed
                            status = GpLocationInfo.STATUS_LOCATION_SUCCESS
                            type = result.type
                            accuracy = result.accuracy
                            cityName = result.cityName
                            countryCode =  result.countryCode
                            refreshType = currentRefreshState//赋值刷新类型,切换状态和强制状态只作用一次//TODO
                        } ?: kotlin.run {
                            oldLocationInfo = getNewLocationInfo(Double.MIN_VALUE, result).apply {
                                status = GpLocationInfo.STATUS_LOCATION_SUCCESS
                            }
                        }
                    }
                    it.emitter.onNext(it.oldLocationInfo!!)
                }
                val oldPlaceLocationInfo = it.oldPlaceLocationInfo
                val needRefreshPlace = oldPlaceLocationInfo == null
                        || refreshStrategy.shouldRefreshWhenGotPlace(oldPlaceLocationInfo, result, currentRefreshState)
                        || (requestPlaceFailed && requestPlaceFailedCount < 3)
                Log.d(TAG,"placeNeedRefreshList add ${it}")
               // if (needRefreshPlace) {
                    placeNeedRefreshList.add(it)
               // }
            }
            if (placeNeedRefreshList.isNotEmpty()) {
                refreshPlace(result, placeNeedRefreshList)
                Log.d(TAG,"locationListener succ placeNeedRefreshList.isNotEmpty() ")
            }
            else { //如果不需要刷新，需要更新首页loading状态
                Log.d(TAG,"locationListener succ placeNeedRefreshList.isEmpty() ")
                BroadcastManagerUtil.sendLocalMessage(BroadcastManagerUtil.locationSucc)
            }

            currentRefreshState = GpLocationInfo.REFRESH_STATE_FORGROUND
        }else{
            if (!retry()){
                AnalyticsManager.logEvent("locationListener_fail")
                val text ="locationListener error"
                TencentCOSUtils.uploadErrorLog(App.context,text,"locationListener_error")
                //设置地理位置获取成功标志位
                App.isLocationSucc = false;
                //发送获取地理位置失败消息,会在mainactivity处理
                Log.d(TAG,"BroadcastManagerUtil.locationError 1")
                BroadcastManagerUtil.sendLocalMessage(BroadcastManagerUtil.locationError)
                locationEmitterList.forEach { locationLiveData ->
                    locationLiveData.oldLocationInfo?.let {
                        locationLiveData.emitter.onNext(it.apply { status = GpLocationInfo.STATUS_LOCATION_FAILED})
                    }?: kotlin.run {
                        locationLiveData.emitter.onNext(getNewLocationInfo())
                    }
                }
            }
        }
    }
    override fun observeLocationInfo(refreshStrategy:GpLocationStrategy?, type:LocationObserverType, parentType:LocationObserverType?):Observable<GpLocationInfo<LocationInfoData>> {
        if (refreshStrategy == null && parentType == null){
            return Observable.empty()
        }
        if (parentType != null){
        }
        val strategy = refreshStrategy ?: EmptyRefreshStrategy
        return Observable.create<GpLocationInfo<LocationInfoData>> { emitter->
            val observer =  if (lastGotPlaceLocationInfo != null){
                LocationLiveData(type,lastGotPlaceLocationInfo!!.copy(),lastGotPlaceLocationInfo!!.copy(),emitter,strategy)
            }else{
                LocationLiveData(type,null,null,emitter,strategy)
            }
            observer.parentType = parentType
            val disposable = object:Disposable{
                override fun isDisposed(): Boolean {
                    return !locationEmitterList.contains(observer)
                }
                override fun dispose() {
                    locationEmitterList.remove(observer)
                    observer.disposeChildren()
                }
            }
            observer.disposable = disposable
            emitter.setDisposable(disposable)
            if (parentType != null) {
                locationEmitterList.firstOrNull {
                    it.type === parentType
                }?.let {
                    if (it.addChild(observer)) {
                        observer.parentObserver = it
                    }
                }
            } else {
                locationEmitterList.forEach {
                    if(it.parentType === type){
                        if (observer.addChild(it)) {
                            it.parentObserver = observer
                        }
                    }
                }
            }
            locationEmitterList.add(observer)
        }
    }

    override fun getLocationInfo(): GpLocationInfo<LocationInfoData>? {
        return lastGotPlaceLocationInfo
    }

    override fun stopLocation() {
        singleExecutor.execute {
            stopLocationSync()
        }
    }

    private fun stopLocationSync() {
        if (locationClient.isStarted()) {
            locationClient.stop()
            if (periodDisposable?.isDisposed == false){
                periodDisposable?.dispose()
            }
            while (locationClient.isStarted()){
                Thread.sleep(100)
            }
            eventListenerList.forEach {
                it.onEvent(LocationServiceEvent.EVENT_ON_STOP)
            }
            locationDisposable.clear()
        }
    }

    /**
     * 开始定位
     *
     * @param context
     */
    override fun startLocation(context: Context?) {
        singleExecutor.execute {
            startLocationSync()
        }
    }

    override fun reStartLocation(context: Context?) {
        singleExecutor.execute {
            locationClient.reStart()
            startLocationSync()
        }
    }


    private fun startLocationSync(){
        if (!locationClient.isStarted()) {
            locationClient.start()
            AnalyticsManager.logEvent("locationClient_start")
            requestPlaceFailedCount = 0
            while (!locationClient.isStarted()){
                Thread.sleep(100)
            }
            eventListenerList.forEach { it.onEvent(LocationServiceEvent.EVENT_ON_START) }
            retryCount = 0// 把定位次数置为0
            retryAltitudeCount = 0
            if (periodMode == LOCATION_MODE_PERIODIC) {
                periodDisposable = Observable.interval(5000L, 5000L, TimeUnit.SECONDS).subscribe {
                    if (retryMax > 1){
                        if (retryCount in 1 until retryMax){
                            retryCount = retryMax
                        }else { // 从未有定位结果或者超过
                            retryCount = Long.MAX_VALUE
                        }
                    }
                    Log.i(TAG,"commonBroadcastReceiver singleExecutor location has started，do nothing !locationClient.isStarted(")
                    locationClient.requestLocation()
                }
            }else{
                Log.i(TAG,"commonBroadcastReceiver singleExecutor location  locationClient.isStarted")
                locationClient.requestLocation()
            }
        }else{

            Log.i(TAG,"commonBroadcastReceiver == singleExecutor location has started，do nothing")
        }
    }

    override fun refreshLocation(context: Context?) {
        if (!locationClient.isStarted()){
            Log.i(TAG,"commonBroadcastReceiver refreshLocation !locationClient.isStarted()")
            startLocation(context)
        // 没打开的时候打开定位服务
        }
        else {
            Log.i(TAG,"commonBroadcastReceiver refreshLocation stop")
            locationClient.stop()
        }

        singleExecutor.execute{
            AnalyticsManager.logEvent("locationClient_refreshLocation")
            Log.i(TAG,"commonBroadcastReceiver singleExecutor.execute locationClient.requestLocation")
            startLocationSync()
        }

    }

    override fun init(context: Context) {
        init(context, currentLocationClientName)
    }

    override fun init(context: Context,@LocationClient clientName: String) {
    }

    override fun switchLocationClient(clientName: String): Observable<Boolean> {
        return (context?: App.context)?.let { context ->
            Observable.just(0).map {
                if (locationClient.getName() != clientName) {
                    if(locationClient.isStarted()) {
                        stopLocationSync()
                        locationClient.destroy()
                    }
                    eventListenerList.forEach { it.onEvent(LocationServiceEvent.EVENT_ON_SWITCH_LOCATION_CLIENT) }
                    locationClient.init(context,getLocationOption())
                    locationClient.registerListener(locationListener)
                    locationClient.registerListener(netWorkTimeListener)
                    locationClient.registerListener(weatherServiceListener)
                    this.currentLocationClientName = locationClient.getName()
                }
                true
            }.subscribeOn(Schedulers.from(singleExecutor))
        }?:Observable.just(false)
    }

    override fun getCurrentLocationClientName(): String {
        return locationClient.getName()
    }

    override fun startAssistantLocation(webView: WebView) {
        locationClient.startAssistantLocation(webView)
    }

    override fun stopAssistantLocation() {
        locationClient.stopAssistantLocation()
    }

    private val eventListenerList = CopyOnWriteArrayList<BaseLocationService.LocationServiceEventListener>() // Collections.synchronizedList(LinkedList<ILocationService2.LocationServiceEventListener>())

    override fun registerServiceEvent(eventListener: BaseLocationService.LocationServiceEventListener) {
        eventListenerList.add(eventListener)
    }

    override fun unregisterServiceEvent(eventListener: BaseLocationService.LocationServiceEventListener) {
        eventListenerList.remove(eventListener)
    }



    /**
     * 增加定位监听
     *
     * @param listener
     */
    override fun registerLocationListener(listener: (Int, GpLocationInfo<LocationInfoData>?) -> Unit) {
        locationClient.registerListener(locationListener)
    }

    private fun retry():Boolean{
        if (retryCount < retryMax){
            Observable.timer(1,TimeUnit.SECONDS)
                .subscribeOn(AndroidSchedulers.mainThread())
                .subscribe {
                    if (retryCount < retryMax) {
                        retryCount++
                        locationClient.requestLocation()
                    }
                }.addTo(locationDisposable)
            return true
        }
        return false
    }

    private fun retryAltitude():Boolean{
        if (retryAltitudeCount < retryAltitudeMax){
            Observable.timer(1,TimeUnit.SECONDS)
                .subscribeOn(AndroidSchedulers.mainThread())
                .subscribe {
                    if (retryAltitudeCount < retryAltitudeMax) {
                        retryAltitudeCount++
                        locationClient.requestLocation()
                    }
                }.addTo(locationDisposable)
            return true
        }
        return false
    }


    override fun setLocationPeriodic(periodic:Boolean) {
        locationClient.resetLocationOption(getLocationOption())
    }

    override fun setOnlyGps(onlyGps: Boolean) {
        locationClient.resetLocationOption(getLocationOption())
    }
   private fun equipAddressFormatAB(address: String, fullAddress: Address): String {

       val after = address
       return after
    }
    private suspend fun getFromLocation(
        latitude: Double,
        longitude: Double,
        maxResults: Int = 1
    ): List<Address> = withContext(Dispatchers.IO) {
        try {
            val addresses = geocoder.getFromLocation(
                latitude,
                longitude,
                maxResults
            ) ?: emptyList()
            AnalyticsManager.logEvent("geocoder_getFromLocation")

            //上报一下地址
            if (addresses.isNotEmpty()) {
                try {
                    val text ="geocoder  succ, latitude:${latitude} longitude:${longitude} addresses[0]: ${addresses[0]}}"
                    TencentCOSUtils.uploadErrorLog(App.context,text,"geocoder")
                }
                catch (e:Exception){
                    AnalyticsManager.logEvent("getFromLocation_upload_error")
                }

            }
            else {
                try {
                    val text ="geocoder  failed ddresses.Empty, latitude:${latitude} longitude:${longitude} addresses[0]: ${addresses[0]}}"
                    TencentCOSUtils.uploadErrorLog(App.context,text,"geocoder_empty")
                }
                catch (e:Exception){
                    AnalyticsManager.logEvent("getFromLocation_upload_error")
                }
            }
            addresses


        } catch (e: Exception) {
            val text ="getFromLocation latitude:${latitude} longitude:${longitude} error:${e.message}"
            TencentCOSUtils.uploadErrorLog(App.context,text,"getFromLocation_error")
            AnalyticsManager.logEvent("geocoder_getFromLocation_error")



            emptyList()
        }
    }
    override fun refreshPlace(
        newLocation: GpLocationInfo<LocationInfoData>,
        observerList: List<LocationLiveData>
    ) {
        var addressFromGeo:List<Address> = listOfNotNull()
        var cacheLocation:LocationInfoData? = null
        var retryCount = 0
        val maxRetries = 3
        val lastSavedLocation = getLastSaveLocationInfo()

        lastSavedLocation?.let { saved ->
            Log.d(TAG, "Using cached location lastSavedLocation $lastSavedLocation ${ lastSavedLocation?.rawAddress}")
            val distance = calculateDistance(
                saved.latitude, saved.longitude,
                newLocation.latitude, newLocation.longitude
            )
            if (distance < 50) {
               cacheLocation = saved.locationInfoDataObject
                addressFromGeo = saved.rawAddress
            }
        }

        suspend fun tryGeocoding(): List<Address> {
            if (Geocoder.isPresent()) {
                val addresses = getFromLocation(newLocation.latitude, newLocation.longitude)
                AnalyticsManager.logEvent("refreshPlace_geocoder_getFromLocation")
                if (addresses.isNotEmpty()) {
                    addresses.onEach {
                        it.apply {
                            var al = equipAddressFormatAB(getAddressLine(0), it)
                            setAddressLine(0, al)
                        }

                    }
                }
                return addresses
            }
            return emptyList()
        }

        GlobalScope.launchSafe {
            if (addressFromGeo.isEmpty()){
                Log.d(TAG, "lastSavedLocation addressFromGeo is empty tryGeocoding")
                do {
                    addressFromGeo = tryGeocoding()
                    if (addressFromGeo.isEmpty() && retryCount < maxRetries) {
                        delay(500) // Wait 0.5 second before retry
                        retryCount++
                    }
                } while (addressFromGeo.isEmpty() && retryCount < maxRetries)
                //最后一次才发错误

                if (addressFromGeo.isEmpty() ){
                    Log.d(TAG,"BroadcastManagerUtil.locationError 2 requestPlaceFailedCount $requestPlaceFailedCount  retryCount $retryCount retryMax: $maxRetries")
                    if (requestPlaceFailedCount>=2) {
                        BroadcastManagerUtil.sendLocalMessage(BroadcastManagerUtil.locationError)
                    }
                    requestPlaceFailedCount++
                }
                else {
                    Log.d(TAG,"BroadcastManagerUtil.locationError 2 requestPlaceFailedCount $requestPlaceFailedCount retryCount $retryCount retryMax: $maxRetries")
                }
            }
            else {
                Log.d(TAG, "lastSavedLocation addressFromGeo is not empty use it : ${addressFromGeo[0]}")
                val text = "lastSavedLocation addressFromGeo is not empty use it : ${addressFromGeo[0]}"
                TencentCOSUtils.uploadErrorLog(App.context, text, "lastSavedLocation")
            }
            withContext(Dispatchers.Main) {
                if (addressFromGeo.isNotEmpty()  ) {
                    // 获取地点成功
                    val locationInfo = getNewLocationInfo(
                        newLocation.altitude,
                        newLocation
                    )
                    locationInfo.locationInfoDataObject = LocationInfoData()
                    locationInfo.status = GpLocationInfo.STATUS_REQUEST_PLACE_SUCCESS
                    locationInfo.rawAddress = addressFromGeo
                    //获取国家代码
                    locationInfo.countryCode = getCountryCode(addressFromGeo)
                    observerList.forEach {
                        if (it.disposable?.isDisposed == false) {
                            it.oldLocationInfo = withContext(Dispatchers.IO) {
                                locationInfo.copy()
                            }
                            it.oldPlaceLocationInfo = withContext(Dispatchers.IO) {
                                locationInfo.copy()
                            }
                            it.emitter.onNext(locationInfo)
                        }
                    }
                    lastGotPlaceLocationInfo = locationInfo
                    //保存到本地
                    saveLocationInfo(locationInfo)
                    BroadcastManagerUtil.sendLocalMessage(BroadcastManagerUtil.locationSucc)
                }
                else{ //获取地点失败，但是已经有经纬度，经纬度还是可以取到
                   // Log.d(TAG,"BroadcastManagerUtil.locationError 3")
                   // BroadcastManagerUtil.sendLocalMessage(BroadcastManagerUtil.locationError) //发送一个错误
                    val locationInfo = getNewLocationInfo(
                        newLocation.altitude,
                        newLocation
                    )

                    locationInfo.locationInfoDataObject = LocationInfoData()
                    locationInfo.status = GpLocationInfo.STATUS_REQUEST_PLACE_SUCCESS
                    locationInfo.rawAddress = addressFromGeo
                    //获取国家代码
                    locationInfo.countryCode = getCountryCode(addressFromGeo)
                    observerList.forEach {
                        if (it.disposable?.isDisposed == false) {
                            it.oldLocationInfo = withContext(Dispatchers.IO) {
                                locationInfo.copy()
                            }
                            it.oldPlaceLocationInfo = withContext(Dispatchers.IO) {
                                locationInfo.copy()
                            }
                            it.emitter.onNext(locationInfo)
                        }
                    }
                    lastGotPlaceLocationInfo = locationInfo
                }
            }
        }
    }

    private val gson by lazy { Gson() }
    private val prefs by lazy { 
        App.context.getSharedPreferences("location_prefs", Context.MODE_PRIVATE) 
    }
    private val LOCATION_KEY = "last_location"
    private val ADDRESS_KEY = "last_address"

    private fun saveAddress(address: Address) {
        try {
            val serializableAddress = SerializableAddress(address)
            val json = gson.toJson(serializableAddress)
            prefs.edit().putString(ADDRESS_KEY, json).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error saving address", e)
            val text = "saveAddress error: ${e.message}"
            TencentCOSUtils.uploadErrorLog(App.context, text, "saveAddressError")
        }
    }

    private fun getAddress(): Address? {
        return try {
            val json = prefs.getString(ADDRESS_KEY, null)
            json?.let {
                val serializableAddress = gson.fromJson(it, SerializableAddress::class.java)
                serializableAddress.toAddress()
            }


        } catch (e: Exception) {
            Log.e(TAG, "Error loading saved address", e)
            val text = "getAddress error: ${e.message}"
            TencentCOSUtils.uploadErrorLog(App.context, text, "loadAddressError")
            null
        }
    }
    private fun saveLocationInfo(location: GpLocationInfo<LocationInfoData>) {
        try {
            location.rawAddress.forEach { address ->
                try {
                    saveAddress(address)
                }
                catch (e:Exception){
                    Log.e(TAG, "Error loading saved address", e)
                    val text = "getAddress error: ${e.message}"
                    TencentCOSUtils.uploadErrorLog(App.context, text, "saveAddressError")
                }

            }
            val tempLocation = location.copy().apply {
                rawAddress = emptyList()
            }
            val json = gson.toJson(tempLocation)
            prefs.edit().putString(LOCATION_KEY, json).apply()
        } catch (e: Exception) {
            Log.e(TAG, "Error saving location", e)
            val text = "saveLocationInfo error: ${e.message}"
            TencentCOSUtils.uploadErrorLog(App.context, text, "saveLocationError")
        }
    }

    private fun getLastSaveLocationInfo(): GpLocationInfo<LocationInfoData>? {
        return try {
            val json = prefs.getString(LOCATION_KEY, null)
            json?.let {
                val location = gson.fromJson(it, GpLocationInfo::class.java) as GpLocationInfo<LocationInfoData>
                val savedAddress = getAddress()
                if (savedAddress != null) {
                    location.rawAddress = listOf(savedAddress)
                }
                location
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error loading saved location", e)
            val text = "getLastSaveLocationInfo error: ${e.message}"
            TencentCOSUtils.uploadErrorLog(App.context, text, "loadLocationError")
            null
        }
    }
    private fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Float {
        val results = FloatArray(1)
        android.location.Location.distanceBetween(lat1, lon1, lat2, lon2, results)
        return results[0]
    }
    private fun getCountryCode(addressFromGeo:List<Address>) :String {
        var result = ""
        if (!addressFromGeo.isNullOrEmpty()) {
            addressFromGeo[0].run {
                result = countryCode
            }
        }
        return result
    }

    private fun getNewLocationInfo(oldAltitude:Double, bdLocation: GpLocationInfo<LocationInfoData>):GpLocationInfo<LocationInfoData>{
        return bdLocation.copy().apply {
            if (altitude == Double.MIN_VALUE){
                altitude = oldAltitude
            }
        }
    }

    private fun getNewLocationInfo():GpLocationInfo<LocationInfoData>{
        return GpLocationInfo<LocationInfoData>().apply {
            latitude = Double.MIN_VALUE
            longitude = Double.MIN_VALUE
            createTime = System.currentTimeMillis()
            locationClientName = locationClient.getName()
        }
    }

    override fun setRefreshState(state: Int) {
        if(state <= currentRefreshState) {
            currentRefreshState = state
        }
    }

    private fun getLocationOption():LocationOptions{
        return LocationOptions(
            true,
            5000,
            false,
        )
    }

}