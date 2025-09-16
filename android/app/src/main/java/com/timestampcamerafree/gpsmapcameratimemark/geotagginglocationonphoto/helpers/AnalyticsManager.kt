package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import android.location.Location
import android.os.Bundle
import android.util.Log
import androidx.window.area.WindowAreaSession
import com.google.firebase.analytics.FirebaseAnalytics
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App.Companion
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils.GPAppUtils

/**
 * 统计管理类
 *
 */
object AnalyticsManager {

        lateinit var mFirebaseAnalytics: FirebaseAnalytics

        private var TAG ="AnalyticsManager"
        private var analyticsManagerSessionId: Long = 0;
        fun logEvent(event:String) {
            try {
                val finalEvt = "$event"
                val bundle = Bundle()
                val ver = App.context.packageManager.getPackageInfo(App.context.packageName, 0).versionName
                bundle.putString(FirebaseAnalytics.Param.ITEM_ID, event)
                //item_name 设为app 版本
                bundle.putString(FirebaseAnalytics.Param.ITEM_NAME, ver)
                //增加一个设备状况
                bundle.putString(FirebaseAnalytics.Param.SOURCE_PLATFORM, GPAppUtils.getDeviceInfoString())
                mFirebaseAnalytics.logEvent(finalEvt, bundle)
            }
            catch (e:Exception){
                 Log.d(TAG, "logEvent error: ${e.message}")
            }
        }
        fun initGaSessionId() {
           // Log.d(TAG, "analyticsManagerSessionId initGaSessionId ==")
            try {
                mFirebaseAnalytics.sessionId.addOnSuccessListener {
                    try {
                        analyticsManagerSessionId = it
                    }
                    catch (e:Exception){
                        Log.d(TAG, "addOnSuccessListener error: ${e.message}")
                    }
                   // Log.d(TAG, "analyticsManagerSessionId addOnSuccessListener $analyticsManagerSessionId")
                }
            }
            catch (ex:Exception){
                Log.d(TAG, "initGaSessionId error: ${ex.message}")
            }
        }
        fun getGaSessionId():Long{
            return analyticsManagerSessionId
        }

}