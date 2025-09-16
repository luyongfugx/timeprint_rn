package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils

import android.content.Context
import android.util.Log

import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.watermark.WatermarkManager.Companion


/**
 *  add by waynelu
 *  本地存储接口
 */
class LocalStorageManager{
    companion object {
        const val prefixLocalKey = "pre_key_"
        private val sharedPreferences = App.context.getSharedPreferences(prefixLocalKey, Context.MODE_PRIVATE)
        fun save(key: String, json: String) {
            val editor = sharedPreferences.edit()
            editor.putString(key, json)
            editor.apply()
        }

        fun getString(key: String): String? {
            Log.e("LocalStorageManager","getWaterModelByID LocalStorageManager :${key}")
            val json = sharedPreferences.getString(key, null) ?: return null
            return json;
            // return Gson().fromJson(json, T::class.java)
        }
        fun savePhoneBootTime(time: Long) {
            val editor = sharedPreferences.edit()
            editor.putString("phoneBootTime", time.toString())
            editor.apply()
        }

        fun getPhoneBootTime(): Long {
            val tm =  sharedPreferences.getString("phoneBootTime", "-1") ?: return -1;
           return  tm.toLong()

        }
        //设置曾经连过网
        fun saveHasNetWork(time: Long) {
            val editor = sharedPreferences.edit()
            editor.putString("HasNetWork", time.toString())
            editor.apply()
        }
       //曾经连过网
        fun getHasNetWork(): Long {
            val tm =  sharedPreferences.getString("HasNetWork", "-1") ?: return -1;
            return  tm.toLong()

        }


    }
    //

}
