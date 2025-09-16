package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.utils

import android.content.Context
object DisplayUtil {
    fun getScreenWidth(context: Context): Int {
//        : 1080 2230 resolution 1944 2592 viewHeight:1440
        val metric = context.resources.displayMetrics

        return metric.widthPixels
    }
    fun getScreenHeight(context: Context): Int {
        val metric = context.resources.displayMetrics
        return metric.heightPixels
    }
}