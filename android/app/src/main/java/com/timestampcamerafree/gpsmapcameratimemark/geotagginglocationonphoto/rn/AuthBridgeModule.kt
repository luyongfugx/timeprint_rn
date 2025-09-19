package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.rn
import android.content.Context
import android.util.Log
import com.facebook.react.bridge.*

/**
 *  rn 的登录bridge 模块
 *
 */
class AuthBridgeModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {
    //命名空间
    var namespace = "supabase"

    override fun getName(): String = "AuthBridge"

    @ReactMethod
    fun saveSession(sessionJson: String) {
        val prefs = reactApplicationContext.getSharedPreferences(namespace, Context.MODE_PRIVATE)
        prefs.edit().putString("session", sessionJson).apply()
    }

    @ReactMethod
    fun getSession(promise: Promise) {
        val prefs = reactApplicationContext.getSharedPreferences(namespace, Context.MODE_PRIVATE)
        val session = prefs.getString("session", null)
        promise.resolve(session)
    }

    @ReactMethod
    fun saveTeamInfo(teamInfo: String) {
        Log.d("AuthBridgeModule","saveTeamInfo: $teamInfo")
        val prefs = reactApplicationContext.getSharedPreferences(namespace, Context.MODE_PRIVATE)
        prefs.edit().putString("teamInfo", teamInfo).apply()
    }

    @ReactMethod
    fun getTeamInfo(promise: Promise) {
        val prefs = reactApplicationContext.getSharedPreferences(namespace, Context.MODE_PRIVATE)
        val teamInfo = prefs.getString("teamInfo", null)
        promise.resolve(teamInfo)
    }
}
