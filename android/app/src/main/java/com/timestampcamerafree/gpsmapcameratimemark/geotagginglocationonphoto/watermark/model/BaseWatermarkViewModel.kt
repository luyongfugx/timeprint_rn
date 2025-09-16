package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model
import android.annotation.SuppressLint
import android.location.Address
import android.util.Log
import androidx.lifecycle.LiveData
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.R
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.GpLocationInfo
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.models.accurate.LocationInfoData
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.ServiceConfig
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.location.LocationObserverType
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.location.GpLocationStrategy
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpDateFormat
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpTimeManager

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpUiUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GpWeatherManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.TencentCOSUtils
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.address.WatermarkAddressItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.coordinate.WatermarkCoordinateItem
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.GPDateStyle
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.model.datetime.WatermarkTimeItem
import io.reactivex.rxjava3.android.schedulers.AndroidSchedulers
import io.reactivex.rxjava3.core.Observable
import io.reactivex.rxjava3.disposables.CompositeDisposable
import io.reactivex.rxjava3.disposables.Disposable
import io.reactivex.rxjava3.schedulers.Schedulers

import java.util.Date
import java.util.Locale
import java.util.concurrent.TimeUnit

// view model
class BaseWatermarkViewModel : ViewModel() {
    private val TAG = "BaseWatermarkViewModel"
    var name = MutableLiveData<String>()
    var locationText = MutableLiveData<String>()
    var watermarkModel = MutableLiveData<BaseWatermarkModel>()
    var hmText = MutableLiveData<String>()
    var logoUrl  = MutableLiveData<String>()
    var logoOpen = MutableLiveData<Boolean>(false)
    var logoDrawable = MutableLiveData<Boolean>(true)
    var weekText = MutableLiveData<String>()

    var lat  = MutableLiveData<String>()
    var lng  = MutableLiveData<String>()

    private val _hm01 = MutableLiveData<Int>()
    private val _hm02 = MutableLiveData<Int>()
    private val _hm03 = MutableLiveData<Int>()
    private val _hm04 = MutableLiveData<Int>()

    var hm01: LiveData<Int> =  _hm01
    var hm02: LiveData<Int> =   _hm02
    var hm03: LiveData<Int> =  _hm03
    var hm04: LiveData<Int>  = _hm04
    private val _id9DateDrawableList = MutableLiveData<List<Int>>()
    var id9DateDrawableList: LiveData<List<Int>> = _id9DateDrawableList

    private val _id9TimeDrawableList = MutableLiveData<List<Int>>()
    var id9TimeDrawableList: LiveData<List<Int>> = _id9TimeDrawableList
    var dateText = MutableLiveData<String>()
    //ampm,时区,星期
    var amPmTimeZoneWeek = MutableLiveData<String>()

    var watermarkTitle = MutableLiveData<String>()
    //副标题
    var watermarkSubtitle = MutableLiveData<String>()
    private val disposable: CompositeDisposable = CompositeDisposable()
    private val locationCompositeDisposable: CompositeDisposable = CompositeDisposable()
    init {
        initBase()
       // resetItem()
        disposable.add(
            Observable.interval(1, TimeUnit.SECONDS)
                .subscribeOn(Schedulers.io())
                .observeOn(AndroidSchedulers.mainThread())
                .subscribe {
                    resetItem()
                }
        )
        val locationDisposable: Disposable = ServiceConfig.getLocationService()
            .observeLocationInfo(
                GpLocationStrategy.getDefaultStrategy(),
                LocationObserverType.MAIN,
                null
            )
            .subscribe({ locationInfo ->
                when (locationInfo.status) {
                    GpLocationInfo.STATUS_REQUEST_PLACE_SUCCESS -> {
                        resetLocationInfo(locationInfo)
                    }
                    GpLocationInfo.STATUS_LOCATION_SUCCESS -> {
                    }

                    GpLocationInfo.STATUS_REQUEST_PLACE_FAILED -> {
                    }

                    GpLocationInfo.STATUS_LOCATION_FAILED -> {

                    }

                    else -> {

                    }
                }
            }, { throwable ->
//                Log.e(
//                    TAG,
//                    "observe location info error",
//                    throwable
//                )
            })
        locationCompositeDisposable.add(locationDisposable)

    }

