package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils

import android.content.Context
import android.content.res.Resources
import android.os.Build
import android.util.DisplayMetrics
import android.view.Display
import com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.App
import android.provider.Settings
import android.util.Log

object GPAppUtils {
       //是否新版
        fun isNewVer(newVer:String):Boolean {
            try {
                val curVer = App.context.packageManager.getPackageInfo(App.context.packageName, 0).versionName
                val intCurVer = curVer?.replace(".","")?.toInt()
                val intNewVer = newVer.replace(".","").toInt()
                return intNewVer > intCurVer!!
            }
            catch (e:Exception) {
                return false;
            }

        }

        fun getDeviceInfoString():String {
          return   getDeviceBrand() +"_"+ getDeviceManufacturer() +"_"+ getDeviceModel() +
                    "_"+ getAndroidVersion() +"_"+ getSDKVersion()
        }
        fun getDeviceModel(): String {
            return Build.MODEL
        }

        fun getDeviceManufacturer(): String {
            return Build.MANUFACTURER
        }

        fun getDeviceBrand(): String {
            return Build.BRAND
        }

        fun getAndroidVersion(): String {
            return Build.VERSION.RELEASE
        }

        fun getSDKVersion(): Int {
            return Build.VERSION.SDK_INT
        }
    fun getStatusBarHeight(context: Context): Int {
        var result = 0
        val resourceId = context.resources.getIdentifier(
            "status_bar_height", "dimen", "android"
        )
        if (resourceId > 0) {
            result = context.resources.getDimensionPixelSize(resourceId)
        }
        return result
    }
    fun getNavigationBarHeight(resources: Resources, d: Display): Int {
        var result = 0
        val resourceId = resources.getIdentifier("navigation_bar_height", "dimen", "android")
        if (resourceId > 0 && checkHasNavigationBar(d)) {
            result = resources.getDimensionPixelSize(resourceId)
        }
        return result
    }
    private fun checkHasNavigationBar(d: Display): Boolean {
        val realDisplayMetrics = DisplayMetrics()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
            d.getRealMetrics(realDisplayMetrics)
        }

        val realHeight = realDisplayMetrics.heightPixels
        val realWidth = realDisplayMetrics.widthPixels

        val displayMetrics = DisplayMetrics()
        d.getMetrics(displayMetrics)

        val displayHeight = displayMetrics.heightPixels
        val displayWidth = displayMetrics.widthPixels

        return (realWidth - displayWidth) > 0 || (realHeight - displayHeight) > 0
    }

}
