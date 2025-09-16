package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto

import android.app.Application
import android.content.Context
import android.os.Bundle
import com.google.firebase.analytics.FirebaseAnalytics
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers.AnalyticsManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.services.ServiceConfig
import java.util.UUID


class App : Application() {
    companion object {
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

    override fun onCreate() {
        super.onCreate()
        context = applicationContext
        //统计类接入
        mFirebaseAnalytics = FirebaseAnalytics.getInstance(this);
        AnalyticsManager.mFirebaseAnalytics = mFirebaseAnalytics
        AnalyticsManager.initGaSessionId()
        AnalyticsManager.logEvent("App_Start")
        //服务初始化
        ServiceConfig.init()

    }
}