    private fun resetLocationInfo(locationInfo: GpLocationInfo<LocationInfoData>) {
            val tempData = watermarkModel.value?.clone()
            tempData?.items?.forEach {
                when (it?.id) {
                    WatermarkItemID.address.id -> {
                        if(it.extraAddressInfo != null){
                            it.extraAddressInfo!!.rawAddress = locationInfo.rawAddress
                        }
                        else {
                            it.extraAddressInfo = WatermarkAddressItem().apply {
                                rawAddress = locationInfo.rawAddress
                            }
                        }
                        //获取格式地址
                        val lText = it.extraAddressInfo!!.getShowAddress()
                        locationText.value =  lText
                        it.content =  lText
                    }
                    WatermarkItemID.coordinate.id ->  {
                        //获取经纬度格式
                        if(it.extraCoordinateInfo != null){
                            it.extraCoordinateInfo!!.latitude = locationInfo.latitude
                            it.extraCoordinateInfo!!.longitude =  locationInfo.longitude
                        }
                        else {
                            it.extraCoordinateInfo = WatermarkCoordinateItem().apply {
                                latitude = locationInfo.latitude
                                longitude =  locationInfo.longitude
                            }
                        }
                        val lText = it.extraCoordinateInfo?.getShowLatLng() ?: ""
                        it.content =  lText
                        //设置lat lng 地图使用
                        try {
                            val latLngArray = it.extraCoordinateInfo?.getShowLatLng()?.split(",")
                            if (latLngArray !=null && latLngArray.size ==2){
                                lat.value = latLngArray[0]
                                lng.value = latLngArray[1]
                            }
                        }
                        catch (e:Exception){
                            Log.d(TAG,"getShowLatLng error ${e.message}")
                        }
                    }
                    //最多保留6位
                    WatermarkItemID.altitude.id ->  it.content = "%.6f".format(locationInfo.altitude)
                }
            }
            //赋值以触发更新
            watermarkModel.value = tempData!!

    }

    /**
     * 初始化
     *
     */
    fun initBase(){
        try {


       val timeItem = WatermarkTimeItem().apply {
            is12Hour = false
            style = GPDateStyle.dayMonthYear
            showWeek = true
        }
        val time = GpTimeManager.getExactTime()
        if (GpTimeManager.canMakeSureRealTime){
            hmText.value =    GpDateFormat.toHHmm(time, timeItem.is12Hour, timeItem.showWeek, timeItem.showTimeZone, timeItem.style)
            weekText.value = GpDateFormat.toFullWeekText(time)
            val dateTextItem = WatermarkTimeItem()
            dateTextItem.style = timeItem.style
            dateText.value = GpDateFormat.localizedDateString(Date(time), dateTextItem.style,  dateTextItem.is12Hour,false, false,false,true )
            amPmTimeZoneWeek.value = weekText.value
            watermarkSubtitle.value = ""
            setHmText()
        }
        else {
            hmText.value ="--:--"
            weekText.value = "--"
            dateText.value = "--.--.--"
            amPmTimeZoneWeek.value = ""
            watermarkSubtitle.value = ""
        }
        }
        catch (e:Exception){
            val errorText = "initBase error  error:${e.message}"
            TencentCOSUtils.uploadErrorLog(App.context,errorText,"initBaseError")
        }
       // resetItem()
    }

