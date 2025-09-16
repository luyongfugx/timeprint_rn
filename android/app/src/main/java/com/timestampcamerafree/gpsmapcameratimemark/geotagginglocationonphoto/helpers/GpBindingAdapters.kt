package com.timestampcamerafree.gpsmapcameratimemark.geotagginglocationonphoto.helpers

import android.graphics.Color
import android.graphics.drawable.ColorDrawable
import android.view.View
import androidx.databinding.BindingAdapter

/**
 * 设置颜色30%的透明度，在地图水印背景使用
 */
object GpBindingAdapters {
    @BindingAdapter("android:backgroundWith30Transparency")
    @JvmStatic
    fun setBackgroundWith30Transparency(view: View, color: Int?) {
        if (color == null) {
            view.background = null
            return
        }

        val red = Color.red(color)
        val green = Color.green(color)
        val blue = Color.blue(color)
        val alpha = (255 * 0.30).toInt() //

        val transparentColor = Color.argb(alpha, red, green, blue)
        view.background = ColorDrawable(transparentColor)
    }
}