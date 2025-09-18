package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.rn
import android.content.Context
import com.facebook.react.bridge.*

/**
 *  rn 的登录bridge 模块
 *
 */
class AuthBridgeModule(reactContext: ReactApplicationContext) :
    ReactContextBaseJavaModule(reactContext) {

    override fun getName(): String = "AuthBridge"

    @ReactMethod
    fun saveSession(sessionJson: String) {
        println("👤 Logged in saveSession : $sessionJson ")
        val prefs = reactApplicationContext.getSharedPreferences("supabase", Context.MODE_PRIVATE)
        prefs.edit().putString("session", sessionJson).apply()
    }

    @ReactMethod
    fun getSession(promise: Promise) {
        val prefs = reactApplicationContext.getSharedPreferences("supabase", Context.MODE_PRIVATE)
        val session = prefs.getString("session", null)
        promise.resolve(session)
    }
}