    @SuppressLint("SuspiciousIndentation")
    fun resetItem(isCaptureCover:Boolean = false){
       // Log.d(TAG,"resetItem isCaptureCover:${isCaptureCover}  ${watermarkModel.value} ")
        try {
            val baseModel = watermarkModel.value?.clone()
            baseModel?.items?.forEach {
            if (it != null) {
                when(it.id){
                    //如果是时间，则赋值
                    WatermarkItemID.watermarkSubtitle.id ->{
                        if (it.isOpen == true){
                            watermarkSubtitle.value = it.content ?:""
                        }
                        else {
                            watermarkSubtitle.value = ""
                        }
                    }
                    WatermarkItemID.logo.id ->{
                        logoDrawable.value = false;
                        if (it.isOpen == true){
                           // Log.d(TAG,"logo url: ${it.logoInfo?.selectLogoPath}")
                            if(it.logoInfo?.position?.position == 0 ){
                                logoOpen.value = true
                                logoUrl.value = it.logoInfo?.selectLogoPath ?:""
                                if (logoUrl.value == "timeprint"){
                                    logoDrawable.value = true;
                                }
                                else {
                                    logoDrawable.value = false;
                                }
                               // Log.d(TAG,"logo url ==: ${logoUrl.value}")
                            }
                            else {
                                logoOpen.value = false
                                logoUrl.value = ""
                            }
                        }
                        else {
                            logoOpen.value = false
                            logoUrl.value = ""
                        }
                    }
                    WatermarkItemID.time.id -> {
                       // Log.d(TAG,"resetItem isCaptureCover:${isCaptureCover}  WatermarkItemID.time.id ${GpTimeManager.canMakeSureRealTime}")
                        //如果是cover 或者确定真实时间
                        val time = GpTimeManager.getExactTime()
                        if (GpTimeManager.canMakeSureRealTime || isCaptureCover){
                            val timeItem = it.extraTime
                            hmText.value = GpDateFormat.toHHmm(time, timeItem.is12Hour, timeItem.showWeek, timeItem.showTimeZone, timeItem.style)
                            weekText.value = GpDateFormat.toFullWeekText(time)
                            val dateTextItem = WatermarkTimeItem()
                            dateTextItem.style = timeItem.style
                            dateText.value = GpDateFormat.localizedDateString(Date(time), dateTextItem.style,  dateTextItem.is12Hour,false, false,false,true )
                            //设置
                            setHmText()
                            if(baseModel.id == WatermarkID.ID9_1.id) {
                                val dateTimeStringList =    GpDateFormat.getID9DateTimeString(Date(time), timeItem.style, timeItem.is12Hour)
                                val dateArr =   dateTimeStringList.first
                                val timeArray = dateTimeStringList.second
                                setId9TimeDrawableList(timeArray)
                                setId9DateDrawableList(dateArr)
                            }
                            amPmTimeZoneWeek.value = GpDateFormat.toAmPmTimeZoneWeek(time,timeItem)
                            it.content  = GpDateFormat.localizedDateString(Date(time), timeItem.style,  timeItem.is12Hour, timeItem.showWeek, timeItem.showTimeZone )
                        }
                        else {
                            hmText.value ="--:--"
                            weekText.value = "--"
                            it.content = "--.--.--"
                            dateText.value = "--.--.--"
                            amPmTimeZoneWeek.value = ""
                            watermarkSubtitle.value = ""
                        }
                        }
                    WatermarkItemID.weather.id -> {
                        //天气
                        var weatherInfo = GpWeatherManager.getWeatherInfo()
                        if (weatherInfo ==null && isCaptureCover) { //如果是截图cover模式，给一个假天气
                            weatherInfo = GpWeatherManager.getFakeWeatherInfo()
                            it.content  = weatherInfo?.showWeather(it.weatherStyle) ?:""
                        }
                        else {
                            it.content  = weatherInfo?.showWeather(it.weatherStyle) ?:""
                        }

                    }
                    WatermarkItemID.coordinate.id ->{
                        //设置一下
                        try {
                            var latLngArray = it.extraCoordinateInfo?.getShowLatLng()?.split(",")
                           // Log.d(TAG,"change lat lng: $latLngArray ===== ")
                            if (latLngArray !=null && latLngArray.size ==2){
                                lat.value = latLngArray[0]
                                lng.value = latLngArray[1]
                            }
                        }
                        catch (e:Exception){
                            Log.d(TAG,"getShowLatLng error ${e.message}")
                        }
                    }
                    //地址更新
                    WatermarkItemID.address.id ->{
                        if(it.extraAddressInfo!=null ) {
                            // Log.d(TAG,"BaseWatermarkViewModel address ${tempData.name} ${tempData.id}")
                            val lText = it.extraAddressInfo?.getShowAddress() ?:""
                            //必须是地址请求成功才行
                            if (App.isLocationSucc ){
                                locationText.value =  lText
                                it.content = lText
                            }
                            else if(!isCaptureCover){ //如果没请求地址成功并且是非isCaptureCover，则不显示地址
                                locationText.value =  ""
                                it.content = ""
                            }


                        }
                        else if(isCaptureCover){
                            // Log.d(TAG,"BaseWatermarkViewModel address isCaptureCover ${it}")
                            //如果截图
                            ServiceConfig.getLocationService().getLocationInfo()
                                if (ServiceConfig.getLocationService().getLocationInfo() !=null){
                                    ServiceConfig.getLocationService().getLocationInfo()
                                        ?.let { it1 -> resetLocationInfo(it1) }
                                }
                            else {
                                    it.extraAddressInfo = WatermarkAddressItem().apply {
                                        //Log.i(TAG,"isCaptureCover=== ${isCaptureCover} ${GpUiUtils.getLocalizedText("k_appstore_address")}")
                                        val address = Address(Locale.getDefault()).apply {
                                            locality = ""
                                            countryName = ""
                                            adminArea = ""
                                            subAdminArea = ""
                                            subLocality = ""
                                            subThoroughfare = ""
                                            thoroughfare = ""
                                            featureName = GpUiUtils.getString(R.string.k_appstore_address)
                                            postalCode = "100000"
                                            phone = "10086"
                                            url = "https://www.beijing.com"
                                            extras = null
                                        }
                                        address.setAddressLine(0,GpUiUtils.getString(R.string.k_appstore_address))
                                        rawAddress = listOf(address)
                                    }
                                    it.content = it.extraAddressInfo!!.getShowAddress()
                                }

                            locationText.value = it.extraAddressInfo?.getShowAddress() ?:""
                            it.content =  it.extraAddressInfo?.getShowAddress() ?:""
                        }
                    }
                    //标题
                    WatermarkItemID.watermarkTitle.id ->{
                        if (it.isOpen == true){
                            watermarkTitle.value = it.content ?:""
                        }
                        else {
                            watermarkTitle.value = ""
                        }
                    }
                    WatermarkItemID.note.id ->{
                        if(baseModel.id == WatermarkID.ID9_1.id){
                            if (it.isOpen == true ){
                                watermarkTitle.value = it.content ?:""
                            }
                            else {
                                watermarkTitle.value = ""
                            }
                        }
                    }

                    //会议
                    WatermarkItemID.wm8_meeting_title.id ->{
                        if (it.isOpen == true){
                            watermarkTitle.value = it.content ?:""
                        }
                        else {
                            watermarkTitle.value = ""
                        }
                    }
                    else -> {

                    }
                }
            }
        }
        //赋值以触发更新
        if(!isCaptureCover){
            watermarkModel.value = baseModel!!
        }

        }
        catch (e:Exception){
            val errorText = "resetItem error  error:${e.message}"
            TencentCOSUtils.uploadErrorLog(App.context,errorText,"resetItemError")
        }
    }
    private fun setId9DateDrawableList(idList: List<Int>){
        val tempList = mutableListOf<Int>()
        idList.forEach { tempList.add(WatermarkManager.getClockDrawable(it,false))  }
        _id9DateDrawableList.value = tempList
    }
    private fun setId9TimeDrawableList(idList: List<Int>){
        val tempList = mutableListOf<Int>()
        idList.forEach { tempList.add(WatermarkManager.getClockDrawable(it,true))  }
        _id9TimeDrawableList.value = tempList
    }

    private fun setHmText(){
        try {
            hmText.let {
                val hmText = it.value;
                _hm01.value =   WatermarkManager.getDigitDrawable(hmText?.get(0).toString().toInt())
                _hm02.value =  WatermarkManager.getDigitDrawable(hmText?.get(1).toString().toInt())
                _hm03.value =  WatermarkManager.getDigitDrawable(hmText?.get(3).toString().toInt())
                _hm04.value =  WatermarkManager.getDigitDrawable(hmText?.get(4).toString().toInt())
            }
        }
        catch (e:Exception){
            val errorText = "setHmText error  hmText:${hmText.value} error:${e.message}"
            TencentCOSUtils.uploadErrorLog(App.context,errorText,"setHmTextError")
        }

    }

    fun clean(){
       onCleared()
    }
    override fun onCleared() {
        super.onCleared()
        disposable.dispose()
        locationCompositeDisposable.dispose()
    }


}