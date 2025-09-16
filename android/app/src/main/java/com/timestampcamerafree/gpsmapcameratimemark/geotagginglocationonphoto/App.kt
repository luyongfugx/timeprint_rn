package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto



import android.app.Application
import android.content.Context
import android.util.Log
import com.facebook.react.ReactApplication
import com.google.firebase.analytics.FirebaseAnalytics
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.ServiceConfig
import com.facebook.react.PackageList
import com.facebook.react.ReactHost
import com.facebook.react.ReactNativeApplicationEntryPoint.loadReactNative
import com.facebook.react.ReactNativeHost
import com.facebook.react.ReactPackage
import com.facebook.react.defaults.DefaultReactHost.getDefaultReactHost
import com.facebook.react.defaults.DefaultReactNativeHost

class App : Application() , ReactApplication {

    companion object {
        val TAG ="App"
        lateinit var context: Context
        lateinit var mFirebaseAnalytics:FirebaseAnalytics ;
        //是否网络连接
        var isNetWorkConnected = false;
        //是否获取经纬度成功
        var isLocationSucc = false;
        //显示一次就行
        var isShowLocationTip = false;
        //点击到了权限
        var isFromPermission = false;
        //是否获取时间错误
        var isTimeError =  false;
    }
    override val reactNativeHost: ReactNativeHost =
        object : DefaultReactNativeHost(this) {
            override fun getPackages(): List<ReactPackage> =
                PackageList(this).packages.apply {
                    // Packages that cannot be autolinked yet can be added manually here, for example:
                    // add(MyReactNativePackage())
                }

            override fun getJSMainModuleName(): String = "index"

            override fun getUseDeveloperSupport(): Boolean =  BuildConfig.DEBUG

            override val isNewArchEnabled: Boolean = BuildConfig.IS_NEW_ARCHITECTURE_ENABLED
            override val isHermesEnabled: Boolean = BuildConfig.IS_HERMES_ENABLED
        }

    override val reactHost: ReactHost
        get() = getDefaultReactHost(applicationContext, reactNativeHost)

    override fun onCreate() {
        super.onCreate()
        loadReactNative(this)
        context = applicationContext
        //统计类接入
        mFirebaseAnalytics = FirebaseAnalytics.getInstance(this);
        AnalyticsManager.mFirebaseAnalytics = mFirebaseAnalytics
        AnalyticsManager.logEvent("App_Start")
        //服务初始化
        ServiceConfig.init()
        //loadReactNative

        Log.d(TAG,"ReactApplication useDeveloperSupport:${reactNativeHost.useDeveloperSupport} ${reactNativeHost}")
    }
}



//class App : Application() {
//    companion object {
//        lateinit var context: Context
//        lateinit var mFirebaseAnalytics:FirebaseAnalytics ;
//        //是否网络连接
//        var isNetWorkConnected = false;
//        //是否获取经纬度成功
//        var isLocationSucc = false;
//        //显示一次就行
//        var isShowLocationTip = false;
//        //点击到了权限
//        var isFromPermission = false;
//        //是否获取时间错误
//        var isTimeError =  false;
//    }
//
//    override fun onCreate() {
//        super.onCreate()
//        context = applicationContext
//        //统计类接入
//        mFirebaseAnalytics = FirebaseAnalytics.getInstance(this);
//        AnalyticsManager.mFirebaseAnalytics = mFirebaseAnalytics
//        AnalyticsManager.initGaSessionId()
//        AnalyticsManager.logEvent("App_Start")
//        //服务初始化
//        ServiceConfig.init()
//
//    }
//}
